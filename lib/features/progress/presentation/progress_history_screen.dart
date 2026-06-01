import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_screen.dart';
import '../../payments/data/payments_repository.dart';
import '../../timesheets/data/timesheets_repository.dart';

enum ProgressHistoryMode { weeks, payoutPeriods }

class ProgressHistoryScreen extends ConsumerStatefulWidget {
  const ProgressHistoryScreen({super.key});

  static const routePath = '/progress';

  @override
  ConsumerState<ProgressHistoryScreen> createState() =>
      _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends ConsumerState<ProgressHistoryScreen> {
  ProgressHistoryMode _mode = ProgressHistoryMode.weeks;
  String? _projectName;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(weeklyProgressHistoryProvider);
    final payments = ref.watch(paymentsSnapshotProvider);

    return AppScreen(
      title: 'История прогресса',
      subtitle: 'Цели, отработанное время и переработка по неделям и выплатам.',
      actions: [
        SegmentedButton<ProgressHistoryMode>(
          segments: const [
            ButtonSegment(
              value: ProgressHistoryMode.weeks,
              label: Text('По неделям'),
            ),
            ButtonSegment(
              value: ProgressHistoryMode.payoutPeriods,
              label: Text('По выплатам'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.single),
        ),
      ],
      children: [
        if (_mode == ProgressHistoryMode.weeks)
          history.when(
            data: (items) => _WeeklyHistoryView(
              items: items,
              selectedProject: _projectName,
              onProjectChanged: (value) => setState(() => _projectName = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => EmptyState(
              title: 'История прогресса недоступна',
              message: error.toString(),
            ),
          )
        else
          payments.when(
            data: (snapshot) => _PayoutPeriodHistoryView(
              items: snapshot.periodProgress,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => EmptyState(
              title: 'Периоды выплат недоступны',
              message: error.toString(),
            ),
          ),
      ],
    );
  }
}

class _WeeklyHistoryView extends StatelessWidget {
  const _WeeklyHistoryView({
    required this.items,
    required this.selectedProject,
    required this.onProjectChanged,
  });

  final List<WeeklyProjectProgress> items;
  final String? selectedProject;
  final ValueChanged<String?> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    final projects = items.map((item) => item.projectName).toSet().toList()
      ..sort();
    final filtered = selectedProject == null
        ? items
        : items.where((item) => item.projectName == selectedProject).toList();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 280,
            child: DropdownButtonFormField<String?>(
              initialValue: selectedProject,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Проект'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Все проекты', overflow: TextOverflow.ellipsis),
                ),
                for (final project in projects)
                  DropdownMenuItem(
                    value: project,
                    child: Text(project, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onProjectChanged,
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Text(
              'Нет данных за выбранный период.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            const _ProgressHeader(title: 'Неделя / проект'),
            const SizedBox(height: 8),
            for (final item in filtered) ...[
              _ProgressRow(
                title:
                    '${DateTimeFormats.date.format(item.weekStart)} · ${item.projectName}',
                goalSeconds: item.goalSeconds,
                trackedSeconds: item.trackedSeconds,
                amountMinor: item.amountMinor,
              ),
              if (item != filtered.last) const Divider(height: 18),
            ],
          ],
        ],
      ),
    );
  }
}

class _PayoutPeriodHistoryView extends StatelessWidget {
  const _PayoutPeriodHistoryView({required this.items});

  final List<PaymentPeriodProgress> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            Text(
              'Нет активных периодов выплат.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            const _ProgressHeader(title: 'Период / проект'),
            const SizedBox(height: 8),
            for (final item in items) ...[
              Text(
                item.projectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${DateTimeFormats.date.format(item.periodStart)} — '
                '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _ProgressRow(
                title:
                    'За период выплат нужно ${formatDurationSeconds(item.requiredSeconds)}, '
                    'отработано ${formatDurationSeconds(item.trackedSeconds)}, '
                    '${item.balanceSeconds >= 0 ? 'запас' : 'осталось'} '
                    '${formatDurationSeconds(item.balanceSeconds.abs())}',
                goalSeconds: item.requiredSeconds,
                trackedSeconds: item.trackedSeconds,
                amountMinor: item.expectedAmountMinor,
              ),
              if (item != items.last) const Divider(height: 22),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(flex: 3, child: Text(title, style: style)),
        Expanded(child: Text('Цель', style: style)),
        Expanded(child: Text('Сделано', style: style)),
        Expanded(child: Text('Баланс', style: style)),
        Expanded(child: Text('Доход', style: style)),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.goalSeconds,
    required this.trackedSeconds,
    required this.amountMinor,
  });

  final String title;
  final int goalSeconds;
  final int trackedSeconds;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final balance = trackedSeconds - goalSeconds;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
            Expanded(child: Text(formatDurationSeconds(goalSeconds))),
            Expanded(child: Text(formatDurationSeconds(trackedSeconds))),
            Expanded(
              child: Text(
                balance >= 0
                    ? '+${formatDurationSeconds(balance)}'
                    : formatDurationSeconds(balance.abs()),
              ),
            ),
            Expanded(child: Text(formatMoneyRub(amountMinor))),
          ],
        ),
        const SizedBox(height: 8),
        AppGoalProgressBar(
          trackedSeconds: trackedSeconds,
          targetSeconds: goalSeconds,
          height: 6,
        ),
      ],
    );
  }
}
