import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/network/kimai_url.dart';

void main() {
  group('normalizeKimaiBaseUrl', () {
    test('appends api to host URL', () {
      expect(
        normalizeKimaiBaseUrl('http://kimai.geryon.space'),
        'http://kimai.geryon.space/api',
      );
    });

    test('removes trailing slash before appending api', () {
      expect(
        normalizeKimaiBaseUrl('http://kimai.geryon.space/'),
        'http://kimai.geryon.space/api',
      );
    });

    test('keeps existing api path', () {
      expect(
        normalizeKimaiBaseUrl('http://kimai.geryon.space/api'),
        'http://kimai.geryon.space/api',
      );
    });

    test('normalizes trailing slash after api', () {
      expect(
        normalizeKimaiBaseUrl('http://kimai.geryon.space/api/'),
        'http://kimai.geryon.space/api',
      );
    });

    test('avoids duplicate api path', () {
      expect(
        normalizeKimaiBaseUrl(' http://kimai.geryon.space/api/api/ '),
        'http://kimai.geryon.space/api',
      );
    });
  });
}
