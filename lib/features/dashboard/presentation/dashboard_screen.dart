import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_screen.dart';
import '../../local_tracking/data/local_tracking_repository.dart';
import '../../local_tracking/presentation/timer_screen.dart';
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
    final progressHistory = ref.watch(weeklyProgressHistoryProvider);
    final syncState = ref.watch(syncControllerProvider);
    final activeEntry = ref.watch(activeTimeEntryProvider);
    final pendingLocalEntries = ref.watch(pendingLocalEntriesCountProvider);

    return AppScreen(
      title: 'Обзор',
      subtitle: 'Неделя, период выплат, ближайшие деньги и ритм работы.',
      actions: [
        FilledButton.icon(
          onPressed: syncState.isSyncing ? null : () => _syncNow(ref, context),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: Text(syncState.isSyncing ? 'Синхронизация' : 'Обновить'),
        ),
      ],
      children: [
        activeEntry.when(
          data: (entry) => DashboardTimerCard(entry: entry),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        pendingLocalEntries.when(
          data: (count) => count == 0
              ? const SizedBox.shrink()
              : AppPanel(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Есть неотправленные локальные записи: $count',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go(TimerScreen.routePath),
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Синхронизация'),
                      ),
                    ],
                  ),
                ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
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
          data: (data) => CurrentWeekPanel(summary: data),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Обзор недоступен',
            message: error.toString(),
          ),
        ),
        projectSummaries.when(
          data: (items) => CurrentProjectProgressPanel(items: items),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Прогресс по проектам недоступен',
            message: error.toString(),
          ),
        ),
        payments.when(
          data: (snapshot) => Column(
            children: [
              PaymentPeriodProgressPanel(items: snapshot.periodProgress),
              const SizedBox(height: 16),
              NextPaymentsPanel(items: snapshot.nextExpected),
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Выплаты недоступны',
            message: error.toString(),
          ),
        ),
        summary.when(
          data: (data) => WorkRhythmPanel(summary: data),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        progressHistory.when(
          data: (items) => WeeklyProgressHistoryTable(items: items),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'История прогресса недоступна',
            message: error.toString(),
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

class DashboardTimerCard extends StatefulWidget {
  const DashboardTimerCard({required this.entry, super.key});

  final ActiveTimeEntry? entry;

  @override
  State<DashboardTimerCard> createState() => _DashboardTimerCardState();
}

class _DashboardTimerCardState extends State<DashboardTimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (mounted && widget.entry != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    if (entry == null) {
      return AppPanel(
        child: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Таймер не запущен',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go(TimerScreen.routePath),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Запустить'),
            ),
          ],
        ),
      );
    }

    final seconds = DateTime.now().toUtc().difference(entry.beginAt).inSeconds;
    final durationSeconds = seconds < 60 ? 60 : seconds;

    return AppPanel(
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.projectName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((entry.activityName ?? '').isNotEmpty)
                  Text(
                    entry.activityName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                if ((entry.description ?? '').isNotEmpty)
                  Text(
                    entry.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Начало: ${DateTimeFormats.date.format(entry.beginAt.toLocal())} '
                  '${DateTimeFormats.time.format(entry.beginAt.toLocal())} · '
                  '${formatDurationSeconds(durationSeconds)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!entry.isLocal)
                  Text(
                    'Активная запись Kimai',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(TimerScreen.routePath),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(entry.isLocal ? 'Изменить' : 'Открыть'),
              ),
              if (entry.isLocal)
                FilledButton.icon(
                  onPressed: () => context.go(TimerScreen.routePath),
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Стоп'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrentWeekPanel extends StatelessWidget {
  const CurrentWeekPanel({required this.summary, super.key});

  final TimesheetSummary summary;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMetricRow(
      children: [
        MetricTile(
          label: 'Отработано за неделю',
          value: formatDurationSeconds(summary.totalSeconds),
          icon: Icons.timer_rounded,
        ),
        MetricTile(
          label: 'Доход за неделю',
          value: formatMoneyRub(summary.amountMinor),
          icon: Icons.payments_rounded,
        ),
        MetricTile(
          label: 'Записей',
          value: summary.entryCount.toString(),
          icon: Icons.list_alt_rounded,
        ),
      ],
    );
  }
}

class CurrentProjectProgressPanel extends StatelessWidget {
  const CurrentProjectProgressPanel({required this.items, super.key});

  final List<ProjectWeekSummary> items;

  @override
  Widget build(BuildContext context) {
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
  }
}

class ProjectProgressCard extends StatelessWidget {
  const ProjectProgressCard({required this.summary, super.key});

  final ProjectWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final goalSeconds = summary.goalSeconds;
    final balanceLabel = summary.overworkSeconds > 0
        ? 'Переработка ${formatDurationSeconds(summary.overworkSeconds)}'
        : 'Осталось ${formatDurationSeconds(summary.remainingSeconds)}';

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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppGoalProgressBar(
            trackedSeconds: summary.totalSeconds,
            targetSeconds: goalSeconds,
          ),
          const SizedBox(height: 12),
          Text(
            '${formatDurationSeconds(summary.totalSeconds)} / '
            '${formatDurationSeconds(goalSeconds)} · '
            '${summary.progressPercent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(balanceLabel, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            formatMoneyRub(summary.amountMinor),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class PaymentPeriodProgressPanel extends StatelessWidget {
  const PaymentPeriodProgressPanel({required this.items, super.key});

  final List<PaymentPeriodProgress> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Период выплат', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Нет активных периодов выплат.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in items) ...[
              Text(
                item.projectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${DateTimeFormats.date.format(item.periodStart)} - '
                '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))} · '
                'выплата ${DateTimeFormats.date.format(item.payoutDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Нужно ${formatDurationSeconds(item.requiredSeconds)}, '
                'отработано ${formatDurationSeconds(item.trackedSeconds)}, '
                '${item.balanceSeconds >= 0 ? 'запас' : 'осталось'} '
                '${formatDurationSeconds(item.balanceSeconds.abs())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                formatMoneyRub(item.expectedAmountMinor),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'До выплаты: ${_daysUntil(item.payoutDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item != items.last) const Divider(height: 20),
            ],
        ],
      ),
    );
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
          if (items.isEmpty)
            Text(
              'Нет ожидаемых выплат с суммой.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
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
                          '${DateTimeFormats.date.format(item.payoutDate)} · '
                          '${DateTimeFormats.date.format(item.periodStart)} - '
                          '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
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

class WorkRhythmPanel extends StatelessWidget {
  const WorkRhythmPanel({required this.summary, super.key});

  final TimesheetSummary summary;

  @override
  Widget build(BuildContext context) {
    final averagePerDay = summary.totalSeconds ~/ 7;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ритм работы', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'В среднем за день на этой неделе: ${formatDurationSeconds(averagePerDay)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class WeeklyProgressHistoryPanel extends StatelessWidget {
  const WeeklyProgressHistoryPanel({required this.items, super.key});

  final List<WeeklyProjectProgress> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(24).toList();
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'История прогресса',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text(
              'Нет данных по недельным целям.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in visible) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${DateTimeFormats.date.format(item.weekStart)} · ${item.projectName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(formatDurationSeconds(item.goalSeconds)),
                  ),
                  Expanded(
                    child: Text(formatDurationSeconds(item.trackedSeconds)),
                  ),
                  Expanded(
                    child: Text(
                      item.overworkSeconds > 0
                          ? '+${formatDurationSeconds(item.overworkSeconds)}'
                          : formatDurationSeconds(item.remainingSeconds),
                    ),
                  ),
                  Expanded(child: Text(formatMoneyRub(item.amountMinor))),
                ],
              ),
              if (item != visible.last) const Divider(height: 16),
            ],
        ],
      ),
    );
  }
}

