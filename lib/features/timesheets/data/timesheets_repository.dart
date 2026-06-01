import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';
import '../../../core/utils/tags.dart';
import '../../local_tracking/data/local_tracking_repository.dart';

class TimesheetSummary {
  const TimesheetSummary({
    required this.totalSeconds,
    required this.amountMinor,
    required this.entryCount,
  });

  final int totalSeconds;
  final int amountMinor;
  final int entryCount;

  double get billableAmount => amountMinor / 100;
}

class ProjectWeekSummary {
  const ProjectWeekSummary({
    required this.projectName,
    required this.color,
    required this.totalSeconds,
    required this.weeklyGoalHours,
    required this.amountMinor,
  });

  final String projectName;
  final String? color;
  final int totalSeconds;
  final double? weeklyGoalHours;
  final int amountMinor;

  double get hours => totalSeconds / 3600;
  double get progressPercent {
    final goal = weeklyGoalHours;
    if (goal == null || goal <= 0) {
      return 0;
    }

    return (hours / goal * 100).clamp(0, 999).toDouble();
  }

  int get goalSeconds => ((weeklyGoalHours ?? 0) * 3600).round();
  int get remainingSeconds =>
      goalSeconds > totalSeconds ? goalSeconds - totalSeconds : 0;
  int get overworkSeconds =>
      totalSeconds > goalSeconds ? totalSeconds - goalSeconds : 0;
}

