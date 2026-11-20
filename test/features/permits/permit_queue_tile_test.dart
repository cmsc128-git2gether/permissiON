import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/admin/permit_queue_tile.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/models/permit_model.dart';

PermitModel _permit({bool late = false, String? reason}) => PermitModel(
  id: 'p1',
  userId: 'u1',
  surname: 'De Guzman',
  givenName: 'Mikaela',
  roomNum: '13',
  permitType: PermitType.late,
  destination: 'SM City',
  purpose: 'Buy materials',
  emergencyContactPerson: 'Mom',
  emergencyContactNum: '09124521673',
  expectedTimeIn: DateTime(2026, 11, 3, 22, 45),
  createdAt: DateTime(2026, 11, 3, 18, 7),
  isLateFiling: late,
  lateFilingReason: reason,
);

Widget _wrap(PermitModel p, {VoidCallback? onTap}) => MaterialApp(
  home: Scaffold(
    body: PermitQueueTile(item: p, onTap: onTap ?? () {}),
  ),
);

void main() {
  group('lateFilingReasonOrDefault', () {
    test('returns the trimmed reason', () {
      expect(
        _permit(late: true, reason: '  Meeting  ').lateFilingReasonOrDefault,
        'Meeting',
      );
    });

    for (final r in [null, '', '   ']) {
      test('falls back for ${r == null ? 'null' : "'$r'"}', () {
        expect(
          _permit(late: true, reason: r).lateFilingReasonOrDefault,
          'No reason given',
        );
      });
    }
  });

  group('PermitQueueTile', () {
    testWidgets('late filing: shows chip and reason', (t) async {
      await t.pumpWidget(_wrap(_permit(late: true, reason: 'Meeting')));

      expect(find.text('Late filing'), findsOneWidget);
      expect(find.text('Meeting'), findsOneWidget);
    });

    testWidgets('late filing without reason: shows fallback', (t) async {
      await t.pumpWidget(_wrap(_permit(late: true)));

      expect(find.text('No reason given'), findsOneWidget);
    });

    testWidgets('late filing: tile is highlighted', (t) async {
      await t.pumpWidget(_wrap(_permit(late: true)));

      final tile = t.widget<ListTile>(find.byType(ListTile));
      expect(tile.tileColor, isNotNull);
    });

    testWidgets('on-time: no chip, reason or highlight', (t) async {
      await t.pumpWidget(_wrap(_permit()));

      expect(find.text('Late filing'), findsNothing);
      expect(find.text('No reason given'), findsNothing);
      expect(t.widget<ListTile>(find.byType(ListTile)).tileColor, isNull);
    });

    testWidgets('shows name and room', (t) async {
      await t.pumpWidget(_wrap(_permit()));

      expect(find.text('De Guzman, Mikaela'), findsOneWidget);
      expect(find.text('Room 13'), findsOneWidget);
    });

    testWidgets('tap calls onTap', (t) async {
      var tapped = false;
      await t.pumpWidget(_wrap(_permit(), onTap: () => tapped = true));

      await t.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });
}
