import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/data_enums.dart';

void main() {
    group('AccessLevel', () {
        test('parses known database strings', () {
            expect(AccessLevel.fromString('end_user'), AccessLevel.endUser);
            expect(AccessLevel.fromString('admin'), AccessLevel.admin);
        });

        test('throws on unknown string', () {
            expect(() => AccessLevel.fromString('user'), throwsArgumentError);
        });

        test('is case-sensitive', () {
            expect(() => AccessLevel.fromString('END_USER'), throwsArgumentError);
            expect(() => AccessLevel.fromString('ADMIN'), throwsArgumentError);
        });

        test('round trip: value -> fromString returns the same case', () {
            for (final level in AccessLevel.values) {
                expect(AccessLevel.fromString(level.value), level);
            }
        });
  });

    group('PermitStatus', () {
        test('round trip for every case', () {
            for (final s in PermitStatus.values) {
                expect(PermitStatus.fromString(s.value), s);
            }
        });

        test('throws on empty string', () {
            expect(() => PermitStatus.fromString(''), throwsArgumentError);
        });
  });

    group('PermitType', () {
        test('round trip for every case', () {
            for (final t in PermitType.values) {
            expect(PermitType.fromString(t.value), t);
            }
        });
    });

    group('QrStatus', () {
        test('round trip for every case', () {
            for (final s in QrStatus.values) {
            expect(QrStatus.fromString(s.value), s);
            }
        });
    });
}