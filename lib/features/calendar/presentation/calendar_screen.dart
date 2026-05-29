import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../timesheets/data/timesheets_repository.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(currentMonthTimesheetsProvider);

    return AppScreen(
      title: 'Calendar',
      subtitle: DateTimeFormats.month.format(DateTime.now()),
      children: [
        entries.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No entries this month',
                message: 'Sync Kimai to populate local calendar data.',
              );
            }

            final grouped = <DateTime, int>{};
            for (final item in items) {
              final day = DateTime(
                item.beginAt.year,
                item.beginAt.month,
                item.beginAt.day,
              );
              grouped[day] = (grouped[day] ?? 0) + item.durationSeconds;
            }

            return AppPanel(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in grouped.entries)
                    SizedBox(
                      width: 132,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateTimeFormats.compactDate.format(entry.key),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatDurationMinutes(entry.value ~/ 60),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
}
