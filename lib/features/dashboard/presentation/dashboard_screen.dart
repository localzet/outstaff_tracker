import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../payments/data/payments_repository.dart';
import '../../payments/presentation/payments_screen.dart';
import '../../sync/data/sync_controller.dart';
import '../../timesheets/data/timesheets_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentWeekSummaryProvider);
    final projectSummaries = ref.watch(projectWeekSummariesProvider);
    final payments = ref.watch(paymentsSnapshotProvider);
    final syncState = ref.watch(syncControllerProvider);

    return AppScreen(
      title: 'Обзор',
      subtitle: 'Текущая неделя, доход и ближайшие выплаты.',
      actions: [
        FilledButton.icon(
          onPressed: syncState.isSyncing ? null : () => _syncNow(ref, context),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: Text(syncState.isSyncing ? 'Синхронизация' : 'Обновить'),
        ),
      ],
      children: [
        if (syncState.lastError != null)
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Последняя ошибка синхронизации',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
            ),
          ),
        summary.when(
          data: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final tiles = [
                MetricTile(
                  label: 'Часы за неделю',
                  value: formatDurationSeconds(data.totalSeconds),
                  icon: Icons.timer_rounded,
                ),
                MetricTile(
                  label: 'Доход за неделю',
                  value: formatMoneyRub(data.amountMinor),
                  icon: Icons.payments_rounded,
                ),
                MetricTile(
                  label: 'Записи',
                  value: data.entryCount.toString(),
                  icon: Icons.list_alt_rounded,
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      if (tile != tiles.last) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final tile in tiles) ...[
                    Expanded(child: tile),
                    if (tile != tiles.last) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Обзор недоступен',
            message: error.toString(),
          ),
        ),
        projectSummaries.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Нет активных проектов',
                message: 'Включите проекты и укажите ставки.',
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 760
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: cardWidth,
                        child: ProjectProgressCard(summary: item),
                      ),
                  ],
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Прогресс по проектам недоступен',
            message: error.toString(),
          ),
        ),
        payments.when(
          data: (snapshot) {
            final next = snapshot.nextExpected;
            if (next.isEmpty) {
              return const EmptyState(
                title: 'Нет ожидаемых выплат',
                message: 'Настройте правила выплат в проектах.',
              );
            }

            return NextPaymentsPanel(items: next);
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Выплаты недоступны',
            message: error.toString(),
          ),
        ),
        const AppPanel(
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Токен Kimai хранится защищённо. Данные остаются на этом устройстве.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _syncNow(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(syncControllerProvider.notifier).runManualSync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Синхронизация завершена')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $error')),
        );
      }
    }
  }
}

class ProjectProgressCard extends StatelessWidget {
  const ProjectProgressCard({required this.summary, super.key});

  final ProjectWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final goal = summary.weeklyGoalHours;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _parseColor(summary.color),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.projectName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal == null || goal <= 0
                ? 0
                : (summary.hours / goal).clamp(0, 1).toDouble(),
            backgroundColor: AppColors.surfaceElevated,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          Text(
            '${formatDurationSeconds(summary.totalSeconds)} / ${_formatGoal(goal)} · ${summary.progressPercent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            formatMoneyRub(summary.amountMinor),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  String _formatGoal(double? goal) {
    if (goal == null || goal <= 0) {
      return '0 мин';
    }

    return formatDurationRu(Duration(minutes: (goal * 60).round()));
  }
}

class NextPaymentsPanel extends StatelessWidget {
  const NextPaymentsPanel({required this.items, super.key});

  final List<PaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ближайшие выплаты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.go(PaymentsScreen.routePath),
                child: const Text('Все выплаты'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.projectName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${DateTimeFormats.date.format(item.payoutDate)} · ${DateTimeFormats.date.format(item.periodStart)} - ${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoneyRub(item.expectedAmountMinor),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (item != items.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

Color _parseColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) {
    return AppColors.textMuted;
  }

  final parsed = int.tryParse(value.substring(1), radix: 16);
  if (parsed == null) {
    return AppColors.textMuted;
  }

  return Color(0xFF000000 | parsed);
}
