import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';

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
}

class NextPayoutEstimate {
  const NextPayoutEstimate({
    required this.rule,
    required this.estimatedDate,
    required this.amountMinor,
  });

  final String rule;
  final DateTime estimatedDate;
  final int amountMinor;
}

enum TimesheetSortField {
  date,
  duration,
  amount;
}

class TimesheetFilters {
  const TimesheetFilters({
    required this.begin,
    required this.end,
    this.appProjectId,
    this.searchText,
    this.sortField = TimesheetSortField.date,
    this.sortAscending = false,
  });

  final DateTime begin;
  final DateTime end;
  final String? appProjectId;
  final String? searchText;
  final TimesheetSortField sortField;
  final bool sortAscending;

  @override
  bool operator ==(Object other) {
    return other is TimesheetFilters &&
        other.begin == begin &&
        other.end == end &&
        other.appProjectId == appProjectId &&
        other.searchText == searchText &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending;
  }

  @override
  int get hashCode => Object.hash(
        begin,
        end,
        appProjectId,
        searchText,
        sortField,
        sortAscending,
      );
}

class TimesheetEntry {
  const TimesheetEntry({
    required this.timesheet,
    required this.projectName,
    required this.projectColor,
    required this.hourlyRateMinor,
  });

  final Timesheet timesheet;
  final String projectName;
  final String? projectColor;
  final int? hourlyRateMinor;
}

class TimesheetProjectOption {
  const TimesheetProjectOption({
    required this.appProjectId,
    required this.name,
  });