class WeeklyProgressHistoryTable extends StatelessWidget {
  const WeeklyProgressHistoryTable({required this.items, super.key});

  final List<WeeklyProjectProgress> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(24).toList();
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'История прогресса',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text(
              'Нет данных по недельным целям.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            const _ProgressHistoryHeader(),
            const SizedBox(height: 8),
            for (final item in visible) ...[
              _DashboardProgressHistoryRow(item: item),
              if (item != visible.last) const Divider(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressHistoryHeader extends StatelessWidget {
  const _ProgressHistoryHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(flex: 2, child: Text('Неделя / проект', style: style)),
        Expanded(child: Text('Цель', style: style)),
        Expanded(child: Text('Сделано', style: style)),
        Expanded(child: Text('Баланс', style: style)),
        Expanded(child: Text('Доход', style: style)),
      ],
    );
  }
}

class _DashboardProgressHistoryRow extends StatelessWidget {
  const _DashboardProgressHistoryRow({required this.item});

  final WeeklyProjectProgress item;

  @override
  Widget build(BuildContext context) {
    final balance = item.overworkSeconds > 0
        ? '+${formatDurationSeconds(item.overworkSeconds)}'
        : formatDurationSeconds(item.remainingSeconds);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${DateTimeFormats.date.format(item.weekStart)} · ${item.projectName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(formatDurationSeconds(item.goalSeconds))),
            Expanded(child: Text(formatDurationSeconds(item.trackedSeconds))),
            Expanded(child: Text(balance)),
            Expanded(child: Text(formatMoneyRub(item.amountMinor))),
          ],
        ),
        const SizedBox(height: 8),
        AppGoalProgressBar(
          trackedSeconds: item.trackedSeconds,
          targetSeconds: item.goalSeconds,
          height: 6,
        ),
      ],
    );
  }
}

class ResponsiveMetricRow extends StatelessWidget {
  const ResponsiveMetricRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _daysUntil(DateTime payoutDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(
    payoutDate.year,
    payoutDate.month,
    payoutDate.day,
  ).difference(today).inDays;
  if (days <= 0) {
    return 'сегодня';
  }

  return '$days дн.';
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
