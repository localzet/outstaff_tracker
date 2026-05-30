import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../settings/data/settings_repository.dart';

class PeriodValue {
  const PeriodValue({
    required this.label,
    required this.begin,
    required this.end,
    required this.value,
  });

  final String label;
  final DateTime begin;
  final DateTime end;
  final double value;
}

class ProjectDistributionItem {
  const ProjectDistributionItem({
    required this.projectName,
    required this.color,
    required this.totalSeconds,
    required this.amountMinor,
  });

  final String projectName;
  final String? color;
  final int totalSeconds;
  final int amountMinor;
}

class GoalCompletionStat {
  const GoalCompletionStat({
    required this.projectName,
    required this.color,
    required this.weeklyGoalHours,
    required this.actualHours,
  });

  final String projectName;
  final String? color;
  final double weeklyGoalHours;
  final double actualHours;

  double get completionRate {
    if (weeklyGoalHours <= 0) {
      return 0;
    }

    return (actualHours / weeklyGoalHours * 100).clamp(0, 999).toDouble();
  }
}

class AverageWorkingDayStats {
  const AverageWorkingDayStats({
    required this.workingDays,
    required this.totalSeconds,
  });

  final int workingDays;
  final int totalSeconds;

  double get averageHours =>
      workingDays == 0 ? 0 : totalSeconds / workingDays / 3600;
}

class ProjectAverageStat {
  const ProjectAverageStat({
    required this.projectName,
    required this.color,
    required this.averageDaySeconds,
    required this.averageWeekSeconds,
  });

  final String projectName;
  final String? color;
  final int averageDaySeconds;
  final int averageWeekSeconds;
}

class TimeDistributionStat {
  const TimeDistributionStat({
    required this.label,
    required this.totalSeconds,
  });

  final String label;
  final int totalSeconds;
}

class CapacityStats {
  const CapacityStats({
    required this.averageWeekSeconds,
    required this.capacitySeconds,
  });

  final int averageWeekSeconds;
  final int capacitySeconds;

  int get freeSeconds => capacitySeconds - averageWeekSeconds;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.weeklyHours,
    required this.monthlyIncome,
    required this.projectDistribution,
    required this.goalCompletion,
    required this.averageWorkingDay,
    required this.projectAverages,
    required this.hoursByWeekday,
    required this.hoursByHour,
    required this.capacity,
  });

  final List<PeriodValue> weeklyHours;
  final List<PeriodValue> monthlyIncome;
  final List<ProjectDistributionItem> projectDistribution;
  final List<GoalCompletionStat> goalCompletion;
  final AverageWorkingDayStats averageWorkingDay;
  final List<ProjectAverageStat> projectAverages;
  final List<TimeDistributionStat> hoursByWeekday;
  final List<TimeDistributionStat> hoursByHour;
  final CapacityStats capacity;

  PeriodValue? get bestWeek => _extremeWeek(compareMax: true);
  PeriodValue? get worstWeek => _extremeWeek(compareMax: false);

  PeriodValue? _extremeWeek({required bool compareMax}) {
    if (weeklyHours.isEmpty) {
      return null;
    }

    return weeklyHours.reduce(
      (a, b) => compareMax
          ? (a.value >= b.value ? a : b)
          : (a.value <= b.value ? a : b),
    );
  }
}

