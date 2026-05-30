import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../data/timesheets_repository.dart';

class TimesheetsScreen extends ConsumerStatefulWidget {
  const TimesheetsScreen({super.key});

  static const routePath = '/timesheets';

  @override
  ConsumerState<TimesheetsScreen> createState() => _TimesheetsScreenState();
}

class _TimesheetsScreenState extends ConsumerState<TimesheetsScreen> {
  late DateTime _begin;
  late DateTime _end;
  String? _projectId;
  String _searchText = '';
  TimesheetSortField _sortField = TimesheetSortField.date;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _begin = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1);
  }

  @override
  Widget build(BuildContext context) {
    final filters = TimesheetFilters(
      begin: _begin,
      end: _end,
      appProjectId: _projectId,
      searchText: _searchText,
      sortField: _sortField,
      sortAscending: _sortAscending,
    );
    final entries = ref.watch(_filteredTimesheetsProvider(filters));
    final totals = ref.watch(_timesheetTotalsProvider(filters));
    final projects = ref.watch(_availableProjectsProvider);

    return AppScreen(
      title: 'Учёт времени',
      subtitle: 'Записи времени из Kimai.',
      children: [
        AppPanel(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(
                  '${DateTimeFormats.compactDate.format(_begin)} - '
                  '${DateTimeFormats.compactDate.format(_end.subtract(const Duration(days: 1)))}',
                ),
              ),
              SizedBox(
                width: 220,
                child: projects.when(
                  data: (items) => DropdownButtonFormField<String?>(
                    initialValue: _projectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Проект'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Все проекты',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final project in items)
                        DropdownMenuItem(
                          value: project.appProjectId,
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Активность или описание',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<TimesheetSortField>(
                  initialValue: _sortField,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Сортировка'),
                  items: const [
                    DropdownMenuItem(
                      value: TimesheetSortField.date,
                      child: Text('Дата', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: TimesheetSortField.duration,
                      child: Text(
                        'Длительность',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: TimesheetSortField.amount,
                      child: Text('Сумма', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortField = value);
                    }
                  },
                ),
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _sortAscending = !_sortAscending),
                icon: Icon(
                  _sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                ),
                tooltip: _sortAscending ? 'По возрастанию' : 'По убыванию',
              ),
              OutlinedButton.icon(
                onPressed: () => _exportCsv(filters),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Экспорт CSV'),
              ),
            ],
          ),
        ),
        totals.when(
          data: (value) => TimesheetTotalsBar(
            summary: value,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Итоги недоступны',
            message: error.toString(),
          ),
        ),
        entries.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Нет записей за выбранный период',
                message: 'Синхронизируйте Kimai или измените фильтры.',
              );
            }

            return TimesheetsTable(
              entries: items,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Записи недоступны',
            message: error.toString(),
            action: _CopyErrorButton(error: error),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _begin,
        end: _end.subtract(const Duration(days: 1)),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _begin = DateTime(
        selected.start.year,
        selected.start.month,
        selected.start.day,
      );
      _end = DateTime(
        selected.end.year,
        selected.end.month,
        selected.end.day,
      ).add(const Duration(days: 1));
    });
  }

  Future<void> _exportCsv(TimesheetFilters filters) async {
    final entries = await ref
        .read(timesheetsRepositoryProvider)
        .getTimesheetsFiltered(filters);
    final csv = _buildCsv(entries);
    await Clipboard.setData(ClipboardData(text: csv));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV скопирован: ${entries.length} строк')),
      );
    }
  }

  String _buildCsv(List<TimesheetEntry> entries) {
    final rows = <List<String>>[
      [
        'date',
        'project',
        'activity',
        'description',
        'duration_hours',
        'duration_minutes',
        'duration_human',
        'rate',
        'amount',
      ],
      for (final entry in entries)
        [
          entry.timesheet.beginAt.toLocal().toIso8601String(),
          entry.projectName,
          entry.timesheet.activityName ?? '',
          entry.timesheet.description ?? '',
          (entry.timesheet.durationSeconds / 3600).toStringAsFixed(2),
          (entry.timesheet.durationSeconds ~/ 60).toString(),
          formatDurationSeconds(entry.timesheet.durationSeconds),
          entry.hourlyRateMinor == null
              ? ''
              : (entry.hourlyRateMinor! / 100).toStringAsFixed(2),
          entry.timesheet.amountMinor == null
              ? ''
              : (entry.timesheet.amountMinor! / 100).toStringAsFixed(2),
        ],
    ];

    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }

    return escaped;
  }
}

