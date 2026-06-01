import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';
import '../../../core/network/network_providers.dart';
import 'local_tracking_repository.dart';

class LocalTrackingSyncResult {
  const LocalTrackingSyncResult({
    required this.synced,
    required this.failed,
    required this.conflicts,
  });

  final int synced;
  final int failed;
  final int conflicts;

  bool get hasErrors => failed > 0 || conflicts > 0;
}

class LocalTrackingSyncService {
  LocalTrackingSyncService(this._ref);

  final Ref _ref;

  Future<LocalTrackingSyncResult> syncPendingEntries() async {
    final repository = _ref.read(localTrackingRepositoryProvider);
    final client = await _ref.read(kimaiApiClientProvider.future);
    final entries = await repository.getSyncableEntries();
    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    for (final entry in entries) {
      if (entry.kimaiTimesheetId != null) {
        conflicts++;
        await repository.markConflict(
          entry.id,
          'Local entry already has kimai_timesheet_id=${entry.kimaiTimesheetId}; POST skipped.',
        );
        continue;
      }

      if (entry.endAt == null) {
        failed++;
        await repository.markSyncFailed(
          entry.id,
          'Cannot sync running entry without end_at.',
        );
        continue;
      }

      await repository.markSyncing(entry.id);
      try {
        final duplicate = await _findLikelyDuplicate(client, entry);
        if (duplicate != null) {
          conflicts++;
          await repository.markConflict(
            entry.id,
            'Possible duplicate Kimai timesheet id=${duplicate.id}. Local entry was not posted.',
          );
          continue;
        }

        final remote = await client.createTimesheet(
          projectId: entry.kimaiProjectId,
          activityId: entry.activityId,
          beginAt: entry.beginAt,
          endAt: entry.endAt!,
          description: entry.description ?? '',
          tags: entry.tags,
        );
        await repository.markSynced(
          entry: entry,
          kimaiTimesheetId: remote.id,
        );
        synced++;
      } catch (error) {
        failed++;
        await repository.markSyncFailed(entry.id, _diagnosticError(error));
      }
    }

    return LocalTrackingSyncResult(
      synced: synced,
      failed: failed,
      conflicts: conflicts,
    );
  }

  Future<void> refreshActivities() async {
    final client = await _ref.read(kimaiApiClientProvider.future);
    final database = _ref.read(appDatabaseProvider);
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

  Future<KimaiTimesheetDto?> _findLikelyDuplicate(
    KimaiApiClient client,
    LocalTimeEntry entry,
  ) async {
    final end = entry.endAt;
    if (end == null) {
      return null;
    }

    final result = await client.fetchTimesheets(
      entry.beginAt.subtract(const Duration(minutes: 1)),
      end.add(const Duration(minutes: 1)),
      projectId: entry.kimaiProjectId,
    );
    for (final remote in result) {
      if (remote.id == entry.kimaiTimesheetId) {
        return remote;
      }
      final description = remote.description ?? '';
      final sameWindow =
          remote.beginAt.difference(entry.beginAt).inSeconds.abs() <= 1 &&
              remote.endAt != null &&
              remote.endAt!.difference(end).inSeconds.abs() <= 1;
      final sameDuration =
          (remote.durationSeconds - entry.durationSeconds).abs() <= 1;
      final sameDescription =
          description.trim() == (entry.description ?? '').trim();
      if (sameWindow && sameDuration && sameDescription) {
        return remote;
      }
    }

    return null;
  }

  Object _diagnosticError(Object error) {
    if (error is KimaiApiException) {
      return error.details.toDiagnosticString(syncType: 'local_tracking');
    }
    if (error is DioException) {
      return error.message ?? error.toString();
    }

    return error;
  }
}

final localTrackingSyncServiceProvider =
    Provider<LocalTrackingSyncService>(LocalTrackingSyncService.new);
