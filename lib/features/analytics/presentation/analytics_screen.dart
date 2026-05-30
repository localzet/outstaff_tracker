import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../payments/data/payments_repository.dart';
import '../data/analytics_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const routePath = '/analytics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(analyticsSnapshotProvider);
    final payments = ref.watch(paymentsSnapshotProvider);

    return AppScreen(
      title: 'Аналитика',
      subtitle: 'Загрузка, ритм работы и способность взять новый проект.',
      children: [
        snapshot.when(
          data: (data) {
            final hasData = data.weeklyHours.any((item) => item.value > 0) ||
                data.monthlyIncome.any((item) => item.value > 0) ||
                data.projectDistribution.isNotEmpty;
            if (!hasData) {
              return const EmptyState(
                title: 'Аналитики пока нет',
                message: 'Синхронизируйте записи Kimai, чтобы увидеть отчёты.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  children: [
                    MetricCard(
                      label: 'Средний рабочий день',
                      value: formatDurationSeconds(
                        (data.averageWorkingDay.averageHours * 3600).round(),
                      ),
                      detail:
                          '${data.averageWorkingDay.workingDays} рабочих дней',
                    ),
                    MetricCard(
                      label: 'Лучшая неделя',
                      value: _weekValue(data.bestWeek),
                      detail: data.bestWeek?.label ?? '-',
                    ),
                    MetricCard(
                      label: 'Свободно по мощности',
                      value: data.capacity.freeSeconds >= 0
                          ? formatDurationSeconds(data.capacity.freeSeconds)
                          : '-${formatDurationSeconds(data.capacity.freeSeconds.abs())}',
                      detail:
                          'Средняя загрузка: ${formatDurationSeconds(data.capacity.averageWeekSeconds)} / нед',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalyticsChartPanel(
                  title: 'Тренд 12 недель',
                  child: BarChartWidget(values: data.weeklyHours),
                ),
                const SizedBox(height: 16),
                AnalyticsChartPanel(
                  title: 'Доход по месяцам',
                  child: BarChartWidget(values: data.monthlyIncome),
                ),
                const SizedBox(height: 16),
                ResponsiveGrid(
                  children: [
                    AnalyticsChartPanel(
                      title: 'Распределение по проектам',
                      child: ProjectDistributionChart(
                        items: data.projectDistribution,
                      ),
                    ),
                    GoalCompletionPanel(items: data.goalCompletion),
                  ],
                ),
                const SizedBox(height: 16),
                WorkloadAnalyticsPanel(data: data),
                const SizedBox(height: 16),
                payments.when(
                  data: (snapshot) =>
                      PayoutForecastPanel(items: snapshot.nextExpected),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => EmptyState(
                    title: 'Прогноз выплат недоступен',
                    message: error.toString(),
                  ),
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Аналитика недоступна',
            message: error.toString(),
          ),
        ),
      ],
    );
  }

  String _weekValue(PeriodValue? value) {
    if (value == null) {
      return '-';
    }

    return formatDurationSeconds((value.value * 3600).round());
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({required this.children, super.key});

  final List<Widget> children;

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
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class AnalyticsChartPanel extends StatelessWidget {
  const AnalyticsChartPanel({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(height: 260, child: child),
        ],
      ),
    );
  }
}

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({required this.values, super.key});

  final List<PeriodValue> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );

    return BarChart(
      BarChartData(
        maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 38),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    values[index].label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var index = 0; index < values.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].value,
                  width: 12,
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ProjectDistributionChart extends StatelessWidget {
  const ProjectDistributionChart({required this.items, super.key});

  final List<ProjectDistributionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'Нет данных по проектам',
        message: 'Распределение появится после синхронизации.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final item in items)
                  PieChartSectionData(
                    value: item.totalSeconds.toDouble(),
                    title: '',
                    color: _parseColor(item.color),
                    radius: 72,
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final item in items)
              Text(
                '${item.projectName}: ${formatDurationSeconds(item.totalSeconds)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ],
    );
  }
}

class GoalCompletionPanel extends StatelessWidget {
  const GoalCompletionPanel({required this.items, super.key});

  final List<GoalCompletionStat> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выполнение целей',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'Укажите недельные цели в проектах.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in items) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.projectName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${item.completionRate.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (item.completionRate / 100).clamp(0, 1).toDouble(),
                backgroundColor: AppColors.surfaceElevated,
                color: _parseColor(item.color),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class WorkloadAnalyticsPanel extends StatelessWidget {
  const WorkloadAnalyticsPanel({required this.data, super.key});

  final AnalyticsSnapshot data;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Загрузка и ритм',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Средняя загрузка: '
            '${formatDurationSeconds(data.capacity.averageWeekSeconds)} / нед',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            data.capacity.freeSeconds >= 0
                ? 'Свободно: ${formatDurationSeconds(data.capacity.freeSeconds)} / нед'
                : 'Перегруз: ${formatDurationSeconds(data.capacity.freeSeconds.abs())} / нед',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              _DistributionList(
                title: 'По дням недели',
                items: data.hoursByWeekday,
              ),
              _DistributionList(
                title: 'По часам дня',
                items: data.hoursByHour
                    .where((item) => item.totalSeconds > 0)
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Средние значения по проектам',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in data.projectAverages)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.circle,
                size: 12,
                color: _parseColor(item.color),
              ),
              title: Text(item.projectName),
              subtitle: Text(
                'В день: ${formatDurationSeconds(item.averageDaySeconds)} · '
                'в неделю: ${formatDurationSeconds(item.averageWeekSeconds)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _DistributionList extends StatelessWidget {
  const _DistributionList({required this.title, required this.items});

  final String title;
  final List<TimeDistributionStat> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('Нет данных.', style: Theme.of(context).textTheme.bodyMedium)
          else
            for (final item in items.take(12)) ...[
              Row(
                children: [
                  SizedBox(width: 56, child: Text(item.label)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _relativeValue(item, items),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatDurationSeconds(item.totalSeconds)),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  double _relativeValue(
    TimeDistributionStat item,
    List<TimeDistributionStat> items,
  ) {
    final max = items.fold<int>(
      0,
      (current, value) =>
          value.totalSeconds > current ? value.totalSeconds : current,
    );
    if (max == 0) {
      return 0;
    }

    return item.totalSeconds / max;
  }
}

class PayoutForecastPanel extends StatelessWidget {
  const PayoutForecastPanel({required this.items, super.key});

  final List<PaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Прогноз выплат',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Нет ближайших выплат с суммой.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.event_available_rounded,
                  color: _parseColor(item.color),
                ),
                title: Text(item.projectName),
                subtitle: Text(
                  '${DateTimeFormats.date.format(item.periodStart)} — '
                  '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
                ),
                trailing: Text(
                  formatMoneyRub(item.expectedAmountMinor),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
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
