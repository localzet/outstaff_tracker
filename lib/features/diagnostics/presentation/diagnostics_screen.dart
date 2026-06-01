import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/connectivity_diagnostics.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../../updates/data/update_controller.dart';
import '../../updates/data/update_service.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  static const routePath = '/diagnostics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(_diagnosticsProvider);

    return AppScreen(
      title: 'Диагностика',
      subtitle:
          'Состояние приложения, обновлений и синхронизаций для поддержки.',
      children: [
        diagnostics.when(
          data: (data) => AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Версия приложения', value: data.appVersion),
                _Row(label: 'Платформа', value: data.platform),
                _Row(label: 'Канал обновлений', value: data.updateChannel),
                _Row(label: 'Версия данных', value: data.schemaVersion),
                _Row(label: 'Адрес Kimai', value: data.baseUrl),
                _Row(
                  label: 'API-ключ сохранён',
                  value: data.tokenSaved ? 'да' : 'нет',
                ),
                _Row(
                  label: 'Активные проекты',
                  value: data.enabledProjects.toString(),
                ),
                _Row(
                  label: 'Последняя версия',
                  value: data.latestVersion ?? 'не проверялась',
                ),
                _Row(
                  label: 'Файл обновления',
                  value: data.selectedUpdateAsset ?? 'не выбран',
                ),
                _Row(
                  label: 'Источник обновлений',
                  value: data.updateSourceUrl ?? 'не проверялся',
                ),
                _Row(
                  label: 'Статус обновления',
                  value: data.updateEligibilityReason ?? 'не проверялся',
                ),
                const SizedBox(height: 12),
                const DiagnosticsUpdateBlock(),
                const SizedBox(height: 12),
                Text(
                  'Последние синхронизации',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.logs.isEmpty)
                  Text(
                    'Истории синхронизаций пока нет.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  for (final log in data.logs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.startedAt.toLocal()} · ${log.operation} · ${log.status} · ${log.message ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (log.error != null && log.error!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            SelectableText(
                              log.error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.warning),
                            ),
                          ],
                          if (log.debug != null && log.debug!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            SelectableText(
                              log.debug!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _checkConnectivity(context, ref),
                      icon: const Icon(Icons.wifi_find_rounded, size: 18),
                      label: const Text('Проверить подключение'),
                    ),
                    if (data.lastError != null)
                      OutlinedButton.icon(
                        onPressed: () => _copy(context, data.lastError!),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Скопировать последнюю ошибку'),
                      ),
                    if (data.lastSyncDebugReport != null)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _copy(context, data.lastSyncDebugReport!),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Скопировать отчёт синхронизации'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _copy(context, data.report),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Скопировать отчёт диагностики'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Диагностика недоступна',
            message: error.toString(),
          ),
        ),
      ],
    );
  }

  Future<void> _checkConnectivity(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(connectivityDiagnosticsServiceProvider).checkKimai();
    await Clipboard.setData(ClipboardData(text: result.toReport()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.summary)),
      );
    }
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скопировано')),
      );
    }
  }
}

class _DiagnosticsData {
  const _DiagnosticsData({
    required this.appVersion,
    required this.platform,
    required this.updateChannel,
    required this.schemaVersion,
    required this.baseUrl,
    required this.tokenSaved,
    required this.enabledProjects,
    required this.logs,
    this.latestVersion,
    this.selectedUpdateAsset,
    this.updateSourceUrl,
    this.updateEligibilityReason,
  });

  final String appVersion;
  final String platform;
  final String updateChannel;
  final String schemaVersion;
  final String baseUrl;
  final bool tokenSaved;
  final int enabledProjects;
  final List<SyncLog> logs;
  final String? latestVersion;
  final String? selectedUpdateAsset;
  final String? updateSourceUrl;
  final String? updateEligibilityReason;

  String? get lastError {
    for (final log in logs) {
      final error = log.error;
      if (error != null && error.isNotEmpty) {
        return error;
      }
    }

    return null;
  }

