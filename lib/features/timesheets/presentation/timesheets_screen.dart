import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../data/timesheets_repository.dart';

class TimesheetsScreen extends ConsumerWidget {
  const TimesheetsScreen({super.key});

  static const routePath = '/timesheets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheets = ref.watch(recentTimesheetsProvider);

    return AppScreen(
      title: 'Timesheets',
      subtitle: 'Recent locally cached Kimai records.',
      children: [
        timesheets.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No timesheets yet',
                message: 'Configure Kimai in Settings and run sync.',
              );
            }

            return AppPanel(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ListTile(
                    title:
                        Text(item.description ?? item.activityName ?? 'Work'),
                    subtitle: Text(
                      '${DateTimeFormats.date.format(item.beginAt)} '
                      '${DateTimeFormats.time.format(item.beginAt)}',
                    ),
                    trailing: Text(
                      formatDurationMinutes(item.durationSeconds ~/ 60),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Timesheets are unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }
}
