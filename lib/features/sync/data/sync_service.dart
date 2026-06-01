import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';
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
    required this.reconciledRemovals,
    required this.enabledProjects,
    required this.failedProjects,
    required this.debugReport,
  });

  final int importedEntries;
  final int reconciledRemovals;
  final int enabledProjects;
  final List<String> failedProjects;
  final String debugReport;

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
    final range = buildFullYearSyncRange();

    return _syncTimesheets(
      ranges: _splitByMonth(range),
      mode: TimesheetSyncMode.full,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> incrementalSyncLast7Days({
    void Function(SyncProgress progress)? onProgress,
  }) {
    final range = buildLast7DaysSyncRange();

    return _syncTimesheets(
      ranges: [range],
      mode: TimesheetSyncMode.incremental,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> manualSync({
    void Function(SyncProgress progress)? onProgress,
  }) {
    final range = buildLast7DaysSyncRange();

    return _syncTimesheets(
      ranges: [range],
      mode: TimesheetSyncMode.manual,
      onProgress: onProgress,
    );
  }

  Future<TimesheetSyncResult> _syncTimesheets({
    required List<KimaiSyncRange> ranges,
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
      await _syncActivities(database, client);
      final timesheetsRepository = _ref.read(timesheetsRepositoryProvider);
      await _syncTags(client, timesheetsRepository);
      final firstBegin = ranges.first.begin;
      final finalEnd = ranges.last.end;
      var importedEntries = 0;
      var reconciledRemovals = 0;
      var remoteEntriesFetched = 0;
      final failures = <String>[];
      final projectReports = <String>[];
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
          final projectEntriesById = <int, KimaiTimesheetDto>{};
          final projectRequests = <KimaiTimesheetRequestSummary>[];
          for (final range in ranges) {
            final result = await _retryTransient(
              () => client.fetchTimesheetsDetailed(
                range.begin,
                range.end,
                projectId: kimaiProjectId,
              ),
            );
            for (final entry in result.entries) {
              projectEntriesById[entry.id] = entry;
            }
            projectRequests.addAll(result.requests);
          }
          final projectEntries = projectEntriesById.values.toList(
            growable: false,
          );
          await timesheetsRepository.upsertRemoteTimesheets(
            projectEntries,
            enabledProjects,
          );
          final removed = await timesheetsRepository.reconcileRemoteDeletions(
            kimaiProjectId: kimaiProjectId,
            begin: firstBegin,
            end: finalEnd,
            remoteTimesheetIds: projectEntriesById.keys.toSet(),
          );
          remoteEntriesFetched += projectEntries.length;
          importedEntries += projectEntries.length;
          reconciledRemovals += removed;
          projectReports.add(
            _formatProjectReport(
              projectName: project.name,
              projectId: kimaiProjectId,
              begin: firstBegin,
              end: finalEnd,
              status: 'success',
              entriesReceived: projectEntries.length,
              reconciledRemovals: removed,
              requests: projectRequests,
            ),
          );
        } catch (error) {
          final failure = _formatProjectFailure(
            error,
            projectName: project.name,
            projectId: kimaiProjectId,
            mode: mode,
          );
          failures.add(failure);
          projectReports.add(
            _formatProjectReport(
              projectName: project.name,
              projectId: kimaiProjectId,
              begin: firstBegin,
              end: finalEnd,
              status: 'failed',
              entriesReceived: 0,
              reconciledRemovals: 0,
              requests: const [],
              error: failure,
            ),
          );
        } finally {
          completedProjects += 1;
        }
      }

      final finishedAt = DateTime.now().toUtc();
      final status = failures.isEmpty ? 'success' : 'partial';
      final debugReport = _formatSyncDebugReport(
        mode: mode,
        begin: firstBegin,
        end: finalEnd,
        enabledProjects: enabledProjects.length,
        remoteEntriesFetched: remoteEntriesFetched,
        localUpserts: importedEntries,
        reconciledRemovals: reconciledRemovals,
        failedProjects: failures.length,
        projectReports: projectReports,
      );
      await database.transaction(() async {
        await (database.update(database.syncLogs)
              ..where((table) => table.id.equals(logId)))
            .write(
          SyncLogsCompanion(
            status: Value(status),
            message: Value(
              'Projects: ${enabledProjects.length}; fetched: $remoteEntriesFetched; upserts: $importedEntries; reconciled removals: $reconciledRemovals; failed: ${failures.length}',
            ),
            error:
                Value(failures.isEmpty ? null : failures.join('\n\n---\n\n')),
            debug: Value(debugReport),
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
        reconciledRemovals: reconciledRemovals,
        enabledProjects: enabledProjects.length,
        failedProjects: failures,
        debugReport: debugReport,
      );
    } catch (error, stackTrace) {
      final finishedAt = DateTime.now().toUtc();
      final details = _formatSyncError(error, mode: mode);
      await (database.update(database.syncLogs)
            ..where((table) => table.id.equals(logId)))
          .write(
        SyncLogsCompanion(
          status: const Value('failed'),
          message: Value(error.toString()),
          error: Value(details),
          debug: Value(details),
          finishedAt: Value(finishedAt),
        ),
      );

      Error.throwWithStackTrace(SyncFailureException(details), stackTrace);
    }
  }

  Future<void> _syncActivities(
    AppDatabase database,
    KimaiApiClient client,
  ) async {
    final activities = await client.fetchActivities();
    final now = DateTime.now().toUtc();
    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.kimaiActivities,
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

  Future<void> _syncTags(
    KimaiApiClient client,
    TimesheetsRepository timesheetsRepository,
  ) async {
    try {
      final tags = await client.fetchTags();
      await timesheetsRepository.upsertKimaiTags(tags);
    } on KimaiApiException catch (error) {
      final statusCode = error.details.statusCode;
      if (statusCode != 404 && statusCode != 405) {
        rethrow;
      }
    }
  }

  static List<KimaiSyncRange> _splitByMonth(KimaiSyncRange range) {
    final chunks = <KimaiSyncRange>[];
    var cursor = range.begin;
    while (!cursor.isAfter(range.end)) {
      final nextMonth = DateTime(cursor.year, cursor.month + 1);
      final monthEnd = nextMonth.subtract(const Duration(seconds: 1));
      final chunkEnd = monthEnd.isBefore(range.end) ? monthEnd : range.end;
      chunks.add(KimaiSyncRange(begin: cursor, end: chunkEnd));
      cursor = nextMonth;
    }

    return chunks;
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
    final dioError = switch (error) {
      KimaiApiException(:final source) => source,
      DioException() => error,
      _ => null,
    };

    if (dioError == null) {
      return false;
    }

    return dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.connectionError ||
        (dioError.response?.statusCode != null &&
            dioError.response!.statusCode! >= 500);
  }

  String _formatProjectFailure(
    Object error, {
    required String projectName,
    required int projectId,
    required TimesheetSyncMode mode,
  }) {
    return [
      'project_name=$projectName',
      _formatSyncError(error, mode: mode, projectId: projectId),
    ].join('\n');
  }

  String _formatSyncDebugReport({
    required TimesheetSyncMode mode,
    required DateTime begin,
    required DateTime end,
    required int enabledProjects,
    required int remoteEntriesFetched,
    required int localUpserts,
    required int reconciledRemovals,
    required int failedProjects,
    required List<String> projectReports,
  }) {
    return [
      'sync_type=${mode.name}',
      'begin=${formatKimaiDateTime(begin)}',
      'end=${formatKimaiDateTime(end)}',
      'enabled_projects=$enabledProjects',
      'total_remote_entries_fetched=$remoteEntriesFetched',
      'total_local_upserts=$localUpserts',
      'total_reconciled_removals=$reconciledRemovals',
      'failed_projects=$failedProjects',
      for (final report in projectReports) ...[
        'project_sync_start',
        report,
        'project_sync_end',
      ],
    ].join('\n');
  }

  String _formatProjectReport({
    required String projectName,
    required int projectId,
    required DateTime begin,
    required DateTime end,
    required String status,
    required int entriesReceived,
    required int reconciledRemovals,
    required List<KimaiTimesheetRequestSummary> requests,
    String? error,
  }) {
    return [
      'project_name=$projectName',
      'project_id=$projectId',
      'first_begin=${formatKimaiDateTime(begin)}',
      'final_end=${formatKimaiDateTime(end)}',
      'status=$status',
      'pages_requested=${requests.length}',
      'entries_received=$entriesReceived',
      'reconciled_removals=$reconciledRemovals',
      for (final request in requests) ...[
        'request_start',
        request.toDiagnosticString(),
        'request_end',
      ],
      if (error != null) ...[
        'error_start',
        error,
        'error_end',
      ],
    ].join('\n');
  }

  String _formatSyncError(
    Object error, {
    required TimesheetSyncMode mode,
    int? projectId,
  }) {
    if (error is KimaiApiException) {
      return error.details.toDiagnosticString(
        projectId: projectId,
        syncType: mode.name,
      );
    }

    if (error is DioException) {
      final request = error.requestOptions;
      final uri = request.uri;
      final baseUrl = request.baseUrl.isNotEmpty
          ? request.baseUrl
          : uri.replace(path: '', query: '', fragment: '').toString();

      return KimaiRequestErrorDetails(
        timestamp: DateTime.now().toUtc(),
        baseUrl: baseUrl,
        method: request.method,
        path: uri.path,
        queryParameters: {
          for (final entry in request.queryParameters.entries)
            if (entry.value != null) entry.key: entry.value as Object,
        },
        statusCode: error.response?.statusCode,
        responseBody: stringifyKimaiResponseData(error.response?.data),
      ).toDiagnosticString(projectId: projectId, syncType: mode.name);
    }

    return [
      'timestamp=${DateTime.now().toUtc().toIso8601String()}',
      'sync_type=${mode.name}',
      if (projectId != null) 'project_id=$projectId',
      'error=$error',
    ].join('\n');
  }
}

final syncServiceProvider = Provider<SyncService>(SyncService.new);

class SyncFailureException implements Exception {
  const SyncFailureException(this.details);

  final String details;

  @override
  String toString() => details;
}
