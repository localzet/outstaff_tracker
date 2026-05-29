import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
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
}