class TimesheetTotalsBar extends StatelessWidget {
  const TimesheetTotalsBar({
    required this.summary,
    super.key,
  });

  final TimesheetSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _TotalItem(
            label: 'Всего времени',
            value: formatDurationSeconds(summary.totalSeconds),
          ),
          _TotalItem(
            label: 'Сумма',
            value: formatMoneyRub(summary.amountMinor),
          ),
          _TotalItem(
            label: 'Записи',
            value: summary.entryCount.toString(),
          ),
        ],
      ),
    );
  }
}

class TimesheetsTable extends StatelessWidget {
  const TimesheetsTable({
    required this.entries,
    super.key,
  });

  final List<TimesheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.bodyMedium,
          dataTextStyle: Theme.of(context).textTheme.bodyMedium,
          dividerThickness: 1,
          columns: const [
            DataColumn(label: Text('Дата')),
            DataColumn(label: Text('Проект')),
            DataColumn(label: Text('Активность')),
            DataColumn(label: Text('Описание')),
            DataColumn(label: Text('Длительность')),
            DataColumn(label: Text('Ставка')),
            DataColumn(label: Text('Сумма')),
          ],
          rows: [
            for (final entry in entries)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${DateTimeFormats.date.format(entry.timesheet.beginAt.toLocal())} '
                      '${DateTimeFormats.time.format(entry.timesheet.beginAt.toLocal())}',
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        _ColorDot(color: entry.projectColor),
                        const SizedBox(width: 8),
                        Text(entry.projectName),
                      ],
                    ),
                  ),
                  DataCell(Text(entry.timesheet.activityName ?? '-')),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        entry.timesheet.description ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatDurationSeconds(entry.timesheet.durationSeconds),
                    ),
                  ),
                  DataCell(
                    Text(
                      entry.hourlyRateMinor == null
                          ? '-'
                          : formatMoneyRub(entry.hourlyRateMinor!),
                    ),
                  ),
                  DataCell(
                    Text(
                      entry.timesheet.amountMinor == null
                          ? '-'
                          : formatMoneyRub(entry.timesheet.amountMinor!),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  const _TotalItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({this.color});

  final String? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _parseColor(color),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }

  Color _parseColor(String? value) {
    if (value == null || !value.startsWith('#') || value.length != 7) {
      return AppColors.textMuted;
    }

    final parsed = int.tryParse(value.substring(1), radix: 16);
    if (parsed == null) {
      return AppColors.textMuted;
    }

    return Color(0xFF000000 | parsed);
  }
}

class _CopyErrorButton extends StatelessWidget {
  const _CopyErrorButton({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: error.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка скопирована')),
          );
        }
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text('Скопировать ошибку'),
    );
  }
}

final _filteredTimesheetsProvider = StreamProvider.autoDispose
    .family<List<TimesheetEntry>, TimesheetFilters>((ref, filters) {
  return ref
      .watch(timesheetsRepositoryProvider)
      .watchTimesheetsFiltered(filters);
});

final _timesheetTotalsProvider = StreamProvider.autoDispose
    .family<TimesheetSummary, TimesheetFilters>((ref, filters) {
  return ref.watch(timesheetsRepositoryProvider).watchTimesheetTotals(filters);
});

final _availableProjectsProvider =
    FutureProvider.autoDispose<List<TimesheetProjectOption>>((ref) {
  return ref
      .watch(timesheetsRepositoryProvider)
      .getAvailableTimesheetProjects();
});