class WeeklyProjectProgress {
  const WeeklyProjectProgress({
    required this.weekStart,
    required this.weekEnd,
    required this.projectName,
    required this.color,
    required this.goalSeconds,
    required this.trackedSeconds,
    required this.amountMinor,
    required this.paymentPeriodLabel,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final String projectName;
  final String? color;
  final int goalSeconds;
  final int trackedSeconds;
  final int amountMinor;
  final String paymentPeriodLabel;

  int get remainingSeconds =>
      goalSeconds > trackedSeconds ? goalSeconds - trackedSeconds : 0;
  int get overworkSeconds =>
      trackedSeconds > goalSeconds ? trackedSeconds - goalSeconds : 0;
}

enum TimesheetSortField {
  date,
  project,
  activity,
  duration,
  amount,
  status;
}

class TimesheetFilters {
  const TimesheetFilters({
    required this.begin,
    required this.end,
    this.appProjectId,
    this.tag,
    this.searchText,
    this.sortField = TimesheetSortField.date,
    this.sortAscending = false,
  });

  final DateTime begin;
  final DateTime end;
  final String? appProjectId;
  final String? tag;
  final String? searchText;
  final TimesheetSortField sortField;
  final bool sortAscending;

  @override
  bool operator ==(Object other) {
    return other is TimesheetFilters &&
        other.begin == begin &&
        other.end == end &&
        other.appProjectId == appProjectId &&
        other.tag == tag &&
        other.searchText == searchText &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending;
  }

  @override
  int get hashCode => Object.hash(
        begin,
        end,
        appProjectId,
        tag,
        searchText,
        sortField,
        sortAscending,
      );
}

class TimesheetEntry {
  const TimesheetEntry({
    required this.id,
    required this.kimaiTimesheetId,
    required this.kimaiProjectId,
    required this.appProjectId,
    required this.activityId,
    required this.activityName,
    required this.description,
    required this.beginAt,
    required this.endAt,
    required this.durationSeconds,
    required this.projectName,
    required this.projectColor,
    required this.hourlyRateMinor,
    required this.amountMinor,
    required this.localStatus,
    this.tags,
  });

  final String id;
  final int? kimaiTimesheetId;
  final int? kimaiProjectId;
  final String? appProjectId;
  final int? activityId;
  final String? activityName;
  final String? description;
  final DateTime beginAt;
  final DateTime? endAt;
  final int durationSeconds;
  final String projectName;
  final String? projectColor;
  final int? hourlyRateMinor;
  final int? amountMinor;
  final LocalTimeEntryStatus? localStatus;
  final String? tags;

  bool get isLocal => localStatus != null;
}

class TimesheetProjectOption {
  const TimesheetProjectOption({
    required this.appProjectId,
    required this.kimaiProjectId,
    required this.name,
  });

  final String appProjectId;
  final int kimaiProjectId;
  final String name;
}

class TimesheetEditInput {
  const TimesheetEditInput({
    required this.entryId,
    required this.appProjectId,
    required this.kimaiProjectId,
    required this.beginAt,
    required this.endAt,
    this.kimaiTimesheetId,
    this.activityId,
    this.activityName,
    this.description,
    this.tags,
  });

  final String entryId;
  final int? kimaiTimesheetId;
  final String appProjectId;
  final int kimaiProjectId;
  final int? activityId;
  final String? activityName;
  final String? description;
  final String? tags;
  final DateTime beginAt;
  final DateTime endAt;
}

class ProjectFinancialDiagnostics {
  const ProjectFinancialDiagnostics({
    required this.kimaiProjectId,
    required this.appProjectId,
    required this.projectName,
    required this.hourlyRateMinor,
    required this.timesheetsCount,
    required this.zeroAmountTimesheetsCount,
    required this.totalDurationSeconds,
    required this.totalAmountMinor,
  });

  final int? kimaiProjectId;
  final String appProjectId;
  final String projectName;
  final int? hourlyRateMinor;
  final int timesheetsCount;
  final int zeroAmountTimesheetsCount;
  final int totalDurationSeconds;
  final int totalAmountMinor;
}

class FinancialDiagnostics {
  const FinancialDiagnostics({
    required this.enabledProjectsCount,
    required this.enabledProjectsWithZeroRate,
    required this.zeroAmountTimesheetsCount,
    required this.projects,
  });

  final int enabledProjectsCount;
  final int enabledProjectsWithZeroRate;
  final int zeroAmountTimesheetsCount;
  final List<ProjectFinancialDiagnostics> projects;

  String toReport() {
    return [
      'financial_integrity',
      'enabled_projects=$enabledProjectsCount',
      'enabled_projects_with_zero_rate=$enabledProjectsWithZeroRate',
      'zero_amount_timesheets=$zeroAmountTimesheetsCount',
      for (final project in projects) ...[
        'project=${project.projectName}',
        '  kimai_project_id=${project.kimaiProjectId ?? 'none'}',
        '  app_project_id=${project.appProjectId}',
        '  hourly_rate_minor=${project.hourlyRateMinor ?? 0}',
        '  timesheets_count=${project.timesheetsCount}',
        '  zero_amount_timesheets=${project.zeroAmountTimesheetsCount}',
        '  total_duration_seconds=${project.totalDurationSeconds}',
        '  total_amount_minor=${project.totalAmountMinor}',
      ],
    ].join('\n');
  }
}

class ProjectAmountRepairSummary {
  const ProjectAmountRepairSummary({
    required this.projectName,
    required this.rowsFixed,
    required this.oldTotalMinor,
    required this.newTotalMinor,
  });

  final String projectName;
  final int rowsFixed;
  final int oldTotalMinor;
  final int newTotalMinor;
}

class AmountRepairSummary {
  const AmountRepairSummary({required this.projects});

  final List<ProjectAmountRepairSummary> projects;

  int get rowsFixed =>
      projects.fold(0, (sum, project) => sum + project.rowsFixed);
  int get oldTotalMinor =>
      projects.fold(0, (sum, project) => sum + project.oldTotalMinor);
  int get newTotalMinor =>
      projects.fold(0, (sum, project) => sum + project.newTotalMinor);
}

class TimesheetsRepository {
  TimesheetsRepository(this._database);

  final AppDatabase _database;

  Stream<List<Timesheet>> watchRecentTimesheets({int limit = 100}) {
    final query = _database.select(_database.timesheets)
      ..orderBy([(table) => OrderingTerm.desc(table.beginAt)])
      ..limit(limit);

    return query.watch();
  }

  Stream<List<Timesheet>> watchTimesheetsInRange(DateTime begin, DateTime end) {
    final query = _database.select(_database.timesheets)
      ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
      ..where((table) => table.beginAt.isSmallerThanValue(end))
      ..orderBy([(table) => OrderingTerm.asc(table.beginAt)]);

    return query.watch();
  }

  Stream<List<TimesheetEntry>> watchTimesheetsFiltered(
    TimesheetFilters filters,
  ) {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM local_time_entries',
          readsFrom: {_database.timesheets, _database.localTimeEntries},
        )
        .watch()
        .asyncMap((_) => getTimesheetsFiltered(filters));
  }

  Future<List<TimesheetEntry>> getTimesheetsFiltered(
    TimesheetFilters filters,
  ) async {
    final remoteRows = await _timesheetsFilteredQuery(filters).get();
    final localRows = await _localTimesheetsFilteredQuery(filters).get();
    final entries = [
      ..._mapRemoteTimesheetEntries(remoteRows),
      ..._mapLocalTimesheetEntries(localRows),
    ];

    entries.sort((a, b) {
      final compared = switch (filters.sortField) {
        TimesheetSortField.date => a.beginAt.compareTo(b.beginAt),
        TimesheetSortField.project => a.projectName.compareTo(b.projectName),
        TimesheetSortField.activity => (a.activityName ?? '').compareTo(
            b.activityName ?? '',
          ),
        TimesheetSortField.duration => a.durationSeconds.compareTo(
            b.durationSeconds,
          ),
        TimesheetSortField.amount => (a.amountMinor ?? 0).compareTo(
            b.amountMinor ?? 0,
          ),
        TimesheetSortField.status => (a.localStatus?.storageValue ?? 'kimai')
            .compareTo(b.localStatus?.storageValue ?? 'kimai'),
      };

      return filters.sortAscending ? compared : -compared;
    });

    return entries;
  }

  Stream<TimesheetSummary> watchTimesheetTotals(TimesheetFilters filters) {
    return watchTimesheetsFiltered(filters).map((items) {
      return TimesheetSummary(
        totalSeconds: items.fold(
          0,
          (sum, item) => sum + item.durationSeconds,
        ),
        amountMinor: items.fold(
          0,
          (sum, item) => sum + (item.amountMinor ?? 0),
        ),
        entryCount: items.length,
      );
    });
  }

  Future<List<TimesheetProjectOption>> getAvailableTimesheetProjects() async {
    final rows = await _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.appProjects.kimaiProjectId,
        ),
      ),
    ]).get();

    return [
      for (final row in rows)
        TimesheetProjectOption(
          appProjectId: row.readTable(_database.appProjects).id,
          kimaiProjectId: row.readTable(_database.kimaiProjects).id,
          name: row.readTable(_database.kimaiProjects).name,
        ),
    ];
  }

  Future<Timesheet?> getRemoteTimesheet(int kimaiTimesheetId) {
    final query = _database.select(_database.timesheets)
      ..where((table) => table.id.equals(kimaiTimesheetId));

    return query.getSingleOrNull();
  }

  Future<void> applyRemoteEdit(KimaiTimesheetDto item) async {
    final projects = await _database.select(_database.appProjects).get();
    await upsertRemoteTimesheets([item], projects);
  }

  Future<void> updateLocalTimesheet(TimesheetEditInput input) async {
    _validateEditWindow(input.beginAt, input.endAt);
    final end = _normalizedEndAt(input.beginAt, input.endAt);
    final now = DateTime.now().toUtc();
    final project = await (_database.select(_database.appProjects)
          ..where((table) => table.id.equals(input.appProjectId))
          ..where((table) => table.kimaiProjectId.equals(input.kimaiProjectId)))
        .getSingleOrNull();
    if (project == null) {
      throw StateError('Выбранный проект не связан с Kimai.');
    }

    await (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(input.entryId)))
        .write(
      LocalTimeEntriesCompanion(
        projectId: Value(input.appProjectId),
        kimaiProjectId: Value(input.kimaiProjectId),
        activityId: Value(input.activityId),
        activityName: Value(_blankToNull(input.activityName)),
        description: Value(_blankToNull(input.description)),
        tags: Value(formatTags(parseTags(input.tags))),
        beginAt: Value(input.beginAt.toUtc()),
        endAt: Value(end),
        durationSeconds: Value(_durationSeconds(input.beginAt, end)),
        status: Value(LocalTimeEntryStatus.syncPending.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markLocalEditFailed(String entryId, Object error) {
    final now = DateTime.now().toUtc();

    return _database.customUpdate(
      'UPDATE local_time_entries '
      'SET status = ?, sync_attempts = sync_attempts + 1, '
      'last_sync_error = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(LocalTimeEntryStatus.editFailed.storageValue),
        Variable(error.toString()),
        Variable(now),
        Variable(entryId),
      ],
      updates: {_database.localTimeEntries},
    );
  }

  Future<List<String>> getAvailableActivities() async {
    final rows =
        await (_database.selectOnly(_database.timesheets, distinct: true)
              ..addColumns([_database.timesheets.activityName])
              ..where(_database.timesheets.activityName.isNotNull()))
            .get();
    final activities = rows
        .map((row) => row.read(_database.timesheets.activityName))
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList()
      ..sort();

    return activities;
  }

  Future<List<String>> getAvailableTags() async {
    final tagRows = await (_database.selectOnly(_database.kimaiTags)
          ..addColumns([_database.kimaiTags.name]))
        .get();
    final remoteRows = await (_database.selectOnly(_database.timesheets)
          ..addColumns([_database.timesheets.tags]))
        .get();
    final localRows = await (_database.selectOnly(_database.localTimeEntries)
          ..addColumns([_database.localTimeEntries.tags]))
        .get();
    final values = <String>{};

    for (final row in tagRows) {
      final name = row.read(_database.kimaiTags.name);
      if (name != null && name.trim().isNotEmpty) {
        values.add(name.trim());
      }
    }
    for (final row in remoteRows) {
      values.addAll(parseTags(row.read(_database.timesheets.tags)));
    }
    for (final row in localRows) {
      values.addAll(parseTags(row.read(_database.localTimeEntries.tags)));
    }

    return values.toList()..sort();
  }

  Stream<TimesheetSummary> watchSummary(DateTime begin, DateTime end) {
    return watchTimesheetsFiltered(
      TimesheetFilters(begin: begin, end: end),
    ).map(_summaryFromEntries);
  }

  Future<TimesheetSummary> getCurrentWeekSummary() async {
    final range = currentWeekRange();
    final items = await getTimesheetsFiltered(
      TimesheetFilters(begin: range.begin, end: range.end),
    );

    return _summaryFromEntries(items);
  }

  Stream<TimesheetSummary> watchCurrentWeekSummary() {
    final range = currentWeekRange();

    return watchSummary(range.begin, range.end);
  }

  Future<List<ProjectWeekSummary>> getProjectWeekSummaries() async {
    final range = currentWeekRange();
    final rows = await _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.appProjects.kimaiProjectId,
        ),
      ),
    ]).get();
    final timesheets = await getTimesheetsFiltered(
      TimesheetFilters(begin: range.begin, end: range.end),
    );

    return _projectSummaries(rows, timesheets);
  }

  Stream<List<ProjectWeekSummary>> watchProjectWeekSummaries() {
    final range = currentWeekRange();

    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM app_projects '
          'UNION ALL SELECT COUNT(*) FROM kimai_projects '
          'UNION ALL SELECT COUNT(*) FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM local_time_entries',
          readsFrom: {
            _database.appProjects,
            _database.kimaiProjects,
            _database.timesheets,
            _database.localTimeEntries,
          },
        )
        .watch()
        .asyncMap((_) async {
          final rows = await _database.select(_database.appProjects).join([
            innerJoin(
              _database.kimaiProjects,
              _database.kimaiProjects.id.equalsExp(
                _database.appProjects.kimaiProjectId,
              ),
            ),
          ]).get();
          final timesheets = await getTimesheetsFiltered(
            TimesheetFilters(begin: range.begin, end: range.end),
          );

          return _projectSummaries(rows, timesheets);
        });
  }

  Stream<List<WeeklyProjectProgress>> watchWeeklyProgressHistory({
    int weeks = 8,
  }) {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM app_projects '
          'UNION ALL SELECT COUNT(*) FROM kimai_projects '
          'UNION ALL SELECT COUNT(*) FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM local_time_entries',
          readsFrom: {
            _database.appProjects,
            _database.kimaiProjects,
            _database.timesheets,
            _database.localTimeEntries,
          },
        )
        .watch()
        .asyncMap((_) => getWeeklyProgressHistory(weeks: weeks));
  }

  Future<List<WeeklyProjectProgress>> getWeeklyProgressHistory({
    int weeks = 8,
  }) async {
    final current = currentWeekRange().begin;
    final rows = await _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.appProjects.kimaiProjectId,
        ),
      ),
    ]).get();
    final enabledRows = rows
        .where((row) => row.readTable(_database.appProjects).enabled)
        .toList(growable: false);
    final begin = current.subtract(Duration(days: 7 * (weeks - 1)));
    final timesheets = await getTimesheetsFiltered(
      TimesheetFilters(begin: begin, end: current.add(const Duration(days: 7))),
    );
    final result = <WeeklyProjectProgress>[];

    for (var index = 0; index < weeks; index++) {
      final weekStart = current.subtract(Duration(days: 7 * index));
      final weekEnd = weekStart.add(const Duration(days: 7));
      for (final row in enabledRows) {
        final appProject = row.readTable(_database.appProjects);
        final kimaiProject = row.readTable(_database.kimaiProjects);
        final projectTimesheets = timesheets
            .where(
              (item) =>
                  item.appProjectId == appProject.id &&
                  !item.beginAt.isBefore(weekStart) &&
                  item.beginAt.isBefore(weekEnd),
            )
            .toList(growable: false);
        result.add(
          WeeklyProjectProgress(
            weekStart: weekStart,
            weekEnd: weekEnd,
            projectName: kimaiProject.name,
            color: appProject.color ?? kimaiProject.color,
            goalSeconds: ((appProject.weeklyGoalHours ?? 0) * 3600).round(),
            trackedSeconds: projectTimesheets.fold(
              0,
              (sum, item) => sum + item.durationSeconds,
            ),
            amountMinor: projectTimesheets.fold(
              0,
              (sum, item) => sum + (item.amountMinor ?? 0),
            ),
            paymentPeriodLabel: appProject.payoutRule,
          ),
        );
      }
    }

    return result;
  }

  Future<void> upsertTimesheets(List<KimaiTimesheetDto> timesheets) async {
    final projects = await _database.select(_database.appProjects).get();

    return upsertRemoteTimesheets(timesheets, projects);
  }

  Future<void> upsertRemoteTimesheets(
    List<KimaiTimesheetDto> timesheets,
    List<AppProject> appProjects,
  ) async {
    final now = DateTime.now().toUtc();
    final rateHistory =
        await _database.select(_database.projectRateHistory).get();
    final projectsByKimaiId = {
      for (final project in appProjects)
        if (project.kimaiProjectId != null) project.kimaiProjectId!: project,
    };

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.timesheets,
        [
          for (final item in timesheets)
            TimesheetsCompanion(
              id: Value(item.id),
              kimaiProjectId: Value(item.projectId),
              appProjectId: Value(projectsByKimaiId[item.projectId]?.id),
              activityId: Value(item.activityId),
              activityName: Value(item.activityName),
              description: Value(item.description),
              beginAt: Value(item.beginAt),
              endAt: Value(item.endAt),
              durationSeconds: Value(item.durationSeconds),
              rate: Value(item.rate),
              amountMinor: Value(
                calculateTimesheetAmountMinor(
                  durationSeconds: item.durationSeconds,
                  hourlyRateMinor: _rateForTimesheet(
                    project: projectsByKimaiId[item.projectId],
                    rateHistory: rateHistory,
                    beginAt: item.beginAt,
                  ),
                ),
              ),
              currency: const Value('RUB'),
              exported: Value(item.exported),
              tags: Value(item.tags),
              kimaiUpdatedAt: Value(item.updatedAt),
              syncedAt: Value(now),
            ),
        ],
      );
    });
  }

  Future<int> reconcileRemoteDeletions({
    required int kimaiProjectId,
    required DateTime begin,
    required DateTime end,
    required Set<int> remoteTimesheetIds,
  }) async {
    final localRows = await (_database.select(_database.timesheets)
          ..where((table) => table.kimaiProjectId.equals(kimaiProjectId))
          ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
          ..where((table) => table.beginAt.isSmallerOrEqualValue(end)))
        .get();
    final idsToDelete = [
      for (final row in localRows)
        if (!remoteTimesheetIds.contains(row.id)) row.id,
    ];
    if (idsToDelete.isEmpty) {
      return 0;
    }

    return (_database.delete(_database.timesheets)
          ..where((table) => table.id.isIn(idsToDelete)))
        .go();
  }

  Future<void> upsertKimaiTags(List<KimaiTagDto> tags) async {
    final now = DateTime.now().toUtc();
    final normalized = <String, KimaiTagDto>{};
    for (final tag in tags) {
      final name = tag.name.trim();
      if (name.isNotEmpty) {
        normalized[tag.id.trim().isEmpty ? name : tag.id.trim()] = tag;
      }
    }

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.kimaiTags,
        [
          for (final entry in normalized.entries)
            KimaiTagsCompanion(
              id: Value(entry.key),
              name: Value(entry.value.name.trim()),
              color: Value(entry.value.color),
              syncedAt: Value(now),
            ),
        ],
      );
    });
  }

  Future<FinancialDiagnostics> getFinancialDiagnostics() async {
    final rows = await _database.select(_database.appProjects).join([
      leftOuterJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.appProjects.kimaiProjectId,
        ),
      ),
    ]).get();
    final enabledRows = rows
        .where((row) => row.readTable(_database.appProjects).enabled)
        .toList(growable: false);
    final projects = <ProjectFinancialDiagnostics>[];

    for (final row in enabledRows) {
      final appProject = row.readTable(_database.appProjects);
      final kimaiProject = row.readTableOrNull(_database.kimaiProjects);
      final timesheets = await (_database.select(_database.timesheets)
            ..where((table) => table.appProjectId.equals(appProject.id)))
          .get();
      final zeroAmountTimesheets = timesheets
          .where(
            (timesheet) =>
                timesheet.durationSeconds > 0 &&
                ((timesheet.amountMinor ?? 0) == 0),
          )
          .length;

      projects.add(
        ProjectFinancialDiagnostics(
          kimaiProjectId: appProject.kimaiProjectId,
          appProjectId: appProject.id,
          projectName: kimaiProject?.name ?? appProject.name,
          hourlyRateMinor: appProject.hourlyRateMinor,
          timesheetsCount: timesheets.length,
          zeroAmountTimesheetsCount: zeroAmountTimesheets,
          totalDurationSeconds: timesheets.fold(
            0,
            (sum, timesheet) => sum + timesheet.durationSeconds,
          ),
          totalAmountMinor: timesheets.fold(
            0,
            (sum, timesheet) => sum + (timesheet.amountMinor ?? 0),
          ),
        ),
      );
    }

    return FinancialDiagnostics(
      enabledProjectsCount: enabledRows.length,
      enabledProjectsWithZeroRate: enabledRows
          .where(
            (row) =>
                (row.readTable(_database.appProjects).hourlyRateMinor ?? 0) <=
                0,
          )
          .length,
      zeroAmountTimesheetsCount: projects.fold(
        0,
        (sum, project) => sum + project.zeroAmountTimesheetsCount,
      ),
      projects: projects,
    );
  }

  Future<AmountRepairSummary> repairZeroAmountTimesheets() async {
    final appProjects = await (_database.select(_database.appProjects)
          ..where((table) => table.enabled.equals(true)))
        .get();
    final rateHistory =
        await _database.select(_database.projectRateHistory).get();
    final summaries = <ProjectAmountRepairSummary>[];

    await _database.transaction(() async {
      for (final project in appProjects) {
        final rows = await (_database.select(_database.timesheets)
              ..where((table) => table.appProjectId.equals(project.id))
              ..where((table) => table.durationSeconds.isBiggerThanValue(0))
              ..where(
                (table) =>
                    table.amountMinor.isNull() | table.amountMinor.equals(0),
              ))
            .get();
        if (rows.isEmpty) {
          continue;
        }

        var rowsFixed = 0;
        var oldTotal = 0;
        var newTotal = 0;
        for (final timesheet in rows) {
          final rate = _rateForTimesheet(
                project: project,
                rateHistory: rateHistory,
                beginAt: timesheet.beginAt,
              ) ??
              project.hourlyRateMinor;
          final amount = calculateTimesheetAmountMinor(
            durationSeconds: timesheet.durationSeconds,
            hourlyRateMinor: rate,
          );
          if (amount == null || amount <= 0) {
            continue;
          }

          oldTotal += timesheet.amountMinor ?? 0;
          newTotal += amount;
          rowsFixed++;
          await (_database.update(_database.timesheets)
                ..where((table) => table.id.equals(timesheet.id)))
              .write(TimesheetsCompanion(amountMinor: Value(amount)));
        }

        if (rowsFixed > 0) {
          summaries.add(
            ProjectAmountRepairSummary(
              projectName: project.name,
              rowsFixed: rowsFixed,
              oldTotalMinor: oldTotal,
              newTotalMinor: newTotal,
            ),
          );
        }
      }

      if (summaries.isNotEmpty) {
        final now = DateTime.now().toUtc();
        await _database.into(_database.syncLogs).insert(
              SyncLogsCompanion.insert(
                id: 'amount_repair_${now.microsecondsSinceEpoch}',
                operation: 'amount_repair',
                status: 'success',
                message: Value('Fixed ${summaries.fold<int>(
                  0,
                  (sum, item) => sum + item.rowsFixed,
                )} rows'),
                debug: Value(
                  [
                    for (final summary in summaries)
                      '${summary.projectName}: rows=${summary.rowsFixed}, '
                          'old=${summary.oldTotalMinor}, new=${summary.newTotalMinor}',
                  ].join('\n'),
                ),
                startedAt: now,
                finishedAt: Value(now),
              ),
            );
      }
    });

    return AmountRepairSummary(projects: summaries);
  }

  TimesheetSummary _summaryFromEntries(List<TimesheetEntry> items) {
    return TimesheetSummary(
      totalSeconds: items.fold(0, (sum, item) => sum + item.durationSeconds),
      amountMinor: items.fold(0, (sum, item) => sum + (item.amountMinor ?? 0)),
      entryCount: items.length,
    );
  }

  List<ProjectWeekSummary> _projectSummaries(
    List<TypedResult> projectRows,
    List<TimesheetEntry> timesheets,
  ) {
    return [
      for (final row in projectRows)
        if (row.readTable(_database.appProjects).enabled)
          _projectSummary(
            row.readTable(_database.kimaiProjects),
            row.readTable(_database.appProjects),
            timesheets,
          ),
    ];
  }

  ProjectWeekSummary _projectSummary(
    KimaiProject kimaiProject,
    AppProject appProject,
    List<TimesheetEntry> timesheets,
  ) {
    final projectTimesheets = timesheets
        .where((item) => item.appProjectId == appProject.id)
        .toList(growable: false);

    return ProjectWeekSummary(
      projectName: kimaiProject.name,
      color: appProject.color ?? kimaiProject.color,
      totalSeconds: projectTimesheets.fold(
        0,
        (sum, item) => sum + item.durationSeconds,
      ),
      weeklyGoalHours: appProject.weeklyGoalHours,
      amountMinor: projectTimesheets.fold(
        0,
        (sum, item) => sum + (item.amountMinor ?? 0),
      ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _timesheetsFilteredQuery(
    TimesheetFilters filters,
  ) {
    final query = _database.select(_database.timesheets).join([
      leftOuterJoin(
        _database.appProjects,
        _database.appProjects.id.equalsExp(_database.timesheets.appProjectId),
      ),
      leftOuterJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.timesheets.kimaiProjectId,
        ),
      ),
    ])
      ..where(_database.timesheets.beginAt.isBiggerOrEqualValue(filters.begin))
      ..where(_database.timesheets.beginAt.isSmallerThanValue(filters.end));

    final projectId = filters.appProjectId;
    if (projectId != null && projectId.isNotEmpty) {
      query.where(_database.timesheets.appProjectId.equals(projectId));
    }

    final search = filters.searchText?.trim();
    if (search != null && search.isNotEmpty) {
      final escaped = search.replaceAll('%', r'\%').replaceAll('_', r'\_');
      final pattern = '%$escaped%';
      query.where(
        _database.timesheets.activityName.like(pattern) |
            _database.timesheets.description.like(pattern) |
            _database.timesheets.tags.like(pattern) |
            _database.kimaiProjects.name.like(pattern),
      );
    }

    final tag = filters.tag?.trim();
    if (tag != null && tag.isNotEmpty) {
      final escaped = tag.replaceAll('%', r'\%').replaceAll('_', r'\_');
      query.where(_database.timesheets.tags.like('%$escaped%'));
    }

    query.orderBy([
      switch (filters.sortField) {
        TimesheetSortField.date => OrderingTerm(
            expression: _database.timesheets.beginAt,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
        TimesheetSortField.project => OrderingTerm(
            expression: _database.kimaiProjects.name,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
        TimesheetSortField.activity => OrderingTerm(
            expression: _database.timesheets.activityName,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
        TimesheetSortField.duration => OrderingTerm(
            expression: _database.timesheets.durationSeconds,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
        TimesheetSortField.amount => OrderingTerm(
            expression: _database.timesheets.amountMinor,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
        TimesheetSortField.status => OrderingTerm(
            expression: _database.timesheets.exported,
            mode: filters.sortAscending ? OrderingMode.asc : OrderingMode.desc,
          ),
      },
    ]);

    return query;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _localTimesheetsFilteredQuery(
    TimesheetFilters filters,
  ) {
    final query = _database.select(_database.localTimeEntries).join([
      leftOuterJoin(
        _database.appProjects,
        _database.appProjects.id.equalsExp(
          _database.localTimeEntries.projectId,
        ),
      ),
      leftOuterJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.localTimeEntries.kimaiProjectId,
        ),
      ),
    ])
      ..where(
        _database.localTimeEntries.beginAt.isBiggerOrEqualValue(filters.begin),
      )
      ..where(
        _database.localTimeEntries.beginAt.isSmallerThanValue(filters.end),
      )
      ..where(
        _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.running.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.syncingStart.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.runningSynced.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.runningLocal.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.syncPending.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.syncFailed.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.stopFailed.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.editFailed.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.conflict.storageValue,
            ),
      );

    final projectId = filters.appProjectId;
    if (projectId != null && projectId.isNotEmpty) {
      query.where(_database.localTimeEntries.projectId.equals(projectId));
    }

    final search = filters.searchText?.trim();
    if (search != null && search.isNotEmpty) {
      final escaped = search.replaceAll('%', r'\%').replaceAll('_', r'\_');
      final pattern = '%$escaped%';
      query.where(
        _database.localTimeEntries.activityName.like(pattern) |
            _database.localTimeEntries.description.like(pattern) |
            _database.localTimeEntries.tags.like(pattern) |
            _database.kimaiProjects.name.like(pattern),
      );
    }

    final tag = filters.tag?.trim();
    if (tag != null && tag.isNotEmpty) {
      final escaped = tag.replaceAll('%', r'\%').replaceAll('_', r'\_');
      query.where(_database.localTimeEntries.tags.like('%$escaped%'));
    }

    return query;
  }

  List<TimesheetEntry> _mapRemoteTimesheetEntries(List<TypedResult> rows) {
    return [
      for (final row in rows) _remoteEntryFromRow(row),
    ];
  }

  TimesheetEntry _remoteEntryFromRow(TypedResult row) {
    final timesheet = row.readTable(_database.timesheets);
    final durationSeconds = _displayRemoteDuration(timesheet);

    return TimesheetEntry(
      id: timesheet.id.toString(),
      kimaiTimesheetId: timesheet.id,
      kimaiProjectId: timesheet.kimaiProjectId,
      appProjectId: timesheet.appProjectId,
      activityId: timesheet.activityId,
      activityName: timesheet.activityName,
      description: timesheet.description,
      beginAt: timesheet.beginAt,
      endAt: timesheet.endAt,
      durationSeconds: durationSeconds,
      projectName: row.readTableOrNull(_database.kimaiProjects)?.name ??
          row.readTableOrNull(_database.appProjects)?.name ??
          'Unknown project',
      projectColor: row.readTableOrNull(_database.appProjects)?.color ??
          row.readTableOrNull(_database.kimaiProjects)?.color,
      hourlyRateMinor: _displayRateMinor(
        durationSeconds: durationSeconds,
        amountMinor: timesheet.amountMinor,
      ),
      amountMinor: timesheet.endAt == null
          ? calculateTimesheetAmountMinor(
              durationSeconds: durationSeconds,
              hourlyRateMinor:
                  row.readTableOrNull(_database.appProjects)?.hourlyRateMinor,
            )
          : timesheet.amountMinor,
      localStatus: null,
      tags: timesheet.tags,
    );
  }

  List<TimesheetEntry> _mapLocalTimesheetEntries(List<TypedResult> rows) {
    return [
      for (final row in rows)
        _localEntryFromRow(
          row,
          row.readTable(_database.localTimeEntries),
        ),
    ];
  }

  TimesheetEntry _localEntryFromRow(TypedResult row, LocalTimeEntry entry) {
    final amountMinor = calculateTimesheetAmountMinor(
      durationSeconds: _displayDuration(entry),
      hourlyRateMinor:
          row.readTableOrNull(_database.appProjects)?.hourlyRateMinor,
    );

    return TimesheetEntry(
      id: entry.id,
      kimaiTimesheetId: entry.kimaiTimesheetId,
      kimaiProjectId: entry.kimaiProjectId,
      appProjectId: entry.projectId,
      activityId: entry.activityId,
      activityName: entry.activityName,
      description: entry.description,
      beginAt: entry.beginAt,
      endAt: entry.endAt,
      durationSeconds: _displayDuration(entry),
      projectName: row.readTableOrNull(_database.kimaiProjects)?.name ??
          row.readTableOrNull(_database.appProjects)?.name ??
          'Unknown project',
      projectColor: row.readTableOrNull(_database.appProjects)?.color ??
          row.readTableOrNull(_database.kimaiProjects)?.color,
      hourlyRateMinor:
          row.readTableOrNull(_database.appProjects)?.hourlyRateMinor,
      amountMinor: amountMinor,
      localStatus: LocalTimeEntryStatus.fromStorage(entry.status),
      tags: entry.tags,
    );
  }
}

final timesheetsRepositoryProvider = Provider<TimesheetsRepository>((ref) {
  return TimesheetsRepository(ref.watch(appDatabaseProvider));
});

final recentTimesheetsProvider = StreamProvider<List<Timesheet>>((ref) {
  return ref.watch(timesheetsRepositoryProvider).watchRecentTimesheets();
});

final currentMonthSummaryProvider = StreamProvider<TimesheetSummary>((ref) {
  final now = DateTime.now();
  final begin = DateTime(now.year, now.month);
  final end = DateTime(now.year, now.month + 1);

  return ref.watch(timesheetsRepositoryProvider).watchSummary(begin, end);
});

final currentMonthTimesheetsProvider = StreamProvider<List<Timesheet>>((ref) {
  final now = DateTime.now();
  final begin = DateTime(now.year, now.month);
  final end = DateTime(now.year, now.month + 1);

  return ref.watch(timesheetsRepositoryProvider).watchTimesheetsInRange(
        begin,
        end,
      );
});

final currentWeekSummaryProvider = StreamProvider<TimesheetSummary>((ref) {
  return ref.watch(timesheetsRepositoryProvider).watchCurrentWeekSummary();
});

final projectWeekSummariesProvider =
    StreamProvider<List<ProjectWeekSummary>>((ref) {
  return ref.watch(timesheetsRepositoryProvider).watchProjectWeekSummaries();
});

final weeklyProgressHistoryProvider =
    StreamProvider<List<WeeklyProjectProgress>>((ref) {
  return ref.watch(timesheetsRepositoryProvider).watchWeeklyProgressHistory();
});

({DateTime begin, DateTime end}) currentWeekRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final begin = today.subtract(Duration(days: today.weekday - 1));

  return (begin: begin, end: begin.add(const Duration(days: 7)));
}

int? calculateTimesheetAmountMinor({
  required int durationSeconds,
  required int? hourlyRateMinor,
}) {
  if (hourlyRateMinor == null) {
    return null;
  }

  return (durationSeconds * hourlyRateMinor / 3600).round();
}

int? _rateForTimesheet({
  required AppProject? project,
  required List<ProjectRateHistoryData> rateHistory,
  required DateTime beginAt,
}) {
  if (project == null) {
    return null;
  }

  final projectRates =
      rateHistory.where((rate) => rate.projectId == project.id).toList();
  final matching = projectRates
      .where(
        (rate) =>
            !beginAt.isBefore(rate.effectiveFrom) &&
            (rate.effectiveTo == null || beginAt.isBefore(rate.effectiveTo!)),
      )
      .toList()
    ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));

  if (matching.isNotEmpty) {
    return matching.first.hourlyRateMinor;
  }

  return projectRates.isEmpty ? project.hourlyRateMinor : null;
}

