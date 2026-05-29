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
              currency: Value(
                item.currency ?? projectsByKimaiId[item.projectId]?.currency,
              ),
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
