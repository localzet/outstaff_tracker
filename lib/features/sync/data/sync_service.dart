import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/network_providers.dart';
import '../../projects/data/projects_repository.dart';
import '../../timesheets/data/timesheets_repository.dart';

enum TimesheetSyncMode {
  full,
  incremental,
  manual;

  String get operation => switch (this) {
        TimesheetSyncMode.full => 'timesheets_full_sync',
        TimesheetSyncMode.incremental => 'timesheets_incremental_sync',
        TimesheetSyncMode.manual => 'timesheets_manual_sync',
      };

  String get stateKey => switch (this) {
        TimesheetSyncMode.full => 'sync.timesheets.full',
        TimesheetSyncMode.incremental => 'sync.timesheets.incremental',
        TimesheetSyncMode.manual => 'sync.timesheets.manual',
      };
}

class TimesheetSyncResult {
  const TimesheetSyncResult({
    required this.importedEntries,
    required this.enabledProjects,
  });

  final int importedEntries;
  final int enabledProjects;
}

class SyncService {
  SyncService(this._ref);

  final Ref _ref;

  Future<TimesheetSyncResult> fullSyncLastYear() {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 365));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.full,
    );
  }

  Future<TimesheetSyncResult> incrementalSyncLast7Days() {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 7));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.incremental,
    );
  }

  Future<TimesheetSyncResult> manualSync() {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 7));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.manual,
    );
  }

  Future<TimesheetSyncResult> _syncTimesheets({
    required DateTime begin,
    required DateTime end,
    required TimesheetSyncMode mode,
  }) async {
    final database = _ref.read(appDatabaseProvider);
    final startedAt = DateTime.now().toUtc();
    final logId = '${mode.operation}_${startedAt.microsecondsSinceEpoch}';

    await database.into(database.syncLogs).insert(
          SyncLogsCompanion.insert(
            id: logId,
            operation: mode.operation,
            status: 'running',
            startedAt: startedAt,
          ),
        );

    try {
      final enabledProjects = await _ref
          .read(projectsRepositoryProvider)
          .getEnabledKimaiAppProjects();
      final client = await _ref.read(kimaiApiClientProvider.future);
      final timesheetsRepository = _ref.read(timesheetsRepositoryProvider);
      var importedEntries = 0;

      for (final project in enabledProjects) {
        final kimaiProjectId = project.kimaiProjectId;
        if (kimaiProjectId == null) {
          continue;
        }

        final timesheets = await client.fetchTimesheets(
          begin,
          end,
          projectId: kimaiProjectId,
        );
        await timesheetsRepository.upsertRemoteTimesheets(
          timesheets,
          enabledProjects,
        );
        importedEntries += timesheets.length;
      }

      // TODO: Add reconciliation for remote deletions after confirming Kimai deletion semantics.
      final finishedAt = DateTime.now().toUtc();
      await database.transaction(() async {
        await (database.update(database.syncLogs)
              ..where((table) => table.id.equals(logId)))
            .write(
          SyncLogsCompanion(
            status: const Value('success'),
            message: Value(
              'Synced $importedEntries entries from ${enabledProjects.length} projects',
            ),
            finishedAt: Value(finishedAt),
          ),
        );
        await database.into(database.syncState).insertOnConflictUpdate(
              SyncStateCompanion(
                key: Value(mode.stateKey),
                value: Value(importedEntries.toString()),
                lastSyncedAt: Value(finishedAt),
                updatedAt: Value(finishedAt),
              ),
            );
      });

      return TimesheetSyncResult(
        importedEntries: importedEntries,
        enabledProjects: enabledProjects.length,
      );
    } catch (error) {
      final finishedAt = DateTime.now().toUtc();
      await (database.update(database.syncLogs)
            ..where((table) => table.id.equals(logId)))
          .write(
        SyncLogsCompanion(
          status: const Value('failed'),
          message: Value(error.toString()),
          finishedAt: Value(finishedAt),
        ),
      );

      rethrow;
    }
  }
}

final syncServiceProvider = Provider<SyncService>(SyncService.new);
