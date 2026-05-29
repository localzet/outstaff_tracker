import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';

class TimesheetSummary {
  const TimesheetSummary({
    required this.totalSeconds,
    required this.billableAmount,
    required this.entryCount,
  });

  final int totalSeconds;
  final double billableAmount;
  final int entryCount;
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
      final billableAmount = items.fold<double>(
        0,
        (sum, item) => sum + (item.rate ?? 0),
      );

      return TimesheetSummary(
        totalSeconds: totalSeconds,
        billableAmount: billableAmount,
        entryCount: items.length,
      );
    });
  }

  Future<void> upsertTimesheets(List<KimaiTimesheetDto> timesheets) async {
    final now = DateTime.now().toUtc();

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.timesheets,
        [
          for (final item in timesheets)
            TimesheetsCompanion(
              id: Value(item.id),
              kimaiProjectId: Value(item.projectId),
              activityName: Value(item.activityName),
              description: Value(item.description),
              beginAt: Value(item.beginAt),
              endAt: Value(item.endAt),
              durationSeconds: Value(item.durationSeconds),
              rate: Value(item.rate),
              currency: Value(item.currency),
              exported: Value(item.exported),
              tags: Value(item.tags),
              kimaiUpdatedAt: Value(item.updatedAt),
              syncedAt: Value(now),
            ),
        ],
      );
    });
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