class AnalyticsRepository {
  AnalyticsRepository(this._database, {SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository;

  final AppDatabase _database;
  final SettingsRepository? _settingsRepository;

  Future<List<PeriodValue>> getWeeklyHoursHistory({int weeks = 12}) async {
    final currentStart = _startOfWeek(DateTime.now());

    return [
      for (var index = weeks - 1; index >= 0; index--)
        await _weeklyHours(currentStart.subtract(Duration(days: index * 7))),
    ];
  }

  Future<List<PeriodValue>> getMonthlyIncomeHistory({int months = 6}) async {
    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month);

    return [
      for (var index = months - 1; index >= 0; index--)
        await _monthlyIncome(
          DateTime(currentStart.year, currentStart.month - index),
        ),
    ];
  }

  Future<List<ProjectDistributionItem>> getProjectDistribution({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final rows = await _projectRows();
    final timesheets = await _timesheetsInRange(range.begin, range.end);

    return [
      for (final row in rows)
        _distributionItem(
          kimaiProject: row.readTable(_database.kimaiProjects),
          appProject: row.readTable(_database.appProjects),
          timesheets: timesheets,
        ),
    ]..removeWhere((item) => item.totalSeconds == 0 && item.amountMinor == 0);
  }

  Future<List<GoalCompletionStat>> getGoalCompletionStats({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final rows = await _projectRows();
    final timesheets = await _timesheetsInRange(range.begin, range.end);

    return [
      for (final row in rows)
        if ((row.readTable(_database.appProjects).weeklyGoalHours ?? 0) > 0)
          _goalStat(
            kimaiProject: row.readTable(_database.kimaiProjects),
            appProject: row.readTable(_database.appProjects),
            timesheets: timesheets,
          ),
    ];
  }

  Future<AverageWorkingDayStats> getAverageWorkingDayStats({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final timesheets = await _timesheetsInRange(range.begin, range.end);
    final dayTotals = <DateTime, int>{};
    for (final item in timesheets) {
      final local = item.beginAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      dayTotals[day] = (dayTotals[day] ?? 0) + item.durationSeconds;
    }

    return AverageWorkingDayStats(
      workingDays: dayTotals.length,
      totalSeconds: dayTotals.values.fold(0, (sum, value) => sum + value),
    );
  }

  Future<List<ProjectAverageStat>> getProjectAverageStats({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final rows = await _projectRows();
    final timesheets = await _timesheetsInRange(range.begin, range.end);
    final weeks =
        mathMax(1, (range.end.difference(range.begin).inDays / 7).ceil());

    return [
      for (final row in rows)
        _projectAverageStat(
          kimaiProject: row.readTable(_database.kimaiProjects),
          appProject: row.readTable(_database.appProjects),
          timesheets: timesheets,
          weeks: weeks,
        ),
    ]..removeWhere(
        (item) => item.averageDaySeconds == 0 && item.averageWeekSeconds == 0,
      );
  }

  Future<List<TimeDistributionStat>> getHoursByWeekday({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final timesheets = await _timesheetsInRange(range.begin, range.end);
    const labels = [
      'Пн',
      'Вт',
      'Ср',
      'Чт',
      'Пт',
      'Сб',
      'Вс',
    ];
    final totals = List<int>.filled(7, 0);
    for (final item in timesheets) {
      totals[item.beginAt.toLocal().weekday - 1] += item.durationSeconds;
    }

    return [
      for (var index = 0; index < labels.length; index++)
        TimeDistributionStat(label: labels[index], totalSeconds: totals[index]),
    ];
  }

  Future<List<TimeDistributionStat>> getHoursByHour({
    DateTime? begin,
    DateTime? end,
  }) async {
    final range = _defaultAnalyticsRange(begin: begin, end: end);
    final timesheets = await _timesheetsInRange(range.begin, range.end);
    final totals = List<int>.filled(24, 0);
    for (final item in timesheets) {
      totals[item.beginAt.toLocal().hour] += item.durationSeconds;
    }

    return [
      for (var hour = 0; hour < totals.length; hour++)
        TimeDistributionStat(
          label: '${hour.toString().padLeft(2, '0')}:00',
          totalSeconds: totals[hour],
        ),
    ];
  }

  Future<CapacityStats> getCapacityStats() async {
    final settings =
        await (_settingsRepository ?? SettingsRepository(_database))
            .loadSettings();
    final weekly = await getWeeklyHoursHistory(weeks: 4);
    final averageHours = weekly.isEmpty
        ? 0
        : weekly.fold<double>(0, (sum, item) => sum + item.value) /
            weekly.length;

    return CapacityStats(
      averageWeekSeconds: (averageHours * 3600).round(),
      capacitySeconds: (settings.comfortableWeeklyCapacityHours * 3600).round(),
    );
  }

  Future<AnalyticsSnapshot> getSnapshot() async {
    final weeklyHours = await getWeeklyHoursHistory();
    final monthlyIncome = await getMonthlyIncomeHistory();
    final distribution = await getProjectDistribution();
    final goals = await getGoalCompletionStats();
    final average = await getAverageWorkingDayStats();
    final projectAverages = await getProjectAverageStats();
    final hoursByWeekday = await getHoursByWeekday();
    final hoursByHour = await getHoursByHour();
    final capacity = await getCapacityStats();

    return AnalyticsSnapshot(
      weeklyHours: weeklyHours,
      monthlyIncome: monthlyIncome,
      projectDistribution: distribution,
      goalCompletion: goals,
      averageWorkingDay: average,
      projectAverages: projectAverages,
      hoursByWeekday: hoursByWeekday,
      hoursByHour: hoursByHour,
      capacity: capacity,
    );
  }

  Stream<AnalyticsSnapshot> watchSnapshot() {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM app_projects '
          'UNION ALL SELECT COUNT(*) FROM payout_dates '
          'UNION ALL SELECT COUNT(*) FROM timesheets '
          'UNION ALL SELECT COUNT(*) FROM sync_state',
          readsFrom: {
            _database.appProjects,
            _database.payoutDates,
            _database.timesheets,
            _database.syncState,
          },
        )
        .watch()
        .asyncMap((_) => getSnapshot());
  }

  Future<PeriodValue> _weeklyHours(DateTime begin) async {
    final end = begin.add(const Duration(days: 7));
    final timesheets = await _timesheetsInRange(begin, end);
    final seconds = timesheets.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );

    return PeriodValue(
      label: '${begin.month}/${begin.day}',
      begin: begin,
      end: end,
      value: seconds / 3600,
    );
  }

  Future<PeriodValue> _monthlyIncome(DateTime begin) async {
    final end = DateTime(begin.year, begin.month + 1);
    final timesheets = await _timesheetsInRange(begin, end);
    final amountMinor = timesheets.fold<int>(
      0,
      (sum, item) => sum + (item.amountMinor ?? 0),
    );

    return PeriodValue(
      label: '${begin.month}/${begin.year}',
      begin: begin,
      end: end,
      value: amountMinor / 100,
    );
  }

  Future<List<TypedResult>> _projectRows() {
    return _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id
            .equalsExp(_database.appProjects.kimaiProjectId),
      ),
    ]).get();
  }

  Future<List<Timesheet>> _timesheetsInRange(DateTime begin, DateTime end) {
    final query = _database.select(_database.timesheets)
      ..where((table) => table.beginAt.isBiggerOrEqualValue(begin))
      ..where((table) => table.beginAt.isSmallerThanValue(end));

    return query.get();
  }

  ProjectDistributionItem _distributionItem({
    required KimaiProject kimaiProject,
    required AppProject appProject,
    required List<Timesheet> timesheets,
  }) {
    final projectTimesheets = timesheets.where(
      (item) => item.appProjectId == appProject.id,
    );

    return ProjectDistributionItem(
      projectName: kimaiProject.name,
      color: appProject.color ?? kimaiProject.color,
      totalSeconds: projectTimesheets.fold(
        0,
        (sum, item) => sum + item.durationSeconds,
      ),
      amountMinor: projectTimesheets.fold(
        0,
        (sum, item) => sum + (item.amountMinor ?? 0),
      ),
    );
  }

  GoalCompletionStat _goalStat({
    required KimaiProject kimaiProject,
    required AppProject appProject,
    required List<Timesheet> timesheets,
  }) {
    final projectSeconds = timesheets
        .where((item) => item.appProjectId == appProject.id)
        .fold<int>(0, (sum, item) => sum + item.durationSeconds);

    return GoalCompletionStat(
      projectName: kimaiProject.name,
      color: appProject.color ?? kimaiProject.color,
      weeklyGoalHours: appProject.weeklyGoalHours ?? 0,
      actualHours: projectSeconds / 3600,
    );
  }

  ProjectAverageStat _projectAverageStat({
    required KimaiProject kimaiProject,
    required AppProject appProject,
    required List<Timesheet> timesheets,
    required int weeks,
  }) {
    final projectTimesheets =
        timesheets.where((item) => item.appProjectId == appProject.id);
    final dayTotals = <DateTime, int>{};
    var totalSeconds = 0;
    for (final item in projectTimesheets) {
      final local = item.beginAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      dayTotals[day] = (dayTotals[day] ?? 0) + item.durationSeconds;
      totalSeconds += item.durationSeconds;
    }

    return ProjectAverageStat(
      projectName: kimaiProject.name,
      color: appProject.color ?? kimaiProject.color,
      averageDaySeconds:
          dayTotals.isEmpty ? 0 : (totalSeconds / dayTotals.length).round(),
      averageWeekSeconds: (totalSeconds / weeks).round(),
    );
  }

  ({DateTime begin, DateTime end}) _defaultAnalyticsRange({
    DateTime? begin,
    DateTime? end,
  }) {
    final now = DateTime.now();
    return (
      begin: begin ?? now.subtract(const Duration(days: 84)),
      end: end ?? now.add(const Duration(days: 1)),
    );
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    ref.watch(appDatabaseProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final analyticsSnapshotProvider = StreamProvider<AnalyticsSnapshot>((ref) {
  return ref.watch(analyticsRepositoryProvider).watchSnapshot();
});

DateTime _startOfWeek(DateTime value) {
  final day = DateTime(value.year, value.month, value.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

int mathMax(int a, int b) => a > b ? a : b;
