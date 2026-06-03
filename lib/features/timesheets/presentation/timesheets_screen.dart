import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/export/export_file_saver.dart';
import '../../../core/export/report_file_exporter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/tags.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/responsive_data_table.dart';
import '../../local_tracking/data/local_tracking_repository.dart';
import '../data/timesheet_edit_service.dart';
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
  String? _tag;
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
      tag: _tag,
      searchText: _searchText,
      sortField: _sortField,
      sortAscending: _sortAscending,
    );
    final entries = ref.watch(_filteredTimesheetsProvider(filters));
    final totals = ref.watch(_timesheetTotalsProvider(filters));
    final projects = ref.watch(_availableProjectsProvider);
    final tags = ref.watch(_availableTagsProvider);

    return AppScreen(
      title: 'Учёт времени',
      subtitle: 'Записи времени из Kimai.',
      expandContent: true,
      children: [
        AppFilterBar(
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
                    const DropdownMenuItem<String?>(
                      value: null,
                      child:
                          Text('Все проекты', overflow: TextOverflow.ellipsis),
                    ),
                    for (final project in items)
                      DropdownMenuItem<String?>(
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
              width: 180,
              child: tags.when(
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _tag,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Метки'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Все метки', overflow: TextOverflow.ellipsis),
                    ),
                    for (final tag in items)
                      DropdownMenuItem<String?>(
                        value: tag,
                        child: Text(tag, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _tag = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(error.toString()),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Активность, описание, проект или метка',
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
                    value: TimesheetSortField.project,
                    child: Text('Проект', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: TimesheetSortField.activity,
                    child: Text('Активность', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: TimesheetSortField.duration,
                    child:
                        Text('Длительность', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: TimesheetSortField.amount,
                    child: Text('Сумма', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: TimesheetSortField.status,
                    child: Text('Статус', overflow: TextOverflow.ellipsis),
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
              onPressed: () => setState(() => _sortAscending = !_sortAscending),
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
              label: const Text('CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportXlsx(filters),
              icon: const Icon(Icons.table_view_rounded, size: 18),
              label: const Text('XLSX'),
            ),
          ],
        ),
        totals.when(
          data: (value) => TimesheetTotalsBar(summary: value),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Итоги недоступны',
            message: error.toString(),
          ),
        ),
        entries.when(
          data: (items) => TimesheetsTable(
            entries: items,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
            onEdit: _editTimesheet,
            onDelete: _deleteTimesheet,
          ),
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
    await _saveExport(
      fileName: _fileName('csv'),
      bytes: buildCsvBytes(_exportRows(entries)),
      mimeType: 'text/csv',
    );
  }

  Future<void> _exportXlsx(TimesheetFilters filters) async {
    final entries = await ref
        .read(timesheetsRepositoryProvider)
        .getTimesheetsFiltered(filters);
    await _saveExport(
      fileName: _fileName('xlsx'),
      bytes: buildXlsxBytes([
        ExportSheet(name: 'Timesheets', rows: _exportRows(entries)),
      ]),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _saveExport({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final result = await saveOrShareExportFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.shared
              ? 'Файл отчёта готов к отправке'
              : 'Файл отчёта сохранён',
        ),
      ),
    );
  }

  List<List<Object?>> _exportRows(List<TimesheetEntry> entries) {
    return [
      [
        'Дата',
        'Проект',
        'Активность',
        'Метки',
        'Описание',
        'Минуты',
        'Длительность',
        'Ставка',
        'Сумма',
        'Статус',
      ],
      for (final entry in entries)
        [
          entry.beginAt.toLocal().toIso8601String(),
          entry.projectName,
          entry.activityName ?? '',
          formatTagsForDisplay(entry.tags),
          entry.description ?? '',
          entry.durationSeconds ~/ 60,
          formatDurationSeconds(entry.durationSeconds),
          entry.hourlyRateMinor == null
              ? null
              : (entry.hourlyRateMinor! / 100).toStringAsFixed(2),
          entry.amountMinor == null
              ? null
              : (entry.amountMinor! / 100).toStringAsFixed(2),
          entry.localStatus?.label ?? 'Kimai',
        ],
    ];
  }

  String _fileName(String extension) {
    final project = _projectId ?? 'all';
    final from = DateTimeFormats.compactDate.format(_begin);
    final to = DateTimeFormats.compactDate.format(
      _end.subtract(const Duration(days: 1)),
    );

    return 'outstaff_report_${_safeFilePart(project)}_${_safeFilePart(from)}_${_safeFilePart(to)}.$extension';
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-zА-Яа-я0-9._-]+'), '_');
  }

  void _onSort(String key, bool ascending) {
    setState(() {
      _sortField = switch (key) {
        'project' => TimesheetSortField.project,
        'activity' => TimesheetSortField.activity,
        'duration' => TimesheetSortField.duration,
        'amount' => TimesheetSortField.amount,
        'status' => TimesheetSortField.status,
        _ => TimesheetSortField.date,
      };
      _sortAscending = ascending;
    });
  }

  Future<void> _editTimesheet(TimesheetEntry entry) async {
    final repository = ref.read(timesheetsRepositoryProvider);
    final projects = await repository.getAvailableTimesheetProjects();
    if (!mounted) {
      return;
    }

    final input = await showDialog<TimesheetEditInput>(
      context: context,
      builder: (context) => TimesheetEditDialog(
        entry: entry,
        projects: projects,
      ),
    );
    if (input == null) {
      return;
    }

    try {
      await ref.read(timesheetEditServiceProvider).save(input);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись сохранена')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _deleteTimesheet(TimesheetEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: Text(
          entry.kimaiTimesheetId == null
              ? 'Локальная запись будет удалена без отправки в Kimai.'
              : 'Запись будет удалена в Kimai и затем скрыта локально.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(timesheetEditServiceProvider).delete(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись удалена')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
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
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<TimesheetEntry> entries;
  final TimesheetSortField sortField;
  final bool sortAscending;
  final void Function(String key, bool ascending) onSort;
  final ValueChanged<TimesheetEntry> onEdit;
  final ValueChanged<TimesheetEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable<TimesheetEntry>(
      items: entries,
      sortColumnKey: _sortKey(sortField),
      sortAscending: sortAscending,
      onSort: onSort,
      columns: [
        AppTableColumn(
          key: 'date',
          label: 'Дата',
          width: 150,
          cellBuilder: (context, entry) => Text(
            '${DateTimeFormats.date.format(entry.beginAt.toLocal())} '
            '${DateTimeFormats.time.format(entry.beginAt.toLocal())}',
          ),
        ),
        AppTableColumn(
          key: 'project',
          label: 'Проект',
          width: 180,
          cellBuilder: (context, entry) => Row(
            children: [
              _ColorDot(color: entry.projectColor),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: entry.projectName,
                  child: Text(
                    entry.projectName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppTableColumn(
          key: 'activity',
          label: 'Активность',
          width: 150,
          cellBuilder: (context, entry) => Text(
            entry.activityName ?? '-',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'tags',
          label: 'Метки',
          width: 180,
          sortable: false,
          cellBuilder: (context, entry) => _TagChips(tags: entry.tags),
        ),
        AppTableColumn(
          key: 'description',
          label: 'Описание',
          width: 260,
          sortable: false,
          cellBuilder: (context, entry) => Tooltip(
            message: entry.description ?? '-',
            child: Text(
              entry.description ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        AppTableColumn(
          key: 'duration',
          label: 'Длительность',
          width: 120,
          cellBuilder: (context, entry) => Text(
            formatDurationSeconds(entry.durationSeconds),
          ),
        ),
        AppTableColumn(
          key: 'status',
          label: 'Статус',
          width: 140,
          cellBuilder: (context, entry) => _LocalStatusChip(entry: entry),
        ),
        AppTableColumn(
          key: 'rate',
          label: 'Ставка',
          width: 110,
          sortable: false,
          cellBuilder: (context, entry) => Text(
            entry.hourlyRateMinor == null
                ? '-'
                : formatMoneyRub(entry.hourlyRateMinor!),
          ),
        ),
        AppTableColumn(
          key: 'amount',
          label: 'Сумма',
          width: 110,
          cellBuilder: (context, entry) => Text(
            entry.amountMinor == null
                ? '-'
                : formatMoneyRub(entry.amountMinor!),
          ),
        ),
        AppTableColumn(
          key: 'actions',
          label: '',
          width: 96,
          sortable: false,
          cellBuilder: (context, entry) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: entry.endAt == null ? null : () => onEdit(entry),
                icon: const Icon(Icons.edit_rounded, size: 18),
                tooltip: 'Изменить',
              ),
              IconButton(
                onPressed: entry.endAt == null ? null : () => onDelete(entry),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ],
      emptyTitle: 'Нет записей за выбранный период',
      emptyMessage: 'Синхронизируйте Kimai или измените фильтры.',
      mobileCardBuilder: (context, entry) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ColorDot(color: entry.projectColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.projectName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(formatDurationSeconds(entry.durationSeconds)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${DateTimeFormats.date.format(entry.beginAt.toLocal())} '
            '${DateTimeFormats.time.format(entry.beginAt.toLocal())}',
          ),
          Text(entry.activityName ?? '-'),
          _TagChips(tags: entry.tags),
          if ((entry.description ?? '').isNotEmpty)
            Text(entry.description!, overflow: TextOverflow.ellipsis),
          _LocalStatusChip(entry: entry),
          const SizedBox(height: 6),
          Text(
            entry.amountMinor == null
                ? '-'
                : formatMoneyRub(entry.amountMinor!),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  onPressed: entry.endAt == null ? null : () => onEdit(entry),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: 'Изменить',
                ),
                IconButton(
                  onPressed: entry.endAt == null ? null : () => onDelete(entry),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: 'Удалить',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimesheetEditDialog extends ConsumerStatefulWidget {
  const TimesheetEditDialog({
    required this.entry,
    required this.projects,
    super.key,
  });

  final TimesheetEntry entry;
  final List<TimesheetProjectOption> projects;

  @override
  ConsumerState<TimesheetEditDialog> createState() =>
      _TimesheetEditDialogState();
}

class _TimesheetEditDialogState extends ConsumerState<TimesheetEditDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late DateTime _beginAt;
  late DateTime _endAt;
  String? _appProjectId;
  int? _activityId;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _descriptionController = TextEditingController(
      text: entry.description ?? '',
    );
    _tagsController = TextEditingController(text: entry.tags ?? '');
    _beginAt = entry.beginAt.toLocal();
    _endAt = (entry.endAt ?? entry.beginAt.add(const Duration(minutes: 1)))
        .toLocal();
    _appProjectId = entry.appProjectId;
    _activityId = entry.activityId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = _selectedProject;
    final activities = project == null
        ? const AsyncValue<List<TimerActivityOption>>.data([])
        : ref.watch(_editActivitiesProvider(project.kimaiProjectId));
    final tags = ref.watch(_availableTagsProvider);

    return AlertDialog(
      title: const Text('Изменить запись'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _appProjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Проект'),
                items: [
                  for (final item in widget.projects)
                    DropdownMenuItem(
                      value: item.appProjectId,
                      child: Text(item.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _appProjectId = value;
                    _activityId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              activities.when(
                data: (items) => DropdownButtonFormField<int?>(
                  initialValue: _activityId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Активность'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Без активности'),
                    ),
                    for (final item in items)
                      DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _activityId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(error.toString()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Теги'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              tags.when(
                data: (items) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in items.take(12))
                      FilterChip(
                        label: Text(tag),
                        selected: parseTags(_tagsController.text)
                            .map((value) => value.toLowerCase())
                            .contains(tag.toLowerCase()),
                        onSelected: (_) => _toggleTag(tag),
                      ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _EditDateTimeButton(
                    label: 'Начало',
                    value: _beginAt,
                    onChanged: (value) => setState(() => _beginAt = value),
                  ),
                  _EditDateTimeButton(
                    label: 'Окончание',
                    value: _endAt,
                    onChanged: (value) => setState(() => _endAt = value),
                  ),
                ],
              ),
              if (!_endAt.isAfter(_beginAt)) ...[
                const SizedBox(height: 8),
                const Text(
                  'Окончание должно быть позже начала.',
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  TimesheetProjectOption? get _selectedProject {
    final projectId = _appProjectId;
    if (projectId == null) {
      return null;
    }

    for (final project in widget.projects) {
      if (project.appProjectId == projectId) {
        return project;
      }
    }

    return null;
  }

  bool get _canSave => _selectedProject != null && _endAt.isAfter(_beginAt);

  void _toggleTag(String tag) {
    final values = parseTags(_tagsController.text).toList();
    final index = values.indexWhere(
      (value) => value.toLowerCase() == tag.toLowerCase(),
    );
    if (index >= 0) {
      values.removeAt(index);
    } else {
      values.add(tag);
    }

    setState(() => _tagsController.text = formatTags(values) ?? '');
  }

  void _save() {
    final project = _selectedProject;
    if (project == null) {
      return;
    }

    Navigator.of(context).pop(
      TimesheetEditInput(
        entryId: widget.entry.id,
        kimaiTimesheetId: widget.entry.kimaiTimesheetId,
        appProjectId: project.appProjectId,
        kimaiProjectId: project.kimaiProjectId,
        activityId: _activityId,
        activityName: _activityName(project.kimaiProjectId),
        description: _descriptionController.text,
        tags: _tagsController.text,
        beginAt: _beginAt,
        endAt: _endAt,
      ),
    );
  }

  String? _activityName(int kimaiProjectId) {
    final activities = ref.read(_editActivitiesProvider(kimaiProjectId));
    final items = activities.valueOrNull ?? const <TimerActivityOption>[];
    for (final item in items) {
      if (item.id == _activityId) {
        return item.name;
      }
    }

    return _activityId == widget.entry.activityId
        ? widget.entry.activityName
        : null;
  }
}

class _EditDateTimeButton extends StatelessWidget {
  const _EditDateTimeButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pick(context),
      icon: const Icon(Icons.event_rounded, size: 18),
      label: Text(
        '$label: ${DateTimeFormats.date.format(value)} '
        '${DateTimeFormats.time.format(value)}',
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) {
      return;
    }

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final String? tags;

  @override
  Widget build(BuildContext context) {
    final values = parseTags(tags);
    if (values.isEmpty) {
      return const Text('-');
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in values.take(3))
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                tag,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _LocalStatusChip extends StatelessWidget {
  const _LocalStatusChip({required this.entry});

  final TimesheetEntry entry;

  @override
  Widget build(BuildContext context) {
    final status = entry.localStatus;
    if (status == null) {
      return const Text('Kimai');
    }

    final color = switch (status) {
      LocalTimeEntryStatus.synced => AppColors.accent,
      LocalTimeEntryStatus.syncFailed => AppColors.danger,
      LocalTimeEntryStatus.conflict => AppColors.warning,
      _ => AppColors.warning,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(status.label, style: TextStyle(color: color)),
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

String _sortKey(TimesheetSortField field) {
  return switch (field) {
    TimesheetSortField.project => 'project',
    TimesheetSortField.activity => 'activity',
    TimesheetSortField.duration => 'duration',
    TimesheetSortField.amount => 'amount',
    TimesheetSortField.status => 'status',
    TimesheetSortField.date => 'date',
  };
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

final _availableTagsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(timesheetsRepositoryProvider).watchAvailableTags();
});

final _editActivitiesProvider = FutureProvider.autoDispose
    .family<List<TimerActivityOption>, int>((ref, kimaiProjectId) {
  return ref
      .watch(localTrackingRepositoryProvider)
      .getActivityOptions(kimaiProjectId);
});
