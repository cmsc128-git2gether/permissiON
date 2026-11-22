import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/permit_request.dart';
import 'package:permission_app/features/presentation/permits/permit_wizard_screen.dart';
import 'package:permission_app/router/app_router.dart';
import 'package:permission_app/theme/app_theme.dart';

final _router = createRouter(
  newPermitBuilder: (_) => PermitWizardScreen(
    userId: 'preview-user',
    loadFiler: () async => const PermitFiler(
        surname: 'Dela Cruz', givenName: 'Juan', roomNum: '204', floor: 2),
    createPermit: (request, {lateReason}) async {
      await Future<void>.delayed(const Duration(seconds: 1));
    },
  ),
);

void main() => runApp(MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    ));