import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/export/export_file_saver.dart';
import '../../../core/export/report_file_exporter.dart';
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
  String _tag = '';
  String _searchText = '';
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
      subtitle: 'Детализация времени по проектам, периоду, людям и меткам.',
      expandContent: true,
      actions: [
        OutlinedButton.icon(
          onPressed: _result == null ? null : () => _exportCsv(_result!),
          icon: const Icon(Icons.table_view_rounded, size: 18),
          label: const Text('CSV'),
        ),
        OutlinedButton.icon(
          onPressed: _result == null ? null : () => _exportXlsx(_result!),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('XLSX'),
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
                data: (items) => DropdownButtonFormField<int?>(
                  initialValue: _projectId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Проект'),
                  items: [
                    for (final project in items)
                      DropdownMenuItem<int?>(
                        value: project.id,
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
              width: 180,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Активность',
                  prefixIcon: Icon(Icons.work_outline_rounded, size: 18),
                ),
                onChanged: (value) => setState(() => _activity = value),
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Метки',
                  prefixIcon: Icon(Icons.sell_outlined, size: 18),
                ),
                onChanged: (value) => setState(() => _tag = value),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Поиск',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                ),
                onChanged: (value) => setState(() => _searchText = value),
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
                    value: ReportSortField.project,
                    child: Text('Проект'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.activity,
                    child: Text('Активность'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.duration,
                    child: Text('Время'),
                  ),
                  DropdownMenuItem(
                    value: ReportSortField.minutes,
                    child: Text('Минуты'),
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
              onPressed: _loading ? null : _loadReport,
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
          ReportUserSummaryTable(
            items: _result!.userSummaries,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
          ),
        if (_result != null)
          ReportProjectSummaryTable(
            items: _result!.projectSummaries,
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
            message: 'Выберите фильтры и сформируйте отчёт.',
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
      _end = DateTime(selected.end.year, selected.end.month, selected.end.day)
          .add(const Duration(days: 1));
    });
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = await ref.read(reportsRepositoryProvider.future);
      final result = await repository.buildReport(
        ReportQuery(
          projectId: _projectId,
          begin: _begin,
          end: _end,
          userId: _userId,
          activity: _activity,
          tag: _tag,
          searchText: _searchText,
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

  Future<void> _exportCsv(ReportResult result) async {
    final bytes = buildCsvBytes(_detailsRows(result));
    await _saveExport(
      fileName: _fileName('csv'),
      bytes: bytes,
      mimeType: 'text/csv',
    );
  }

  Future<void> _exportXlsx(ReportResult result) async {
    final bytes = buildXlsxBytes([
      ExportSheet(name: 'Summary by users', rows: _userSummaryRows(result)),
      ExportSheet(
        name: 'Summary by projects',
        rows: _projectSummaryRows(result),
      ),
      ExportSheet(name: 'Details', rows: _detailsRows(result)),
    ]);
    await _saveExport(
      fileName: _fileName('xlsx'),
      bytes: bytes,
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

  List<List<Object?>> _userSummaryRows(ReportResult result) {
    return [
      ['Пользователь', 'Проекты', 'Время', 'Минуты', 'Записей', 'Сумма'],
      for (final item in result.userSummaries)
        [
          item.userName,
          item.projectNames.join(', '),
          formatDurationSeconds(item.totalDurationSeconds),
          item.totalMinutes,
          item.entriesCount,
          item.totalAmountMinor == 0
              ? null
              : (item.totalAmountMinor / 100).toStringAsFixed(2),
        ],
    ];
  }

  List<List<Object?>> _projectSummaryRows(ReportResult result) {
    return [
      ['Проект', 'Пользователей', 'Время', 'Минуты', 'Записей', 'Сумма'],
      for (final item in result.projectSummaries)
        [
          item.projectName,
          item.userCount,
          formatDurationSeconds(item.totalDurationSeconds),
          item.totalMinutes,
          item.entriesCount,
          item.totalAmountMinor == 0
              ? null
              : (item.totalAmountMinor / 100).toStringAsFixed(2),
        ],
    ];
  }

  List<List<Object?>> _detailsRows(ReportResult result) {
    return [
      [
        'Дата',
        'Пользователь',
        'Проект',
        'Активность',
        'Метки',
        'Описание',
        'Начало',
        'Конец',
        'Длительность',
        'Минуты',
        'Сумма',
      ],
      for (final entry in result.entries)
        [
          DateTimeFormats.date.format(entry.begin.toLocal()),
          entry.userName,
          entry.projectName,
          entry.activity,
          entry.tags,
          entry.description,
          DateTimeFormats.time.format(entry.begin.toLocal()),
          entry.end == null
              ? ''
              : DateTimeFormats.time.format(entry.end!.toLocal()),
          entry.durationHuman,
          entry.durationMinutes,
          entry.amountMinor == null
              ? null
              : (entry.amountMinor! / 100).toStringAsFixed(2),
        ],
    ];
  }

  String _fileName(String extension) {
    final project = _projectId == null ? 'all' : 'project_$_projectId';
    final from = DateTimeFormats.compactDate.format(_begin);
    final to = DateTimeFormats.compactDate.format(
      _end.subtract(const Duration(days: 1)),
    );

    return 'outstaff_report_${_safeFilePart(project)}_${_safeFilePart(from)}_${_safeFilePart(to)}.$extension';
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-zА-Яа-я0-9._-]+'), '_');
  }

  ReportSortField _sortFieldFromKey(String key) {
    return switch (key) {
      'project' => ReportSortField.project,
      'activity' => ReportSortField.activity,
      'duration' => ReportSortField.duration,
      'minutes' => ReportSortField.minutes,
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
                label: 'Проектов',
                value: result.projectSummaries.length.toString(),
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
        ],
      ),
    );
  }
}

class ReportUserSummaryTable extends StatelessWidget {
  const ReportUserSummaryTable({
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
          key: 'project',
          label: 'Проекты',
          width: 260,
          cellBuilder: (context, item) => Text(
            item.projectNames.join(', '),
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
      emptyTitle: 'Сводка по пользователям пуста',
      emptyMessage: 'Kimai не вернул записей по выбранным фильтрам.',
      mobileCardBuilder: (context, item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.userName, style: Theme.of(context).textTheme.titleMedium),
          Text(item.projectNames.join(', '), overflow: TextOverflow.ellipsis),
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

class ReportProjectSummaryTable extends StatelessWidget {
  const ReportProjectSummaryTable({
    required this.items,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    super.key,
  });

  final List<ProjectReportSummary> items;
  final ReportSortField sortField;
  final bool sortAscending;
  final void Function(String key, bool ascending) onSort;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable<ProjectReportSummary>(
      items: items,
      sortColumnKey: _sortKey(sortField),
      sortAscending: sortAscending,
      onSort: onSort,
      columns: [
        AppTableColumn(
          key: 'project',
          label: 'Проект',
          width: 260,
          cellBuilder: (context, item) => Text(
            item.projectName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'user',
          label: 'Пользователей',
          width: 130,
          numeric: true,
          cellBuilder: (context, item) => Text(item.userCount.toString()),
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
      emptyTitle: 'Сводка по проектам пуста',
      emptyMessage: 'Kimai не вернул записей по выбранным фильтрам.',
      mobileCardBuilder: (context, item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.projectName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(formatDurationSeconds(item.totalDurationSeconds)),
          Text('Пользователей: ${item.userCount}'),
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
          cellBuilder: (context, item) => Text(
            item.projectName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'activity',
          label: 'Активность',
          width: 160,
          cellBuilder: (context, item) => Text(
            item.activity,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppTableColumn(
          key: 'tags',
          label: 'Метки',
          width: 180,
          sortable: false,
          cellBuilder: (context, item) => _TagText(value: item.tags),
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
          key: 'minutes',
          label: 'Минуты',
          width: 90,
          numeric: true,
          cellBuilder: (context, item) => Text(item.durationMinutes.toString()),
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
          Text(item.activity),
          _TagText(value: item.tags),
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

class _TagText extends StatelessWidget {
  const _TagText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const Text('-');
    }

    return Tooltip(
      message: value,
      child: Text(value, overflow: TextOverflow.ellipsis),
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
    ReportSortField.project => 'project',
    ReportSortField.activity => 'activity',
    ReportSortField.duration => 'duration',
    ReportSortField.minutes => 'minutes',
    ReportSortField.amount => 'amount',
    ReportSortField.date => 'date',
    ReportSortField.entriesCount => 'entries',
    ReportSortField.user => 'user',
  };
}
