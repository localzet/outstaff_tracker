import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class UsersLocal extends Table {
  TextColumn get id => text()();
  IntColumn get kimaiUserId => integer().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class KimaiProjects extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get customerName => text().nullable()();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  BoolColumn get billable => boolean().withDefault(const Constant(true))();
  TextColumn get color => text().nullable()();
  DateTimeColumn get kimaiUpdatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class KimaiActivities extends Table {
  IntColumn get id => integer()();
  IntColumn get projectId => integer().nullable()();
  TextColumn get name => text()();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppProjects extends Table {
  TextColumn get id => text()();
  IntColumn get kimaiProjectId => integer()
      .nullable()
      .customConstraint('NULL REFERENCES kimai_projects(id)')();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  RealColumn get hourlyRate => real().nullable()();
  IntColumn get hourlyRateMinor => integer().nullable()();
  RealColumn get weeklyGoalHours => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('RUB'))();
  TextColumn get payoutRule => text().withDefault(const Constant('none'))();
  DateTimeColumn get payoutAnchorDate => dateTime().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PayoutDates extends Table {
  TextColumn get id => text()();
  TextColumn get appProjectId =>
      text().customConstraint('NOT NULL REFERENCES app_projects(id)')();
  DateTimeColumn get payoutDate => dateTime()();
  RealColumn get expectedAmount => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('RUB'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectRateHistory extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().customConstraint('NOT NULL REFERENCES app_projects(id)')();
  IntColumn get hourlyRateMinor => integer()();
  DateTimeColumn get effectiveFrom => dateTime()();
  DateTimeColumn get effectiveTo => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Timesheets extends Table {
  IntColumn get id => integer()();
  IntColumn get kimaiProjectId => integer()
      .nullable()
      .customConstraint('NULL REFERENCES kimai_projects(id)')();
  TextColumn get appProjectId =>
      text().nullable().customConstraint('NULL REFERENCES app_projects(id)')();
  TextColumn get activityName => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get beginAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get rate => real().nullable()();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get currency => text().nullable()();
  BoolColumn get exported => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get kimaiUpdatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalTimeEntries extends Table {
  TextColumn get id => text()();
  IntColumn get kimaiTimesheetId => integer().nullable()();
  TextColumn get projectId =>
      text().customConstraint('NOT NULL REFERENCES app_projects(id)')();
  IntColumn get kimaiProjectId =>
      integer().customConstraint('NOT NULL REFERENCES kimai_projects(id)')();
  IntColumn get activityId => integer().nullable()();
  TextColumn get activityName => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get beginAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  IntColumn get kimaiProjectId =>
      integer().customConstraint('NOT NULL REFERENCES kimai_projects(id)')();
  DateTimeColumn get payoutDate => dateTime()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get expectedAmountMinor => integer()();
  IntColumn get actualAmountMinor => integer().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()();
  TextColumn get status => text()();
  TextColumn get message => text().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get debug => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    UsersLocal,
    SyncState,
    KimaiProjects,
    KimaiActivities,
    AppProjects,
    PayoutDates,
    ProjectRateHistory,
    Timesheets,
    LocalTimeEntries,
    Payments,
    SyncLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'outstaff_tracker',
                native: const DriftNativeOptions(shareAcrossIsolates: true),
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(appProjects, appProjects.enabled);
            await m.addColumn(appProjects, appProjects.weeklyGoalHours);
            await m.addColumn(appProjects, appProjects.payoutRule);
          }
          if (from < 3) {
            await m.addColumn(appProjects, appProjects.hourlyRateMinor);
            await m.addColumn(timesheets, timesheets.amountMinor);
          }
          if (from < 4) {
            await m.addColumn(syncLogs, syncLogs.error);
          }
          if (from < 5) {
            await m.addColumn(syncLogs, syncLogs.debug);
          }
          if (from < 6) {
            await m.createTable(payments);
          }
          if (from < 7) {
            await m.addColumn(appProjects, appProjects.payoutAnchorDate);
          }
          if (from < 8) {
            await m.createTable(projectRateHistory);
          }
          if (from < 9) {
            await m.createTable(kimaiActivities);
            await m.createTable(localTimeEntries);
          }
          if (from < 10) {
            await m.addColumn(localTimeEntries, localTimeEntries.tags);
          }
        },
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);

  return database;
});
