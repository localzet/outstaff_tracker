import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_database.dart';
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
      subtitle: 'Состояние приложения и история синхронизаций для поддержки.',
      children: [
        diagnostics.when(
          data: (data) => AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: 'Версия приложения', value: data.appVersion),
                _Row(label: 'Версия данных', value: data.schemaVersion),
                _Row(label: 'Адрес Kimai', value: data.baseUrl),
                _Row(
                  label: 'Включённые проекты',
                  value: data.enabledProjects.toString(),
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
                            '${log.startedAt.toLocal()} - ${log.operation} - ${log.status} - ${log.message ?? ''}',
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
                    if (data.lastError != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: data.lastError!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Last error copied'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Скопировать последнюю ошибку'),
                      ),
                    if (data.lastSyncDebugReport != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: data.lastSyncDebugReport!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Last sync debug copied'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Скопировать отчёт синхронизации'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: data.report),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diagnostic report copied'),
                            ),
                          );
                        }
                      },
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
}

class _DiagnosticsData {
  const _DiagnosticsData({
    required this.appVersion,
    required this.schemaVersion,
    required this.baseUrl,
    required this.enabledProjects,
    required this.logs,
  });

  final String appVersion;
  final String schemaVersion;
  final String baseUrl;
  final int enabledProjects;
  final List<SyncLog> logs;

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
      'data_version=$schemaVersion',
      'kimai_base_url=$baseUrl',
      'enabled_projects=$enabledProjects',
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
            width: 160,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
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
            onPressed: nativeUpdatesSupported
                ? () => controller.installLatestUpdate()
                : () => launchUrl(
                      Uri.parse(result!.metadata.releaseNotesUrl),
                      mode: LaunchMode.externalApplication,
                    ),
            icon: Icon(
              nativeUpdatesSupported
                  ? Icons.download_rounded
                  : Icons.open_in_new_rounded,
              size: 18,
            ),
            label: Text(
              nativeUpdatesSupported ? 'Обновить' : 'Открыть релиз',
            ),
          ),
      ],
    );
  }
}

final _diagnosticsProvider = FutureProvider<_DiagnosticsData>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final settings = await ref.watch(settingsRepositoryProvider).loadSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  final enabledProjects = await (database.select(database.appProjects)
        ..where((table) => table.enabled.equals(true)))
      .get();
  final logs = await (database.select(database.syncLogs)
        ..orderBy([(table) => OrderingTerm.desc(table.startedAt)])
        ..limit(10))
      .get();

  return _DiagnosticsData(
    appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
    schemaVersion: database.schemaVersion.toString(),
    baseUrl: settings.baseUrl.isEmpty ? 'Not configured' : settings.baseUrl,
    enabledProjects: enabledProjects.length,
    logs: logs,
  );
});
