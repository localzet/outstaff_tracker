import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import 'native_update_runner.dart';
import 'update_metadata.dart';

enum UpdateInstallMode {
  native,
  browser,
}

abstract interface class UpdateService {
  UpdateInstallMode get installMode;

  Future<UpdateMetadata> fetchLatestMetadata();

  Future<void> startUpdate(UpdateMetadata metadata);
}

class NativeAutoUpdaterService implements UpdateService {
  NativeAutoUpdaterService({
    required Dio dio,
    NativeUpdateRunner? nativeRunner,
  })  : _dio = dio,
        _nativeRunner = nativeRunner ?? const NativeUpdateRunner();

  static const latestJsonUrl = String.fromEnvironment(
    'OUTSTAFF_UPDATE_FEED_URL',
    defaultValue:
        'https://github.com/localzet/outstaff_tracker/releases/latest/download/latest.json',
  );

  static const appcastUrl = String.fromEnvironment(
    'OUTSTAFF_APPCAST_URL',
    defaultValue:
        'https://github.com/localzet/outstaff_tracker/releases/latest/download/appcast.xml',
  );

  final Dio _dio;
  final NativeUpdateRunner _nativeRunner;

  bool get isAvailable => _nativeRunner.isSupported;

  @override
  UpdateInstallMode get installMode => UpdateInstallMode.native;

  @override
  Future<UpdateMetadata> fetchLatestMetadata() async {
    if (!isAvailable) {
      throw UnsupportedError('Native updater is not available.');
    }

    final response = await _dio.getUri<Map<String, Object?>>(
      Uri.parse(latestJsonUrl),
      options: Options(
        headers: const {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Update metadata is empty.');
    }

    return UpdateMetadata.fromJson(data);
  }

  @override
  Future<void> startUpdate(UpdateMetadata metadata) async {
    await _nativeRunner.configure(appcastUrl);
    await _nativeRunner.checkForUpdates();
  }
}

class GitHubReleaseUpdateService implements UpdateService {
  GitHubReleaseUpdateService({required Dio dio}) : _dio = dio;

  static const repository = String.fromEnvironment(
    'OUTSTAFF_GITHUB_REPOSITORY',
    defaultValue: 'localzet/outstaff_tracker',
  );

  static const latestReleaseUrl =
      'https://api.github.com/repos/$repository/releases/latest';

  final Dio _dio;

  @override
  UpdateInstallMode get installMode => UpdateInstallMode.browser;

  @override
  Future<UpdateMetadata> fetchLatestMetadata() async {
    final response = await _dio.getUri<Map<String, Object?>>(
      Uri.parse(latestReleaseUrl),
      options: Options(
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Outstaff Tracker updater',
        },
        responseType: ResponseType.json,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('GitHub release response is empty.');
    }

    return UpdateMetadata.fromGitHubReleaseJson(data);
  }

  @override
  Future<void> startUpdate(UpdateMetadata metadata) async {
    final assetUrl = Uri.parse(metadata.windowsInstaller.url);
    final releaseUrl = Uri.parse(metadata.releaseNotesUrl);
    final openedAsset = await launchUrl(
      assetUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!openedAsset) {
      await launchUrl(releaseUrl, mode: LaunchMode.externalApplication);
    }
  }
}
