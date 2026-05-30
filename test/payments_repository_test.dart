import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/features/payments/data/payments_repository.dart';
import 'package:outstaff_tracker/features/projects/data/projects_repository.dart';

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
}
