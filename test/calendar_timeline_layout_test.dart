import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/features/calendar/presentation/calendar_screen.dart';

void main() {
  const hourHeight = 72.0;
  final day = DateTime(2026, 5, 31);

  test('calculates 30 minute event height', () {
    final events = layoutCalendarTimelineEvents<String>(
      day: day,
      dayWidth: 200,
      hourHeight: hourHeight,
      horizontalPadding: 0,
      columnGap: 0,
      events: [
        CalendarTimelineEventInput(
          payload: 'event',
          begin: DateTime(2026, 5, 31, 9),
          end: DateTime(2026, 5, 31, 9, 30),
          durationSeconds: 1800,
        ),
      ],
    );

    expect(events.single.height, closeTo(36, 0.001));
  });

  test('calculates 2 hour event height', () {
    final events = layoutCalendarTimelineEvents<String>(
      day: day,
      dayWidth: 200,
      hourHeight: hourHeight,
      horizontalPadding: 0,
      columnGap: 0,
      events: [
        CalendarTimelineEventInput(
          payload: 'event',
          begin: DateTime(2026, 5, 31, 10),
          end: DateTime(2026, 5, 31, 12),
          durationSeconds: 7200,
        ),
      ],
    );

    expect(events.single.height, closeTo(144, 0.001));
  });

  test('calculates top position for event at 14:30', () {
    final events = layoutCalendarTimelineEvents<String>(
      day: day,
      dayWidth: 200,
      hourHeight: hourHeight,
      horizontalPadding: 0,
      columnGap: 0,
      events: [
        CalendarTimelineEventInput(
          payload: 'event',
          begin: DateTime(2026, 5, 31, 14, 30),
          end: DateTime(2026, 5, 31, 15),
          durationSeconds: 1800,
        ),
      ],
    );

    expect(events.single.top, closeTo(1044, 0.001));
  });

  test('renders overlapping events side by side', () {
    final events = layoutCalendarTimelineEvents<String>(
      day: day,
      dayWidth: 200,
      hourHeight: hourHeight,
      horizontalPadding: 0,
      columnGap: 0,
      events: [
        CalendarTimelineEventInput(
          payload: 'first',
          begin: DateTime(2026, 5, 31, 14),
          end: DateTime(2026, 5, 31, 16),
          durationSeconds: 7200,
        ),
        CalendarTimelineEventInput(
          payload: 'second',
          begin: DateTime(2026, 5, 31, 15),
          end: DateTime(2026, 5, 31, 17),
          durationSeconds: 7200,
        ),
      ],
    );

    final first = events.singleWhere((event) => event.payload == 'first');
    final second = events.singleWhere((event) => event.payload == 'second');

    expect(first.columnCount, 2);
    expect(second.columnCount, 2);
    expect(first.left, closeTo(0, 0.001));
    expect(first.width, closeTo(100, 0.001));
    expect(second.left, closeTo(100, 0.001));
    expect(second.width, closeTo(100, 0.001));
  });
}
