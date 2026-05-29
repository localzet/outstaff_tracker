import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/network_providers.dart';
import '../../projects/data/projects_repository.dart';
import '../../timesheets/data/timesheets_repository.dart';

class KimaiConnectResult {
  const KimaiConnectResult({required this.importedProjects});

  final int importedProjects;
}

class SyncRepository {
  SyncRepository(this._ref);

  final Ref _ref;

  Future<bool> checkConnection() async {
    final client = await _ref.read(kimaiApiClientProvider.future);

    return client.checkConnection();
  }

  Future<KimaiConnectResult> connectKimai() async {
    final database = _ref.read(appDatabaseProvider);
    final startedAt = DateTime.now().toUtc();
    final logId = 'kimai_connect_${startedAt.microsecondsSinceEpoch}';

    await database.into(database.syncLogs).insert(
          SyncLogsCompanion.insert(
            id: logId,
            operation: 'kimai_connect',
            status: 'running',
            startedAt: startedAt,
          ),
        );

    try {
      final client = await _ref.read(kimaiApiClientProvider.future);
      await client.checkConnection();

      final projects = await client.fetchProjects();
      if (projects.isEmpty) {
        throw const KimaiEmptyProjectsException();
      }

      await _ref.read(projectsRepositoryProvider).upsertKimaiProjects(projects);

      final finishedAt = DateTime.now().toUtc();
      await database.transaction(() async {
        await (database.update(database.syncLogs)
              ..where((table) => table.id.equals(logId)))
            .write(
          SyncLogsCompanion(
            status: const Value('success'),
            message: Value('Imported ${projects.length} projects'),
            finishedAt: Value(finishedAt),
          ),
        );
        await database.into(database.syncState).insertOnConflictUpdate(
              SyncStateCompanion(
                key: const Value('sync.kimai.last_connect'),
                value: Value('Imported ${projects.length} projects'),
                lastSyncedAt: Value(finishedAt),
                updatedAt: Value(finishedAt),
              ),
            );
      });

      return KimaiConnectResult(importedProjects: projects.length);
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

  Future<void> syncRange(DateTime begin, DateTime end) async {
    final client = await _ref.read(kimaiApiClientProvider.future);
    final projects = await client.fetchProjects();
    final timesheets = await client.fetchTimesheets(begin, end);

    await _ref.read(projectsRepositoryProvider).upsertKimaiProjects(projects);
    await _ref.read(timesheetsRepositoryProvider).upsertTimesheets(timesheets);
  }
}

final syncRepositoryProvider = Provider<SyncRepository>(SyncRepository.new);

final latestSyncLogProvider = StreamProvider<SyncLog?>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final query = database.select(database.syncLogs)
    ..orderBy([(table) => OrderingTerm.desc(table.startedAt)])
    ..limit(1);

  return query.watchSingleOrNull();
});

class KimaiEmptyProjectsException implements Exception {
  const KimaiEmptyProjectsException();

  @override
  String toString() => 'Kimai returned an empty project list.';
}
