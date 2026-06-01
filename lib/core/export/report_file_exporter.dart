import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

class ExportSheet {
  const ExportSheet({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<List<Object?>> rows;
}

Uint8List buildCsvBytes(List<List<Object?>> rows, {String delimiter = ';'}) {
  final body = rows
      .map(
        (row) =>
            row.map((cell) => _escapeCsvCell(cell, delimiter)).join(delimiter),
      )
      .join('\r\n');

  return Uint8List.fromList(utf8.encode('\uFEFF$body'));
}

Uint8List buildXlsxBytes(List<ExportSheet> sheets) {
  final workbook = Excel.createExcel();
  var first = true;

  for (final source in sheets) {
    final name = _sanitizeSheetName(source.name);
    final sheet = workbook[name];
    if (first) {
      final defaultSheet = workbook.getDefaultSheet();
      if (defaultSheet != null && defaultSheet != name) {
        workbook.delete(defaultSheet);
      }
      first = false;
    }

    _writeSheet(sheet, source.rows);
  }

  final bytes = workbook.encode();
  if (bytes == null || bytes.isEmpty) {
    throw StateError('XLSX export generated empty data.');
  }

  return Uint8List.fromList(bytes);
}

void _writeSheet(Sheet sheet, List<List<Object?>> rows) {
  final headerStyle = CellStyle(bold: true);
  final widths = <int, int>{};

  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
      final value = row[columnIndex];
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
      );
      cell.value = _toCellValue(value);
      if (rowIndex == 0) {
        cell.cellStyle = headerStyle;
      }
      widths[columnIndex] = [
        widths[columnIndex] ?? 0,
        value?.toString().length ?? 0,
      ].reduce((left, right) => left > right ? left : right);
    }
  }

  for (final entry in widths.entries) {
    sheet.setColumnWidth(entry.key, entry.value.clamp(10, 42).toDouble());
  }
}

CellValue _toCellValue(Object? value) {
  if (value == null) {
    return TextCellValue('');
  }
  if (value is int) {
    return IntCellValue(value);
  }
  if (value is double) {
    return DoubleCellValue(value);
  }
  if (value is num) {
    return DoubleCellValue(value.toDouble());
  }
  if (value is DateTime) {
    final local = value.toLocal();
    return DateTimeCellValue(
      year: local.year,
      month: local.month,
      day: local.day,
      hour: local.hour,
      minute: local.minute,
      second: local.second,
    );
  }

  return TextCellValue(value.toString());
}

String _escapeCsvCell(Object? value, String delimiter) {
  final raw = value?.toString() ?? '';
  final escaped = raw.replaceAll('"', '""');
  if (escaped.contains(delimiter) ||
      escaped.contains('\n') ||
      escaped.contains('\r') ||
      escaped.contains('"')) {
    return '"$escaped"';
  }

  return escaped;
}

String _sanitizeSheetName(String value) {
  final sanitized = value.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();

  return sanitized.isEmpty
      ? 'Sheet'
      : sanitized.substring(0, sanitized.length.clamp(0, 31));
}
