import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/responsive_data_table.dart';
import '../data/payments_repository.dart';

enum _PaymentFilter { all, expected, overdue, paid, assumedPaid, problematic }

enum _PaymentSortField {
  payoutDate,
  project,
  expectedAmount,
  actualAmount,
  status,
  balance,
}

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  static const routePath = '/payments';

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  _PaymentFilter _filter = _PaymentFilter.all;
  _PaymentSortField _sortField = _PaymentSortField.payoutDate;
  bool _sortAscending = true;
  String? _projectName;
  String _searchText = '';
  DateTimeRange? _dateRange;
  bool _onlyUpcoming = false;
  bool _onlyUnpaidOrOverdue = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(paymentsSnapshotProvider);

    return AppScreen(
      title: 'Выплаты',
      subtitle: 'Ожидаемые, просроченные и полученные выплаты по проектам.',
      expandContent: true,
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
          label: const Text('Считать прошлые оплаченными'),
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

            final projects = data.all
                .map((item) => item.projectName)
                .toSet()
                .toList()
              ..sort();
            final items = _sortedItems(_filteredItems(data));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterBar(
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<_PaymentFilter>(
                        initialValue: _filter,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Статус'),
                        items: [
                          for (final filter in _PaymentFilter.values)
                            DropdownMenuItem(
                              value: filter,
                              child: Text(
                                _filterLabel(filter),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filter = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _projectName,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Проект'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все проекты'),
                          ),
                          for (final project in projects)
                            DropdownMenuItem(
                              value: project,
                              child: Text(
                                project,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _projectName = value),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Поиск',
                          hintText: 'Проект или заметка',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchText = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        _dateRange == null
                            ? 'Период'
                            : '${DateTimeFormats.compactDate.format(_dateRange!.start)} - ${DateTimeFormats.compactDate.format(_dateRange!.end)}',
                      ),
                    ),
                    FilterChip(
                      selected: _onlyUpcoming,
                      label: const Text('Будущие'),
                      onSelected: (value) =>
                          setState(() => _onlyUpcoming = value),
                    ),
                    FilterChip(
                      selected: _onlyUnpaidOrOverdue,
                      label: const Text('Не оплачены'),
                      onSelected: (value) =>
                          setState(() => _onlyUnpaidOrOverdue = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ResponsiveDataTable<PaymentItem>(
                  items: items,
                  columns: _columns(),
                  sortColumnKey: _sortField.name,
                  sortAscending: _sortAscending,
                  onSort: (key, ascending) {
                    setState(() {
                      _sortField = _PaymentSortField.values.firstWhere(
                        (field) => field.name == key,
                        orElse: () => _PaymentSortField.payoutDate,
                      );
                      _sortAscending = ascending;
                    });
                  },
                  emptyTitle: 'Выплат по фильтрам нет',
                  emptyMessage: 'Измените статус, проект, период или поиск.',
                  mobileCardBuilder: (context, item) => _PaymentMobileCard(
                    item: item,
                    onMarkPaid: () => _markPaid(item),
                    onEdit: () => _showEditDialog(item),
                    onCopy: () => _copySummary(item),
                  ),
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

  List<AppTableColumn<PaymentItem>> _columns() {
    return [
      AppTableColumn(
        key: _PaymentSortField.project.name,
        label: 'Проект',
        width: 180,
        cellBuilder: (context, item) => _ProjectCell(item: item),
      ),
      AppTableColumn(
        key: _PaymentSortField.payoutDate.name,
        label: 'Дата выплаты',
        width: 118,
        cellBuilder: (context, item) =>
            Text(DateTimeFormats.date.format(item.payoutDate)),
      ),
      AppTableColumn(
        key: 'period',
        label: 'Период',
        sortable: false,
        width: 150,
        cellBuilder: (context, item) => Text(_periodLabel(item)),
      ),
      AppTableColumn(
        key: 'tracked',
        label: 'Отработано',
        sortable: false,
        width: 115,
        cellBuilder: (context, item) =>
            Text(formatDurationSeconds(item.trackedSeconds)),
      ),
      AppTableColumn(
        key: 'goal',
        label: 'Цель периода',
        sortable: false,
        width: 118,
        cellBuilder: (context, item) =>
            Text(formatDurationSeconds(item.requiredSeconds)),
      ),
      AppTableColumn(
        key: _PaymentSortField.balance.name,
        label: 'Баланс',
        width: 115,
        cellBuilder: (context, item) => Text(_balanceLabel(item)),
      ),
      AppTableColumn(
        key: _PaymentSortField.expectedAmount.name,
        label: 'Ожидается',
        numeric: true,
        width: 112,
        cellBuilder: (context, item) =>
            Text(formatMoneyRub(item.expectedAmountMinor)),
      ),
      AppTableColumn(
        key: _PaymentSortField.actualAmount.name,
        label: 'Получено',
        numeric: true,
        width: 112,
        cellBuilder: (context, item) => Text(
          item.actualAmountMinor == null
              ? '-'
              : formatMoneyRub(item.actualAmountMinor!),
        ),
      ),
      AppTableColumn(
        key: _PaymentSortField.status.name,
        label: 'Статус',
        width: 180,
        cellBuilder: (context, item) => _StatusChip(status: item.status),
      ),
      AppTableColumn(
        key: 'actions',
        label: 'Действия',
        sortable: false,
        width: 224,
        cellBuilder: (context, item) => _PaymentActions(
          item: item,
          onMarkPaid: () => _markPaid(item),
          onEdit: () => _showEditDialog(item),
          onCopy: () => _copySummary(item),
        ),
      ),
    ];
  }

  Future<void> _pickDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _dateRange,
    );
    if (selected != null) {
      setState(() => _dateRange = selected);
    }
  }

  List<PaymentItem> _filteredItems(PaymentsSnapshot snapshot) {
    final byStatus = switch (_filter) {
      _PaymentFilter.all => snapshot.all,
      _PaymentFilter.expected => snapshot.expected,
      _PaymentFilter.overdue => snapshot.overdue,
      _PaymentFilter.paid => snapshot.paid,
      _PaymentFilter.assumedPaid => snapshot.assumedPaid,
      _PaymentFilter.problematic => snapshot.problematic,
    };
    final query = _searchText.trim().toLowerCase();
    final now = DateTime.now();

    return byStatus.where((item) {
      if (_projectName != null && item.projectName != _projectName) {
        return false;
      }
      if (_onlyUpcoming &&
          item.payoutDate.isBefore(DateTime(now.year, now.month, now.day))) {
        return false;
      }
      if (_onlyUnpaidOrOverdue &&
          item.status != PaymentStatus.expected &&
          item.status != PaymentStatus.overdue) {
        return false;
      }
      final range = _dateRange;
      if (range != null &&
          (item.payoutDate.isBefore(range.start) ||
              item.payoutDate.isAfter(range.end))) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return item.projectName.toLowerCase().contains(query) ||
          (item.note ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<PaymentItem> _sortedItems(List<PaymentItem> items) {
    return [...items]..sort((left, right) {
        final result = switch (_sortField) {
          _PaymentSortField.payoutDate =>
            left.payoutDate.compareTo(right.payoutDate),
          _PaymentSortField.project =>
            left.projectName.compareTo(right.projectName),
          _PaymentSortField.expectedAmount =>
            left.expectedAmountMinor.compareTo(right.expectedAmountMinor),
          _PaymentSortField.actualAmount => (left.actualAmountMinor ?? 0)
              .compareTo(right.actualAmountMinor ?? 0),
          _PaymentSortField.status =>
            left.status.index.compareTo(right.status.index),
          _PaymentSortField.balance =>
            left.balanceSeconds.compareTo(right.balanceSeconds),
        };
        return _sortAscending ? result : -result;
      });
  }

  String _filterLabel(_PaymentFilter filter) {
    return switch (filter) {
      _PaymentFilter.all => 'Все',
      _PaymentFilter.expected => 'Ожидаются',
      _PaymentFilter.overdue => 'Просрочены',
      _PaymentFilter.paid => 'Оплачено',
      _PaymentFilter.assumedPaid => 'Предположительно',
      _PaymentFilter.problematic => 'Проблемные',
    };
  }

  Future<void> _markPaid(PaymentItem item) {
    return ref.read(paymentsRepositoryProvider).markPaid(item);
  }

  Future<void> _showEditDialog(PaymentItem item) async {
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

  Future<void> _copySummary(PaymentItem item) async {
    final text = [
      item.projectName,
      'Дата выплаты: ${DateTimeFormats.date.format(item.payoutDate)}',
      'Период: ${_periodLabel(item)}',
      'Отработано: ${formatDurationSeconds(item.trackedSeconds)}',
      'Цель периода: ${formatDurationSeconds(item.requiredSeconds)}',
      'Баланс: ${_balanceLabel(item)}',
      'Ожидается: ${formatMoneyRub(item.expectedAmountMinor)}',
      if (item.actualAmountMinor != null)
        'Получено: ${formatMoneyRub(item.actualAmountMinor!)}',
      'Статус: ${item.status.label}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сводка скопирована')),
      );
    }
  }
}

class _PaymentMobileCard extends StatelessWidget {
  const _PaymentMobileCard({
    required this.item,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onCopy,
  });

  final PaymentItem item;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _ProjectCell(item: item)),
            _StatusChip(status: item.status),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _MiniMetric(
              label: 'Дата',
              value: DateTimeFormats.date.format(item.payoutDate),
            ),
            _MiniMetric(label: 'Период', value: _periodLabel(item)),
            _MiniMetric(
              label: 'Отработано',
              value: formatDurationSeconds(item.trackedSeconds),
            ),
            _MiniMetric(label: 'Баланс', value: _balanceLabel(item)),
            _MiniMetric(
              label: 'Ожидается',
              value: formatMoneyRub(item.expectedAmountMinor),
            ),
            if (item.actualAmountMinor != null)
              _MiniMetric(
                label: 'Получено',
                value: formatMoneyRub(item.actualAmountMinor!),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _PaymentActions(
          item: item,
          onMarkPaid: onMarkPaid,
          onEdit: onEdit,
          onCopy: onCopy,
        ),
      ],
    );
  }
}

class _PaymentActions extends StatelessWidget {
  const _PaymentActions({
    required this.item,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onCopy,
  });

  final PaymentItem item;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (item.status == PaymentStatus.expected ||
            item.status == PaymentStatus.overdue)
          OutlinedButton(
            onPressed: onMarkPaid,
            child: const Text('Оплачено'),
          ),
        IconButton.filledTonal(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Редактировать',
        ),
        IconButton.filledTonal(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
          tooltip: 'Скопировать',
        ),
      ],
    );
  }
}

class _ProjectCell extends StatelessWidget {
  const _ProjectCell({required this.item});

  final PaymentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _parseColor(item.color),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Tooltip(
            message: item.projectName,
            child: Text(item.projectName, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(label: status.label, color: _statusColor(status));
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
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

String _periodLabel(PaymentItem item) {
  return '${DateTimeFormats.compactDate.format(item.periodStart)}–'
      '${DateTimeFormats.compactDate.format(item.periodEnd.subtract(const Duration(days: 1)))}';
}

String _balanceLabel(PaymentItem item) {
  return item.balanceSeconds >= 0
      ? '+${formatDurationSeconds(item.balanceSeconds)}'
      : '-${formatDurationSeconds(item.balanceSeconds.abs())}';
}

Color _statusColor(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.expected => AppColors.accent,
    PaymentStatus.overdue => AppColors.danger,
    PaymentStatus.paid => AppColors.textMuted,
    PaymentStatus.assumedPaid => AppColors.textMuted,
    PaymentStatus.skipped => AppColors.warning,
    PaymentStatus.disputed => AppColors.danger,
  };
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
