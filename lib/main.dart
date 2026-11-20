import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' as m;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/auth_notifier.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'app/router.dart';
import 'features/authentication/data/auth_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepository = AuthRepository();
  final auth = AuthNotifier(authRepository);
  final router = createRouter(auth, authRepository);

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => m.Theme(
        data: m.ThemeData.light(),
        child: m.Localizations(
          locale: const Locale('en', 'US'),
          delegates: const [
            m.DefaultMaterialLocalizations.delegate,
            m.DefaultWidgetsLocalizations.delegate,
          ],
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
