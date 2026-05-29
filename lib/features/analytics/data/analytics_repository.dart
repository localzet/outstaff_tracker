import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../projects/data/projects_repository.dart';

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

class PayoutForecast {
  const PayoutForecast({
    required this.projectName,
    required this.color,
    required this.rule,
    required this.nextPayoutDate,
    required this.previousPayoutDate,
    required this.unpaidAmountMinor,
  });

  final String projectName;
  final String? color;
  final String rule;
  final DateTime nextPayoutDate;
  final DateTime previousPayoutDate;
  final int unpaidAmountMinor;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.weeklyHours,
    required this.monthlyIncome,
    required this.projectDistribution,
    required this.goalCompletion,
    required this.averageWorkingDay,
    required this.payoutForecasts,
  });

  final List<PeriodValue> weeklyHours;
  final List<PeriodValue> monthlyIncome;
  final List<ProjectDistributionItem> projectDistribution;
  final List<GoalCompletionStat> goalCompletion;
  final AverageWorkingDayStats averageWorkingDay;
  final List<PayoutForecast> payoutForecasts;

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
  AnalyticsRepository(this._database);

  final AppDatabase _database;

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

  Future<List<PayoutForecast>> getPayoutForecasts() async {
    final rows = await _projectRows();
    final customDates = await _database.select(_database.payoutDates).get();
    final now = DateTime.now();
    final forecasts = <PayoutForecast>[];

    for (final row in rows) {
      final appProject = row.readTable(_database.appProjects);
      if (!appProject.enabled ||
          appProject.payoutRule == PayoutRule.none.storageValue) {
        continue;
      }

      final dates = customDates
          .where((date) => date.appProjectId == appProject.id)
          .map((date) => date.payoutDate)
          .toList()
        ..sort();
      final next = _nextPayoutDate(appProject.payoutRule, now, dates);
      final previous = _previousPayoutDate(appProject.payoutRule, next, dates);
      final unpaidAmount = await _unpaidAmount(appProject.id, previous, next);

      forecasts.add(
        PayoutForecast(
          projectName: row.readTable(_database.kimaiProjects).name,
          color:
              appProject.color ?? row.readTable(_database.kimaiProjects).color,
          rule: appProject.payoutRule,
          nextPayoutDate: next,
          previousPayoutDate: previous,
          unpaidAmountMinor: unpaidAmount,
        ),
      );
    }

    forecasts.sort((a, b) => a.nextPayoutDate.compareTo(b.nextPayoutDate));

    return forecasts;
  }

  Future<AnalyticsSnapshot> getSnapshot() async {
    final weeklyHours = await getWeeklyHoursHistory();
    final monthlyIncome = await getMonthlyIncomeHistory();
    final distribution = await getProjectDistribution();
    final goals = await getGoalCompletionStats();
    final average = await getAverageWorkingDayStats();
    final payouts = await getPayoutForecasts();

    return AnalyticsSnapshot(
      weeklyHours: weeklyHours,
      monthlyIncome: monthlyIncome,
      projectDistribution: distribution,
      goalCompletion: goals,
      averageWorkingDay: average,
      payoutForecasts: payouts,
    );
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

  Future<int> _unpaidAmount(
    String appProjectId,
    DateTime previous,
    DateTime next,
  ) async {
    final query = _database.select(_database.timesheets)
      ..where((table) => table.appProjectId.equals(appProjectId))
      ..where((table) => table.beginAt.isBiggerOrEqualValue(previous))
      ..where((table) => table.beginAt.isSmallerThanValue(next));
    final timesheets = await query.get();

    return timesheets.fold<int>(
      0,
      (sum, item) => sum + (item.amountMinor ?? 0),
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
  return AnalyticsRepository(ref.watch(appDatabaseProvider));
});

final analyticsSnapshotProvider = FutureProvider<AnalyticsSnapshot>((ref) {
  return ref.watch(analyticsRepositoryProvider).getSnapshot();
});

final payoutForecastsProvider = FutureProvider<List<PayoutForecast>>((ref) {
  return ref.watch(analyticsRepositoryProvider).getPayoutForecasts();
});

DateTime _startOfWeek(DateTime value) {
  final day = DateTime(value.year, value.month, value.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime _nextPayoutDate(
  String rule,
  DateTime from,
  List<DateTime> customDates,
) {
  final today = DateTime(from.year, from.month, from.day);
  if (rule == PayoutRule.customDates.storageValue) {
    return customDates.firstWhere(
      (date) => !date.isBefore(today),
      orElse: () => today,
    );
  }

  final stepDays = switch (rule) {
    'biweekly' => 14,
    'triweekly' => 21,
    'monthly' => 0,
    _ => 0,
  };

  if (rule == 'monthly') {
    return DateTime(today.year, today.month + 1, 1);
  }

  return today.add(Duration(days: stepDays));
}

DateTime _previousPayoutDate(
  String rule,
  DateTime next,
  List<DateTime> customDates,
) {
  if (rule == PayoutRule.customDates.storageValue) {
    final previous = customDates.where((date) => date.isBefore(next)).toList();
    return previous.isEmpty
        ? next.subtract(const Duration(days: 30))
        : previous.last;
  }

  return switch (rule) {
    'biweekly' => next.subtract(const Duration(days: 14)),
    'triweekly' => next.subtract(const Duration(days: 21)),
    'monthly' => DateTime(next.year, next.month - 1, next.day),
    _ => next.subtract(const Duration(days: 30)),
  };
}
