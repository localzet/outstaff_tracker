import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/utils/semantic_version.dart';
import 'package:outstaff_tracker/features/updates/data/update_metadata.dart';

void main() {
  group('SemanticVersion', () {
    test('compares numeric segments correctly', () {
      expect(
        SemanticVersion.parse('0.1.9')
            .compareTo(SemanticVersion.parse('0.1.10')),
        isNegative,
      );
    });

    test('ignores leading v and build metadata', () {
      expect(
        SemanticVersion.parse('v0.1.0+1')
            .compareTo(SemanticVersion.parse('0.1.0+2')),
        0,
      );
    });
  });

  group('UpdateMetadata', () {
    test('parses latest.json metadata', () {
      final metadata = UpdateMetadata.fromJson({
        'tag': 'v1.0.2',
        'version': '1.0.2',
        'pubspecVersion': '0.1.0+1',
        'publishedAt': '2026-06-01T00:00:00Z',
        'prerelease': false,
        'releaseNotesUrl':
            'https://github.com/localzet/outstaff_tracker/releases/tag/v1.0.2',
        'assets': {
          'windowsInstaller': {
            'name': 'outstaff_tracker-setup-1.0.2.exe',
            'url':
                'https://github.com/localzet/outstaff_tracker/releases/download/v1.0.2/outstaff_tracker-setup-1.0.2.exe',
            'sha256': 'abc123',
            'size': 42,
          },
          'androidApk': {
            'name': 'outstaff_tracker-android-1.0.2.apk',
            'url':
                'https://github.com/localzet/outstaff_tracker/releases/download/v1.0.2/outstaff_tracker-android-1.0.2.apk',
            'sha256': 'def456',
            'size': 84,
          },
        },
      });

      expect(metadata.version, '1.0.2');
      expect(
        metadata.windowsInstaller.name,
        'outstaff_tracker-setup-1.0.2.exe',
      );
      expect(metadata.windowsInstaller.sha256, 'abc123');
      expect(metadata.androidApk?.name, 'outstaff_tracker-android-1.0.2.apk');
    });

    test('chooses installer asset and ignores portable zip', () {
      final asset = chooseWindowsInstallerAsset(const [
        ReleaseAsset(
          name: 'outstaff_tracker-windows-portable-1.0.2.zip',
          url: 'https://example.com/portable.zip',
        ),
        ReleaseAsset(
          name: 'outstaff_tracker-setup-1.0.2.exe',
          url: 'https://example.com/setup.exe',
        ),
      ]);

      expect(asset.name, 'outstaff_tracker-setup-1.0.2.exe');
    });

    test('parses GitHub Releases API response', () {
      final metadata = UpdateMetadata.fromGitHubReleaseJson({
        'tag_name': 'v1.0.3',
        'html_url':
            'https://github.com/localzet/outstaff_tracker/releases/tag/v1.0.3',
        'published_at': '2026-06-01T10:00:00Z',
        'prerelease': false,
        'assets': [
          {
            'name': 'outstaff_tracker-windows-portable-1.0.3.zip',
            'browser_download_url': 'https://example.com/portable.zip',
          },
          {
            'name': 'outstaff_tracker-setup-1.0.3.exe',
            'browser_download_url': 'https://example.com/setup.exe',
            'size': 100,
          },
          {
            'name': 'outstaff_tracker-android-1.0.3.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 200,
          },
        ],
      });

      expect(metadata.version, '1.0.3');
      expect(metadata.prerelease, isFalse);
      expect(metadata.windowsInstaller.url, 'https://example.com/setup.exe');
      expect(metadata.androidApk?.url, 'https://example.com/app.apk');
    });

    test('chooses Android APK and ignores app bundle', () {
      final asset = chooseAndroidApkAssetOrNull(const [
        ReleaseAsset(
          name: 'outstaff_tracker-android-1.0.2.aab',
          url: 'https://example.com/app.aab',
        ),
        ReleaseAsset(
          name: 'outstaff_tracker-android-1.0.2.apk',
          url: 'https://example.com/app.apk',
        ),
      ]);

      expect(asset?.name, 'outstaff_tracker-android-1.0.2.apk');
    });

    test('marks newer release as available', () {
      final decision = decideUpdate(
        currentVersion: '0.1.9',
        metadata: _metadata(version: '0.1.10'),
        includePrerelease: false,
      );

      expect(decision.status, UpdateDecisionStatus.available);
    });

    test('ignores same or older release', () {
      final same = decideUpdate(
        currentVersion: '0.1.10+1',
        metadata: _metadata(version: '0.1.10'),
        includePrerelease: false,
      );
      final older = decideUpdate(
        currentVersion: '0.1.10',
        metadata: _metadata(version: '0.1.9'),
        includePrerelease: false,
      );

      expect(same.status, UpdateDecisionStatus.current);
      expect(older.status, UpdateDecisionStatus.current);
    });

    test('ignores prerelease by default', () {
      final decision = decideUpdate(
        currentVersion: '0.1.9',
        metadata: _metadata(version: '0.2.0-beta.1', prerelease: true),
        includePrerelease: false,
      );

      expect(decision.status, UpdateDecisionStatus.ignoredPrerelease);
    });
  });
}

UpdateMetadata _metadata({
  required String version,
  bool prerelease = false,
}) {
  return UpdateMetadata(
    tag: 'v$version',
    version: version,
    releaseNotesUrl: 'https://example.com/releases/tag/v$version',
    prerelease: prerelease,
    windowsInstaller: ReleaseAsset(
      name: 'outstaff_tracker-setup-$version.exe',
      url: 'https://example.com/outstaff_tracker-setup-$version.exe',
    ),
  );
}
