import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';
import 'package:outstaff_tracker/core/network/network_providers.dart';
import 'package:outstaff_tracker/features/local_tracking/data/local_tracking_repository.dart';
import 'package:outstaff_tracker/features/local_tracking/data/local_tracking_sync_service.dart';

void main() {
  late AppDatabase database;
  late LocalTrackingRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalTrackingRepository(database);

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
  });

  tearDown(() => database.close());

  test('start timer writes running entry', () async {
    final entry = await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );

    expect(entry.status, LocalTimeEntryStatus.running.storageValue);
    expect(entry.endAt, null);
    expect(entry.durationSeconds, 0);
  });

  test('stop timer writes sync_pending entry', () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );

    final stopped = await repository.stopRunningTimer(
      now: DateTime.utc(2026, 6, 1, 10, 30),
    );

    expect(stopped.status, LocalTimeEntryStatus.syncPending.storageValue);
    expect(
      stopped.endAt!.toUtc(),
      DateTime.utc(2026, 6, 1, 10, 30),
    );
    expect(stopped.durationSeconds, 5400);
  });

  test('stopped timer shorter than one minute is rounded to one minute',
      () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );

    final stopped = await repository.stopRunningTimer(
      now: DateTime.utc(2026, 6, 1, 9, 0, 10),
    );

    expect(stopped.endAt!.toUtc(), DateTime.utc(2026, 6, 1, 9, 1));
    expect(stopped.durationSeconds, 60);
  });

  test('app restart preserves running timer', () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );

    final restartedRepository = LocalTrackingRepository(database);
    final running = await restartedRepository.getRunningEntry();

    expect(running == null, false);
    expect(running!.beginAt.toUtc(), DateTime.utc(2026, 6, 1, 9));
  });

  test('active entry falls back to running Kimai timesheet', () async {
    await database.into(database.timesheets).insert(
          TimesheetsCompanion.insert(
            id: const Value(601),
            kimaiProjectId: const Value(1),
            appProjectId: const Value('kimai_1'),
            activityName: const Value('Development'),
            description: const Value('Remote timer'),
            beginAt: DateTime.utc(2026, 6, 1, 9),
            durationSeconds: const Value(0),
            syncedAt: DateTime.utc(2026, 6, 1, 9),
          ),
        );

    final active = await repository.getActiveEntry();

    expect(active == null, false);
    expect(active!.kimaiTimesheetId, 601);
    expect(active.isLocal, false);
    expect(active.projectName, 'Kimai project');
  });

  test('offline stopped entry syncs when online', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
        durationSeconds: 3600,
      ),
    );
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );
    await repository.stopRunningTimer(now: DateTime.utc(2026, 6, 1, 10));

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(localTrackingSyncServiceProvider)
        .syncPendingEntries();
    final entry = await database.select(database.localTimeEntries).getSingle();

    expect(result.synced, 1);
    expect(entry.status, LocalTimeEntryStatus.synced.storageValue);
    expect(entry.kimaiTimesheetId, 501);
    expect(fakeClient.createCalls, 1);
  });

  test('online timer start creates Kimai entry and stores id', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
      startedTimesheet: KimaiTimesheetDto(
        id: 701,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    final entry =
        await container.read(localTrackingSyncServiceProvider).startTimer(
              appProjectId: 'kimai_1',
              kimaiProjectId: 1,
              beginAt: DateTime.utc(2026, 6, 1, 9),
            );

    expect(entry.status, LocalTimeEntryStatus.runningSynced.storageValue);
    expect(entry.kimaiTimesheetId, 701);
    expect(fakeClient.startCalls, 1);
  });

  test('offline timer start keeps local running entry only', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
      startError: DioException(
        requestOptions: RequestOptions(path: '/api/timesheets'),
        type: DioExceptionType.connectionError,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    final entry =
        await container.read(localTrackingSyncServiceProvider).startTimer(
              appProjectId: 'kimai_1',
              kimaiProjectId: 1,
              beginAt: DateTime.utc(2026, 6, 1, 9),
            );

    expect(entry.status, LocalTimeEntryStatus.runningLocal.storageValue);
    expect(entry.kimaiTimesheetId, null);
    expect(fakeClient.startCalls, 1);
  });

  test('Kimai start server error keeps timer active as sync failed', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
      startError: DioException(
        requestOptions: RequestOptions(path: '/api/timesheets'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/api/timesheets'),
          statusCode: 500,
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      () => container.read(localTrackingSyncServiceProvider).startTimer(
            appProjectId: 'kimai_1',
            kimaiProjectId: 1,
            beginAt: DateTime.utc(2026, 6, 1, 9),
          ),
      throwsA(isA<DioException>()),
    );

    final running = await repository.getRunningEntry();
    expect(running == null, false);
    expect(running!.status, LocalTimeEntryStatus.syncFailed.storageValue);
    expect(running.endAt, null);
  });

  test('stop synced timer updates Kimai and local status', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
      stoppedTimesheet: KimaiTimesheetDto(
        id: 701,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
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

    final local = await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      beginAt: DateTime.utc(2026, 6, 1, 9),
      now: DateTime.utc(2026, 6, 1, 9),
      status: LocalTimeEntryStatus.runningSynced,
    );
    await repository.markRunningSynced(id: local.id, kimaiTimesheetId: 701);

    final stopped =
        await container.read(localTrackingSyncServiceProvider).stopTimer(
              endAt: DateTime.utc(2026, 6, 1, 10),
            );

    expect(stopped.status, LocalTimeEntryStatus.synced.storageValue);
    expect(stopped.durationSeconds, 3600);
    expect(fakeClient.stopCalls, 1);
  });

  test('failed synced stop is retried with Kimai stop endpoint', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 501,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        durationSeconds: 0,
      ),
      stoppedTimesheet: KimaiTimesheetDto(
        id: 701,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
        durationSeconds: 3600,
      ),
      stopErrors: [
        DioException(
          requestOptions: RequestOptions(path: '/api/timesheets/701/stop'),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);
    final local = await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      beginAt: DateTime.utc(2026, 6, 1, 9),
      now: DateTime.utc(2026, 6, 1, 9),
      status: LocalTimeEntryStatus.runningSynced,
    );
    await repository.markRunningSynced(id: local.id, kimaiTimesheetId: 701);

    await expectLater(
      () => container.read(localTrackingSyncServiceProvider).stopTimer(
            endAt: DateTime.utc(2026, 6, 1, 10),
          ),
      throwsA(isA<DioException>()),
    );

    final failed = await database.select(database.localTimeEntries).getSingle();
    expect(failed.status, LocalTimeEntryStatus.stopFailed.storageValue);
    expect(failed.endAt!.toUtc(), DateTime.utc(2026, 6, 1, 10));

    final result = await container
        .read(localTrackingSyncServiceProvider)
        .syncPendingEntries();
    final synced = await database.select(database.localTimeEntries).getSingle();

    expect(result.synced, 1);
    expect(fakeClient.stopCalls, 2);
    expect(fakeClient.createCalls, 0);
    expect(synced.status, LocalTimeEntryStatus.synced.storageValue);
  });

  test('synced local entry preserves activity id in timesheets', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 504,
        projectId: 1,
        activityId: 7,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
        durationSeconds: 3600,
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
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      activityId: 7,
      activityName: 'Development',
      now: DateTime.utc(2026, 6, 1, 9),
    );
    await repository.stopRunningTimer(now: DateTime.utc(2026, 6, 1, 10));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localTrackingSyncServiceProvider).syncPendingEntries();
    final timesheet = await database.select(database.timesheets).getSingle();

    expect(timesheet.activityId, 7);
    expect(timesheet.activityName, 'Development');
  });

  test('sync sends description exactly without local metadata', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 502,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
        durationSeconds: 3600,
      ),
    );
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      description: 'Fix auth bug',
      now: DateTime.utc(2026, 6, 1, 9),
    );
    await repository.stopRunningTimer(now: DateTime.utc(2026, 6, 1, 10));

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localTrackingSyncServiceProvider).syncPendingEntries();

    expect(fakeClient.lastDescription, 'Fix auth bug');
  });

  test('tags are preserved and sent to Kimai', () async {
    final fakeClient = _FakeKimaiClient(
      createdTimesheet: KimaiTimesheetDto(
        id: 503,
        projectId: 1,
        beginAt: DateTime.utc(2026, 6, 1, 9),
        endAt: DateTime.utc(2026, 6, 1, 10),
        durationSeconds: 3600,
      ),
    );
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      tags: 'bug, urgent',
      now: DateTime.utc(2026, 6, 1, 9),
    );
    await repository.stopRunningTimer(now: DateTime.utc(2026, 6, 1, 10));

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith((ref) async => fakeClient),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localTrackingSyncServiceProvider).syncPendingEntries();
    final entry = await database.select(database.localTimeEntries).getSingle();

    expect(entry.tags, 'bug, urgent');
    expect(fakeClient.lastTags, 'bug, urgent');
  });

  test('failed sync increments attempts and stores error', () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );
    final stopped = await repository.stopRunningTimer(
      now: DateTime.utc(2026, 6, 1, 10),
    );

    await repository.markSyncFailed(stopped.id, 'activity is required');
    final entry = await database.select(database.localTimeEntries).getSingle();

    expect(entry.status, LocalTimeEntryStatus.syncFailed.storageValue);
    expect(entry.syncAttempts, 1);
    expect(entry.lastSyncError, contains('activity'));
  });

  test('duplicate prevention skips entry with kimai_timesheet_id', () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );
    final stopped = await repository.stopRunningTimer(
      now: DateTime.utc(2026, 6, 1, 10),
    );
    await (database.update(database.localTimeEntries)
          ..where((table) => table.id.equals(stopped.id)))
        .write(const LocalTimeEntriesCompanion(kimaiTimesheetId: Value(501)));

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        kimaiApiClientProvider.overrideWith(
          (ref) async => _FakeKimaiClient(
            createdTimesheet: KimaiTimesheetDto(
              id: 502,
              projectId: 1,
              beginAt: DateTime.utc(2026, 6, 1, 9),
              durationSeconds: 3600,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(localTrackingSyncServiceProvider)
        .syncPendingEntries();
    final entry = await database.select(database.localTimeEntries).getSingle();

    expect(result.conflicts, 1);
    expect(entry.status, LocalTimeEntryStatus.conflict.storageValue);
  });

  test('only one running timer is allowed', () async {
    await repository.startTimer(
      appProjectId: 'kimai_1',
      kimaiProjectId: 1,
      now: DateTime.utc(2026, 6, 1, 9),
    );

    expect(
      () => repository.startTimer(
        appProjectId: 'kimai_1',
        kimaiProjectId: 1,
        now: DateTime.utc(2026, 6, 1, 10),
      ),
      throwsStateError,
    );
  });
}

