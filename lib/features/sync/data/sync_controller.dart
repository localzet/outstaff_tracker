import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'sync_service.dart';

class SyncControllerState {
  const SyncControllerState({
    required this.isSyncing,
    this.lastError,
    this.lastFullSyncAt,
    this.lastIncrementalSyncAt,
  });

  const SyncControllerState.idle()
      : isSyncing = false,
        lastError = null,
        lastFullSyncAt = null,
        lastIncrementalSyncAt = null;

  final bool isSyncing;
  final String? lastError;
  final DateTime? lastFullSyncAt;
  final DateTime? lastIncrementalSyncAt;

  SyncControllerState copyWith({
    bool? isSyncing,
    String? lastError,
    bool clearError = false,
    DateTime? lastFullSyncAt,
    DateTime? lastIncrementalSyncAt,
  }) {
    return SyncControllerState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: clearError ? null : lastError ?? this.lastError,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
      lastIncrementalSyncAt:
          lastIncrementalSyncAt ?? this.lastIncrementalSyncAt,
    );
  }
}

class SyncController extends Notifier<SyncControllerState> {
  @override
  SyncControllerState build() {
    _loadSyncState();

    return const SyncControllerState.idle();
  }

  Future<void> runFullSync() {
    return _run(
      () => ref.read(syncServiceProvider).fullSyncLastYear(),
      TimesheetSyncMode.full,
    );
  }

  Future<void> runIncrementalSync() {
    return _run(
      () => ref.read(syncServiceProvider).incrementalSyncLast7Days(),
      TimesheetSyncMode.incremental,
    );
  }

  Future<void> runManualSync() {
    return _run(
      () => ref.read(syncServiceProvider).manualSync(),
      TimesheetSyncMode.manual,
    );
  }

  Future<void> _run(
    Future<TimesheetSyncResult> Function() action,
    TimesheetSyncMode mode,
  ) async {
    if (state.isSyncing) {
      return;
    }

    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      await action();
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        isSyncing: false,
        lastFullSyncAt: mode == TimesheetSyncMode.full ? now : null,
        lastIncrementalSyncAt: mode == TimesheetSyncMode.full ? null : now,
      );
    } catch (error) {
      state = state.copyWith(isSyncing: false, lastError: error.toString());
      rethrow;
    }
  }

  Future<void> _loadSyncState() async {
    final database = ref.read(appDatabaseProvider);
    final rows = await database.select(database.syncState).get();
    final byKey = {for (final row in rows) row.key: row.lastSyncedAt};

    state = state.copyWith(
      lastFullSyncAt: byKey[TimesheetSyncMode.full.stateKey],
      lastIncrementalSyncAt: byKey[TimesheetSyncMode.incremental.stateKey] ??
          byKey[TimesheetSyncMode.manual.stateKey],
    );
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncControllerState>(SyncController.new);
