import 'package:intl/intl.dart';

abstract final class DateTimeFormats {
  static final date = DateFormat.yMMMd();
  static final time = DateFormat.Hm();
  static final month = DateFormat.yMMMM();
  static final compactDate = DateFormat('yyyy-MM-dd');
  static final weekday = DateFormat.E();
}

String formatDurationMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours == 0) {
    return '${rest}m';
  }

  if (rest == 0) {
    return '${hours}h';
  }

  return '${hours}h ${rest}m';
}

String formatDurationSeconds(int seconds) {
  return formatDurationMinutes((seconds / 60).round());
}
