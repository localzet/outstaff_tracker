import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'native_update_runner.dart';
import 'update_metadata.dart';

enum UpdateInstallMode {
  native,
  browser,
}

abstract interface class UpdateService {
  UpdateInstallMode get installMode;

  String get sourceUrl;

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
  String get sourceUrl => latestJsonUrl;

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
  String get sourceUrl => latestReleaseUrl;

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
    final asset = updateAssetForPlatform(metadata);
    final assetUrl = asset == null ? null : Uri.parse(asset.url);
    final releaseUrl = Uri.parse(metadata.releaseNotesUrl);
    final openedAsset = assetUrl != null &&
        await launchUrl(assetUrl, mode: LaunchMode.externalApplication);
    if (!openedAsset) {
      await launchUrl(releaseUrl, mode: LaunchMode.externalApplication);
    }
  }
}

ReleaseAsset? updateAssetForPlatform(UpdateMetadata metadata) {
  if (kIsWeb) {
    return null;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => metadata.windowsInstaller,
    TargetPlatform.android => metadata.androidApk,
    _ => null,
  };
}

String updatePlatformLabel() {
  if (kIsWeb) {
    return 'Web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}
