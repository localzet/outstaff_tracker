import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../sync/data/sync_repository.dart';
import '../../timesheets/data/timesheets_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentMonthSummaryProvider);
    final currencyFormat = NumberFormat.simpleCurrency();

    return AppScreen(
      title: 'Dashboard',
      subtitle: 'Current month overview from local SQLite data.',
      actions: [
        FilledButton.icon(
          onPressed: () => _syncCurrentMonth(ref, context),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: const Text('Sync'),
        ),
      ],
      children: [
        summary.when(
          data: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final tiles = [
                MetricTile(
                  label: 'Tracked time',
                  value: formatDurationMinutes(data.totalSeconds ~/ 60),
                  icon: Icons.timer_rounded,
                ),
                MetricTile(
                  label: 'Billable amount',
                  value: currencyFormat.format(data.billableAmount),
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

  Future<void> _syncCurrentMonth(WidgetRef ref, BuildContext context) async {
    final now = DateTime.now();
    final begin = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    try {
      await ref.read(syncRepositoryProvider).syncRange(begin, end);
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
