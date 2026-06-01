import 'dart:convert';

import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/db/app_database.dart';
import 'package:outstaff_tracker/core/export/report_file_exporter.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';
import 'package:outstaff_tracker/core/utils/tags.dart';
import 'package:outstaff_tracker/features/reports/data/reports_repository.dart';

void main() {
  group('Kimai tags parsing', () {
    test('parses tags from list of strings', () {
      final entry = KimaiTimesheetDto.fromJson({
        'id': 1,
        'begin': '2026-01-01T09:00:00+0000',
        'duration': 3600,
        'tags': ['billable', ' urgent '],
      });

      expect(parseTags(entry.tags), ['billable', 'urgent']);
      expect(entry.tagSourceKeys, ['tags']);
    });

    test('parses tags from list of objects', () {
      final entry = KimaiTimesheetDto.fromJson({
        'id': 2,
        'begin': '2026-01-01T09:00:00+0000',
        'duration': 3600,
        'tags': [
          {'name': 'backend'},
          {'name': 'review'},
        ],
      });

      expect(parseTags(entry.tags), ['backend', 'review']);
    });
  });

  group('report mapping and exports', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('report uses real user, project and activity names', () async {
      final repository = ReportsRepository(
        database: database,
        apiClient: _FakeKimaiClient([
          KimaiTimesheetDto.fromJson({
            'id': 11,
            'begin': '2026-05-01T09:00:00+0000',
            'end': '2026-05-01T10:00:00+0000',
            'duration': 3600,
            'rate': 1500,
            'project': {
              'id': 42,
              'name': 'Tracker',
              'customer': {'name': 'Acme'},
            },
            'activity': {'id': 5, 'name': 'Development'},
            'user': {
              'id': 7,
              'alias': 'Ivan Petrov',
              'displayName': 'Ivan P.',
              'username': 'ivan',
              'name': 'Ivan',
            },
            'tags': ['backend'],
          }),
        ]),
      );

      final report = await repository.buildReport(
        ReportQuery(
          projectId: 42,
          begin: DateTime.utc(2026, 5),
          end: DateTime.utc(2026, 6),
        ),
      );
      final entry = report.entries.single;

      expect(entry.userName, 'Ivan Petrov');
      expect(entry.projectName, 'Acme / Tracker');
      expect(entry.activity, 'Development');
      expect(entry.tags, 'backend');
      expect(report.userSummaries.single.projectNames, ['Acme / Tracker']);
      expect(report.projectSummaries.single.projectName, 'Acme / Tracker');
    });

    test('export data contains tags and localized CSV headers', () {
      final rows = [
        ['Дата', 'Пользователь', 'Проект', 'Метки'],
        ['2026-05-01', 'Ivan Petrov', 'Tracker', 'backend, urgent'],
      ];
      final bytes = buildCsvBytes(rows);
      final csv = utf8.decode(bytes);

      expect(csv, contains('Дата;Пользователь;Проект;Метки'));
      expect(csv, contains('backend, urgent'));
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    });

    test('XLSX generation returns bytes with expected sheets', () {
      final bytes = buildXlsxBytes([
        const ExportSheet(
          name: 'Summary by users',
          rows: [
            ['Пользователь', 'Метки'],
            ['Ivan Petrov', 'backend'],
          ],
        ),
        const ExportSheet(
          name: 'Summary by projects',
          rows: [
            ['Проект', 'Записей'],
            ['Tracker', 1],
          ],
        ),
        const ExportSheet(
          name: 'Details',
          rows: [
            ['Дата', 'Метки'],
            ['2026-05-01', 'backend'],
          ],
        ),
      ]);
      final decoded = Excel.decodeBytes(bytes);

      expect(bytes, isNotEmpty);
      expect(
        decoded.tables.keys,
        containsAll([
          'Summary by users',
          'Summary by projects',
          'Details',
        ]),
      );
    });
  });
}

class _FakeKimaiClient implements KimaiApiClient {
  _FakeKimaiClient(this.reportEntries);

  final List<KimaiTimesheetDto> reportEntries;

  @override
  Future<bool> checkConnection() async => true;

  @override
  Future<KimaiTimesheetDto> createTimesheet({
    required int projectId,
    required DateTime beginAt,
    required DateTime endAt,
    required String description,
    int? activityId,
    String? tags,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<KimaiActivityDto>> fetchActivities({int? projectId}) async {
    return const [];
  }

  @override
  Future<KimaiCurrentUserDto> fetchCurrentUser() async {
    return const KimaiCurrentUserDto(
      id: 1,
      username: 'admin',
      displayName: 'Admin',
      roles: ['ROLE_ADMIN'],
    );
  }

  @override
  Future<List<KimaiProjectDto>> fetchProjects() async {
    return const [];
  }

  @override
  Future<List<KimaiTimesheetDto>> fetchTimesheets(
    DateTime begin,
    DateTime end, {
    int? projectId,
  }) async {
    return reportEntries;
  }

  @override
  Future<KimaiTimesheetFetchResult> fetchTimesheetsDetailed(
    DateTime begin,
    DateTime end, {
    int? projectId,
  }) async {
    return KimaiTimesheetFetchResult(
      entries: reportEntries,
      requests: const [],
    );
  }

  @override
  Future<KimaiTimesheetFetchResult> fetchTimesheetsForReport({
    int? projectId,
    required DateTime begin,
    required DateTime end,
    int? userId,
  }) async {
    return KimaiTimesheetFetchResult(
      entries: reportEntries,
      requests: const [],
    );
  }

  @override
  Future<List<KimaiUserDto>> fetchUsers() async {
    return const [];
  }
}
