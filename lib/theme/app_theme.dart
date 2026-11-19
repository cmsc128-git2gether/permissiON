import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/data_enums.dart';

class AppColors {
  static const brandPink = Color(0xFFFBB4C0); // header and bottom bar
  static const action = Color(0xFF5E57B5);    // main buttons, "+" button
  static const flow = Color(0xFFA83D66);      // filing wizard
  static const heading = Color(0xFF7A1F3D);   // section headings
  static const pageBg = Color.fromARGB(97, 247, 230, 233);    // page background, behind the cards
  static const cardBg = Color.fromRGBO(255, 255, 255, 1);
  static const fieldBg = Color.fromARGB(255, 253, 234, 238);
  static const ink = Color(0xFF1B1B1F);
}

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class StatusColors {
  const StatusColors(this.bg, this.fg);
  final Color bg, fg;

  static StatusColors of(PermitStatus s) => switch (s) {
        PermitStatus.pending => const StatusColors(Color(0xFFFFE8C2), Color(0xFFB26A00)),
        PermitStatus.active => const StatusColors(Color(0xFFD4F0D4), Color(0xFF2E7D32)),
        PermitStatus.completed => const StatusColors(Color(0xFFD0DCF8), Color(0xFF2F4FA8)),
        PermitStatus.denied => const StatusColors(Color(0xFFF3C6CE), Color(0xFFA3243B)),
        PermitStatus.cancelled => const StatusColors(Color(0xFFE3E3E3), Color(0xFF5F5F5F)),
        PermitStatus.overdue => const StatusColors(Color(0xFFFFD2B8), Color(0xFFC03A00)),
      };
  
    ///Solid pills for admin tables (white text on a strong color).
  static StatusColors solid(PermitStatus s) => switch (s) {
        PermitStatus.pending => const StatusColors(Color(0xFFF5A623), Color(0xFF1B1B1F)),
        PermitStatus.active => const StatusColors(Color(0xFF2E7D32), Colors.white),
        PermitStatus.completed => const StatusColors(Color(0xFF2F4FA8), Colors.white),
        PermitStatus.denied => const StatusColors(Color(0xFFFDECEE), Color(0xFFB00020)),
        PermitStatus.cancelled => const StatusColors(Color(0xFF6B6B6B), Colors.white),
        PermitStatus.overdue => const StatusColors(Color(0xFFC03A00), Colors.white),
      };
}

class AppTheme {
  static const sectionHeading = TextStyle(
      fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.heading);

  ///button used inside the "File a New Permit" flow (Next, Confirm).
  static final ButtonStyle flowButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.flow,
    foregroundColor: Colors.white,
    shape: const StadiumBorder(),
    minimumSize: const Size(96, 44),
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.action).copyWith(
      primary: AppColors.action,
      onPrimary: Colors.white,
      secondary: AppColors.flow,
      onSecondary: Colors.white,
      tertiary: AppColors.heading,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.pageBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandPink,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.action, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          minimumSize: const Size(96, 44), // comfortable tap target
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.action,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.brandPink,
        indicatorColor: Colors.white,
      ),
    );
  }

    /// Admin (web) look: raspberry primary, light-pink page, compact controls.
  static ThemeData admin() {
    final base = light();
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.flow,
      onPrimary: Colors.white,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cardBg,
      visualDensity: VisualDensity.compact,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.flow,
          foregroundColor: Colors.white,
          shape: shape,
          minimumSize: const Size(64, 36),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.flow,
          side: const BorderSide(color: AppColors.flow),
          shape: shape,
          minimumSize: const Size(64, 36),
        ),
      ),
    );
  }
}

class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}