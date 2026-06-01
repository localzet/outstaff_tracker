import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_screen.dart';

typedef AppTableCellBuilder<T> = Widget Function(BuildContext context, T item);
typedef AppMobileCardBuilder<T> = Widget Function(BuildContext context, T item);

class AppTableColumn<T> {
  const AppTableColumn({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
    this.sortable = true,
    this.width,
  });

  final String key;
  final String label;
  final AppTableCellBuilder<T> cellBuilder;
  final bool numeric;
  final bool sortable;
  final double? width;
}

class ResponsiveDataTable<T> extends StatelessWidget {
  const ResponsiveDataTable({
    required this.items,
    required this.columns,
    required this.mobileCardBuilder,
    this.sortColumnKey,
    this.sortAscending = true,
    this.onSort,
    this.emptyTitle = 'Нет данных',
    this.emptyMessage = 'Измените фильтры или синхронизируйте данные.',
    this.error,
    this.loading = false,
    super.key,
  });

  final List<T> items;
  final List<AppTableColumn<T>> columns;
  final AppMobileCardBuilder<T> mobileCardBuilder;
  final String? sortColumnKey;
  final bool sortAscending;
  final void Function(String key, bool ascending)? onSort;
  final String emptyTitle;
  final String emptyMessage;
  final Object? error;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LinearProgressIndicator();
    }

    if (error != null) {
      return EmptyState(
        title: 'Не удалось загрузить данные',
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

    if (items.isEmpty) {
      return EmptyState(title: emptyTitle, message: emptyMessage);
    }

    final compact = MediaQuery.sizeOf(context).width < 760;
    if (compact) {
      return AppPanel(
        padding: EdgeInsets.zero,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: mobileCardBuilder(context, items[index]),
            );
          },
        ),
      );
    }

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
            dataTextStyle: Theme.of(context).textTheme.bodyMedium,
            headingRowHeight: 42,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 58,
            dividerThickness: 1,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: sortAscending,
            columns: [
              for (final column in columns)
                DataColumn(
                  numeric: column.numeric,
                  onSort: !column.sortable || onSort == null
                      ? null
                      : (_, ascending) => onSort!(column.key, ascending),
                  label: SizedBox(
                    width: column.width,
                    child: Text(
                      column.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    for (final column in columns)
                      DataCell(
                        SizedBox(
                          width: column.width,
                          child: column.cellBuilder(context, item),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  int? get _sortColumnIndex {
    final key = sortColumnKey;
    if (key == null) {
      return null;
    }
    final index = columns.indexWhere((column) => column.key == key);
    return index < 0 ? null : index;
  }
}

class AppFilterBar extends StatelessWidget {
  const AppFilterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
