import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../timesheets/data/timesheets_repository.dart';

enum LocalTimeEntryStatus {
  draft('draft'),
  starting('starting'),
  syncingStart('syncing_start'),
  running('running'),
  runningSynced('running_synced'),
  runningLocal('running_local'),
  stopped('stopped'),
  syncPending('sync_pending'),
  syncing('syncing'),
  synced('synced'),
  syncFailed('sync_failed'),
  stopFailed('stop_failed'),
  editFailed('edit_failed'),
  conflict('conflict');

  const LocalTimeEntryStatus(this.storageValue);

  final String storageValue;

  String get label => switch (this) {
        LocalTimeEntryStatus.draft => 'Черновик',
        LocalTimeEntryStatus.starting => 'Запуск',
        LocalTimeEntryStatus.syncingStart => 'Идёт в Kimai',
        LocalTimeEntryStatus.running => 'Идёт',
        LocalTimeEntryStatus.runningSynced => 'Идёт в Kimai',
        LocalTimeEntryStatus.runningLocal => 'Идёт локально',
        LocalTimeEntryStatus.stopped => 'Остановлено',
        LocalTimeEntryStatus.syncPending => 'Ожидает отправки',
        LocalTimeEntryStatus.syncing => 'Отправка',
        LocalTimeEntryStatus.synced => 'Синхронизировано',
        LocalTimeEntryStatus.syncFailed => 'Ошибка отправки',
        LocalTimeEntryStatus.stopFailed => 'Ошибка остановки',
        LocalTimeEntryStatus.editFailed => 'Ошибка редактирования',
        LocalTimeEntryStatus.conflict => 'Конфликт',
      };

  static LocalTimeEntryStatus fromStorage(String value) {
    return LocalTimeEntryStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => LocalTimeEntryStatus.conflict,
    );
  }
}

class TimerProjectOption {
  const TimerProjectOption({
    required this.appProjectId,
    required this.kimaiProjectId,
    required this.name,
  });

  final String appProjectId;
  final int kimaiProjectId;
  final String name;
}

class TimerActivityOption {
  const TimerActivityOption({
    required this.id,
    required this.name,
    this.projectId,
  });

  final int id;
  final String name;
  final int? projectId;
}

class ActiveTimeEntry {
  const ActiveTimeEntry({
    required this.id,
    required this.projectName,
    required this.beginAt,
    required this.isLocal,
    this.kimaiTimesheetId,
    this.status,
    this.activityName,
    this.description,
  });

  final String id;
  final int? kimaiTimesheetId;
  final String projectName;
  final LocalTimeEntryStatus? status;
  final String? activityName;
  final String? description;
  final DateTime beginAt;
  final bool isLocal;
}

class LocalTrackingRepository {
  LocalTrackingRepository(this._database);

  final AppDatabase _database;

