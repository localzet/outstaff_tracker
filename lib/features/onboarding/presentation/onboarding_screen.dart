import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/presentation/settings_screen.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      title: 'Setup',
      subtitle: 'Complete the local Kimai setup to start tracking analytics.',
      actions: [
        FilledButton.icon(
          onPressed: () async {
            await ref
                .read(settingsRepositoryProvider)
                .setOnboardingComplete(true);
            if (context.mounted) {
              context.go(DashboardScreen.routePath);
            }
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Mark complete'),
        ),
      ],
      children: [
        const _OnboardingStep(
          index: 1,
          title: 'Connect Kimai',
          description: 'Add the base URL and API token in Settings.',
        ),
        const _OnboardingStep(
          index: 2,
          title: 'Import projects',
          description: 'Use Connect to fetch real Kimai projects into SQLite.',
        ),
        const _OnboardingStep(
          index: 3,
          title: 'Configure rates and goals',
          description: 'Enable projects and set hourly rates and weekly goals.',
        ),
        const _OnboardingStep(
          index: 4,
          title: 'Sync last year',
          description: 'Run a full local timesheet sync from Settings.',
        ),
        AppPanel(
          child: Row(
            children: [
              const Icon(Icons.settings_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Open Settings to continue setup.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.go(SettingsScreen.routePath),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.index,
    required this.title,
    required this.description,
  });

  final int index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Text(index.toString())),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