class _FakeKimaiClient implements KimaiApiClient {
  _FakeKimaiClient({
    required this.createdTimesheet,
    KimaiTimesheetDto? startedTimesheet,
    KimaiTimesheetDto? stoppedTimesheet,
    this.startError,
    List<Object>? stopErrors,
  })  : startedTimesheet = startedTimesheet ?? createdTimesheet,
        stoppedTimesheet = stoppedTimesheet ?? createdTimesheet,
        stopErrors = stopErrors ?? [];

  final KimaiTimesheetDto createdTimesheet;
  final KimaiTimesheetDto startedTimesheet;
  final KimaiTimesheetDto stoppedTimesheet;
  final Object? startError;
  final List<Object> stopErrors;
  int createCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;
  String? lastDescription;
  String? lastTags;

  @override
  Future<KimaiTimesheetDto> createTimesheet({
    required int projectId,
    required DateTime beginAt,
    required DateTime endAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    createCalls++;
    lastDescription = description;
    lastTags = tags;
    return createdTimesheet;
  }

  @override
  Future<KimaiTimesheetDto> startTimesheet({
    required int projectId,
    required DateTime beginAt,
    required String description,
    int? activityId,
    String? tags,
  }) async {
    startCalls++;
    lastDescription = description;
    lastTags = tags;
    final error = startError;
    if (error != null) {
      throw error;
    }
    return startedTimesheet;
  }

  @override
  Future<KimaiTimesheetDto> stopTimesheet({
    required int kimaiTimesheetId,
    required DateTime endAt,
  }) async {
    stopCalls++;
    if (stopErrors.isNotEmpty) {
      throw stopErrors.removeAt(0);
    }
    return stoppedTimesheet;
  }

  @override
  Future<List<KimaiTimesheetDto>> fetchTimesheets(
    DateTime begin,
    DateTime end, {
    int? projectId,
  }) async {
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
