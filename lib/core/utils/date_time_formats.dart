import 'package:intl/intl.dart';

abstract final class DateTimeFormats {
  static final date = DateFormat('dd.MM.yyyy');
  static final time = DateFormat.Hm();
  static final month = DateFormat('MM.yyyy');
  static final compactDate = DateFormat('dd.MM.yyyy');
  static final weekday = DateFormat('EE', 'ru');
}

String formatDurationMinutes(int minutes) {
  return formatDurationRu(Duration(minutes: minutes));
}

String formatDurationSeconds(int seconds) {
  return formatSecondsRu(seconds);
}

String formatDurationRu(Duration duration) {
  return formatSecondsRu(duration.inSeconds);
}

String formatSecondsRu(int seconds) {
  final minutes = (seconds / 60).round();
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours == 0) {
    return '$rest мин';
  }

  if (rest == 0) {
    return '$hours ч';
  }

  return '$hours ч $rest мин';
}

String formatMoneyRub(int amountMinor) {
  final amount = amountMinor / 100;
  final formatted = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: amountMinor % 100 == 0 ? 0 : 2,
  ).format(amount);

  return formatted.replaceAll('\u00A0', ' ');
}
