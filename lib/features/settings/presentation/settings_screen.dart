import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/kimai_api_client.dart';
import '../../../core/network/kimai_url.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../projects/data/projects_repository.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../sync/data/sync_controller.dart';
import '../../sync/data/sync_repository.dart';
import '../data/app_settings.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const routePath = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _currencyController = TextEditingController();
  final _localeController = TextEditingController();

  bool _settingsLoaded = false;
  bool _saving = false;
  ConnectionStatus _connectionStatus = const ConnectionStatus.idle();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    _currencyController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final latestSyncLog = ref.watch(latestSyncLogProvider);
    final syncState = ref.watch(syncControllerProvider);

    return AppScreen(
      title: 'Settings',
      subtitle: 'Kimai connection and local formatting preferences.',
      children: [
        settings.when(
          data: (data) {
            _hydrateOnce(data);

            return AppPanel(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kimai',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'Example: https://kimai.example.com',
                        helperText: 'Do not include /api manually (optional)',
                      ),
                      validator: (value) {
                        return validateKimaiHostUrl(value ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'API token',
                        hintText: 'Stored securely on this device',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Formatting',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              hintText: 'USD',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: TextFormField(
                            controller: _localeController,
                            decoration: const InputDecoration(
                              labelText: 'Locale',
                              hintText: 'en_US',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _saving ? null : () => _save(),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(_saving ? 'Saving' : 'Save'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _connectKimai,
                          icon: const Icon(
                            Icons.wifi_tethering_rounded,
                            size: 18,
                          ),
                          label: const Text('Connect'),
                        ),
                        OutlinedButton.icon(
                          onPressed: syncState.isSyncing
                              ? null
                              : _runFullTimesheetSync,
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: Text(
                            syncState.isSyncing ? 'Syncing' : 'Sync last year',
                          ),
                        ),
                      ],
                    ),
                    if (syncState.lastError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        syncState.lastError!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Settings are unavailable',
            message: error.toString(),
          ),
        ),
        ConnectionStatusBlock(status: _connectionStatus),
        SyncProgressBlock(syncState: syncState),
        const DataSafetyPanel(),
        latestSyncLog.when(
          data: (log) => LastSyncStatusBlock(
            log: log,
            lastFullSyncAt: syncState.lastFullSyncAt,
            lastIncrementalSyncAt: syncState.lastIncrementalSyncAt,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Last sync status is unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }

  void _hydrateOnce(AppSettings settings) {
    if (_settingsLoaded) {
      return;
    }

    _baseUrlController.text = settings.baseUrl;
    _currencyController.text = settings.currency;
    _localeController.text = settings.locale;
    _settingsLoaded = true;
  }

  Future<bool> _save({bool showFeedback = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    setState(() => _saving = true);
    try {
      final settings = AppSettings(
        baseUrl: normalizeKimaiBaseUrl(_baseUrlController.text),
        currency: _currencyController.text.trim().isEmpty
            ? AppSettings.defaults.currency
            : _currencyController.text.trim().toUpperCase(),
        locale: _localeController.text.trim().isEmpty
            ? AppSettings.defaults.locale
            : _localeController.text.trim(),
      );

      await ref.read(settingsRepositoryProvider).saveSettings(settings);

      final token = _tokenController.text.trim();
      if (token.isNotEmpty) {
        await ref.read(secureTokenStorageProvider).saveKimaiToken(token);
        _tokenController.clear();
      }

      ref
        ..invalidate(appSettingsProvider)
        ..invalidate(kimaiApiClientProvider);

      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }

      return true;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _connectKimai() async {
    final saved = await _save(showFeedback: false);
    if (!saved) {
      return;
    }

    setState(() {
      _connectionStatus = const ConnectionStatus.connecting();
    });

    try {
      final result = await ref.read(syncRepositoryProvider).connectKimai();

      ref
        ..invalidate(projectConfigurationsProvider)
        ..invalidate(kimaiProjectsProvider)
        ..invalidate(latestSyncLogProvider);

      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.success(
            'Connected. Imported ${result.importedProjects} projects.',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Projects imported: ${result.importedProjects}'),
          ),
        );
        context.go(ProjectsScreen.routePath);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.failure(
            _connectionErrorMessage(error),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_connectionErrorMessage(error))),
        );
      }
    }
  }

  String _connectionErrorMessage(Object error) {
    if (error is KimaiEmptyProjectsException) {
      return 'Connected, but Kimai returned no projects.';
    }

    if (error is KimaiApiException) {
      return _connectionErrorMessage(error.source);
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'Unauthorized Kimai token.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Kimai is unreachable. Check the URL and network connection.';
      }

      if (statusCode != null) {
        return 'Kimai returned HTTP $statusCode.';
      }
    }

    return 'Connection failed: $error';
  }

  Future<void> _runFullTimesheetSync() async {
    try {
      await ref.read(syncControllerProvider.notifier).runFullSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last year sync completed')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    }
  }
}

class SyncProgressBlock extends StatelessWidget {
  const SyncProgressBlock({required this.syncState, super.key});

  final SyncControllerState syncState;

  @override
  Widget build(BuildContext context) {
    if (!syncState.isSyncing && syncState.lastError == null) {
      return const SizedBox.shrink();
    }

    final total = syncState.totalProjects;
    final completed = syncState.completedProjects;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sync progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (syncState.isSyncing) ...[
            LinearProgressIndicator(
              value: total <= 0 ? null : completed / total,
            ),
            const SizedBox(height: 8),
            Text(
              '${syncState.currentProject ?? 'Preparing'} · $completed/$total projects',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (syncState.lastError != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              syncState.lastError!,
              style: const TextStyle(color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: syncState.lastError!),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Last error copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy last error'),
            ),
          ],
        ],
      ),
    );
  }
}

