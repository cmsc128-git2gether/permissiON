import 'package:material_ui/material_ui.dart';
import 'package:permission_app/router/app_router.dart'; //only uses app_router not router itself
import 'package:permission_app/theme/app_theme.dart';

final _router = createRouter();

void main() => runApp(MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    ));