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
import '../../payments/data/payments_repository.dart';
import '../../projects/data/projects_repository.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../sync/data/sync_controller.dart';
import '../../sync/data/sync_repository.dart';
import '../../timesheets/data/timesheets_repository.dart';
import '../../updates/data/update_controller.dart';
import '../../updates/data/update_repository.dart';
import '../../updates/data/update_service.dart';
import '../data/app_settings.dart';
import '../data/settings_repository.dart';

final kimaiTokenExistsProvider = FutureProvider<bool>((ref) async {
  final token = await ref.watch(secureTokenStorageProvider).readKimaiToken();
  return token != null && token.trim().isNotEmpty;
});

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
  final _capacityController = TextEditingController();
  bool _assumePastPayoutsPaid = true;
  bool _autoCheckUpdates = true;
  bool _allowInsecureHttp = false;
  bool _settingsLoaded = false;
  bool _saving = false;
  ConnectionStatus _connectionStatus = const ConnectionStatus.idle();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final tokenExists =
        ref.watch(kimaiTokenExistsProvider).valueOrNull ?? false;
    final latestSyncLog = ref.watch(latestSyncLogProvider);
    final syncState = ref.watch(syncControllerProvider);

    return AppScreen(
      title: 'Настройки',
      subtitle:
          'Подключение Kimai, обновления, безопасность и обслуживание данных.',
      children: [
        settings.when(
          data: (data) {
            _hydrateOnce(data);
            final normalizedPreview = normalizeKimaiBaseUrl(
              _baseUrlController.text,
              allowInsecureHttp: _allowInsecureHttp,
            );

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
                        labelText: 'Адрес Kimai',
                        hintText: 'Например: https://kimai.example.com',
                        helperText: '/api можно не указывать',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) => validateKimaiHostUrl(
                        value ?? '',
                        allowInsecureHttp: _allowInsecureHttp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowInsecureHttp,
                      onChanged: (value) {
                        setState(() => _allowInsecureHttp = value);
                      },
                      title: const Text('Разрешить HTTP без шифрования'),
                      subtitle: const Text(
                        'По умолчанию http:// автоматически заменяется на https://.',
                      ),
                    ),
                    if (normalizedPreview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Будет использоваться: $normalizedPreview',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        labelText: 'API-ключ',
                        hintText: tokenExists
                            ? '••••••••••••••••'
                            : 'Введите API-ключ Kimai',
                        helperText: tokenExists
                            ? 'Ключ сохранён. Поле можно оставить пустым.'
                            : 'Ключ хранится защищённо на устройстве.',
                      ),
                      obscureText: true,
                      validator: (value) {
                        final token = value?.trim() ?? '';
                        if (token.isEmpty && !tokenExists) {
                          return 'Введите API-ключ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _tokenController.clear();
                            FocusScope.of(context).requestFocus(FocusNode());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Введите новый API-ключ в поле выше'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.key_rounded, size: 18),
                          label: const Text('Заменить ключ'),
                        ),
                        OutlinedButton.icon(
                          onPressed: tokenExists ? _deleteToken : null,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Удалить ключ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Комфортная загрузка в неделю',
                        suffixText: 'ч',
                        helperText:
                            'Используется для оценки свободной рабочей мощности.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _assumePastPayoutsPaid,
                      onChanged: (value) {
                        setState(() => _assumePastPayoutsPaid = value);
                      },
                      title: const Text(
                        'Считать прошлые выплаты предположительно оплаченными',
                      ),
                      subtitle: const Text(
                        'Старые выплаты не будут мешать в списке ожидаемых действий.',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _autoCheckUpdates,
                      onChanged: (value) {
                        setState(() => _autoCheckUpdates = value);
                      },
                      title: const Text('Проверять обновления автоматически'),
                      subtitle: const Text(
                        'Приложение проверяет новую версию не чаще одного раза в день.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _saving ? null : () => _save(),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(_saving ? 'Сохранение' : 'Сохранить'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _connectKimai,
                          icon: const Icon(
                            Icons.wifi_tethering_rounded,
                            size: 18,
                          ),
                          label: const Text('Подключить'),
                        ),
                        OutlinedButton.icon(
                          onPressed: syncState.isSyncing
                              ? null
                              : _runFullTimesheetSync,
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: Text(
                            syncState.isSyncing
                                ? 'Синхронизация'
                                : 'Синхронизировать год',
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
            title: 'Настройки недоступны',
            message: error.toString(),
          ),
        ),
        ConnectionStatusBlock(status: _connectionStatus),
        const UpdateStatusBlock(),
        SyncProgressBlock(syncState: syncState),
        const FinancialMaintenancePanel(),
        const DataSafetyPanel(),
        latestSyncLog.when(
          data: (log) => LastSyncStatusBlock(
            log: log,
            lastFullSyncAt: syncState.lastFullSyncAt,
            lastIncrementalSyncAt: syncState.lastIncrementalSyncAt,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Статус синхронизации недоступен',
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
    _capacityController.text =
        settings.comfortableWeeklyCapacityHours.toStringAsFixed(0);
    _assumePastPayoutsPaid = settings.assumePastPayoutsPaid;
    _autoCheckUpdates = settings.autoCheckUpdates;
    _allowInsecureHttp = settings.allowInsecureKimaiHttp;
    _settingsLoaded = true;
  }

  Future<bool> _save({bool showFeedback = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    setState(() => _saving = true);
    try {
      final currentSettings =
          await ref.read(settingsRepositoryProvider).loadSettings();
      final capacity = double.tryParse(
            _capacityController.text.trim().replaceAll(',', '.'),
          ) ??
          currentSettings.comfortableWeeklyCapacityHours;
      final normalizedBaseUrl = normalizeKimaiBaseUrl(
        _baseUrlController.text,
        allowInsecureHttp: _allowInsecureHttp,
      );
      final settings = AppSettings(
        baseUrl: normalizedBaseUrl,
        currency: 'RUB',
        locale: 'ru_RU',
        comfortableWeeklyCapacityHours: capacity,
        assumePastPayoutsPaid: _assumePastPayoutsPaid,
        autoCheckUpdates: _autoCheckUpdates,
        includePrereleaseUpdates: currentSettings.includePrereleaseUpdates,
        lastUpdateCheckAt: currentSettings.lastUpdateCheckAt,
        allowInsecureKimaiHttp: _allowInsecureHttp,
      );

      await ref.read(settingsRepositoryProvider).saveSettings(settings);

      final token = _tokenController.text.trim();
      if (token.isNotEmpty) {
        await ref.read(secureTokenStorageProvider).saveKimaiToken(token);
        _tokenController.clear();
      }

      _baseUrlController.text = normalizedBaseUrl;
      ref
        ..invalidate(appSettingsProvider)
        ..invalidate(kimaiApiClientProvider)
        ..invalidate(kimaiTokenExistsProvider);

      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены')),
        );
      }

      return true;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteToken() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить API-ключ?'),
        content: const Text(
          'Подключение к Kimai перестанет работать до ввода нового ключа.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(secureTokenStorageProvider).deleteKimaiToken();
    _tokenController.clear();
    ref
      ..invalidate(kimaiTokenExistsProvider)
      ..invalidate(kimaiApiClientProvider);
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
            'Подключено. Импортировано проектов: ${result.importedProjects}.',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Импортировано проектов: ${result.importedProjects}'),
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
      return 'Подключение выполнено, но Kimai не вернул проекты.';
    }

    if (error is KimaiApiException) {
      return _connectionErrorMessage(error.source);
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'API-ключ Kimai не принят.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Kimai недоступен. Проверьте адрес и подключение.';
      }

      if (statusCode != null) {
        return 'Kimai вернул HTTP $statusCode.';
      }
    }

    return 'Не удалось подключиться: $error';
  }

  Future<void> _runFullTimesheetSync() async {
    try {
      await ref.read(syncControllerProvider.notifier).runFullSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Синхронизация за год завершена')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $error')),
        );
      }
    }
  }
}

class FinancialMaintenancePanel extends ConsumerWidget {
  const FinancialMaintenancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(financialDiagnosticsProvider);

    return diagnostics.when(
      data: (data) => AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Финансовая целостность',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Активных проектов: ${data.enabledProjectsCount}. '
              'Без ставки: ${data.enabledProjectsWithZeroRate}. '
              'Записей с часами без суммы: ${data.zeroAmountTimesheetsCount}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: data.zeroAmountTimesheetsCount == 0
                      ? null
                      : () => _repairAmounts(context, ref),
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: const Text('Пересчитать суммы'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyFinancialDiagnostics(context, data),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Скопировать финансовую диагностику'),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => EmptyState(
        title: 'Финансовая диагностика недоступна',
        message: error.toString(),
      ),
    );
  }

  Future<void> _repairAmounts(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пересчитать суммы?'),
        content: const Text(
          'Будут обновлены только записи с длительностью больше нуля и пустой суммой. '
          'Длительность и данные Kimai не изменятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Пересчитать'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final summary = await ref
        .read(timesheetsRepositoryProvider)
        .repairZeroAmountTimesheets();
    ref
      ..invalidate(financialDiagnosticsProvider)
      ..invalidate(currentWeekSummaryProvider)
      ..invalidate(projectWeekSummariesProvider)
      ..invalidate(weeklyProgressHistoryProvider)
      ..invalidate(paymentsSnapshotProvider)
      ..invalidate(latestSyncLogProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пересчитано записей: ${summary.rowsFixed}'),
        ),
      );
    }
  }

  Future<void> _copyFinancialDiagnostics(
    BuildContext context,
    FinancialDiagnostics data,
  ) async {
    await Clipboard.setData(ClipboardData(text: data.toReport()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Финансовая диагностика скопирована')),
      );
    }
  }
}

