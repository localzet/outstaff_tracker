import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../settings/data/settings_repository.dart';
import 'update_metadata.dart';
import 'update_service.dart';

class UpdateRepository {
  UpdateRepository({
    required SettingsRepository settingsRepository,
    Dio? dio,
    NativeAutoUpdaterService? nativeService,
    GitHubReleaseUpdateService? fallbackService,
  }) : _settingsRepository = settingsRepository {
    final client = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
    _nativeService = nativeService ?? NativeAutoUpdaterService(dio: client);
    _fallbackService =
        fallbackService ?? GitHubReleaseUpdateService(dio: client);
  }

  final SettingsRepository _settingsRepository;
  late final NativeAutoUpdaterService _nativeService;
  late final GitHubReleaseUpdateService _fallbackService;

  Future<PackageInfo> getPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  Future<bool> shouldRunAutomaticCheck() async {
    final settings = await _settingsRepository.loadSettings();
    if (!settings.autoCheckUpdates) {
      return false;
    }

    final lastCheckedAt = settings.lastUpdateCheckAt;
    if (lastCheckedAt == null) {
      return true;
    }

    final now = DateTime.now();
    return now.difference(lastCheckedAt.toLocal()) >= const Duration(days: 1);
  }

  Future<UpdateCheckResult> checkForUpdates() async {
    final settings = await _settingsRepository.loadSettings();
    final packageInfo = await getPackageInfo();
    final serviceResult = await _fetchLatestMetadata();
    final metadata = serviceResult.metadata;
    final decision = decideUpdate(
      currentVersion: packageInfo.version,
      metadata: metadata,
      includePrerelease: settings.includePrereleaseUpdates,
    );
    await _settingsRepository.setLastUpdateCheckAt(DateTime.now().toUtc());

    return UpdateCheckResult(
      currentVersion: packageInfo.version,
      metadata: metadata,
      decision: decision,
      service: serviceResult.service,
    );
  }

  Future<_UpdateServiceResult> _fetchLatestMetadata() async {
    if (_nativeService.isAvailable) {
      try {
        return _UpdateServiceResult(
          metadata: await _nativeService.fetchLatestMetadata(),
          service: _nativeService,
        );
      } catch (_) {
        // Fall back to GitHub Releases when appcast metadata is unavailable.
      }
    }

    return _UpdateServiceResult(
      metadata: await _fallbackService.fetchLatestMetadata(),
      service: _fallbackService,
    );
  }

  Future<void> installLatestUpdate(UpdateCheckResult result) async {
    await result.service.startUpdate(result.metadata);
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.metadata,
    required this.decision,
    required this.service,
  });

  final String currentVersion;
  final UpdateMetadata metadata;
  final UpdateDecision decision;
  final UpdateService service;

  bool get hasUpdate => decision.isAvailable;

  UpdateInstallMode get installMode => service.installMode;
}

class _UpdateServiceResult {
  const _UpdateServiceResult({
    required this.metadata,
    required this.service,
  });

  final UpdateMetadata metadata;
  final UpdateService service;
}

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  return UpdateRepository(
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