  final String appProjectId;
  final String name;
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
    return _timesheetsFilteredQuery(filters).watch().map(_mapTimesheetEntries);
  }

  Future<List<TimesheetEntry>> getTimesheetsFiltered(
    TimesheetFilters filters,
  ) async {
    final rows = await _timesheetsFilteredQuery(filters).get();

    return _mapTimesheetEntries(rows);
  }

  Stream<TimesheetSummary> watchTimesheetTotals(TimesheetFilters filters) {
    return watchTimesheetsFiltered(filters).map((items) {
      return TimesheetSummary(
        totalSeconds: items.fold(
          0,
          (sum, item) => sum + item.timesheet.durationSeconds,
        ),
        amountMinor: items.fold(
          0,
          (sum, item) => sum + (item.timesheet.amountMinor ?? 0),
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
          name: row.readTable(_database.kimaiProjects).name,
        ),
    ];
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

  Stream<TimesheetSummary> watchSummary(DateTime begin, DateTime end) {
    return watchTimesheetsInRange(begin, end).map((items) {
      final totalSeconds = items.fold<int>(
        0,
        (sum, item) => sum + item.durationSeconds,
      );
      final amountMinor = items.fold<int>(
        0,
        (sum, item) => sum + (item.amountMinor ?? 0),
      );

      return TimesheetSummary(
        totalSeconds: totalSeconds,
        amountMinor: amountMinor,
        entryCount: items.length,
      );
    });
  }

  Future<TimesheetSummary> getCurrentWeekSummary() async {
    final range = currentWeekRange();
    final items = await _timesheetsInRange(range.begin, range.end);

    return _summaryFromTimesheets(items);
  }

  Stream<TimesheetSummary> watchCurrentWeekSummary() {
    final range = currentWeekRange();

    return watchTimesheetsInRange(
      range.begin,
      range.end,
    ).map(_summaryFromTimesheets);
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
    final timesheets = await _timesheetsInRange(range.begin, range.end);

    return _projectSummaries(rows, timesheets);
  }

  Stream<List<ProjectWeekSummary>> watchProjectWeekSummaries() {
    final range = currentWeekRange();

    return _database
        .select(_database.appProjects)
        .join([
          innerJoin(
            _database.kimaiProjects,
            _database.kimaiProjects.id.equalsExp(
              _database.appProjects.kimaiProjectId,
            ),
          ),
        ])
        .watch()
        .asyncMap((rows) async {
          final timesheets = await _timesheetsInRange(range.begin, range.end);

          return _projectSummaries(rows, timesheets);
        });
  }

  Future<NextPayoutEstimate?> getNextPayoutEstimate() async {
    final projects = await (_database.select(_database.appProjects)
          ..where((table) => table.enabled.equals(true))
          ..where((table) => table.payoutRule.equals('none').not()))
        .get();
    if (projects.isEmpty) {
      return null;
    }

    final range = currentWeekRange();
    final timesheets = await _timesheetsInRange(range.begin, range.end);
    final amountMinor = timesheets.fold<int>(
      0,
      (sum, item) => sum + (item.amountMinor ?? 0),
    );

    return NextPayoutEstimate(
      rule: projects.first.payoutRule,
      estimatedDate: _nextPayoutDate(projects.first.payoutRule, DateTime.now()),
      amountMinor: amountMinor,
    );
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
              activityName: Value(item.activityName),
              description: Value(item.description),
              beginAt: Value(item.beginAt),
              endAt: Value(item.endAt),
              durationSeconds: Value(item.durationSeconds),
              rate: Value(item.rate),
              amountMinor: Value(
                _calculateAmountMinor(
                  durationSeconds: item.durationSeconds,
                  hourlyRateMinor:
                      projectsByKimaiId[item.projectId]?.hourlyRateMinor,
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

  Future<List<Timesheet>> _timesheetsInRange(DateTime begin, DateTime end) {
    final query = _database.select(_database.timesheets)
      ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
      ..where((table) => table.beginAt.isSmallerThanValue(end));

    return query.get();
  }

  TimesheetSummary _summaryFromTimesheets(List<Timesheet> items) {
    return TimesheetSummary(
      totalSeconds: items.fold(0, (sum, item) => sum + item.durationSeconds),
      amountMinor: items.fold(0, (sum, item) => sum + (item.amountMinor ?? 0)),
      entryCount: items.length,
    );
  }

  List<ProjectWeekSummary> _projectSummaries(
    List<TypedResult> projectRows,
    List<Timesheet> timesheets,
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
    List<Timesheet> timesheets,
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
            _database.timesheets.description.like(pattern),
      );
    }

    query.orderBy([
      switch (filters.sortField) {
        TimesheetSortField.date => OrderingTerm(
            expression: _database.timesheets.beginAt,
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
      },
    ]);

    return query;
  }

  List<TimesheetEntry> _mapTimesheetEntries(List<TypedResult> rows) {
    return [
      for (final row in rows)
        TimesheetEntry(
          timesheet: row.readTable(_database.timesheets),
          projectName: row.readTableOrNull(_database.kimaiProjects)?.name ??
              row.readTableOrNull(_database.appProjects)?.name ??
              'Unknown project',
          projectColor: row.readTableOrNull(_database.appProjects)?.color ??
              row.readTableOrNull(_database.kimaiProjects)?.color,
          hourlyRateMinor:
              row.readTableOrNull(_database.appProjects)?.hourlyRateMinor,
        ),
    ];
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

final nextPayoutEstimateProvider = FutureProvider<NextPayoutEstimate?>((ref) {
  return ref.watch(timesheetsRepositoryProvider).getNextPayoutEstimate();
});

({DateTime begin, DateTime end}) currentWeekRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final begin = today.subtract(Duration(days: today.weekday - 1));

  return (begin: begin, end: begin.add(const Duration(days: 7)));
}

int? _calculateAmountMinor({
  required int durationSeconds,
  required int? hourlyRateMinor,
}) {
  if (hourlyRateMinor == null) {
    return null;
  }

  return (durationSeconds * hourlyRateMinor / 3600).round();
}

DateTime _nextPayoutDate(String rule, DateTime from) {
  final today = DateTime(from.year, from.month, from.day);

  return switch (rule) {
    'biweekly' => today.add(Duration(days: 14 - (today.weekday % 14))),
    'triweekly' => today.add(Duration(days: 21 - (today.weekday % 21))),
    'monthly' => DateTime(today.year, today.month + 1),
    'custom_dates' => today,
    _ => today,
  };
}
