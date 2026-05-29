import 'package:dio/dio.dart';
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
    required this.failedProjects,
  });

  final int importedEntries;
  final int enabledProjects;
  final List<String> failedProjects;

  bool get hasFailures => failedProjects.isNotEmpty;
}

class SyncProgress {
  const SyncProgress({
    required this.currentProject,
    required this.completedProjects,
    required this.totalProjects,
  });

  final String currentProject;
  final int completedProjects;
  final int totalProjects;
}

class SyncService {
  SyncService(this._ref);

  final Ref _ref;

  Future<TimesheetSyncResult> fullSyncLastYear({
    void Function(SyncProgress progress)? onProgress,
  }) {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 365));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.full,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> incrementalSyncLast7Days({
    void Function(SyncProgress progress)? onProgress,
  }) {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 7));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.incremental,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> manualSync({
    void Function(SyncProgress progress)? onProgress,
  }) {
    final end = DateTime.now();
    final begin = end.subtract(const Duration(days: 7));

    return _syncTimesheets(
      begin: begin,
      end: end,
      mode: TimesheetSyncMode.manual,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> _syncTimesheets({
    required DateTime begin,
    required DateTime end,
    required TimesheetSyncMode mode,
    void Function(SyncProgress progress)? onProgress,
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
      final failures = <String>[];
      var completedProjects = 0;

      for (final project in enabledProjects) {
        final kimaiProjectId = project.kimaiProjectId;
        if (kimaiProjectId == null) {
          continue;
        }

        onProgress?.call(
          SyncProgress(
            currentProject: project.name,
            completedProjects: completedProjects,
            totalProjects: enabledProjects.length,
          ),
        );

        try {
          final timesheets = await _retryTransient(
            () => client.fetchTimesheets(begin, end, projectId: kimaiProjectId),
          );
          await timesheetsRepository.upsertRemoteTimesheets(
            timesheets,
            enabledProjects,
          );
          importedEntries += timesheets.length;
        } catch (error) {
          failures.add('${project.name}: $error');
        } finally {
          completedProjects += 1;
        }
      }

      // TODO: Add reconciliation for remote deletions after confirming Kimai deletion semantics.
      final finishedAt = DateTime.now().toUtc();
      final status = failures.isEmpty ? 'success' : 'partial';
      await database.transaction(() async {
        await (database.update(database.syncLogs)
              ..where((table) => table.id.equals(logId)))
            .write(
          SyncLogsCompanion(
            status: Value(status),
            message: Value(
              failures.isEmpty
                  ? 'Synced $importedEntries entries from ${enabledProjects.length} projects'
                  : 'Synced $importedEntries entries; failed ${failures.length} projects',
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
        failedProjects: failures,
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

  Future<T> _retryTransient<T>(Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        if (!_isTransient(error) || attempt == 2) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }

    throw lastError ?? StateError('Unknown sync retry failure');
  }

  bool _isTransient(Object error) {
    if (error is! DioException) {
      return false;
    }

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }
}

final syncServiceProvider = Provider<SyncService>(SyncService.new);
