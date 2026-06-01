import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../data/local_tracking_repository.dart';
import '../data/local_tracking_sync_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  static const routePath = '/timer';

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  TimerProjectOption? _project;
  TimerActivityOption? _activity;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _completedMode = false;
  bool _busy = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = ref.watch(runningLocalTimerProvider);
    final active = ref.watch(activeTimeEntryProvider);
    final queue = ref.watch(localTrackingQueueProvider);
    final pendingCount = ref.watch(pendingLocalEntriesCountProvider);

    return AppScreen(
      title: 'Таймер',
      subtitle: 'Локальный учёт времени с безопасной отправкой в Kimai.',
      actions: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _syncPending,
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: const Text('Синхронизировать ожидающие записи'),
        ),
      ],
      children: [
        const OfflineSafetyBanner(),
        pendingCount.when(
          data: (count) => PendingSyncPanel(count: count),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Очередь недоступна',
            message: error.toString(),
          ),
        ),
        running.when(
          data: (entry) {
            if (entry != null) {
              return RunningTimerPanel(
                entry: entry,
                busy: _busy,
                onStop: _stopTimer,
              );
            }

            return active.when(
              data: (activeEntry) => activeEntry == null
                  ? StartTimerPanel(
                      busy: _busy,
                      selectedProject: _project,
                      selectedActivity: _activity,
                      descriptionController: _descriptionController,
                      tagsController: _tagsController,
                      startAt: _startAt,
                      endAt: _endAt,
                      completedMode: _completedMode,
                      onProjectChanged: (value) {
                        setState(() {
                          _project = value;
                          _activity = null;
                        });
                      },
                      onActivityChanged: (value) =>
                          setState(() => _activity = value),
                      onCompletedModeChanged: (value) =>
                          setState(() => _completedMode = value),
                      onStartAtChanged: (value) =>
                          setState(() => _startAt = value),
                      onEndAtChanged: (value) => setState(() => _endAt = value),
                      onStart: _startTimer,
                    )
                  : ActiveRemoteTimerPanel(entry: activeEntry),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => EmptyState(
                title: 'Таймер недоступен',
                message: error.toString(),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Таймер недоступен',
            message: error.toString(),
          ),
        ),
        queue.when(
          data: (items) => SyncQueuePanel(items: items),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => EmptyState(
            title: 'Очередь синхронизации недоступна',
            message: error.toString(),
          ),
        ),
      ],
    );
  }

  Future<void> _startTimer() async {
    final project = _project;
    if (project == null) {
      _showSnack('Выберите проект.');
      return;
    }

    setState(() => _busy = true);
    try {
      final startAt = _startAt;
      final endAt = _endAt;
      if (await _needsFutureConfirmation(startAt)) {
        final confirmed = await _confirmFutureDate();
        if (!confirmed) {
          return;
        }
      }
      if (_completedMode) {
        if (startAt == null || endAt == null) {
          _showSnack('Укажите начало и окончание.');
          return;
        }
        if (!endAt.isAfter(startAt)) {
          _showSnack('Окончание должно быть позже начала.');
          return;
        }
        await ref.read(localTrackingRepositoryProvider).addCompletedEntry(
              appProjectId: project.appProjectId,
              kimaiProjectId: project.kimaiProjectId,
              activityId: _activity?.id,
              activityName: _activity?.name,
              description: _descriptionController.text,
              tags: _tagsController.text,
              beginAt: startAt,
              endAt: endAt,
            );
        unawaited(_syncPending());
      } else {
        await ref.read(localTrackingRepositoryProvider).startTimer(
              appProjectId: project.appProjectId,
              kimaiProjectId: project.kimaiProjectId,
              activityId: _activity?.id,
              activityName: _activity?.name,
              description: _descriptionController.text,
              tags: _tagsController.text,
              beginAt: startAt,
            );
      }
      _descriptionController.clear();
      _tagsController.clear();
      setState(() {
        _activity = null;
        _startAt = null;
        _endAt = null;
      });
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _needsFutureConfirmation(DateTime? value) async {
    if (value == null) {
      return false;
    }

    return value.isAfter(DateTime.now().add(const Duration(days: 1)));
  }

  Future<bool> _confirmFutureDate() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дата в будущем'),
        content: const Text(
          'Начало записи находится больше чем на сутки в будущем. Создать запись?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _stopTimer() async {
    setState(() => _busy = true);
    try {
      await ref.read(localTrackingRepositoryProvider).stopRunningTimer();
      unawaited(_syncPending());
    } catch (error) {
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _syncPending() async {
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(localTrackingSyncServiceProvider).syncPendingEntries();
      _showSnack(
        'Синхронизация: отправлено ${result.synced}, ошибок ${result.failed}, конфликтов ${result.conflicts}.',
      );
    } catch (error) {
      _showSnack(
        'Нет подключения. Записи сохраняются на устройстве и будут отправлены позже.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class OfflineSafetyBanner extends StatelessWidget {
  const OfflineSafetyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.save_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Локальные записи сохраняются на устройстве. Если Kimai недоступен, они останутся в очереди и будут отправлены позже.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class PendingSyncPanel extends StatelessWidget {
  const PendingSyncPanel({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            'Ожидает отправки: $count',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class StartTimerPanel extends ConsumerWidget {
  const StartTimerPanel({
    required this.busy,
    required this.selectedProject,
    required this.selectedActivity,
    required this.descriptionController,
    required this.tagsController,
    required this.startAt,
    required this.endAt,
    required this.completedMode,
    required this.onProjectChanged,
    required this.onActivityChanged,
    required this.onCompletedModeChanged,
    required this.onStartAtChanged,
    required this.onEndAtChanged,
    required this.onStart,
    super.key,
  });

  final bool busy;
  final TimerProjectOption? selectedProject;
  final TimerActivityOption? selectedActivity;
  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool completedMode;
  final ValueChanged<TimerProjectOption?> onProjectChanged;
  final ValueChanged<TimerActivityOption?> onActivityChanged;
  final ValueChanged<bool> onCompletedModeChanged;
  final ValueChanged<DateTime?> onStartAtChanged;
  final ValueChanged<DateTime?> onEndAtChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(_timerProjectsProvider);
    final activities = selectedProject == null
        ? const AsyncValue<List<TimerActivityOption>>.data([])
        : ref.watch(_timerActivitiesProvider(selectedProject!.kimaiProjectId));

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Новая запись', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.play_arrow_rounded),
                label: Text('Запустить'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.add_task_rounded),
                label: Text('Готовая запись'),
              ),
            ],
            selected: {completedMode},
            onSelectionChanged:
                busy ? null : (values) => onCompletedModeChanged(values.single),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: projects.when(
                  data: (items) => DropdownButtonFormField<TimerProjectOption>(
                    initialValue: selectedProject,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Проект'),
                    items: [
                      for (final item in items)
                        DropdownMenuItem(value: item, child: Text(item.name)),
                    ],
                    onChanged: busy ? null : onProjectChanged,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text(error.toString()),
                ),
              ),
              SizedBox(
                width: 280,
                child: activities.when(
                  data: (items) =>
                      DropdownButtonFormField<TimerActivityOption?>(
                    initialValue: selectedActivity,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Активность'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Без активности'),
                      ),
                      for (final item in items)
                        DropdownMenuItem(value: item, child: Text(item.name)),
                    ],
                    onChanged: busy ? null : onActivityChanged,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text(
                    'Ошибка активностей: $error',
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: descriptionController,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: tagsController,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Теги'),
                ),
              ),
              _DateTimeButton(
                label: 'Начало',
                value: startAt,
                enabled: !busy,
                onChanged: onStartAtChanged,
              ),
              if (completedMode)
                _DateTimeButton(
                  label: 'Окончание',
                  value: endAt,
                  enabled: !busy,
                  onChanged: onEndAtChanged,
                ),
              FilledButton.icon(
                onPressed: busy ? null : onStart,
                icon: Icon(
                  completedMode
                      ? Icons.add_task_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(completedMode ? 'Добавить' : 'Старт'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : '$label: ${DateTimeFormats.date.format(value!.toLocal())} '
            '${DateTimeFormats.time.format(value!.toLocal())}';

    return OutlinedButton.icon(
      onPressed: enabled ? () => _pick(context) : null,
      icon: const Icon(Icons.event_rounded, size: 18),
      label: Text(text),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final initial = value?.toLocal() ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return;
    }

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class RunningTimerPanel extends StatefulWidget {
  const RunningTimerPanel({
    required this.entry,
    required this.busy,
    required this.onStop,
    super.key,
  });

  final LocalTimeEntry entry;
  final bool busy;
  final VoidCallback onStop;

  @override
  State<RunningTimerPanel> createState() => _RunningTimerPanelState();
}

class _RunningTimerPanelState extends State<RunningTimerPanel> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds =
        DateTime.now().toUtc().difference(widget.entry.beginAt).inSeconds;

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
                  'Таймер запущен',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Начало: ${DateTimeFormats.date.format(widget.entry.beginAt.toLocal())} '
                  '${DateTimeFormats.time.format(widget.entry.beginAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  formatDurationSeconds(seconds < 0 ? 0 : seconds),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: widget.busy ? null : widget.onStop,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text('Стоп'),
          ),
        ],
      ),
    );
  }
}

class ActiveRemoteTimerPanel extends StatefulWidget {
  const ActiveRemoteTimerPanel({required this.entry, super.key});

  final ActiveTimeEntry entry;

  @override
  State<ActiveRemoteTimerPanel> createState() => _ActiveRemoteTimerPanelState();
}

class _ActiveRemoteTimerPanelState extends State<ActiveRemoteTimerPanel> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds =
        DateTime.now().toUtc().difference(widget.entry.beginAt).inSeconds;
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
                  widget.entry.projectName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((widget.entry.activityName ?? '').isNotEmpty)
                  Text(
                    widget.entry.activityName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Активная запись Kimai с ${DateTimeFormats.date.format(widget.entry.beginAt.toLocal())} '
                  '${DateTimeFormats.time.format(widget.entry.beginAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  formatDurationSeconds(durationSeconds),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SyncQueuePanel extends ConsumerWidget {
  const SyncQueuePanel({required this.items, super.key});

  final List<LocalTimeEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'Очередь синхронизации пуста',
        message: 'Локальные записи появятся здесь после остановки таймера.',
      );
    }

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Очередь синхронизации',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            LocalQueueRow(entry: item),
            if (item != items.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class LocalQueueRow extends ConsumerWidget {
  const LocalQueueRow({required this.entry, super.key});

  final LocalTimeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = LocalTimeEntryStatus.fromStorage(entry.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${DateTimeFormats.date.format(entry.beginAt.toLocal())} '
              '${DateTimeFormats.time.format(entry.beginAt.toLocal())}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _StatusChip(status: status),
            Text(formatDurationSeconds(entry.durationSeconds)),
            Text('Попыток: ${entry.syncAttempts}'),
          ],
        ),
        if ((entry.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            entry.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if ((entry.tags ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Теги: ${entry.tags!}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if ((entry.lastSyncError ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          SelectableText(
            entry.lastSyncError!,
            style: const TextStyle(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(localTrackingRepositoryProvider).retry(entry.id),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
            ),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(localTrackingRepositoryProvider)
                  .markIgnored(entry.id),
              icon: const Icon(Icons.visibility_off_rounded, size: 18),
              label: const Text('Игнорировать'),
            ),
            OutlinedButton.icon(
              onPressed: () => Clipboard.setData(
                ClipboardData(text: entry.lastSyncError ?? ''),
              ),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Копировать ошибку'),
            ),
            OutlinedButton.icon(
              onPressed: () => _editEntry(context, ref),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Изменить'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editEntry(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: entry.description ?? '');
    final tagsController = TextEditingController(text: entry.tags ?? '');
    final result = await showDialog<({String description, String tags})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить описание'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(labelText: 'Теги'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              (
                description: controller.text,
                tags: tagsController.text,
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    tagsController.dispose();

    if (result == null) {
      return;
    }

    await ref.read(localTrackingRepositoryProvider).updateBeforeRetry(
          id: entry.id,
          activityId: entry.activityId,
          activityName: entry.activityName,
          description: result.description,
          tags: result.tags,
        );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LocalTimeEntryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LocalTimeEntryStatus.synced => AppColors.accent,
      LocalTimeEntryStatus.syncFailed => AppColors.danger,
      LocalTimeEntryStatus.conflict => AppColors.warning,
      _ => AppColors.warning,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(status.label, style: TextStyle(color: color)),
      ),
    );
  }
}

final _timerProjectsProvider =
    FutureProvider.autoDispose<List<TimerProjectOption>>((ref) {
  return ref.watch(localTrackingRepositoryProvider).getProjectOptions();
});

final _timerActivitiesProvider = FutureProvider.autoDispose
    .family<List<TimerActivityOption>, int>((ref, kimaiProjectId) {
  return ref
      .watch(localTrackingRepositoryProvider)
      .getActivityOptions(kimaiProjectId);
});
