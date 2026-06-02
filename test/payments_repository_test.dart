import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/features/local_tracking/data/local_tracking_repository.dart';
import 'package:outstaff_tracker/features/payments/data/payments_repository.dart';
import 'package:outstaff_tracker/features/projects/data/projects_repository.dart';
import 'package:outstaff_tracker/features/timesheets/data/timesheets_repository.dart';

void main() {
  late AppDatabase database;
  late PaymentsRepository payments;
  late ProjectsRepository projects;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    payments = PaymentsRepository(database);
    projects = ProjectsRepository(database);

    await database.into(database.kimaiProjects).insert(
          KimaiProjectsCompanion.insert(
            id: const Value(1),
            name: 'Проект',
            syncedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.appProjects).insert(
          AppProjectsCompanion.insert(
            id: 'kimai_1',
            kimaiProjectId: const Value(1),
            name: 'Проект',
            hourlyRateMinor: const Value(10000),
            payoutRule: const Value('monthly'),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(10),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            beginAt: DateTime.now(),
            endAt: Value(DateTime.now().add(const Duration(hours: 1))),
            durationSeconds: const Value(3600),
            amountMinor: const Value(10000),
            syncedAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() => database.close());

  test('monthly to custom dates changes expected payout source', () async {
    final monthly = await payments.getPayments();
    expect(monthly.expected, isNotEmpty);

    await projects.updateProjectSettings(
      appProjectId: 'kimai_1',
      payoutRule: PayoutRule.customDates,
    );
    await projects.addCustomPayoutDate(
      appProjectId: 'kimai_1',
      input: CustomPayoutDateInput(
        payoutDate: DateTime.now().add(const Duration(days: 10)),
      ),
    );

    final custom = await payments.getPayments();

    expect(custom.expected, isNotEmpty);
    expect(
      custom.expected.first.payoutDate,
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).add(const Duration(days: 10)),
    );
  });

  test('custom payout date deletion removes forecast', () async {
    await projects.updateProjectSettings(
      appProjectId: 'kimai_1',
      payoutRule: PayoutRule.customDates,
    );
    await projects.addCustomPayoutDate(
      appProjectId: 'kimai_1',
      input: CustomPayoutDateInput(
        payoutDate: DateTime.now().add(const Duration(days: 10)),
      ),
    );
    final before = await payments.getPayments();
    expect(before.expected, isNotEmpty);

    final dates = await database.select(database.payoutDates).get();
    await projects.deleteCustomPayoutDate(dates.single.id);

    final after = await payments.getPayments();
    expect(after.expected, isEmpty);
  });

  test('anchor date change recalculates payout period', () {
    final periods = buildPayoutPeriods(
      rule: PayoutRule.biweekly.storageValue,
      anchorDate: DateTime(2026, 5, 15),
      from: DateTime(2026, 5, 1),
      to: DateTime(2026, 6, 1),
      customDates: const [],
    );

    expect(periods.first.payoutDate, DateTime(2026, 5, 15));
    expect(periods.first.start, DateTime(2026, 5, 1));
    expect(periods[1].payoutDate, DateTime(2026, 5, 29));
  });

  test('hourly rate change keeps historical timesheet amount', () async {
    await projects.updateProjectSettings(
      appProjectId: 'kimai_1',
      hourlyRate: 200,
      hourlyRateMinor: 20000,
    );

    final row = await (database.select(database.timesheets)
          ..where((table) => table.id.equals(10)))
        .getSingle();

    expect(row.amountMinor, 10000);

    final rates = await database.select(database.projectRateHistory).get();
    expect(rates.single.hourlyRateMinor, 20000);
  });

  test('weekly goal change updates progress history', () async {
    await projects.updateProjectSettings(
      appProjectId: 'kimai_1',
      weeklyGoalHours: 10,
    );

    final history =
        await TimesheetsRepository(database).getWeeklyProgressHistory(weeks: 1);

    expect(history.single.goalSeconds, 36000);
  });

  test('payments include running local and sync failed open entries', () async {
    final begin = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    await database.into(database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: 'running_local',
            projectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: begin,
            status: LocalTimeEntryStatus.runningLocal.storageValue,
            createdAt: begin,
            updatedAt: begin,
          ),
        );
    await database.into(database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: 'sync_failed_open',
            projectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: begin,
            status: LocalTimeEntryStatus.syncFailed.storageValue,
            createdAt: begin,
            updatedAt: begin,
          ),
        );

    final snapshot = await payments.getPayments();
    final active = snapshot.expected.firstWhere((item) => item.isActivePeriod);

    expect(active.trackedSeconds, greaterThan(3600));
    expect(active.expectedAmountMinor, greaterThan(10000));
  });
}
