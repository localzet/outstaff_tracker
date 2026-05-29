import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_screen.dart';
import '../../timesheets/data/timesheets_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const routePath = '/analytics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheets = ref.watch(currentMonthTimesheetsProvider);

    return AppScreen(
      title: 'Analytics',
      subtitle: 'Time distribution for the current month.',
      children: [
        timesheets.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No analytics yet',
                message: 'Charts use local SQLite timesheets after sync.',
              );
            }

            final dayTotals = <int, double>{};
            for (final item in items) {
              dayTotals[item.beginAt.day] = (dayTotals[item.beginAt.day] ?? 0) +
                  item.durationSeconds / 3600;
            }

            final spots = dayTotals.entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                .toList()
              ..sort((a, b) => a.x.compareTo(b.x));

            return AppPanel(
              child: SizedBox(
                height: 320,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: _gridLine,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppColors.border),
                    ),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: AppColors.accent,
                        barWidth: 2,
                        isCurved: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Analytics are unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }
}

FlLine _gridLine(double value) {
  return const FlLine(color: AppColors.border, strokeWidth: 1);
}