  Stream<LocalTimeEntry?> watchRunningEntry() {
    final query = _database.select(_database.localTimeEntries)
      ..where(
        (table) => _runningStatusExpression(table),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.beginAt)])
      ..limit(1);

    return query.watchSingleOrNull();
  }

  Future<LocalTimeEntry?> getRunningEntry() {
    final query = _database.select(_database.localTimeEntries)
      ..where(
        (table) => _runningStatusExpression(table),
      )
      ..limit(1);

    return query.getSingleOrNull();
  }

  Stream<ActiveTimeEntry?> watchActiveEntry() {
    return _database
        .customSelect(
          'SELECT COUNT(*) AS c FROM local_time_entries '
          "WHERE status IN ('starting', 'syncing_start', 'running', 'running_synced', 'running_local') "
          "OR (status = 'sync_failed' AND end_at IS NULL) "
          'UNION ALL SELECT COUNT(*) FROM timesheets WHERE end_at IS NULL',
          readsFrom: {_database.localTimeEntries, _database.timesheets},
        )
        .watch()
        .asyncMap((_) => getActiveEntry());
  }

  Future<ActiveTimeEntry?> getActiveEntry() async {
    final local = await _activeLocalEntry();
    if (local != null) {
      return local;
    }

    return _activeRemoteEntry();
  }

  Stream<int> watchPendingCount() {
    return _database
        .customSelect(
          "SELECT COUNT(*) AS c FROM local_time_entries "
          "WHERE status IN ('sync_pending', 'sync_failed', 'stop_failed', 'edit_failed', 'conflict')",
          readsFrom: {_database.localTimeEntries},
        )
        .watchSingle()
        .map((row) => row.read<int>('c'));
  }

  Future<ActiveTimeEntry?> _activeLocalEntry() async {
    final query = _database.select(_database.localTimeEntries).join([
      leftOuterJoin(
        _database.appProjects,
        _database.appProjects.id.equalsExp(
          _database.localTimeEntries.projectId,
        ),
      ),
      leftOuterJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.localTimeEntries.kimaiProjectId,
        ),
      ),
    ])
      ..where(
        _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.running.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.starting.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.syncingStart.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.runningSynced.storageValue,
            ) |
            _database.localTimeEntries.status.equals(
              LocalTimeEntryStatus.runningLocal.storageValue,
            ) |
            (_database.localTimeEntries.status.equals(
                  LocalTimeEntryStatus.syncFailed.storageValue,
                ) &
                _database.localTimeEntries.endAt.isNull()),
      )
      ..orderBy([
        OrderingTerm.desc(_database.localTimeEntries.beginAt),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final entry = row.readTable(_database.localTimeEntries);
    return ActiveTimeEntry(
      id: entry.id,
      kimaiTimesheetId: entry.kimaiTimesheetId,
      projectName: row.readTableOrNull(_database.kimaiProjects)?.name ??
          row.readTableOrNull(_database.appProjects)?.name ??
          'Неизвестный проект',
      status: LocalTimeEntryStatus.fromStorage(entry.status),
      activityName: entry.activityName,
      description: entry.description,
      beginAt: entry.beginAt,
      isLocal: true,
    );
  }

  Future<ActiveTimeEntry?> _activeRemoteEntry() async {
    final query = _database.select(_database.timesheets).join([
      leftOuterJoin(
        _database.appProjects,
        _database.appProjects.id.equalsExp(_database.timesheets.appProjectId),
      ),
      leftOuterJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.timesheets.kimaiProjectId,
        ),
      ),
    ])
      ..where(_database.timesheets.endAt.isNull())
      ..orderBy([OrderingTerm.desc(_database.timesheets.beginAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    final entry = row.readTable(_database.timesheets);
    return ActiveTimeEntry(
      id: entry.id.toString(),
      kimaiTimesheetId: entry.id,
      projectName: row.readTableOrNull(_database.kimaiProjects)?.name ??
          row.readTableOrNull(_database.appProjects)?.name ??
          'Неизвестный проект',
      activityName: entry.activityName,
      description: entry.description,
      beginAt: entry.beginAt,
      isLocal: false,
    );
  }

  Stream<List<LocalTimeEntry>> watchQueue() {
    final query = _database.select(_database.localTimeEntries)
      ..where(
        (table) =>
            table.status.equals(LocalTimeEntryStatus.syncPending.storageValue) |
            table.status.equals(LocalTimeEntryStatus.syncFailed.storageValue) |
            table.status.equals(LocalTimeEntryStatus.stopFailed.storageValue) |
            table.status.equals(LocalTimeEntryStatus.editFailed.storageValue) |
            table.status.equals(LocalTimeEntryStatus.synced.storageValue) |
            table.status.equals(LocalTimeEntryStatus.conflict.storageValue),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);

    return query.watch();
  }

  Future<List<LocalTimeEntry>> getSyncableEntries() {
    final query = _database.select(_database.localTimeEntries)
      ..where(
        (table) =>
            table.status.equals(LocalTimeEntryStatus.syncPending.storageValue) |
            table.status.equals(LocalTimeEntryStatus.syncFailed.storageValue) |
            table.status.equals(LocalTimeEntryStatus.stopFailed.storageValue),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.beginAt)]);

    return query.get();
  }

  Future<List<TimerProjectOption>> getProjectOptions() async {
    final query = _database.select(_database.appProjects).join([
      innerJoin(
        _database.kimaiProjects,
        _database.kimaiProjects.id.equalsExp(
          _database.appProjects.kimaiProjectId,
        ),
      ),
    ])
      ..where(_database.appProjects.enabled.equals(true))
      ..where(_database.appProjects.archived.equals(false));

    final result = await query.get();
    return [
      for (final row in result)
        TimerProjectOption(
          appProjectId: row.readTable(_database.appProjects).id,
          kimaiProjectId: row.readTable(_database.kimaiProjects).id,
          name: row.readTable(_database.kimaiProjects).name,
        ),
    ];
  }

  Future<List<TimerActivityOption>> getActivityOptions(
    int kimaiProjectId,
  ) async {
    final query = _database.select(_database.kimaiActivities)
      ..where(
        (table) =>
            table.projectId.equals(kimaiProjectId) | table.projectId.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    final rows = await query.get();

    return [
      for (final row in rows)
        TimerActivityOption(
          id: row.id,
          name: row.name,
          projectId: row.projectId,
        ),
    ];
  }

  Future<LocalTimeEntry> startTimer({
    required String appProjectId,
    required int kimaiProjectId,
    int? activityId,
    String? activityName,
    String? description,
    String? tags,
    DateTime? beginAt,
    DateTime? now,
    LocalTimeEntryStatus status = LocalTimeEntryStatus.running,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final begin = (beginAt ?? timestamp).toUtc();
    final id = 'local_${timestamp.microsecondsSinceEpoch}';

    return _database.transaction(() async {
      final running = await getRunningEntry();
      if (running != null) {
        throw StateError(
          'Уже запущен таймер. Остановите его перед стартом нового.',
        );
      }

      final project = await (_database.select(_database.appProjects)
            ..where((table) => table.id.equals(appProjectId))
            ..where((table) => table.kimaiProjectId.equals(kimaiProjectId)))
          .getSingleOrNull();
      if (project == null) {
        throw StateError(
          'Проект недоступен для локального таймера.',
        );
      }

      await _database.into(_database.localTimeEntries).insert(
            LocalTimeEntriesCompanion.insert(
              id: id,
              projectId: appProjectId,
              kimaiProjectId: kimaiProjectId,
              activityId: Value(activityId),
              activityName: Value(_blankToNull(activityName)),
              description: Value(_blankToNull(description)),
              tags: Value(_blankToNull(tags)),
              beginAt: begin,
              status: status.storageValue,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      return (_database.select(_database.localTimeEntries)
            ..where((table) => table.id.equals(id)))
          .getSingle();
    });
  }

  Future<LocalTimeEntry> addCompletedEntry({
    required String appProjectId,
    required int kimaiProjectId,
    required DateTime beginAt,
    required DateTime endAt,
    int? activityId,
    String? activityName,
    String? description,
    String? tags,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final begin = beginAt.toUtc();
    final normalizedEnd = _normalizedEndAt(begin, endAt.toUtc());
    final id = 'local_${timestamp.microsecondsSinceEpoch}';

    if (!endAt.toUtc().isAfter(begin)) {
      throw StateError(
        'Окончание должно быть позже начала.',
      );
    }

    await _ensureProjectAvailable(appProjectId, kimaiProjectId);
    await _database.into(_database.localTimeEntries).insert(
          LocalTimeEntriesCompanion.insert(
            id: id,
            projectId: appProjectId,
            kimaiProjectId: kimaiProjectId,
            activityId: Value(activityId),
            activityName: Value(_blankToNull(activityName)),
            description: Value(_blankToNull(description)),
            tags: Value(_blankToNull(tags)),
            beginAt: begin,
            endAt: Value(normalizedEnd),
            durationSeconds: Value(_durationSeconds(begin, normalizedEnd)),
            status: LocalTimeEntryStatus.syncPending.storageValue,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );

    return (_database.select(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .getSingle();
  }

  Future<LocalTimeEntry> stopRunningTimer({
    DateTime? endAt,
    DateTime? now,
    LocalTimeEntryStatus? stoppedStatus,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();

    return _database.transaction(() async {
      final running = await getRunningEntry();
      if (running == null) {
        throw StateError(
          'Нет запущенного таймера.',
        );
      }

      final requestedEnd = (endAt ?? timestamp).toUtc();
      final normalizedEnd = _normalizedEndAt(running.beginAt, requestedEnd);
      await (_database.update(_database.localTimeEntries)
            ..where((table) => table.id.equals(running.id)))
          .write(
        LocalTimeEntriesCompanion(
          endAt: Value(normalizedEnd),
          durationSeconds:
              Value(_durationSeconds(running.beginAt, normalizedEnd)),
          status: Value(
            stoppedStatus?.storageValue ??
                (running.kimaiTimesheetId == null
                    ? LocalTimeEntryStatus.syncPending.storageValue
                    : LocalTimeEntryStatus.synced.storageValue),
          ),
          updatedAt: Value(timestamp),
        ),
      );

      return (_database.select(_database.localTimeEntries)
            ..where((table) => table.id.equals(running.id)))
          .getSingle();
    });
  }

  Future<void> markSyncing(String id) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id))
          ..where((table) => table.kimaiTimesheetId.isNull()))
        .write(
      LocalTimeEntriesCompanion(
        status: Value(LocalTimeEntryStatus.syncing.storageValue),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markRunningSynced({
    required String id,
    required int kimaiTimesheetId,
  }) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        kimaiTimesheetId: Value(kimaiTimesheetId),
        status: Value(LocalTimeEntryStatus.runningSynced.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markRunningLocal(String id, {Object? error}) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        status: Value(LocalTimeEntryStatus.runningLocal.storageValue),
        lastSyncError: Value(error?.toString()),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> upsertRunningTimesheetFromKimai({
    required LocalTimeEntry entry,
    required int kimaiTimesheetId,
  }) async {
    final now = DateTime.now().toUtc();
    await _database.into(_database.timesheets).insertOnConflictUpdate(
          TimesheetsCompanion(
            id: Value(kimaiTimesheetId),
            kimaiProjectId: Value(entry.kimaiProjectId),
            appProjectId: Value(entry.projectId),
            activityId: Value(entry.activityId),
            activityName: Value(entry.activityName),
            description: Value(entry.description),
            tags: Value(entry.tags),
            beginAt: Value(entry.beginAt),
            durationSeconds: const Value(0),
            currency: const Value('RUB'),
            syncedAt: Value(now),
          ),
        );
  }

  Future<void> markStopFailed({
    required String id,
    required Object error,
    DateTime? endAt,
    DateTime? beginAt,
  }) async {
    final now = DateTime.now().toUtc();
    final normalizedEnd = beginAt == null || endAt == null
        ? null
        : _normalizedEndAt(beginAt, endAt);

    await (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        endAt:
            normalizedEnd == null ? const Value.absent() : Value(normalizedEnd),
        durationSeconds: normalizedEnd == null || beginAt == null
            ? const Value.absent()
            : Value(_durationSeconds(beginAt, normalizedEnd)),
        status: Value(LocalTimeEntryStatus.stopFailed.storageValue),
        syncAttempts: const Value.absent(),
        lastSyncError: Value(error.toString()),
        updatedAt: Value(now),
      ),
    );
    await _database.customUpdate(
      'UPDATE local_time_entries SET sync_attempts = sync_attempts + 1 '
      'WHERE id = ?',
      variables: [Variable(id)],
      updates: {_database.localTimeEntries},
    );
  }

  Future<void> markSynced({
    required LocalTimeEntry entry,
    required int kimaiTimesheetId,
  }) async {
    final now = DateTime.now().toUtc();

    await _database.transaction(() async {
      await (_database.update(_database.localTimeEntries)
            ..where((table) => table.id.equals(entry.id)))
          .write(
        LocalTimeEntriesCompanion(
          kimaiTimesheetId: Value(kimaiTimesheetId),
          status: Value(LocalTimeEntryStatus.synced.storageValue),
          lastSyncError: const Value(null),
          updatedAt: Value(now),
        ),
      );

      await _database.into(_database.timesheets).insertOnConflictUpdate(
            TimesheetsCompanion(
              id: Value(kimaiTimesheetId),
              kimaiProjectId: Value(entry.kimaiProjectId),
              appProjectId: Value(entry.projectId),
              activityId: Value(entry.activityId),
              activityName: Value(entry.activityName),
              description: Value(entry.description),
              tags: Value(entry.tags),
              beginAt: Value(entry.beginAt),
              endAt: Value(entry.endAt),
              durationSeconds: Value(entry.durationSeconds),
              amountMinor: Value(await _amountMinor(entry)),
              currency: const Value('RUB'),
              syncedAt: Value(now),
            ),
          );
    });
  }

  Future<void> markSyncFailed(String id, Object error) {
    final now = DateTime.now().toUtc();

    return _database.customUpdate(
      'UPDATE local_time_entries '
      'SET status = ?, sync_attempts = sync_attempts + 1, '
      'last_sync_error = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(LocalTimeEntryStatus.syncFailed.storageValue),
        Variable(error.toString()),
        Variable(now),
        Variable(id),
      ],
      updates: {_database.localTimeEntries},
    );
  }

  Future<void> markConflict(String id, String reason) {
    final now = DateTime.now().toUtc();

    return _database.customUpdate(
      'UPDATE local_time_entries '
      'SET status = ?, sync_attempts = sync_attempts + 1, '
      'last_sync_error = ?, updated_at = ? WHERE id = ?',
      variables: [
        Variable(LocalTimeEntryStatus.conflict.storageValue),
        Variable(reason),
        Variable(now),
        Variable(id),
      ],
      updates: {_database.localTimeEntries},
    );
  }

  Future<void> retry(String id) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        status: Value(LocalTimeEntryStatus.syncPending.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markIgnored(String id) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        status: Value(LocalTimeEntryStatus.draft.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateBeforeRetry({
    required String id,
    int? activityId,
    String? activityName,
    String? description,
    String? tags,
  }) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.localTimeEntries)
          ..where((table) => table.id.equals(id)))
        .write(
      LocalTimeEntriesCompanion(
        activityId: Value(activityId),
        activityName: Value(_blankToNull(activityName)),
        description: Value(_blankToNull(description)),
        tags: Value(_blankToNull(tags)),
        status: Value(LocalTimeEntryStatus.syncPending.storageValue),
        lastSyncError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _ensureProjectAvailable(
    String appProjectId,
    int kimaiProjectId,
  ) async {
    final project = await (_database.select(_database.appProjects)
          ..where((table) => table.id.equals(appProjectId))
          ..where((table) => table.kimaiProjectId.equals(kimaiProjectId)))
        .getSingleOrNull();
    if (project == null) {
      throw StateError(
        'Проект недоступен для локального таймера.',
      );
    }
  }

  DateTime _normalizedEndAt(DateTime beginAt, DateTime endAt) {
    final minimumEnd = beginAt.add(const Duration(minutes: 1));
    return endAt.isBefore(minimumEnd) ? minimumEnd : endAt;
  }

  int _durationSeconds(DateTime beginAt, DateTime endAt) {
    final seconds = endAt.difference(beginAt).inSeconds;
    return seconds < 60 ? 60 : seconds;
  }

  Future<void> upsertActivities(List<KimaiActivity> activities) async {
    final now = DateTime.now().toUtc();
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.kimaiActivities,
        [
          for (final activity in activities)
            KimaiActivitiesCompanion(
              id: Value(activity.id),
              projectId: Value(activity.projectId),
              name: Value(activity.name),
              visible: Value(activity.visible),
              syncedAt: Value(now),
            ),
        ],
      );
    });
  }

  Future<int?> _amountMinor(LocalTimeEntry entry) async {
    final project = await (_database.select(_database.appProjects)
          ..where((table) => table.id.equals(entry.projectId)))
        .getSingleOrNull();

    return calculateTimesheetAmountMinor(
      durationSeconds: entry.durationSeconds,
      hourlyRateMinor: project?.hourlyRateMinor,
    );
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}

final localTrackingRepositoryProvider =
    Provider<LocalTrackingRepository>((ref) {
  return LocalTrackingRepository(ref.watch(appDatabaseProvider));
});

final runningLocalTimerProvider = StreamProvider<LocalTimeEntry?>((ref) {
  return ref.watch(localTrackingRepositoryProvider).watchRunningEntry();
});

final activeTimeEntryProvider = StreamProvider<ActiveTimeEntry?>((ref) {
  return ref.watch(localTrackingRepositoryProvider).watchActiveEntry();
});

final pendingLocalEntriesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(localTrackingRepositoryProvider).watchPendingCount();
});

final localTrackingQueueProvider = StreamProvider<List<LocalTimeEntry>>((ref) {
  return ref.watch(localTrackingRepositoryProvider).watchQueue();
});

Expression<bool> _runningStatusExpression(LocalTimeEntries table) {
  return table.status.equals(LocalTimeEntryStatus.running.storageValue) |
      table.status.equals(LocalTimeEntryStatus.starting.storageValue) |
      table.status.equals(LocalTimeEntryStatus.syncingStart.storageValue) |
      table.status.equals(LocalTimeEntryStatus.runningSynced.storageValue) |
      table.status.equals(LocalTimeEntryStatus.runningLocal.storageValue) |
      (table.status.equals(LocalTimeEntryStatus.syncFailed.storageValue) &
          table.endAt.isNull());
}