  String? get lastSyncDebugReport {
    for (final log in logs) {
      final debug = log.debug;
      if (debug != null && debug.isNotEmpty) {
        return debug;
      }
    }

    return null;
  }

  String get report {
    return [
      'Outstaff Tracker diagnostics',
      'app_version=$appVersion',
      'platform=$platform',
      'update_channel=$updateChannel',
      'data_version=$schemaVersion',
      'kimai_base_url=$baseUrl',
      'token_saved=$tokenSaved',
      'enabled_projects=$enabledProjects',
      if (latestVersion != null) 'latest_version=$latestVersion',
      if (selectedUpdateAsset != null) 'selected_asset=$selectedUpdateAsset',
      if (updateSourceUrl != null) 'update_source_url=$updateSourceUrl',
      if (updateEligibilityReason != null)
        'update_eligibility=$updateEligibilityReason',
      for (final log in logs) ...[
        'sync_log=${log.startedAt.toIso8601String()} ${log.operation} ${log.status} ${log.message ?? ''}',
        if (log.error != null && log.error!.isNotEmpty) ...[
          'sync_error_start',
          log.error!,
          'sync_error_end',
        ],
        if (log.debug != null && log.debug!.isNotEmpty) ...[
          'sync_debug_start',
          log.debug!,
          'sync_debug_end',
        ],
      ],
    ].join('\n');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class DiagnosticsUpdateBlock extends ConsumerWidget {
  const DiagnosticsUpdateBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final result = state.result;
    final nativeUpdatesSupported =
        result?.installMode == UpdateInstallMode.native;
    final text = state.isChecking
        ? 'Проверяем обновления...'
        : state.lastError != null
            ? 'Ошибка проверки обновлений: ${state.lastError}'
            : (result?.hasUpdate ?? false)
                ? 'Доступна версия ${result!.metadata.version}'
                : result == null
                    ? 'Проверка обновлений ещё не выполнялась'
                    : 'Обновлений нет';
    final actionLabel = nativeUpdatesSupported == true
        ? 'Обновить'
        : result?.platformLabel == 'Android'
            ? 'Скачать APK'
            : result?.selectedAsset == null
                ? 'Открыть релиз'
                : 'Скачать установщик';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        OutlinedButton.icon(
          onPressed: state.isChecking ? null : () => controller.checkNow(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Проверить обновления'),
        ),
        if (result?.hasUpdate ?? false)
          FilledButton.icon(
            onPressed: () => controller.installLatestUpdate(),
            icon: Icon(
              nativeUpdatesSupported == true
                  ? Icons.download_rounded
                  : Icons.open_in_new_rounded,
              size: 18,
            ),
            label: Text(actionLabel),
          ),
      ],
    );
  }
}

final _diagnosticsProvider = FutureProvider<_DiagnosticsData>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final settings = await ref.watch(settingsRepositoryProvider).loadSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  final token = await ref.watch(secureTokenStorageProvider).readKimaiToken();
  final updateState = ref.watch(updateControllerProvider);
  final enabledProjects = await (database.select(database.appProjects)
        ..where((table) => table.enabled.equals(true)))
      .get();
  final logs = await (database.select(database.syncLogs)
        ..orderBy([(table) => OrderingTerm.desc(table.startedAt)])
        ..limit(10))
      .get();
  final result = updateState.result;

  return _DiagnosticsData(
    appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
    platform: result?.platformLabel ?? updatePlatformLabel(),
    updateChannel: 'stable',
    schemaVersion: database.schemaVersion.toString(),
    baseUrl: settings.baseUrl.isEmpty ? 'не настроен' : settings.baseUrl,
    tokenSaved: token != null && token.trim().isNotEmpty,
    enabledProjects: enabledProjects.length,
    logs: logs,
    latestVersion: result?.metadata.version,
    selectedUpdateAsset: result?.selectedAsset?.name,
    updateSourceUrl: result?.updateSourceUrl,
    updateEligibilityReason: result?.eligibilityReason,
  );
});
