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
        PayoutRule.none => 'Без выплат',
        PayoutRule.biweekly => 'Раз в 2 недели',
        PayoutRule.triweekly => 'Раз в 3 недели',
        PayoutRule.monthly => 'Ежемесячно',
        PayoutRule.customDates => 'Свои даты',
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

class CustomPayoutDateInput {
  const CustomPayoutDateInput({
    required this.payoutDate,
    this.expectedAmount,
    this.note,
  });

  final DateTime payoutDate;
  final double? expectedAmount;
  final String? note;
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

  Stream<List<PayoutDate>> watchCustomPayoutDates(String appProjectId) {
    final query = _database.select(_database.payoutDates)
      ..where((table) => table.appProjectId.equals(appProjectId))
      ..orderBy([(table) => OrderingTerm.asc(table.payoutDate)]);

    return query.watch();
  }

  Future<void> addCustomPayoutDate({
    required String appProjectId,
    required CustomPayoutDateInput input,
  }) async {
    final now = DateTime.now().toUtc();
    await _database.into(_database.payoutDates).insert(
          PayoutDatesCompanion.insert(
            id: 'payout_${now.microsecondsSinceEpoch}',
            appProjectId: appProjectId,
            payoutDate: input.payoutDate,
            expectedAmount: Value(input.expectedAmount),
            note: Value(input.note),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> deleteCustomPayoutDate(String id) {
    return (_database.delete(_database.payoutDates)
          ..where((table) => table.id.equals(id)))
        .go();
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
    DateTime? payoutAnchorDate,
    bool clearPayoutAnchorDate = false,
  }) async {
    final now = DateTime.now().toUtc();

    await _database.transaction(() async {
      final existing = await (_database.select(_database.appProjects)
            ..where((table) => table.id.equals(appProjectId)))
          .getSingleOrNull();

      await (_database.update(_database.appProjects)
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
          payoutAnchorDate: clearPayoutAnchorDate
              ? const Value<DateTime?>(null)
              : payoutAnchorDate == null
                  ? const Value.absent()
                  : Value(payoutAnchorDate),
          updatedAt: Value(now),
        ),
      );

      if (clearHourlyRate || hourlyRateMinor != null) {
        await _recordRateChange(
          appProjectId: appProjectId,
          previousRateMinor: existing?.hourlyRateMinor,
          nextRateMinor: clearHourlyRate ? null : hourlyRateMinor,
          effectiveFrom: now,
        );
      }
    });
  }

  Future<void> _recordRateChange({
    required String appProjectId,
    required int? previousRateMinor,
    required int? nextRateMinor,
    required DateTime effectiveFrom,
  }) async {
    if (previousRateMinor == nextRateMinor) {
      return;
    }

    await (_database.update(_database.projectRateHistory)
          ..where((table) => table.projectId.equals(appProjectId))
          ..where((table) => table.effectiveTo.isNull()))
        .write(ProjectRateHistoryCompanion(effectiveTo: Value(effectiveFrom)));

    if (nextRateMinor == null) {
      return;
    }

    await _database.into(_database.projectRateHistory).insert(
          ProjectRateHistoryCompanion.insert(
            id: 'rate_${effectiveFrom.microsecondsSinceEpoch}_$appProjectId',
            projectId: appProjectId,
            hourlyRateMinor: nextRateMinor,
            effectiveFrom: effectiveFrom,
            createdAt: effectiveFrom,
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

final customPayoutDatesProvider =
    StreamProvider.family<List<PayoutDate>, String>((ref, appProjectId) {
  return ref.watch(projectsRepositoryProvider).watchCustomPayoutDates(
        appProjectId,
      );
});

String _appProjectId(int kimaiProjectId) => 'kimai_$kimaiProjectId';
