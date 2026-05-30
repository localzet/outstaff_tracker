import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../data/payments_repository.dart';

enum _PaymentFilter {
  all,
  expected,
  overdue,
  paid,
  assumedPaid;
}

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  static const routePath = '/payments';

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  _PaymentFilter _filter = _PaymentFilter.all;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(paymentsSnapshotProvider);

    return AppScreen(
      title: 'Выплаты',
      subtitle: 'Ожидаемые, просроченные и полученные выплаты по проектам.',
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await ref
                .read(paymentsRepositoryProvider)
                .markPastPayoutsAssumedPaid();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Прошлые выплаты отмечены как оплаченные'),
                ),
              );
            }
          },
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: const Text('Считать прошлые выплаты оплаченными'),
        ),
      ],
      children: [
        snapshot.when(
          data: (data) {
            if (data.all.isEmpty) {
              return const EmptyState(
                title: 'Выплат пока нет',
                message:
                    'Настройте правила выплат в проектах и синхронизируйте время.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPanel(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in _PaymentFilter.values)
                        ChoiceChip(
                          selected: _filter == filter,
                          label: Text(_filterLabel(filter)),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PaymentSection(
                  title: _filterLabel(_filter),
                  items: _filteredItems(data),
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => CopyableErrorState(
            title: 'Не удалось загрузить выплаты',
            error: error,
          ),
        ),
      ],
    );
  }

  List<PaymentItem> _filteredItems(PaymentsSnapshot snapshot) {
    return switch (_filter) {
      _PaymentFilter.all => snapshot.all,
      _PaymentFilter.expected => snapshot.expected,
      _PaymentFilter.overdue => snapshot.overdue,
      _PaymentFilter.paid => snapshot.paid,
      _PaymentFilter.assumedPaid => snapshot.assumedPaid,
    };
  }

  String _filterLabel(_PaymentFilter filter) {
    return switch (filter) {
      _PaymentFilter.all => 'Все',
      _PaymentFilter.expected => 'Ожидаются',
      _PaymentFilter.overdue => 'Просрочены',
      _PaymentFilter.paid => 'Оплачено',
      _PaymentFilter.assumedPaid => 'Предположительно оплачено',
    };
  }
}

class PaymentSection extends StatelessWidget {
  const PaymentSection({required this.title, required this.items, super.key});

  final String title;
  final List<PaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text('Нет записей.', style: Theme.of(context).textTheme.bodyMedium)
          else
            for (final item in items) ...[
              PaymentTile(item: item),
              if (item != items.last) const Divider(height: 20),
            ],
        ],
      ),
    );
  }
}

class PaymentTile extends ConsumerWidget {
  const PaymentTile({required this.item, super.key});

  final PaymentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _parseColor(item.color),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.projectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Дата выплаты: ${DateTimeFormats.date.format(item.payoutDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Период: ${DateTimeFormats.date.format(item.periodStart)} - '
                '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Отработано: ${formatDurationSeconds(item.trackedSeconds)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Цель периода: ${formatDurationSeconds(item.requiredSeconds)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                item.balanceSeconds >= 0
                    ? 'Запас: +${formatDurationSeconds(item.balanceSeconds)}'
                    : 'Осталось: ${formatDurationSeconds(item.balanceSeconds.abs())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Ожидается: ${formatMoneyRub(item.expectedAmountMinor)}'
                '${item.actualAmountMinor == null ? '' : ' · получено: ${formatMoneyRub(item.actualAmountMinor!)}'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                item.status.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.note != null && item.note!.isNotEmpty)
                Text(item.note!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            if (item.status == PaymentStatus.expected ||
                item.status == PaymentStatus.overdue)
              OutlinedButton(
                onPressed: () async {
                  await ref.read(paymentsRepositoryProvider).markPaid(item);
                },
                child: const Text('Оплачено'),
              ),
            IconButton.filledTonal(
              onPressed: () => _showEditDialog(context, ref),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
            IconButton.filledTonal(
              onPressed: () => _copySummary(context),
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Скопировать',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController(
      text: ((item.actualAmountMinor ?? item.expectedAmountMinor) / 100)
          .toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: item.note ?? '');
    var status = item.status;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактировать выплату'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PaymentStatus>(
                initialValue: status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Статус'),
                items: [
                  for (final value in PaymentStatus.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Сумма, ₽'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Заметка'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      amountController.dispose();
      noteController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    await ref.read(paymentsRepositoryProvider).updatePayment(
          item,
          status: status,
          actualAmountMinor: amount == null ? null : (amount * 100).round(),
          paidAt: status == PaymentStatus.paid ||
                  status == PaymentStatus.assumedPaid
              ? DateTime.now()
              : null,
          note: noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        );
    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _copySummary(BuildContext context) async {
    final text = [
      item.projectName,
      'Дата выплаты: ${DateTimeFormats.date.format(item.payoutDate)}',
      'Период: ${DateTimeFormats.date.format(item.periodStart)} - '
          '${DateTimeFormats.date.format(item.periodEnd.subtract(const Duration(days: 1)))}',
      'Отработано: ${formatDurationSeconds(item.trackedSeconds)}',
      'Цель периода: ${formatDurationSeconds(item.requiredSeconds)}',
      item.balanceSeconds >= 0
          ? 'Запас: +${formatDurationSeconds(item.balanceSeconds)}'
          : 'Осталось: ${formatDurationSeconds(item.balanceSeconds.abs())}',
      'Ожидается: ${formatMoneyRub(item.expectedAmountMinor)}',
      if (item.actualAmountMinor != null)
        'Получено: ${formatMoneyRub(item.actualAmountMinor!)}',
      'Статус: ${item.status.label}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сводка скопирована')),
      );
    }
  }
}

class CopyableErrorState extends StatelessWidget {
  const CopyableErrorState({
    required this.title,
    required this.error,
    super.key,
  });

  final String title;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      message: error.toString(),
      action: OutlinedButton.icon(
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