int? _displayRateMinor({
  required int durationSeconds,
  required int? amountMinor,
}) {
  if (amountMinor == null || durationSeconds <= 0) {
    return null;
  }

  return (amountMinor * 3600 / durationSeconds).round();
}

int _displayRemoteDuration(Timesheet entry) {
  if (entry.endAt == null) {
    final seconds = DateTime.now().toUtc().difference(entry.beginAt).inSeconds;
    return seconds < 60 ? 60 : seconds;
  }

  return entry.durationSeconds < 60 ? 60 : entry.durationSeconds;
}

int _displayDuration(LocalTimeEntry entry) {
  if (entry.status == LocalTimeEntryStatus.running.storageValue) {
    final seconds = DateTime.now().toUtc().difference(entry.beginAt).inSeconds;
    return seconds < 60 ? 60 : seconds;
  }

  return entry.durationSeconds < 60 ? 60 : entry.durationSeconds;
}

void _validateEditWindow(DateTime beginAt, DateTime endAt) {
  if (!endAt.isAfter(beginAt)) {
    throw StateError('Окончание должно быть позже начала.');
  }
}

DateTime _normalizedEndAt(DateTime beginAt, DateTime endAt) {
  final begin = beginAt.toUtc();
  final end = endAt.toUtc();
  final minimumEnd = begin.add(const Duration(minutes: 1));

  return end.isBefore(minimumEnd) ? minimumEnd : end;
}

int _durationSeconds(DateTime beginAt, DateTime endAt) {
  final seconds = endAt.toUtc().difference(beginAt.toUtc()).inSeconds;

  return seconds < 60 ? 60 : seconds;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();

  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
