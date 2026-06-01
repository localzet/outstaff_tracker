import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/network/kimai_api_client.dart';
import 'package:outstaff_tracker/core/network/kimai_url.dart';

void main() {
  group('normalizeKimaiBaseUrl', () {
    test('prepends https and appends api to host URL', () {
      expect(
        normalizeKimaiBaseUrl('kimai.example.com'),
        'https://kimai.example.com/api',
      );
    });

    test('converts http to https by default', () {
      expect(
        normalizeKimaiBaseUrl('http://kimai.example.com'),
        'https://kimai.example.com/api',
      );
    });

    test('appends api to https host URL', () {
      expect(
        normalizeKimaiBaseUrl('https://kimai.example.com'),
        'https://kimai.example.com/api',
      );
    });

    test('keeps existing api path', () {
      expect(
        normalizeKimaiBaseUrl('https://kimai.example.com/api'),
        'https://kimai.example.com/api',
      );
    });

    test('normalizes trailing slash after api', () {
      expect(
        normalizeKimaiBaseUrl('https://kimai.example.com/api/'),
        'https://kimai.example.com/api',
      );
    });

    test('avoids duplicate api path', () {
      expect(
        normalizeKimaiBaseUrl(' https://kimai.example.com/api/api/ '),
        'https://kimai.example.com/api',
      );
    });

    test('keeps http when insecure mode is explicitly allowed', () {
      expect(
        normalizeKimaiBaseUrl(
          'http://kimai.example.com',
          allowInsecureHttp: true,
        ),
        'http://kimai.example.com/api',
      );
    });
  });

  group('formatKimaiDateTime', () {
    test('formats local date time without milliseconds', () {
      expect(
        formatKimaiDateTime(DateTime(2026, 5, 30, 9, 8, 7, 123)),
        '2026-05-30T09:08:07',
      );
    });
  });

  group('buildTimesheetQueryParams', () {
    test('builds date params without null project or pagination', () {
      final params = buildTimesheetQueryParams(
        begin: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 8, 23, 59, 58),
      );

      expect(params, {
        'begin': '2026-05-01T00:00:00',
        'end': '2026-05-08T23:59:58',
      });
      expect(params.containsKey('project'), isFalse);
      expect(params.containsKey('page'), isFalse);
      expect(params.containsKey('size'), isFalse);
    });

    test('includes integer project id when provided', () {
      final params = buildTimesheetQueryParams(
        begin: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 2),
        projectId: 42,
      );

      expect(params['project'], 42);
    });

    test('includes page only when pagination is explicitly requested', () {
      final params = buildTimesheetQueryParams(
        begin: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 2),
        page: 2,
      );

      expect(params['page'], 2);
      expect(params.containsKey('size'), isFalse);
    });
  });
}
