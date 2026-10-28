import 'package:flutter_test/flutter_test.dart';
import 'package:folio/util/date_text.dart';

void main() {
  test('longDate writes the month in full', () {
    expect(longDate(DateTime(2026, 10, 27)), '27 October 2026');
  });

  test('longDate does not pad a single-digit day', () {
    expect(longDate(DateTime(2026, 3, 1)), '1 March 2026');
  });

  test('shortDate abbreviates the month', () {
    expect(shortDate(DateTime(2026, 12, 31)), '31 Dec 2026');
  });

  test('every month has a name', () {
    for (var month = 1; month <= 12; month++) {
      expect(longDate(DateTime(2026, month)), isNotEmpty);
    }
  });
}
