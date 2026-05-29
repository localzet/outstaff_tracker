import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_screen.dart';
import '../data/projects_repository.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  static const routePath = '/projects';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectConfigurationsProvider);

    return AppScreen(
      title: 'Projects',
      subtitle: 'Imported Kimai projects and local billing settings.',
      children: [
        projects.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                title: 'No projects yet',
                message: 'Projects will appear after a successful Kimai sync.',
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
                  return ProjectConfigurationTile(
                    configuration: items[index],
                  );
                },
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Projects are unavailable',
            message: error.toString(),
          ),
        ),
      ],
    );
  }
}

class ProjectConfigurationTile extends ConsumerStatefulWidget {
  const ProjectConfigurationTile({
    required this.configuration,
    super.key,
  });

  final ProjectConfiguration configuration;

  @override
  ConsumerState<ProjectConfigurationTile> createState() =>
      _ProjectConfigurationTileState();
}

class _ProjectConfigurationTileState
    extends ConsumerState<ProjectConfigurationTile> {
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _weeklyGoalController;

  @override
  void initState() {
    super.initState();
    _hourlyRateController = TextEditingController();
    _weeklyGoalController = TextEditingController();
    _hydrateControllers();
  }

  @override
  void didUpdateWidget(ProjectConfigurationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuration.appProject != widget.configuration.appProject) {
      _hydrateControllers();
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProject = widget.configuration.appProject;
    final kimaiProject = widget.configuration.kimaiProject;
    final payoutRule = PayoutRule.fromStorage(appProject.payoutRule);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProjectColorDot(color: appProject.color ?? kimaiProject.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kimaiProject.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kimaiProject.customerName ?? 'No customer',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: appProject.enabled,
                onChanged: (value) => _update(enabled: value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _hourlyRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Hourly rate',
                    prefixIcon: Icon(Icons.payments_rounded, size: 18),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _weeklyGoalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weekly goal',
                    suffixText: 'h',
                    prefixIcon: Icon(Icons.flag_rounded, size: 18),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<PayoutRule>(
                  initialValue: payoutRule,
                  decoration: const InputDecoration(
                    labelText: 'Payout rule',
                    prefixIcon: Icon(Icons.event_repeat_rounded, size: 18),
                  ),
                  items: [
                    for (final rule in PayoutRule.values)
                      DropdownMenuItem(
                        value: rule,
                        child: Text(rule.label),
                      ),
                  ],
                  onChanged: (rule) {
                    if (rule != null) {
                      _update(payoutRule: rule);
                    }
                  },
                ),
              ),
              IconButton.filledTonal(
                onPressed: _saveNumericSettings,
                icon: const Icon(Icons.save_rounded),
                tooltip: 'Save project settings',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in ProjectColorDot.palette)
                IconButton(
                  onPressed: () => _update(color: color),
                  icon: ProjectColorDot(color: color),
                  tooltip: color,
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      color: color == appProject.color
                          ? AppColors.textPrimary
                          : AppColors.border,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _hydrateControllers() {
    final appProject = widget.configuration.appProject;
    _hourlyRateController.text = appProject.hourlyRate?.toString() ?? '';
    _weeklyGoalController.text = appProject.weeklyGoalHours?.toString() ?? '';
  }

  Future<void> _saveNumericSettings() async {
    final hourlyRateText = _hourlyRateController.text.trim();
    final weeklyGoalText = _weeklyGoalController.text.trim();
    final hourlyRate = _parsePositiveDouble(hourlyRateText);
    final weeklyGoal = _parsePositiveDouble(weeklyGoalText);

    if ((hourlyRateText.isNotEmpty && hourlyRate == null) ||
        (weeklyGoalText.isNotEmpty && weeklyGoal == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid positive numbers.')),
      );
      return;
    }

    await _update(
      hourlyRate: hourlyRate,
      clearHourlyRate: hourlyRateText.isEmpty,
      weeklyGoalHours: weeklyGoal,
      clearWeeklyGoalHours: weeklyGoalText.isEmpty,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project settings saved')),
      );
    }
  }

  Future<void> _update({
    bool? enabled,
    double? hourlyRate,
    bool clearHourlyRate = false,
    double? weeklyGoalHours,
    bool clearWeeklyGoalHours = false,
    String? color,
    PayoutRule? payoutRule,
  }) {
    return ref.read(projectsRepositoryProvider).updateProjectSettings(
          appProjectId: widget.configuration.appProject.id,
          enabled: enabled,
          hourlyRate: hourlyRate,
          clearHourlyRate: clearHourlyRate,
          weeklyGoalHours: weeklyGoalHours,
          clearWeeklyGoalHours: clearWeeklyGoalHours,
          color: color,
          payoutRule: payoutRule,
        );
  }

  double? _parsePositiveDouble(String value) {
    if (value.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }
}

class ProjectColorDot extends StatelessWidget {
  const ProjectColorDot({required this.color, super.key});

  static const palette = [
    '#22C55E',
    '#38BDF8',
    '#A78BFA',
    '#F59E0B',
    '#EF4444',
    '#FAFAFA',
  ];

  final String? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _parseColor(color),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
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
}