class DataSafetyPanel extends ConsumerWidget {
  const DataSafetyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPanel(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Data safety', style: Theme.of(context).textTheme.titleMedium),
          OutlinedButton.icon(
            onPressed: () => _exportBackup(context, ref),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Export settings JSON'),
          ),
          OutlinedButton.icon(
            onPressed: () => _importBackup(context, ref),
            icon: const Icon(Icons.file_download_rounded, size: 18),
            label: const Text('Import settings JSON'),
          ),
          OutlinedButton.icon(
            onPressed: () => _clearSettings(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Clear settings/token'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final backup =
        await ref.read(settingsRepositoryProvider).exportSettingsBackup();
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(backup),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings backup copied')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final jsonText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import settings backup'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'JSON'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (jsonText == null || jsonText.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Backup must be a JSON object.');
    }
    await ref.read(settingsRepositoryProvider).importSettingsBackup(decoded);
    ref.invalidate(appSettingsProvider);
    ref.invalidate(kimaiApiClientProvider);
  }

  Future<void> _clearSettings(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local settings?'),
        content: const Text(
          'Kimai URL, onboarding state and API token will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(settingsRepositoryProvider).clearLocalSettings();
    await ref.read(secureTokenStorageProvider).deleteKimaiToken();
    ref.invalidate(appSettingsProvider);
    ref.invalidate(kimaiApiClientProvider);
  }
}

class ConnectionStatus {
  const ConnectionStatus._({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  const ConnectionStatus.idle()
      : this._(
          label: 'Not connected',
          message: 'Save your Kimai URL and token, then connect.',
          color: AppColors.textMuted,
          icon: Icons.radio_button_unchecked_rounded,
        );

  const ConnectionStatus.connecting()
      : this._(
          label: 'Connecting',
          message: 'Checking Kimai and importing projects.',
          color: AppColors.warning,
          icon: Icons.sync_rounded,
        );

  const ConnectionStatus.success(String message)
      : this._(
          label: 'Connected',
          message: message,
          color: AppColors.accent,
          icon: Icons.check_circle_rounded,
        );

  const ConnectionStatus.failure(String message)
      : this._(
          label: 'Connection failed',
          message: message,
          color: AppColors.danger,
          icon: Icons.error_rounded,
        );

  final String label;
  final String message;
  final Color color;
  final IconData icon;
}

class ConnectionStatusBlock extends StatelessWidget {
  const ConnectionStatusBlock({required this.status, super.key});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          Icon(status.icon, color: status.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  status.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LastSyncStatusBlock extends StatelessWidget {
  const LastSyncStatusBlock({
    required this.log,
    required this.lastFullSyncAt,
    required this.lastIncrementalSyncAt,
    super.key,
  });

  final SyncLog? log;
  final DateTime? lastFullSyncAt;
  final DateTime? lastIncrementalSyncAt;

  @override
  Widget build(BuildContext context) {
    if (log == null) {
      return const EmptyState(
        title: 'No sync history',
        message: 'Last sync status will appear after the first Kimai connect.',
      );
    }

    final finishedAt = log!.finishedAt;
    final message = finishedAt == null
        ? '${log!.status}: ${log!.message ?? 'In progress'}'
        : '${log!.status}: ${log!.message ?? 'No details'}';

    return AppPanel(
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  'Full: ${_formatSyncDate(lastFullSyncAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Incremental: ${_formatSyncDate(lastIncrementalSyncAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSyncDate(DateTime? value) {
    if (value == null) {
      return 'Never';
    }

    return '${DateTimeFormats.date.format(value)} ${DateTimeFormats.time.format(value)}';
  }
}
