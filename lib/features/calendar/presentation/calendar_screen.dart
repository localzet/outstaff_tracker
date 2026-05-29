import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../timesheets/data/timesheets_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 7));
    final filters = TimesheetFilters(begin: _weekStart, end: weekEnd);
    final entries = ref.watch(_calendarEntriesProvider(filters));
    final moneyFormat = NumberFormat.simpleCurrency(name: 'RUB');

    return AppScreen(
      title: 'Calendar',
      subtitle:
          '${DateTimeFormats.date.format(_weekStart)} - ${DateTimeFormats.date.format(weekEnd.subtract(const Duration(days: 1)))}',
      actions: [
        IconButton.filledTonal(
          onPressed: () => setState(
            () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous week',
        ),
        OutlinedButton(
          onPressed: () =>
              setState(() => _weekStart = _startOfWeek(DateTime.now())),
          child: const Text('Today'),
        ),
        IconButton.filledTonal(
          onPressed: () => setState(
            () => _weekStart = _weekStart.add(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next week',
        ),
      ],
      children: [
        entries.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No entries this week',
                message: 'Sync Kimai to populate the weekly calendar.',
              );
            }

            return CalendarWeekView(
              weekStart: _weekStart,
              entries: items,
              moneyFormat: moneyFormat,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Calendar is unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }

  DateTime _startOfWeek(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);

    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.weekStart,
    required this.entries,
    required this.moneyFormat,
    super.key,
  });

  final DateTime weekStart;
  final List<TimesheetEntry> entries;
  final NumberFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var index = 0; index < 7; index++)
        weekStart.add(Duration(days: index)),
    ];
    final grouped = {
      for (final day in days)
        day: entries
            .where(
              (entry) => _isSameDay(entry.timesheet.beginAt.toLocal(), day),
            )
            .toList(growable: false),
    };
    final weeklySeconds = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.timesheet.durationSeconds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPanel(
          child: Row(
            children: [
              const Icon(
                Icons.calendar_view_week_rounded,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly total: ${formatDurationSeconds(weeklySeconds)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (final day in days) ...[
                    CalendarDayColumn(
                      day: day,
                      entries: grouped[day] ?? const [],
                      moneyFormat: moneyFormat,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return AppPanel(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final day in days)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              right: day == days.last
                                  ? BorderSide.none
                                  : const BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: CalendarDayColumn(
                            day: day,
                            entries: grouped[day] ?? const [],
                            moneyFormat: moneyFormat,
                            framed: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class CalendarDayColumn extends StatelessWidget {
  const CalendarDayColumn({
    required this.day,
    required this.entries,
    required this.moneyFormat,
    this.framed = true,
    super.key,
  });

  final DateTime day;
  final List<TimesheetEntry> entries;
  final NumberFormat moneyFormat;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.timesheet.durationSeconds,
    );
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${DateTimeFormats.weekday.format(day)} ${day.day}',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatDurationSeconds(totalSeconds),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('No time', style: Theme.of(context).textTheme.bodyMedium)
          else
            for (final entry in entries) ...[
              CalendarEventCard(
                entry: entry,
                moneyFormat: moneyFormat,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );

    if (!framed) {
      return content;
    }

    return AppPanel(padding: EdgeInsets.zero, child: content);
  }
}

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    required this.entry,
    required this.moneyFormat,
    super.key,
  });

  final TimesheetEntry entry;
  final NumberFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final timesheet = entry.timesheet;
    final begin = timesheet.beginAt.toLocal();
    final end = timesheet.endAt?.toLocal();

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => TimesheetDetailDialog(
          entry: entry,
          moneyFormat: moneyFormat,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 54,
                decoration: BoxDecoration(
                  color: _parseColor(entry.projectColor),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.projectName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTimeFormats.time.format(begin)} - ${end == null ? 'running' : DateTimeFormats.time.format(end)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDurationSeconds(timesheet.durationSeconds)} · ${timesheet.description ?? timesheet.activityName ?? 'Work'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimesheetDetailDialog extends StatelessWidget {
  const TimesheetDetailDialog({
    required this.entry,
    required this.moneyFormat,
    super.key,
  });

  final TimesheetEntry entry;
  final NumberFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final timesheet = entry.timesheet;
    final begin = timesheet.beginAt.toLocal();
    final end = timesheet.endAt?.toLocal();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.projectName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Kimai id', value: timesheet.id.toString()),
              _DetailRow(
                label: 'Activity',
                value: timesheet.activityName ?? '-',
              ),
              _DetailRow(
                label: 'Description',
                value: timesheet.description ?? '-',
              ),
              _DetailRow(
                label: 'Begin',
                value:
                    '${DateTimeFormats.date.format(begin)} ${DateTimeFormats.time.format(begin)}',
              ),
              _DetailRow(
                label: 'End',
                value: end == null
                    ? 'Running'
                    : '${DateTimeFormats.date.format(end)} ${DateTimeFormats.time.format(end)}',
              ),
              _DetailRow(
                label: 'Duration',
                value: formatDurationSeconds(timesheet.durationSeconds),
              ),
              _DetailRow(
                label: 'Rate',
                value: entry.hourlyRateMinor == null
                    ? '-'
                    : moneyFormat.format(entry.hourlyRateMinor! / 100),
              ),
              _DetailRow(
                label: 'Amount',
                value: timesheet.amountMinor == null
                    ? '-'
                    : moneyFormat.format(timesheet.amountMinor! / 100),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
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

final _calendarEntriesProvider = StreamProvider.autoDispose
    .family<List<TimesheetEntry>, TimesheetFilters>((ref, filters) {
  return ref
      .watch(timesheetsRepositoryProvider)
      .watchTimesheetsFiltered(filters);
});
