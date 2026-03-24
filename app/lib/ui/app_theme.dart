import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta estilo “boda” (referencia Lovable): terracota/rosa suave + blush.
class AppColors {
  static const primary = Color(0xFFC45C5C);
  static const primaryDark = Color(0xFF9A4545);
  static const background = Color(0xFFFDF8F6);
  static const blush = Color(0xFFFFF5F3);
  static const textPrimary = Color(0xFF2D2424);
  static const textMuted = Color(0xFF7A6F6F);
  static const card = Colors.white;
  static const border = Color(0xFFF0E8E6);
  static const accentHeaderStart = Color(0xFFE8A598);
  static const accentHeaderEnd = Color(0xFFD4A574);
  static const gridIconTint = Color(0xFFB85A5A);
  static const darkViewerBg = Color(0xFF1E1A19);
}

class AppRadii {
  static const card = BorderRadius.all(Radius.circular(18));
  static const button = BorderRadius.all(Radius.circular(14));
  static const pill = BorderRadius.all(Radius.circular(999));
}

class AppShadows {
  static final soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static final lift = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.12),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}

class AppSpacing {
  static const double x1 = 8;
  static const double x1_5 = 12;
  static const double x2 = 16;
  static const double x3 = 24;
}

class AppTextStyles {
  static TextTheme textTheme([TextTheme? base]) {
    final b = base ?? const TextTheme();
    return GoogleFonts.interTextTheme(b).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }

  /// Títulos de marca / evento (serif).
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: AppTextStyles.textTheme(base.textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.button,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
