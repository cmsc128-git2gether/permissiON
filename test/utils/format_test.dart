import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/utils/format.dart';

void main() {
  group('formatDateTime', () {
    test('morning', () {
      expect(formatDateTime(DateTime(2026, 11, 10, 6, 7)), '11/10/2026 6:07 AM');
    });

    test('afternoon', () {
      expect(formatDateTime(DateTime(2026, 10, 10, 18, 30)), '10/10/2026 6:30 PM');
    });

    test('just after midnight shows 12 AM', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 0, 5)), '01/02/2026 12:05 AM');
    });

    test('noon shows 12 PM', () {
      expect(formatDateTime(DateTime(2026, 1, 2, 12, 0)), '01/02/2026 12:00 PM');
    });
  });

  group('formatDate', () {
    test('long month name, no zero padding', () {
      expect(formatDate(DateTime(2026, 10, 10)), 'October 10, 2026');
      expect(formatDate(DateTime(2026, 3, 5)), 'March 5, 2026');
    });
  });
}