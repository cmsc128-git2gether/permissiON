import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/presentation/admin_permit_history_screen.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/models/data_enums.dart';

// Creates sample permit data without connecting to Firebase.
PermitModel createSamplePermit({
  String name = 'Rowanne Jaudian',
  String id = 'test_permit_001',
}) {
  final now = DateTime(2026, 10, 31, 10, 0);

  return PermitModel(
    id: id,
    userId: 'test_user_001',
    fullName: name,
    roomNum: '101',
    permitType: PermitType.late,
    destination: 'Beans and Bubbles',
    purpose: 'Org meeting',
    emergencyContactPerson: 'Maria Ho',
    emergencyContactNum: '09171234567',
    expectedTimeIn: now.add(const Duration(hours: 5)),
    permitStatus: PermitStatus.pending,
    createdAt: now,
  );
}

void main() {
  group('Admin Permit History Screen', () {
    testWidgets('shows loading indicator while waiting for permits',
        (tester) async {
      final controller = StreamController<List<PermitModel>>();

      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPermitHistoryScreen(
            permitsStream: controller.stream,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays permits received from the stream', (tester) async {
      final controller = StreamController<List<PermitModel>>();

      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPermitHistoryScreen(
            permitsStream: controller.stream,
          ),
        ),
      );

      controller.add([
        createSamplePermit(),
        createSamplePermit(
          name: 'Sansa Stark',
          id: 'test_permit_002',
        ),
      ]);

      await tester.pump();
      await tester.pump();

      expect(find.text('All Permits (2)'), findsOneWidget);
      expect(find.text('Rowanne Jaudian'), findsOneWidget);
      expect(find.text('Sansa Stark'), findsOneWidget);
      expect(find.text('PENDING'), findsNWidgets(2));
    });

    testWidgets('displays empty state when there are no permits',
        (tester) async {
      final controller = StreamController<List<PermitModel>>();

      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPermitHistoryScreen(
            permitsStream: controller.stream,
          ),
        ),
      );

      controller.add([]);

      await tester.pump();
      await tester.pump();

      expect(find.text('No Permit History Yet'), findsOneWidget);
      expect(
        find.text('Submitted permits will appear here.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error message when stream fails', (tester) async {
      final controller = StreamController<List<PermitModel>>();

      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminPermitHistoryScreen(
            permitsStream: controller.stream,
          ),
        ),
      );

      controller.addError(Exception('Test Firestore error'));

      await tester.pump();
      await tester.pump();

      expect(
        find.text('Unable to load permit history.'),
        findsOneWidget,
      );
    });
  });
}
