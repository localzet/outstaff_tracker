import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'sync_service.dart';

class SyncControllerState {
  const SyncControllerState({
    required this.isSyncing,
    this.lastError,
    this.lastFullSyncAt,
    this.lastIncrementalSyncAt,
    this.currentProject,
    this.completedProjects = 0,
    this.totalProjects = 0,
  });

  const SyncControllerState.idle()
      : isSyncing = false,
        lastError = null,
        lastFullSyncAt = null,
        lastIncrementalSyncAt = null,
        currentProject = null,
        completedProjects = 0,
        totalProjects = 0;

  final bool isSyncing;
  final String? lastError;
  final DateTime? lastFullSyncAt;
  final DateTime? lastIncrementalSyncAt;
  final String? currentProject;
  final int completedProjects;
  final int totalProjects;

  SyncControllerState copyWith({
    bool? isSyncing,
    String? lastError,
    bool clearError = false,
    DateTime? lastFullSyncAt,
    DateTime? lastIncrementalSyncAt,
    String? currentProject,
    int? completedProjects,
    int? totalProjects,
  }) {
    return SyncControllerState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: clearError ? null : lastError ?? this.lastError,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
      lastIncrementalSyncAt:
          lastIncrementalSyncAt ?? this.lastIncrementalSyncAt,
      currentProject: currentProject,
      completedProjects: completedProjects ?? this.completedProjects,
      totalProjects: totalProjects ?? this.totalProjects,
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
      () => ref.read(syncServiceProvider).fullSyncLastYear(
            onProgress: _onProgress,
          ),
      TimesheetSyncMode.full,
    );
  }

  Future<void> runIncrementalSync() {
    return _run(
      () => ref.read(syncServiceProvider).incrementalSyncLast7Days(
            onProgress: _onProgress,
          ),
      TimesheetSyncMode.incremental,
    );
  }

  Future<void> runManualSync() {
    return _run(
      () => ref.read(syncServiceProvider).manualSync(onProgress: _onProgress),
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
      final result = await action();
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        isSyncing: false,
        currentProject: null,
        lastFullSyncAt: mode == TimesheetSyncMode.full ? now : null,
        lastIncrementalSyncAt: mode == TimesheetSyncMode.full ? null : now,
        lastError: result.hasFailures ? result.failedProjects.join('\n') : null,
        clearError: !result.hasFailures,
      );
    } catch (error) {
      state = state.copyWith(isSyncing: false, lastError: error.toString());
      rethrow;
    }
  }

  void _onProgress(SyncProgress progress) {
    state = state.copyWith(
      currentProject: progress.currentProject,
      completedProjects: progress.completedProjects,
      totalProjects: progress.totalProjects,
    );
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
