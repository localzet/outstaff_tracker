import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';
import 'package:outstaff_tracker/features/projects/data/projects_repository.dart';
import 'package:outstaff_tracker/features/timesheets/data/timesheets_repository.dart';

void main() {
  late AppDatabase database;
  late TimesheetsRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = TimesheetsRepository(database);

    await database.into(database.kimaiProjects).insert(
          KimaiProjectsCompanion.insert(
            id: const Value(1),
            name: 'Kimai project',
            syncedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.appProjects).insert(
          AppProjectsCompanion.insert(
            id: 'kimai_1',
            kimaiProjectId: const Value(1),
            name: 'App project',
            hourlyRateMinor: const Value(10000),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(101),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            activityName: const Value('Development'),
            description: const Value('Feature work'),
            beginAt: DateTime.utc(2026, 5, 1, 9),
            durationSeconds: const Value(3600),
            amountMinor: const Value(10000),
            syncedAt: DateTime.utc(2026),
          ),
        );
  });

  tearDown(() => database.close());

  test('filters timesheets and calculates totals', () async {
    final filters = TimesheetFilters(
      begin: DateTime.utc(2026, 5),
      end: DateTime.utc(2026, 6),
      appProjectId: 'kimai_1',
      searchText: 'feature',
    );

    final entries = await repository.getTimesheetsFiltered(filters);
    final totals = await repository.watchTimesheetTotals(filters).first;

    expect(entries, hasLength(1));
    expect(entries.single.projectName, 'Kimai project');
    expect(totals.totalSeconds, 3600);
    expect(totals.amountMinor, 10000);
    expect(totals.entryCount, 1);
  });

  test('applies rate history only for matching effective period', () async {
    await database.into(database.projectRateHistory).insert(
          ProjectRateHistoryCompanion.insert(
            id: 'rate_1',
            projectId: 'kimai_1',
            hourlyRateMinor: 20000,
            effectiveFrom: DateTime.utc(2026, 6),
            createdAt: DateTime.utc(2026, 6),
          ),
        );

    await repository.upsertRemoteTimesheets(
      [
        KimaiTimesheetDto(
          id: 201,
          projectId: 1,
          beginAt: DateTime.utc(2026, 5, 20, 9),
          durationSeconds: 3600,
        ),
        KimaiTimesheetDto(
          id: 202,
          projectId: 1,
          beginAt: DateTime.utc(2026, 6, 2, 9),
          durationSeconds: 3600,
        ),
      ],
      await database.select(database.appProjects).get(),
    );

    final rows = await (database.select(database.timesheets)
          ..where((table) => table.id.isIn([201, 202]))
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();

    expect(rows[0].amountMinor, null);
    expect(rows[1].amountMinor, 20000);
  });

  test('calculates amount from duration and hourly rate', () {
    expect(
      calculateTimesheetAmountMinor(
        durationSeconds: 3600,
        hourlyRateMinor: 75000,
      ),
      75000,
    );
    expect(
      calculateTimesheetAmountMinor(
        durationSeconds: 5400,
        hourlyRateMinor: 75000,
      ),
      112500,
    );
  });

  test('zero rate produces zero amount and diagnostics flag it', () async {
    await database.into(database.kimaiProjects).insert(
          KimaiProjectsCompanion.insert(
            id: const Value(2),
            name: 'Zero rate project',
            syncedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.appProjects).insert(
          AppProjectsCompanion.insert(
            id: 'kimai_2',
            kimaiProjectId: const Value(2),
            name: 'Zero rate project',
            hourlyRateMinor: const Value(0),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(301),
            kimaiProjectId: const Value(2),
            appProjectId: const Value('kimai_2'),
            beginAt: DateTime.utc(2026, 5, 1, 9),
            durationSeconds: const Value(3600),
            amountMinor: const Value(0),
            syncedAt: DateTime.utc(2026),
          ),
        );

    expect(
      calculateTimesheetAmountMinor(
        durationSeconds: 3600,
        hourlyRateMinor: 0,
      ),
      0,
    );

    final diagnostics = await repository.getFinancialDiagnostics();

    expect(diagnostics.enabledProjectsWithZeroRate, 1);
    expect(diagnostics.zeroAmountTimesheetsCount, 1);
  });

  test('repairs existing zero amount timesheets', () async {
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(302),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            beginAt: DateTime.utc(2026, 5, 2, 9),
            durationSeconds: const Value(5400),
            amountMinor: const Value(0),
            syncedAt: DateTime.utc(2026),
          ),
        );

    final summary = await repository.repairZeroAmountTimesheets();
    final repaired = await (database.select(database.timesheets)
          ..where((table) => table.id.equals(302)))
        .getSingle();

    expect(summary.rowsFixed, 1);
    expect(repaired.amountMinor, 15000);
  });

  test('first configured rate applies to imported historical timesheets',
      () async {
    await database.into(database.kimaiProjects).insert(
          KimaiProjectsCompanion.insert(
            id: const Value(3),
            name: 'Historical project',
            syncedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.appProjects).insert(
          AppProjectsCompanion.insert(
            id: 'kimai_3',
            kimaiProjectId: const Value(3),
            name: 'Historical project',
            createdAt: DateTime.utc(2026, 5),
            updatedAt: DateTime.utc(2026, 5),
          ),
        );
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(303),
            kimaiProjectId: const Value(3),
            appProjectId: const Value('kimai_3'),
            beginAt: DateTime.utc(2026, 4, 1, 9),
            durationSeconds: const Value(3600),
            amountMinor: const Value(0),
            syncedAt: DateTime.utc(2026),
          ),
        );

    await ProjectsRepository(database).updateProjectSettings(
      appProjectId: 'kimai_3',
      hourlyRate: 750,
      hourlyRateMinor: 75000,
    );

    await repository.upsertRemoteTimesheets(
      [
        KimaiTimesheetDto(
          id: 304,
          projectId: 3,
          beginAt: DateTime.utc(2026, 4, 2, 9),
          durationSeconds: 3600,
        ),
      ],
      await database.select(database.appProjects).get(),
    );

    final imported = await (database.select(database.timesheets)
          ..where((table) => table.id.equals(304)))
        .getSingle();
    final rate = await (database.select(database.projectRateHistory)
          ..where((table) => table.projectId.equals('kimai_3')))
        .getSingle();

    expect(rate.effectiveFrom.toUtc(), DateTime.utc(2026, 4, 1, 9));
    expect(imported.amountMinor, 75000);
  });
}
