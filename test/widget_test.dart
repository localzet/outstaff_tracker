import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/utils/date_time_formats.dart';

void main() {
  test('formats tracked minutes', () {
    expect(formatDurationMinutes(0), '0 мин');
    expect(formatDurationMinutes(45), '45 мин');
    expect(formatDurationMinutes(120), '2 ч');
    expect(formatDurationMinutes(135), '2 ч 15 мин');
  });
}
