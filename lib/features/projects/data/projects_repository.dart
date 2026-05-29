import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';

enum PayoutRule {
  none,
  biweekly,
  triweekly,
  monthly,
  customDates;

  String get storageValue => switch (this) {
        PayoutRule.none => 'none',
        PayoutRule.biweekly => 'biweekly',
        PayoutRule.triweekly => 'triweekly',
        PayoutRule.monthly => 'monthly',
        PayoutRule.customDates => 'custom_dates',
      };

  String get label => switch (this) {
        PayoutRule.none => 'None',
        PayoutRule.biweekly => 'Biweekly',
        PayoutRule.triweekly => 'Triweekly',
        PayoutRule.monthly => 'Monthly',
        PayoutRule.customDates => 'Custom dates',
      };

  static PayoutRule fromStorage(String value) {
    return PayoutRule.values.firstWhere(
      (rule) => rule.storageValue == value,
      orElse: () => PayoutRule.none,
    );
  }
}

class ProjectConfiguration {
  const ProjectConfiguration({
    required this.kimaiProject,
    required this.appProject,
  });

  final KimaiProject kimaiProject;
  final AppProject appProject;
}

class ProjectsRepository {
  ProjectsRepository(this._database);

  final AppDatabase _database;

  Stream<List<KimaiProject>> watchKimaiProjects() {
    final query = _database.select(_database.kimaiProjects)
      ..orderBy([
        (table) => OrderingTerm.asc(table.customerName),
        (table) => OrderingTerm.asc(table.name),
      ]);

    return query.watch();
  }

  Stream<List<ProjectConfiguration>> watchProjectConfigurations() {
    final query = _database.select(_database.kimaiProjects).join([
      innerJoin(
        _database.appProjects,
        _database.appProjects.kimaiProjectId.equalsExp(
          _database.kimaiProjects.id,
        ),
      ),
    ])
      ..orderBy([
        OrderingTerm.asc(_database.kimaiProjects.customerName),
        OrderingTerm.asc(_database.kimaiProjects.name),
      ]);

    return query.watch().map(
          (rows) => [
            for (final row in rows)
              ProjectConfiguration(
                kimaiProject: row.readTable(_database.kimaiProjects),
                appProject: row.readTable(_database.appProjects),
              ),
          ],
        );
  }

  Future<List<AppProject>> getEnabledKimaiAppProjects() {
    final query = _database.select(_database.appProjects)
      ..where((table) => table.enabled.equals(true))
      ..where((table) => table.kimaiProjectId.isNotNull())
      ..where((table) => table.archived.equals(false));

    return query.get();
  }

  Future<void> upsertKimaiProjects(List<KimaiProjectDto> projects) async {
    final now = DateTime.now().toUtc();

    await _database.transaction(() async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _database.kimaiProjects,
          [
            for (final project in projects)
              KimaiProjectsCompanion(
                id: Value(project.id),
                name: Value(project.name),
                customerName: Value(project.customerName),
                visible: Value(project.visible),
                billable: Value(project.billable),
                color: Value(project.color),
                kimaiUpdatedAt: Value(project.updatedAt),
                syncedAt: Value(now),
              ),
          ],
        );
      });

      for (final project in projects) {
        final appProjectId = _appProjectId(project.id);
        final existing = await (_database.select(_database.appProjects)
              ..where((table) => table.id.equals(appProjectId)))
            .getSingleOrNull();

        if (existing == null) {
          await _database.into(_database.appProjects).insert(
                AppProjectsCompanion.insert(
                  id: appProjectId,
                  kimaiProjectId: Value(project.id),
                  name: project.name,
                  color: Value(project.color),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        } else {
          await (_database.update(_database.appProjects)
                ..where((table) => table.id.equals(appProjectId)))
              .write(
            AppProjectsCompanion(
              kimaiProjectId: Value(project.id),
              name: Value(project.name),
              color: existing.color == null
                  ? Value(project.color)
                  : const Value.absent(),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  Future<void> updateProjectSettings({
    required String appProjectId,
    bool? enabled,
    double? hourlyRate,
    int? hourlyRateMinor,
    bool clearHourlyRate = false,
    double? weeklyGoalHours,
    bool clearWeeklyGoalHours = false,
    String? color,
    PayoutRule? payoutRule,
  }) {
    final now = DateTime.now().toUtc();

    return (_database.update(_database.appProjects)
          ..where((table) => table.id.equals(appProjectId)))
        .write(
      AppProjectsCompanion(
        enabled: enabled == null ? const Value.absent() : Value(enabled),
        hourlyRate: clearHourlyRate
            ? const Value<double?>(null)
            : hourlyRate == null
                ? const Value.absent()
                : Value(hourlyRate),
        hourlyRateMinor: clearHourlyRate
            ? const Value<int?>(null)
            : hourlyRateMinor == null
                ? const Value.absent()
                : Value(hourlyRateMinor),
        weeklyGoalHours: clearWeeklyGoalHours
            ? const Value<double?>(null)
            : weeklyGoalHours == null
                ? const Value.absent()
                : Value(weeklyGoalHours),
        color: color == null ? const Value.absent() : Value(color),
        payoutRule: payoutRule == null
            ? const Value.absent()
            : Value(payoutRule.storageValue),
        updatedAt: Value(now),
      ),
    );
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(appDatabaseProvider));
});

final kimaiProjectsProvider = StreamProvider<List<KimaiProject>>((ref) {
  return ref.watch(projectsRepositoryProvider).watchKimaiProjects();
});

final projectConfigurationsProvider =
    StreamProvider<List<ProjectConfiguration>>((ref) {
  return ref.watch(projectsRepositoryProvider).watchProjectConfigurations();
});

String _appProjectId(int kimaiProjectId) => 'kimai_$kimaiProjectId';
