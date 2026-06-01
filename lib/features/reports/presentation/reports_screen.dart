import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/responsive_data_table.dart';
import '../data/reports_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  static const routePath = '/reports';

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _begin;
  late DateTime _end;
  int? _projectId;
  int? _userId;
  String _activity = '';
  bool _includeDetails = true;
  ReportSortField _sortField = ReportSortField.user;
  bool _sortAscending = true;
  ReportResult? _result;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _begin = DateTime(now.year, now.month);
    _end = DateTime(now.year, now.month + 1);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(reportProjectsProvider);
    final users = ref.watch(reportUsersProvider);
    final accessInfo = ref.watch(reportAccessInfoProvider);

    return AppScreen(
      title: 'Отчёты',
      subtitle: 'Детализация времени по проекту, периоду и людям из Kimai.',
      actions: [
        OutlinedButton.icon(
          onPressed: _result == null ? null : _exportSummaryCsv,
          icon: const Icon(Icons.summarize_rounded, size: 18),
          label: const Text('CSV сводка'),
        ),
        OutlinedButton.icon(
          onPressed: _result == null ? null : _exportDetailsCsv,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('CSV детали'),
        ),
      ],
      children: [
        accessInfo.when(
          data: _AccessPanel.new,
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Режим недоступен',
            message: error.toString(),
          ),
        ),
        AppFilterBar(
          children: [
            SizedBox(
              width: 280,
              child: projects.when(
                data: (items) {
                  _hydrateProject(items);
                  return DropdownButtonFormField<int>(
                    initialValue: _projectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Проект'),
                    items: [
                      for (final project in items)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(error.toString()),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(
                '${DateTimeFormats.compactDate.format(_begin)} - '
                '${DateTimeFormats.compactDate.format(_end.subtract(const Duration(days: 1)))}',
              ),
            ),
            SizedBox(
              width: 240,
              child: users.when(
                data: (items) => DropdownButtonFormField<int?>(
                  initialValue: _userId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Пользователь'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все доступные'),
                    ),
                    for (final user in items)
                      DropdownMenuItem<int?>(
                        value: user.id,
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _userId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(error.toString()),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Активность',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                ),
                onChanged: (value) => setState(() => _activity = value),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<ReportSortField>(
                initialValue: _sortField,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Сортировка'),
                items: const [
                  DropdownMenuItem(
                    value: ReportSortField.user,
                    child: Text('Пользователь'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.duration,
                    child: Text('Время'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.amount,
                    child: Text('Сумма'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.date,
                    child: Text('Дата'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.entriesCount,
                    child: Text('Записей'),
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
              onPressed: () {
                setState(() => _sortAscending = !_sortAscending);
                if (_result != null) {
                  _loadReport();
                }
              },
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
              ),
              tooltip: _sortAscending ? 'По возрастанию' : 'По убыванию',
            ),
            FilterChip(
              selected: _includeDetails,
              onSelected: (value) => setState(() => _includeDetails = value),
              label: const Text('Детали'),
              avatar: const Icon(Icons.list_alt_rounded, size: 18),
            ),
            FilledButton.icon(
              onPressed: _loading || _projectId == null ? null : _loadReport,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_loading ? 'Формирование' : 'Сформировать'),
            ),
          ],
        ),
        if (_error != null)
          EmptyState(
            title: 'Отчёт недоступен',
            message: _error.toString(),
            action: _CopyErrorButton(error: _error!),
          ),
        if (_result != null) ReportWarningsPanel(result: _result!),
        if (_result != null)
          ReportSummaryTable(
            items: _result!.userSummaries,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
          ),
        if (_includeDetails && _result != null)
          ReportDetailsTable(
            items: _result!.entries,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
          ),
        if (_result == null && !_loading && _error == null)
          const EmptyState(
            title: 'Отчёт ещё не сформирован',
            message: 'Выберите проект и период, затем сформируйте отчёт.',
          ),
      ],
    );
  }

  void _hydrateProject(List<ReportProjectOption> projects) {
    if (_projectId != null || projects.isEmpty) {
      return;
    }

    _projectId = projects.first.id;
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
      _end = DateTime(selected.end.year, selected.end.month, selected.end.day)
          .add(const Duration(days: 1));
    });
  }

  Future<void> _loadReport() async {
    final projectId = _projectId;
    if (projectId == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = await ref.read(reportsRepositoryProvider.future);
      final result = await repository.buildReport(
        ReportQuery(
          projectId: projectId,
          begin: _begin,
          end: _end,
          userId: _userId,
          activity: _activity,
          sortField: _sortField,
          sortAscending: _sortAscending,
        ),
      );
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _result = null;
          _error = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onSort(String key, bool ascending) async {
    setState(() {
      _sortField = _sortFieldFromKey(key);
      _sortAscending = ascending;
    });
    if (_result != null) {
      await _loadReport();
    }
  }

  Future<void> _exportSummaryCsv() async {
    final result = _result;
    if (result == null) {
      return;
    }

    final rows = <List<String>>[
      ['Пользователь', 'Минуты', 'Длительность', 'Записей', 'Сумма'],
      for (final item in result.userSummaries)
        [
          item.userName,
          item.totalMinutes.toString(),
          formatDurationSeconds(item.totalDurationSeconds),
          item.entriesCount.toString(),
          item.totalAmountMinor == 0
              ? ''
              : (item.totalAmountMinor / 100).toStringAsFixed(2),
        ],
    ];

    await _copyCsv(rows, 'CSV сводки скопирован');
  }

  Future<void> _exportDetailsCsv() async {
    final result = _result;
    if (result == null) {
      return;
    }

    final rows = <List<String>>[
      [
        'Дата',
        'Пользователь',
        'Проект',
        'Активность',
        'Описание',
        'Начало',
        'Конец',
        'Минуты',
        'Длительность',
        'Сумма',
      ],
      for (final entry in result.entries)
        [
          DateTimeFormats.date.format(entry.begin.toLocal()),
          entry.userName,
          entry.projectName,
          entry.activity,
          entry.description,
          DateTimeFormats.time.format(entry.begin.toLocal()),
          entry.end == null
              ? ''
              : DateTimeFormats.time.format(entry.end!.toLocal()),
          entry.durationMinutes.toString(),
          entry.durationHuman,
          entry.amountMinor == null
              ? ''
              : (entry.amountMinor! / 100).toStringAsFixed(2),
        ],
    ];

    await _copyCsv(rows, 'CSV деталей скопирован');
  }

  Future<void> _copyCsv(List<List<String>> rows, String message) async {
    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
    await Clipboard.setData(ClipboardData(text: '\uFEFF$csv'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message: ${rows.length - 1} строк')),
      );
    }
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

  ReportSortField _sortFieldFromKey(String key) {
    return switch (key) {
      'duration' => ReportSortField.duration,
      'amount' => ReportSortField.amount,
      'date' => ReportSortField.date,
      'entries' => ReportSortField.entriesCount,
      _ => ReportSortField.user,
    };
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel(this.info);

  final ReportAccessInfo info;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppStatusChip(
            label: 'Режим: ${info.mode.label}',
            color: info.mode == AppMode.pmAdmin
                ? AppColors.accent
                : AppColors.textMuted,
          ),
          AppStatusChip(
            label: info.detectedAdminCapability
                ? 'Права Kimai обнаружены'
                : 'Права Kimai не подтверждены',
            color: info.detectedAdminCapability
                ? AppColors.accent
                : AppColors.warning,
          ),
          Text(
            info.currentUserName.isEmpty
                ? 'Текущий пользователь Kimai не определён.'
                : 'Пользователь: ${info.currentUserName}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (info.warning != null)
            Text(
              info.warning!,
              style: const TextStyle(color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

class ReportWarningsPanel extends StatelessWidget {
  const ReportWarningsPanel({required this.result, super.key});

  final ReportResult result;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _TotalItem(
                label: 'Пользователей',
                value: result.userSummaries.length.toString(),
              ),
              _TotalItem(
                label: 'Записей',
                value: result.entries.length.toString(),
              ),
              _TotalItem(
                label: 'Время',
                value: formatDurationSeconds(
                  result.entries.fold(
                    0,
                    (sum, item) => sum + item.durationSeconds,
                  ),
                ),
              ),
              _TotalItem(
                label: 'Сумма',
                value: formatMoneyRub(
                  result.entries.fold(
                    0,
                    (sum, item) => sum + (item.amountMinor ?? 0),
                  ),
                ),
              ),
            ],
          ),
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final warning in result.warnings)
              Text(warning, style: const TextStyle(color: AppColors.warning)),
          ],
          const SizedBox(height: 8),
          Text(
            'XLSX: TODO после CSV-экспорта, чтобы не добавлять зависимость без необходимости.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class ReportSummaryTable extends StatelessWidget {
  const ReportSummaryTable({
    required this.items,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    super.key,
  });

  final List<UserReportSummary> items;
  final ReportSortField sortField;
  final bool sortAscending;
  final void Function(String key, bool ascending) onSort;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable<UserReportSummary>(
      items: items,
      sortColumnKey: _sortKey(sortField),
      sortAscending: sortAscending,
      onSort: onSort,
      columns: [
        AppTableColumn(
          key: 'user',
          label: 'Пользователь',
          width: 220,
          cellBuilder: (context, item) => Text(
            item.userName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'duration',
          label: 'Время',
          width: 120,
          cellBuilder: (context, item) => Text(
            formatDurationSeconds(item.totalDurationSeconds),
          ),
        ),
        AppTableColumn(
          key: 'minutes',
          label: 'Минуты',
          width: 90,
          sortable: false,
          numeric: true,
          cellBuilder: (context, item) => Text(item.totalMinutes.toString()),
        ),
        AppTableColumn(
          key: 'entries',
          label: 'Записей',
          width: 90,
          numeric: true,
          cellBuilder: (context, item) => Text(item.entriesCount.toString()),
        ),
        AppTableColumn(
          key: 'amount',
          label: 'Сумма',
          width: 120,
          numeric: true,
          cellBuilder: (context, item) => Text(
            item.totalAmountMinor == 0
                ? '-'
                : formatMoneyRub(item.totalAmountMinor),
          ),
        ),
      ],
      emptyTitle: 'Сводка пуста',
      emptyMessage: 'Kimai не вернул записей по выбранным фильтрам.',
      mobileCardBuilder: (context, item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.userName, style: Theme.of(context).textTheme.titleMedium),
          Text(formatDurationSeconds(item.totalDurationSeconds)),
          Text('Записей: ${item.entriesCount}'),
          Text(
            item.totalAmountMinor == 0
                ? '-'
                : formatMoneyRub(item.totalAmountMinor),
          ),
        ],
      ),
    );
  }
}

class ReportDetailsTable extends StatelessWidget {
  const ReportDetailsTable({
    required this.items,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    super.key,
  });

  final List<ReportTimesheetEntry> items;
  final ReportSortField sortField;
  final bool sortAscending;
  final void Function(String key, bool ascending) onSort;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable<ReportTimesheetEntry>(
      items: items,
      sortColumnKey: _sortKey(sortField),
      sortAscending: sortAscending,
      onSort: onSort,
      columns: [
        AppTableColumn(
          key: 'date',
          label: 'Дата',
          width: 110,
          cellBuilder: (context, item) => Text(
            DateTimeFormats.date.format(item.begin.toLocal()),
          ),
        ),
        AppTableColumn(
          key: 'user',
          label: 'Пользователь',
          width: 180,
          cellBuilder: (context, item) => Text(
            item.userName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'project',
          label: 'Проект',
          width: 180,
          sortable: false,
          cellBuilder: (context, item) => Text(
            item.projectName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'activity',
          label: 'Активность',
          width: 160,
          sortable: false,
          cellBuilder: (context, item) => Text(
            item.activity.isEmpty ? '-' : item.activity,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'description',
          label: 'Описание',
          width: 260,
          sortable: false,
          cellBuilder: (context, item) => Tooltip(
            message: item.description.isEmpty ? '-' : item.description,
            child: Text(
              item.description.isEmpty ? '-' : item.description,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        AppTableColumn(
          key: 'begin',
          label: 'Начало',
          width: 80,
          sortable: false,
          cellBuilder: (context, item) => Text(
            DateTimeFormats.time.format(item.begin.toLocal()),
          ),
        ),
        AppTableColumn(
          key: 'end',
          label: 'Конец',
          width: 80,
          sortable: false,
          cellBuilder: (context, item) => Text(
            item.end == null
                ? '-'
                : DateTimeFormats.time.format(item.end!.toLocal()),
          ),
        ),
        AppTableColumn(
          key: 'duration',
          label: 'Длительность',
          width: 120,
          cellBuilder: (context, item) => Text(item.durationHuman),
        ),
        AppTableColumn(
          key: 'amount',
          label: 'Сумма',
          width: 110,
          numeric: true,
          cellBuilder: (context, item) => Text(
            item.amountMinor == null ? '-' : formatMoneyRub(item.amountMinor!),
          ),
        ),
      ],
      emptyTitle: 'Детализация пуста',
      emptyMessage: 'Kimai не вернул записей по выбранным фильтрам.',
      mobileCardBuilder: (context, item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.userName, style: Theme.of(context).textTheme.titleMedium),
          Text('${item.projectName} · ${item.durationHuman}'),
          Text(
            '${DateTimeFormats.date.format(item.begin.toLocal())} '
            '${DateTimeFormats.time.format(item.begin.toLocal())}',
          ),
          if (item.activity.isNotEmpty) Text(item.activity),
          if (item.description.isNotEmpty)
            Text(item.description, overflow: TextOverflow.ellipsis),
          Text(
            item.amountMinor == null ? '-' : formatMoneyRub(item.amountMinor!),
          ),
        ],
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

String _sortKey(ReportSortField field) {
  return switch (field) {
    ReportSortField.duration => 'duration',
    ReportSortField.amount => 'amount',
    ReportSortField.date => 'date',
    ReportSortField.entriesCount => 'entries',
    ReportSortField.user => 'user',
  };
}
