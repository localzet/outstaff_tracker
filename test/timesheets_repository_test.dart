import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';
import 'package:outstaff_tracker/core/network/network_providers.dart';
import 'package:outstaff_tracker/features/local_tracking/data/local_tracking_repository.dart';
import 'package:outstaff_tracker/features/projects/data/projects_repository.dart';
import 'package:outstaff_tracker/features/timesheets/data/timesheet_edit_service.dart';
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
    await database.into(database.kimaiActivities).insert(
          KimaiActivitiesCompanion.insert(
            id: const Value(7),
            projectId: const Value(1),
            name: 'Development',
            syncedAt: DateTime.utc(2026),
          ),
        );
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(101),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            activityId: const Value(7),
            activityName: const Value('Development'),
            description: const Value('Feature work'),
            beginAt: DateTime.utc(2026, 5, 1, 9),
            endAt: Value(DateTime.utc(2026, 5, 1, 10)),
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

  test('running local entry is included in current week summary', () async {
    final begin = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
    await LocalTrackingRepository(database).startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      beginAt: begin,
      now: begin,
    );

    final summary = await repository.getCurrentWeekSummary();

    expect(summary.totalSeconds, greaterThanOrEqualTo(600));
    expect(summary.entryCount, greaterThanOrEqualTo(1));
  });

  test('running remote entry uses dynamic duration in filtered list', () async {
    final begin = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(401),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            beginAt: begin,
            durationSeconds: const Value(0),
            syncedAt: begin,
          ),
        );

    final entries = await repository.getTimesheetsFiltered(
      TimesheetFilters(
        begin: begin.subtract(const Duration(minutes: 1)),
        end: DateTime.now().add(const Duration(minutes: 1)),
      ),
    );
    final entry = entries.singleWhere((item) => item.kimaiTimesheetId == 401);

    expect(entry.endAt, null);
    expect(entry.durationSeconds, greaterThanOrEqualTo(300));
  });

  test('running synced local entry is not duplicated with remote row',
      () async {
    final begin = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(402),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            beginAt: begin,
            durationSeconds: const Value(0),
            syncedAt: begin,
          ),
        );
    await database.into(database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: 'local_running_402',
            kimaiTimesheetId: const Value(402),
            projectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: begin,
            status: LocalTimeEntryStatus.runningSynced.storageValue,
            createdAt: begin,
            updatedAt: begin,
          ),
        );

    final entries = await repository.getTimesheetsFiltered(
      TimesheetFilters(
        begin: begin.subtract(const Duration(minutes: 1)),
        end: DateTime.now().add(const Duration(minutes: 1)),
      ),
    );

    expect(
      entries.where((item) => item.kimaiTimesheetId == 402),
      hasLength(1),
    );
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
          endAt: DateTime.utc(2026, 5, 20, 10),
          durationSeconds: 3600,
        ),
        KimaiTimesheetDto(
          id: 202,
          projectId: 1,
          beginAt: DateTime.utc(2026, 6, 2, 9),
          endAt: DateTime.utc(2026, 6, 2, 10),
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
            endAt: Value(DateTime.utc(2026, 5, 1, 10)),
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
            endAt: Value(DateTime.utc(2026, 5, 2, 10, 30)),
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
            endAt: Value(DateTime.utc(2026, 4, 1, 10)),
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
          endAt: DateTime.utc(2026, 4, 2, 10),
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

  test('edit recent synced timesheet updates Kimai and local row', () async {
    final fakeClient = _FakeKimaiClient(
      updatedTimesheet: KimaiTimesheetDto(
        id: 101,
        projectId: 1,
        activityId: 7,
        activityName: 'Development',
        description: 'Updated work',
        tags: 'bug, urgent',
        beginAt: DateTime.utc(2026, 5, 1, 9, 30),
        endAt: DateTime.utc(2026, 5, 1, 10, 30),
        durationSeconds: 3600,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(timesheetEditServiceProvider).save(
          TimesheetEditInput(
            entryId: '101',
            kimaiTimesheetId: 101,
            appProjectId: 'kimai_1',
            kimaiProjectId: 1,
            activityId: 7,
            activityName: 'Development',
            description: 'Updated work',
            tags: 'bug, urgent',
            beginAt: DateTime.utc(2026, 5, 1, 9, 30),
            endAt: DateTime.utc(2026, 5, 1, 10, 30),
          ),
        );

    final row = await (database.select(database.timesheets)
          ..where((table) => table.id.equals(101)))
        .getSingle();

    expect(fakeClient.updateCalls, 1);
    expect(fakeClient.lastTags, 'bug, urgent');
    expect(row.description, 'Updated work');
    expect(row.tags, 'bug, urgent');
    expect(row.beginAt.toUtc(), DateTime.utc(2026, 5, 1, 9, 30));
  });

  test('edit rejected by Kimai does not corrupt local row', () async {
    final fakeClient = _FakeKimaiClient(
      updatedTimesheet: KimaiTimesheetDto(
        id: 101,
        projectId: 1,
        beginAt: DateTime.utc(2026, 5, 1, 9),
        durationSeconds: 3600,
      ),
      updateError: _kimaiValidationError(),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      () => container.read(timesheetEditServiceProvider).save(
            TimesheetEditInput(
              entryId: '101',
              kimaiTimesheetId: 101,
              appProjectId: 'kimai_1',
              kimaiProjectId: 1,
              activityId: 7,
              activityName: 'Development',
              description: 'Rejected work',
              tags: 'rejected',
              beginAt: DateTime.utc(2026, 5, 1, 11),
              endAt: DateTime.utc(2026, 5, 1, 12),
            ),
          ),
      throwsA(isA<TimesheetEditException>()),
    );

    final row = await (database.select(database.timesheets)
          ..where((table) => table.id.equals(101)))
        .getSingle();

    expect(fakeClient.updateCalls, 1);
    expect(row.description, 'Feature work');
    expect(row.tags, null);
    expect(row.beginAt.toUtc(), DateTime.utc(2026, 5, 1, 9));
  });

  test('full sync removes local synced entry deleted from Kimai', () async {
    final removed = await repository.reconcileRemoteDeletions(
      kimaiProjectId: 1,
      begin: DateTime.utc(2026, 5),
      end: DateTime.utc(2026, 6),
      remoteTimesheetIds: const {},
    );
    final rows = await database.select(database.timesheets).get();

    expect(removed, 1);
    expect(rows, isEmpty);
  });

  test('full sync does not remove local sync pending entry', () async {
    await database.into(database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: 'local_1',
            projectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: DateTime.utc(2026, 5, 1, 11),
            endAt: Value(DateTime.utc(2026, 5, 1, 12)),
            durationSeconds: const Value(3600),
            status: LocalTimeEntryStatus.syncPending.storageValue,
            createdAt: DateTime.utc(2026, 5, 1, 11),
            updatedAt: DateTime.utc(2026, 5, 1, 11),
          ),
        );

    await repository.reconcileRemoteDeletions(
      kimaiProjectId: 1,
      begin: DateTime.utc(2026, 5),
      end: DateTime.utc(2026, 6),
      remoteTimesheetIds: const {},
    );
    final local = await database.select(database.localTimeEntries).getSingle();

    expect(local.status, LocalTimeEntryStatus.syncPending.storageValue);
    expect(local.kimaiTimesheetId, null);
  });

  test('pending local edit conflicts when remote timesheet is missing',
      () async {
    await database.into(database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: 'local_edit_101',
            kimaiTimesheetId: const Value(101),
            projectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: DateTime.utc(2026, 5, 1, 9),
            endAt: Value(DateTime.utc(2026, 5, 1, 10)),
            durationSeconds: const Value(3600),
            status: LocalTimeEntryStatus.editFailed.storageValue,
            createdAt: DateTime.utc(2026, 5, 1, 9),
            updatedAt: DateTime.utc(2026, 5, 1, 9),
          ),
        );

    await repository.reconcileRemoteDeletions(
      kimaiProjectId: 1,
      begin: DateTime.utc(2026, 5),
      end: DateTime.utc(2026, 6),
      remoteTimesheetIds: const {},
    );
    final local = await database.select(database.localTimeEntries).getSingle();

    expect(local.status, LocalTimeEntryStatus.conflict.storageValue);
    expect(local.lastSyncError, contains('Remote Kimai timesheet is missing'));
  });
}

class _FakeKimaiClient implements KimaiApiClient {
  _FakeKimaiClient({
    required this.updatedTimesheet,
    this.updateError,
  });

  final KimaiTimesheetDto updatedTimesheet;
  final Object? updateError;
  int updateCalls = 0;
  String? lastTags;

  @override
  Future<KimaiTimesheetDto> updateTimesheet({
    required int kimaiTimesheetId,
    required int projectId,
    required DateTime beginAt,
    required DateTime endAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    updateCalls++;
    lastTags = tags;
    final error = updateError;
    if (error != null) {
      throw error;
    }

    return updatedTimesheet;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KimaiApiException _kimaiValidationError() {
  final requestOptions = RequestOptions(path: '/api/timesheets/101');
  final response = Response<Object?>(
    requestOptions: requestOptions,
    statusCode: 403,
    data: {'message': 'Timesheet is locked'},
  );
  final source = DioException(
    requestOptions: requestOptions,
    response: response,
  );

  return KimaiApiException(
    KimaiRequestErrorDetails.fromDioException(
      source,
      baseUrl: 'https://kimai.example.test/api',
      method: 'PATCH',
      path: '/timesheets/101',
      queryParameters: const {},
    ),
    source,
  );
}
