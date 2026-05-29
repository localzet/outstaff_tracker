import 'package:flutter_test/flutter_test.dart';
import 'package:outstaff_tracker/core/utils/date_time_formats.dart';

void main() {
  test('formats tracked minutes', () {
    expect(formatDurationMinutes(0), '0m');
    expect(formatDurationMinutes(45), '45m');
    expect(formatDurationMinutes(120), '2h');
    expect(formatDurationMinutes(135), '2h 15m');
  });
}
