import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../sync/data/sync_controller.dart';
import '../../timesheets/data/timesheets_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentWeekSummaryProvider);
    final projectSummaries = ref.watch(projectWeekSummariesProvider);
    final payoutForecasts = ref.watch(payoutForecastsProvider);
    final syncState = ref.watch(syncControllerProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: 'RUB');

    return AppScreen(
      title: 'Dashboard',
      subtitle: 'Current week overview from local SQLite data.',
      actions: [
        FilledButton.icon(
          onPressed: syncState.isSyncing ? null : () => _syncNow(ref, context),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: Text(syncState.isSyncing ? 'Syncing' : 'Sync now'),
        ),
      ],
      children: [
        if (syncState.lastError != null)
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last sync error',
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
                        const SnackBar(content: Text('Last error copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy last error'),
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
                  label: 'Week hours',
                  value: formatDurationMinutes(data.totalSeconds ~/ 60),
                  icon: Icons.timer_rounded,
                ),
                MetricTile(
                  label: 'Estimated income',
                  value: currencyFormat.format(data.amountMinor / 100),
                  icon: Icons.payments_rounded,
                ),
                MetricTile(
                  label: 'Entries',
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
            title: 'Dashboard is unavailable',
            message: error.toString(),
          ),
        ),
        projectSummaries.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No enabled projects',
                message: 'Enable projects and set rates to populate progress.',
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
                        child: ProjectProgressCard(
                          summary: item,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                  ],
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Project progress is unavailable',
            message: error.toString(),
          ),
        ),
        payoutForecasts.when(
          data: (forecasts) {
            if (forecasts.isEmpty) {
              return const EmptyState(
                title: 'No payout rule configured',
                message:
                    'Configure a payout rule in Projects to see estimates.',
              );
            }

            return PayoutForecastCards(
              forecasts: forecasts,
              currencyFormat: currencyFormat,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Payout estimate is unavailable',
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
                  'Kimai token is stored in secure storage. Analytics are computed from the local database.',
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
          const SnackBar(content: Text('Sync completed')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $error')),
        );
      }
    }
  }
}

class ProjectProgressCard extends StatelessWidget {
  const ProjectProgressCard({
    required this.summary,
    required this.currencyFormat,
    super.key,
  });

  final ProjectWeekSummary summary;
  final NumberFormat currencyFormat;

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
            '${summary.hours.toStringAsFixed(1)}h / ${goal?.toStringAsFixed(1) ?? '0'}h · ${summary.progressPercent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(summary.amountMinor / 100),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
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
}

class PayoutForecastCards extends StatelessWidget {
  const PayoutForecastCards({
    required this.forecasts,
    required this.currencyFormat,
    super.key,
  });

  final List<PayoutForecast> forecasts;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 760
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final forecast in forecasts.take(4))
              SizedBox(
                width: width,
                child: AppPanel(
                  child: Row(
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
                              forecast.projectName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateTimeFormats.date.format(forecast.nextPayoutDate)} · ${forecast.rule}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(
                          forecast.unpaidAmountMinor / 100,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
