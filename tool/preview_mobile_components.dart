import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/features/presentation/widgets/empty_state.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/permit_card.dart';
import 'package:permission_app/features/presentation/widgets/step_indicator.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/theme/app_theme.dart';

PermitModel sample(PermitStatus s, {bool late = false}) => PermitModel(
      id: '0680',
      userId: 'u1',
      fullName: 'Name 123',
      roomNum: '20',
      permitType: PermitType.overnight,
      destination: 'Puesto',
      purpose: 'Study',
      emergencyContactPerson: 'Name 1234',
      emergencyContactNum: '0919',
      expectedTimeIn: DateTime(2026, 11, 11, 12, 7),
      createdAt: DateTime(2026, 11, 10, 6, 7),
      permitStatus: s,
      isLateFiling: late,
      lateFilingReason: late ? 'le finished late sorry uwu' : null,
    );

void main() => runApp(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        appBar: AppBar(title: const Text('permissiON')),
        body: ListView(padding: const EdgeInsets.all(16), children: [

          const SizedBox(height: 16),
          for (final s in PermitStatus.values) ...[
            PermitCard(permit: sample(s), actionLabel: 'View/Manage', onAction: () {}),
            const SizedBox(height: 12),
          ],
          PermitCard(permit: sample(PermitStatus.completed), collapsible: true),
          const SizedBox(height: 12),
          PermitCard(permit: sample(PermitStatus.pending, late: true), showStudent: true),
          const SizedBox(height: 12),
          const SizedBox(height: 160, child: EmptyState(message: 'No permits yet')),
          const SizedBox(
              height: 160,
              child: ErrorState(message: 'Could not load permits', onRetry: null)),
        ]),
      ),
    ));