class UpdateStatusBlock extends ConsumerWidget {
  const UpdateStatusBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final result = state.result;
    final updateAvailable = result?.hasUpdate ?? false;
    final nativeUpdatesSupported =
        result?.installMode == UpdateInstallMode.native;
    final actionLabel = nativeUpdatesSupported
        ? 'Обновить'
        : result?.platformLabel == 'Android'
            ? 'Скачать APK'
            : result?.selectedAsset == null
                ? 'Открыть релиз'
                : 'Скачать установщик';
    final statusText = state.isChecking
        ? 'Проверяем обновления...'
        : state.lastError != null
            ? 'Ошибка проверки обновлений'
            : updateAvailable
                ? 'Доступна версия ${result!.metadata.version}'
                : result == null
                    ? 'Проверка ещё не выполнялась'
                    : 'Обновлений нет';

    return AppPanel(
      child: Row(
        children: [
          Icon(
            updateAvailable
                ? Icons.system_update_alt_rounded
                : Icons.verified_rounded,
            color: updateAvailable ? AppColors.warning : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Обновления',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                packageInfo.when(
                  data: (info) => Text(
                    'Текущая версия: ${info.version}+${info.buildNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => Text(
                    'Текущая версия недоступна',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(statusText, style: Theme.of(context).textTheme.bodyMedium),
                if (state.lastError != null) ...[
                  const SizedBox(height: 6),
                  SelectableText(
                    state.lastError!,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed:
                    state.isChecking ? null : () => controller.checkNow(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Проверить'),
              ),
              if (updateAvailable)
                FilledButton.icon(
                  onPressed: nativeUpdatesSupported
                      ? () => controller.installLatestUpdate()
                      : () => controller.installLatestUpdate(),
                  icon: Icon(
                    nativeUpdatesSupported
                        ? Icons.download_rounded
                        : Icons.open_in_new_rounded,
                    size: 18,
                  ),
                  label: Text(
                    actionLabel,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
          Text(
            'Ход синхронизации',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (syncState.isSyncing) ...[
            LinearProgressIndicator(
              value: total <= 0 ? null : completed / total,
            ),
            const SizedBox(height: 8),
            Text(
              '${syncState.currentProject ?? 'Подготовка'} · $completed/$total проектов',
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
                    const SnackBar(content: Text('Ошибка скопирована')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Скопировать ошибку'),
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
          Text(
            'Безопасность данных',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          OutlinedButton.icon(
            onPressed: () => _exportBackup(context, ref),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Экспорт настроек JSON'),
          ),
          OutlinedButton.icon(
            onPressed: () => _importBackup(context, ref),
            icon: const Icon(Icons.file_download_rounded, size: 18),
            label: const Text('Импорт настроек JSON'),
          ),
          OutlinedButton.icon(
            onPressed: () => _clearSettings(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Очистить настройки и ключ'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final backup =
        await ref.read(settingsRepositoryProvider).exportSettingsBackup();
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(backup)),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Резервная копия настроек скопирована')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final jsonText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт настроек'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'JSON'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Импортировать'),
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
      throw const FormatException(
        'Резервная копия должна быть JSON-объектом.',
      );
    }
    await ref.read(settingsRepositoryProvider).importSettingsBackup(decoded);
    ref.invalidate(appSettingsProvider);
    ref.invalidate(kimaiApiClientProvider);
  }

  Future<void> _clearSettings(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить настройки?'),
        content: const Text(
          'Адрес Kimai, состояние onboarding и API-ключ будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(settingsRepositoryProvider).clearLocalSettings();
    await ref.read(secureTokenStorageProvider).deleteKimaiToken();
    ref
      ..invalidate(appSettingsProvider)
      ..invalidate(kimaiApiClientProvider)
      ..invalidate(kimaiTokenExistsProvider);
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
          label: 'Не подключено',
          message: 'Сохраните адрес Kimai и API-ключ, затем подключитесь.',
          color: AppColors.textMuted,
          icon: Icons.radio_button_unchecked_rounded,
        );

  const ConnectionStatus.connecting()
      : this._(
          label: 'Подключение',
          message: 'Проверяем Kimai и импортируем проекты.',
          color: AppColors.warning,
          icon: Icons.sync_rounded,
        );

  const ConnectionStatus.success(String message)
      : this._(
          label: 'Подключено',
          message: message,
          color: AppColors.accent,
          icon: Icons.check_circle_rounded,
        );

  const ConnectionStatus.failure(String message)
      : this._(
          label: 'Ошибка подключения',
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
        title: 'Истории синхронизаций пока нет',
        message: 'Статус появится после первого подключения Kimai.',
      );
    }

    final finishedAt = log!.finishedAt;
    final message = finishedAt == null
        ? '${log!.status}: ${log!.message ?? 'Выполняется'}'
        : '${log!.status}: ${log!.message ?? 'Без деталей'}';

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
                  'Последняя синхронизация',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  'Полная: ${_formatSyncDate(lastFullSyncAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Последние 7 дней: ${_formatSyncDate(lastIncrementalSyncAt)}',
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
      return 'Никогда';
    }

    return '${DateTimeFormats.date.format(value)} ${DateTimeFormats.time.format(value)}';
  }
}

final financialDiagnosticsProvider =
    FutureProvider<FinancialDiagnostics>((ref) {
  return ref.watch(timesheetsRepositoryProvider).getFinancialDiagnostics();
});
