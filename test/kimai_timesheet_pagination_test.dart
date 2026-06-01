import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';

void main() {
  group('fetchKimaiTimesheetPages', () {
    test('fetches a single page when result is smaller than default page size',
        () async {
      final calls = <Map<String, Object>>[];

      final result = await fetchKimaiTimesheetPages(
        begin: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
        requestPage: (query) async {
          calls.add(query);

          return _response(_entries(3));
        },
      );

      expect(result.entries, hasLength(3));
      expect(calls, hasLength(1));
      expect(calls.single.containsKey('page'), isFalse);
    });

    test('fetches multiple pages when pagination headers are present',
        () async {
      final calls = <Map<String, Object>>[];

      final result = await fetchKimaiTimesheetPages(
        begin: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
        requestPage: (query) async {
          calls.add(query);
          final page = query['page'] as int? ?? 1;

          return _response(
            _entries(2, offset: (page - 1) * 2),
            headers: {'x-page': '$page', 'x-total-pages': '3'},
          );
        },
      );

      expect(result.entries, hasLength(6));
      expect(calls.map((call) => call['page']), [null, 2, 3]);
      expect(result.requests, hasLength(3));
    });

    test('stops on empty first page', () async {
      var calls = 0;

      final result = await fetchKimaiTimesheetPages(
        begin: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
        requestPage: (_) async {
          calls += 1;

          return _response([]);
        },
      );

      expect(result.entries, isEmpty);
      expect(calls, 1);
    });

    test('stops when final probed page is smaller than default page size',
        () async {
      final calls = <Map<String, Object>>[];

      final result = await fetchKimaiTimesheetPages(
        begin: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
        requestPage: (query) async {
          calls.add(query);
          final page = query['page'] as int? ?? 1;

          return _response(
            page == 1
                ? _entries(kimaiDefaultPageSize)
                : _entries(3, offset: 50),
          );
        },
      );

      expect(result.entries, hasLength(53));
      expect(calls.map((call) => call['page']), [null, 2]);
    });

    test('reads map responses with data, items and results keys', () async {
      expect(
        readTimesheetPage(_response({'data': _entries(1)})).entries,
        hasLength(1),
      );
      expect(
        readTimesheetPage(_response({'items': _entries(2)})).entries,
        hasLength(2),
      );
      expect(
        readTimesheetPage(_response({'results': _entries(3)})).entries,
        hasLength(3),
      );
    });

    test('uses totalPages and currentPage fields from map responses', () async {
      final calls = <Map<String, Object>>[];

      final result = await fetchKimaiTimesheetPages(
        begin: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31, 23, 59, 59),
        requestPage: (query) async {
          calls.add(query);
          final page = query['page'] as int? ?? 1;

          return _response({
            'data': _entries(1, offset: page - 1),
            'currentPage': page,
            'totalPages': 2,
          });
        },
      );

      expect(result.entries, hasLength(2));
      expect(calls.map((call) => call['page']), [null, 2]);
    });

    test('includes project and user filters for report requests', () async {
      final query = buildTimesheetQueryParams(
        begin: DateTime(2026, 1),
        end: DateTime(2026, 2),
        projectId: 42,
        userId: 7,
        page: 3,
      );

      expect(query['project'], 42);
      expect(query['user'], 7);
      expect(query['page'], 3);
    });

    test('parses user, project and money fields from timesheet', () {
      final page = readTimesheetPage(
        _response([
          {
            'id': 1,
            'begin': '2026-01-01T09:00:00+0000',
            'end': '2026-01-01T10:00:00+0000',
            'duration': 3600,
            'rate': 1500,
            'hourlyRate': 1500,
            'project': {'id': 42, 'name': 'Client project'},
            'activity': {'id': 5, 'name': 'Development'},
            'user': {
              'id': 7,
              'username': 'pm.user',
              'alias': 'PM User',
              'title': 'Project manager',
            },
          },
        ]),
      );

      final entry = page.entries.single;

      expect(entry.projectId, 42);
      expect(entry.projectName, 'Client project');
      expect(entry.userId, 7);
      expect(entry.userName, 'pm.user');
      expect(entry.userAlias, 'PM User');
      expect(entry.userTitle, 'Project manager');
      expect(entry.activityName, 'Development');
      expect(entry.rate, 1500);
      expect(entry.hourlyRate, 1500);
    });
  });

  group('KimaiCurrentUserDto', () {
    test('detects admin reporting capability from roles', () {
      final user = KimaiCurrentUserDto.fromJson({
        'id': 1,
        'username': 'admin',
        'roles': ['ROLE_USER', 'ROLE_ADMIN'],
      });

      expect(user.displayName, 'admin');
      expect(user.hasAdminReportingCapability, isTrue);
    });
  });

  group('buildFullYearSyncRange', () {
    test('uses start of day 365 days ago and end of current local day', () {
      final range = buildFullYearSyncRange(DateTime(2026, 5, 30, 2, 22, 37));

      expect(formatKimaiDateTime(range.begin), '2025-05-30T00:00:00');
      expect(formatKimaiDateTime(range.end), '2026-05-30T23:59:59');
    });
  });
}

Response<Object?> _response(
  Object? data, {
  Map<String, String> headers = const {},
}) {
  return Response<Object?>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/api/timesheets'),
    headers: Headers.fromMap({
      for (final entry in headers.entries) entry.key: [entry.value],
    }),
  );
}

List<Map<String, Object?>> _entries(int count, {int offset = 0}) {
  return [
    for (var index = 0; index < count; index++)
      {
        'id': offset + index + 1,
        'begin': '2026-01-01T00:00:00+0000',
        'duration': 3600,
      },
  ];
}
