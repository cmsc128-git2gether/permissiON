import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/utils/firestore_utils.dart';

void main() {
    group('parseTimestamp', () {
        test('returns null for null', () {
            expect(parseTimestamp(null), isNull);
        });

        test('converts a Firestore Timestamp', () {
            final date = DateTime(2026, 10, 28, 15, 0);
            final result = parseTimestamp(Timestamp.fromDate(date));
            expect(result, date);
        });

        test('passes a DateTime through unchanged', () {
            final date = DateTime(2026, 10, 28);
            expect(parseTimestamp(date), date);
        });

        test('parses a valid date string', () {
            final result = parseTimestamp('2026-10-28T15:00:00');
            expect(result, DateTime(2026, 10, 28, 15, 0));
        });

        test('returns null for an invalid string', () {
            expect(parseTimestamp('not a date'), isNull);
        });

        test('returns null for an unexpected type', () {
            expect(parseTimestamp(12345), isNull);
            expect(parseTimestamp({'a': 1}), isNull);
        });
    });

    group('toTimestamp', () {
        test('returns null for null', () {
            expect(toTimestamp(null), isNull);
        });

        test('round trip: DateTime -> Timestamp -> DateTime', () {
            final date = DateTime(2026, 10, 28, 15, 30);
            expect(parseTimestamp(toTimestamp(date)), date);
        });
    });
}
