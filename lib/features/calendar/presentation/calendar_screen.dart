import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/tags.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_screen.dart';
import '../../timesheets/data/timesheet_edit_service.dart';
import '../../timesheets/data/timesheets_repository.dart';
import '../../timesheets/presentation/timesheets_screen.dart';

const _hourHeight = 72.0;
const _hourLabelWidth = 68.0;
const _dayHeaderHeight = 96.0;
const _minDayWidth = 168.0;
const _minEventHeight = 28.0;
const _timelineHeight = 24 * _hourHeight;

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

    return AppScreen(
      title: 'Календарь',
      subtitle:
          '${DateTimeFormats.date.format(_weekStart)} - ${DateTimeFormats.date.format(weekEnd.subtract(const Duration(days: 1)))}',
      actions: [
        IconButton.filledTonal(
          onPressed: () => setState(
            () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Предыдущая неделя',
        ),
        OutlinedButton(
          onPressed: () =>
              setState(() => _weekStart = _startOfWeek(DateTime.now())),
          child: const Text('Сегодня'),
        ),
        OutlinedButton.icon(
          onPressed: _jumpToDate,
          icon: const Icon(Icons.event_rounded, size: 18),
          label: const Text('Дата'),
        ),
        IconButton.filledTonal(
          onPressed: () => setState(
            () => _weekStart = _weekStart.add(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Следующая неделя',
        ),
      ],
      children: [
        entries.when(
          data: (items) =>
              TimelineCalendar(weekStart: _weekStart, entries: items),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Календарь недоступен',
            message: error.toString(),
            action: _CopyErrorButton(error: error),
          ),
        ),
      ],
    );
  }

  Future<void> _jumpToDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _weekStart,
    );
    if (selected == null) {
      return;
    }

    setState(() => _weekStart = _startOfWeek(selected));
  }

  DateTime _startOfWeek(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);

    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class TimelineCalendar extends StatelessWidget {
  const TimelineCalendar({
    required this.weekStart,
    required this.entries,
    super.key,
  });

  final DateTime weekStart;
  final List<TimesheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var index = 0; index < 7; index++)
        weekStart.add(Duration(days: index)),
    ];
    final entriesByDay = {
      for (final day in days)
        day: entries
            .where(
              (entry) => _isSameDay(entry.beginAt.toLocal(), day),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.beginAt.compareTo(b.beginAt),
          ),
    };
    final totalSeconds = entries.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    final totalAmountMinor = entries.fold<int>(
      0,
      (sum, item) => sum + (item.amountMinor ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalendarHeatmap(days: days, entriesByDay: entriesByDay),
        const SizedBox(height: 12),
        AppPanel(
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SummaryChip(
                icon: Icons.schedule_rounded,
                label: 'За неделю',
                value: formatDurationSeconds(totalSeconds),
              ),
              _SummaryChip(
                icon: Icons.payments_rounded,
                label: 'Сумма',
                value: formatMoneyRub(totalAmountMinor),
              ),
              _SummaryChip(
                icon: Icons.list_alt_rounded,
                label: 'Записей',
                value: entries.length.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const EmptyState(
            title: 'Нет записей на этой неделе',
            message:
                'Синхронизируйте Kimai или выберите другую неделю, чтобы увидеть календарь занятости.',
          )
        else
          AppPanel(
            padding: EdgeInsets.zero,
            child: TimelineGrid(days: days, entriesByDay: entriesByDay),
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    required this.days,
    required this.entriesByDay,
    super.key,
  });

  final List<DateTime> days;
  final Map<DateTime, List<TimesheetEntry>> entriesByDay;

  @override
  Widget build(BuildContext context) {
    const dayTargetSeconds = 8 * 60 * 60;
    final totals = [
      for (final day in days)
        (entriesByDay[day] ?? const <TimesheetEntry>[]).fold<int>(
          0,
          (sum, entry) => sum + entry.durationSeconds,
        ),
    ];
    return AppPanel(
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeFormats.weekday.format(days[index]),
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  AppGoalProgressBar(
                    trackedSeconds: totals[index],
                    targetSeconds: dayTargetSeconds,
                    height: 6,
                  ),
                ],
              ),
            ),
            if (index != days.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class TimelineGrid extends StatelessWidget {
  const TimelineGrid({
    required this.days,
    required this.entriesByDay,
    super.key,
  });

  final List<DateTime> days;
  final Map<DateTime, List<TimesheetEntry>> entriesByDay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0, constraints.maxWidth);
        final dayWidth = math.max(
          _minDayWidth,
          (availableWidth - _hourLabelWidth) / days.length,
        );
        final daysWidth = dayWidth * days.length;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _hourLabelWidth,
              child: Column(
                children: const [
                  SizedBox(height: _dayHeaderHeight),
                  HourLabels(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: daysWidth,
                  child: Column(
                    children: [
                      SizedBox(
                        height: _dayHeaderHeight,
                        child: Row(
                          children: [
                            for (final day in days)
                              SizedBox(
                                width: dayWidth,
                                child: DayHeader(
                                  day: day,
                                  entries: entriesByDay[day] ?? const [],
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: _timelineHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final day in days)
                              SizedBox(
                                width: dayWidth,
                                child: DayTimelineColumn(
                                  day: day,
                                  dayWidth: dayWidth,
                                  entries: entriesByDay[day] ?? const [],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DayHeader extends StatelessWidget {
  const DayHeader({
    required this.day,
    required this.entries,
    super.key,
  });

  final DateTime day;
  final List<TimesheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final seconds = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationSeconds,
    );
    final amount = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.amountMinor ?? 0),
    );
    final isToday = _isSameDay(day, DateTime.now());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday ? AppColors.surfaceElevated : AppColors.surface,
        border: const Border(
          left: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${DateTimeFormats.weekday.format(day)} ${day.day}',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              formatDurationSeconds(seconds),
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              formatMoneyRub(amount),
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class HourLabels extends StatelessWidget {
  const HourLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _hourLabelWidth,
      height: _timelineHeight,
      child: Stack(
        children: [
          for (var hour = 0; hour <= 24; hour++)
            Positioned(
              top: math.max(0, hour * _hourHeight - 8),
              left: 0,
              right: 8,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class DayTimelineColumn extends StatelessWidget {
  const DayTimelineColumn({
    required this.day,
    required this.dayWidth,
    required this.entries,
    super.key,
  });

  final DateTime day;
  final double dayWidth;
  final List<TimesheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final positionedEvents = layoutCalendarTimelineEvents<TimesheetEntry>(
      day: day,
      dayWidth: dayWidth,
      events: [
        for (final entry in entries)
          CalendarTimelineEventInput<TimesheetEntry>(
            payload: entry,
            begin: entry.beginAt,
            end: entry.endAt,
            durationSeconds: entry.durationSeconds,
          ),
      ],
    );
    final now = DateTime.now();
    final isToday = _isSameDay(day, now);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: _timelineHeight,
        child: Stack(
          children: [
            for (var hour = 0; hour <= 24; hour++)
              Positioned(
                top: hour * _hourHeight,
                left: 0,
                right: 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SizedBox(height: 1),
                ),
              ),
            if (isToday) CurrentTimeIndicator(now: now),
            for (final event in positionedEvents)
              Positioned(
                top: event.top,
                left: event.left,
                width: event.width,
                height: event.height,
                child: TimelineEventCard(event: event),
              ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class CalendarTimelineEventInput<T> {
  const CalendarTimelineEventInput({
    required this.payload,
    required this.begin,
    required this.durationSeconds,
    this.end,
  });

  final T payload;
  final DateTime begin;
  final DateTime? end;
  final int durationSeconds;
}

@visibleForTesting
class CalendarTimelineEventGeometry<T> {
  const CalendarTimelineEventGeometry({
    required this.payload,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    required this.column,
    required this.columnCount,
  });

  final T payload;
  final double top;
  final double height;
  final double left;
  final double width;
  final int column;
  final int columnCount;
}

@visibleForTesting
List<CalendarTimelineEventGeometry<T>> layoutCalendarTimelineEvents<T>({
  required DateTime day,
  required double dayWidth,
  required List<CalendarTimelineEventInput<T>> events,
  double hourHeight = _hourHeight,
  double minEventHeight = _minEventHeight,
  double horizontalPadding = 6,
  double columnGap = 4,
}) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final dayHeight = 24 * hourHeight;
  final ranges = [
    for (final event in events)
      if (_EventRange.fromInput(event, dayStart, dayEnd) case final range?)
        range,
  ]..sort((a, b) {
      final byStart = a.startMinute.compareTo(b.startMinute);
      if (byStart != 0) {
        return byStart;
      }

      return a.endMinute.compareTo(b.endMinute);
    });
  final clusters = <List<_EventRange<T>>>[];
  var clusterEnd = -1;

  for (final event in ranges) {
    if (clusters.isEmpty || event.startMinute >= clusterEnd) {
      clusters.add([event]);
      clusterEnd = event.endMinute;
    } else {
      clusters.last.add(event);
      clusterEnd = math.max(clusterEnd, event.endMinute);
    }
  }

  return [
    for (final cluster in clusters)
      ..._layoutTimelineCluster(
        cluster: cluster,
        dayHeight: dayHeight,
        dayWidth: dayWidth,
        hourHeight: hourHeight,
        horizontalPadding: horizontalPadding,
        columnGap: columnGap,
        minEventHeight: minEventHeight,
      ),
  ];
}

List<CalendarTimelineEventGeometry<T>> _layoutTimelineCluster<T>({
  required List<_EventRange<T>> cluster,
  required double dayHeight,
  required double dayWidth,
  required double hourHeight,
  required double horizontalPadding,
  required double columnGap,
  required double minEventHeight,
}) {
  final columnEnds = <int>[];
  final assignments = <_EventRange<T>, int>{};

  for (final event in cluster) {
    var column = columnEnds.indexWhere((end) => end <= event.startMinute);
    if (column == -1) {
      column = columnEnds.length;
      columnEnds.add(event.endMinute);
    } else {
      columnEnds[column] = event.endMinute;
    }
    assignments[event] = column;
  }

  final columnCount = math.max(1, columnEnds.length);
  final usableWidth = math.max(0.0, dayWidth - horizontalPadding * 2);
  final slotWidth = usableWidth / columnCount;

  return [
    for (final event in cluster)
      _layoutTimelineEvent(
        event: event,
        dayHeight: dayHeight,
        hourHeight: hourHeight,
        horizontalPadding: horizontalPadding,
        slotWidth: slotWidth,
        columnGap: columnGap,
        minEventHeight: minEventHeight,
        column: assignments[event] ?? 0,
        columnCount: columnCount,
      ),
  ];
}

CalendarTimelineEventGeometry<T> _layoutTimelineEvent<T>({
  required _EventRange<T> event,
  required double dayHeight,
  required double hourHeight,
  required double horizontalPadding,
  required double slotWidth,
  required double columnGap,
  required double minEventHeight,
  required int column,
  required int columnCount,
}) {
  final top = event.startMinute / 60 * hourHeight;
  final durationHeight =
      (event.endMinute - event.startMinute) / 60 * hourHeight;
  final availableHeight = math.max(0.0, dayHeight - top);
  final height = math.min(
    math.max(minEventHeight, durationHeight),
    availableHeight,
  );
  final left = horizontalPadding + column * slotWidth;
  final width = math.max(0.0, slotWidth - columnGap);

  assert(() {
    if (top < 0 || top + height > dayHeight + 0.01) {
      debugPrint(
        'Calendar event geometry is outside day bounds: '
        'top=$top height=$height dayHeight=$dayHeight',
      );
    }

    return true;
  }());

  return CalendarTimelineEventGeometry<T>(
    payload: event.payload,
    top: top,
    height: height,
    left: left,
    width: width,
    column: column,
    columnCount: columnCount,
  );
}

class _EventRange<T> {
  const _EventRange({
    required this.payload,
    required this.startMinute,
    required this.endMinute,
  });

  static _EventRange<T>? fromInput<T>(
    CalendarTimelineEventInput<T> event,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final begin = event.begin.toLocal();
    final fallbackEnd = event.durationSeconds > 0
        ? begin.add(Duration(seconds: event.durationSeconds))
        : begin.add(const Duration(minutes: 15));
    final rawEnd = event.end?.toLocal() ?? fallbackEnd;
    final end =
        rawEnd.isAfter(begin) ? rawEnd : begin.add(const Duration(minutes: 15));
    final clampedBegin = _maxDateTime(begin, dayStart);
    final clampedEnd = _minDateTime(end, dayEnd);

    if (!clampedEnd.isAfter(clampedBegin)) {
      return null;
    }

    final startMinute = _minuteOfDay(clampedBegin).clamp(0, 24 * 60).toInt();
    final actualDurationMinutes =
        clampedEnd.difference(clampedBegin).inMinutes.clamp(1, 24 * 60).toInt();
    final durationMinutes = math.max(15, actualDurationMinutes);
    final endMinute = math.min(24 * 60, startMinute + durationMinutes);

    return _EventRange<T>(
      payload: event.payload,
      startMinute: startMinute,
      endMinute: math.max(startMinute + 1, endMinute),
    );
  }

  final T payload;
  final int startMinute;
  final int endMinute;
}

class TimelineEventCard extends StatelessWidget {
  const TimelineEventCard({required this.event, super.key});

  final CalendarTimelineEventGeometry<TimesheetEntry> event;

  @override
  Widget build(BuildContext context) {
    final entry = event.payload;
    final begin = entry.beginAt.toLocal();
    final end = entry.endAt?.toLocal();
    final compact = event.height < 54;
    final roomy = event.height >= 88;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => TimesheetDetailDialog(entry: entry),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _parseColor(entry.projectColor),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadii.sm),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${DateTimeFormats.time.format(begin)} - ${end == null ? 'идёт' : DateTimeFormats.time.format(end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          formatDurationSeconds(entry.durationSeconds),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (roomy)
                          Text(
                            entry.description ?? entry.activityName ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentTimeIndicator extends StatelessWidget {
  const CurrentTimeIndicator({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final top = (now.hour * 60 + now.minute) / 60 * _hourHeight;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.danger, height: 1, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class TimesheetDetailDialog extends ConsumerWidget {
  const TimesheetDetailDialog({required this.entry, super.key});

  final TimesheetEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final begin = entry.beginAt.toLocal();
    final end = entry.endAt?.toLocal();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
              _DetailRow(
                label: 'Kimai id',
                value: entry.kimaiTimesheetId?.toString() ?? '-',
              ),
              _DetailRow(
                label: 'Активность',
                value: entry.activityName ?? '-',
              ),
              _DetailRow(
                label: 'Описание',
                value: entry.description ?? '-',
              ),
              _DetailRow(
                label: 'Метки',
                value: formatTagsForDisplay(entry.tags).isEmpty
                    ? '-'
                    : formatTagsForDisplay(entry.tags),
              ),
              _DetailRow(
                label: 'Начало',
                value:
                    '${DateTimeFormats.date.format(begin)} ${DateTimeFormats.time.format(begin)}',
              ),
              _DetailRow(
                label: 'Конец',
                value: end == null
                    ? 'Идёт'
                    : '${DateTimeFormats.date.format(end)} ${DateTimeFormats.time.format(end)}',
              ),
              _DetailRow(
                label: 'Длительность',
                value: formatDurationSeconds(entry.durationSeconds),
              ),
              _DetailRow(
                label: 'Ставка',
                value: entry.hourlyRateMinor == null
                    ? '-'
                    : '${formatMoneyRub(entry.hourlyRateMinor!)}/ч',
              ),
              _DetailRow(
                label: 'Сумма',
                value: entry.amountMinor == null
                    ? '-'
                    : formatMoneyRub(entry.amountMinor!),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: entry.endAt == null
                          ? null
                          : () => _edit(context, ref),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Изменить'),
                    ),
                    OutlinedButton.icon(
                      onPressed: entry.endAt == null
                          ? null
                          : () => _delete(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Удалить'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
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

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final projects = await ref
        .read(timesheetsRepositoryProvider)
        .getAvailableTimesheetProjects();
    if (!context.mounted) {
      return;
    }

    final input = await showDialog<TimesheetEditInput>(
      context: context,
      builder: (context) => TimesheetEditDialog(
        entry: entry,
        projects: projects,
      ),
    );
    if (input == null) {
      return;
    }

    try {
      await ref.read(timesheetEditServiceProvider).save(input);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись сохранена')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: Text(
          entry.kimaiTimesheetId == null
              ? 'Локальная запись будет удалена без отправки в Kimai.'
              : 'Запись будет удалена в Kimai и затем скрыта локально.',
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

    try {
      await ref.read(timesheetEditServiceProvider).delete(entry);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись удалена')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
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
            width: 116,
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

class _CopyErrorButton extends StatelessWidget {
  const _CopyErrorButton({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: error.toString()));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка скопирована')),
          );
        }
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text('Скопировать ошибку'),
    );
  }
}

int _minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

DateTime _maxDateTime(DateTime left, DateTime right) {
  return left.isAfter(right) ? left : right;
}

DateTime _minDateTime(DateTime left, DateTime right) {
  return left.isBefore(right) ? left : right;
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
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
