import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta visual para invitacion de matrimonio: sobria, suave y elegante.
class AppColors {
  static const primary = Color(0xFF7E8E74);
  static const primaryDark = Color(0xFF4E5D4B);
  /// Fondo general (menú, etc.)
  static const background = Color(0xFFF8F5F2);
  /// Fondo pantalla unión evento.
  static const joinLanding = Color(0xFFF8F5F2);
  /// Fondo detrás del menú de módulos.
  static const menuBackground = Color(0xFFF8F5F2);
  /// CTA / acento secundario.
  static const joinAccent = Color(0xFFB8A77E);
  static const blush = Color(0xFFFDFBF8);
  static const textPrimary = Color(0xFF2E343D);
  static const textMuted = Color(0xFF6A7482);
  static const card = Colors.white;
  static const border = Color(0xFFE8E0D8);
  /// Cabecera menú: oliva suave a beige.
  static const accentHeaderStart = Color(0xFF798B76);
  static const accentHeaderEnd = Color(0xFFC7B79B);
  static const gridIconTint = Color(0xFF70828A);
  /// Galería fotos — crema casi blanco (~#FDFBFB, referencia Lovable)
  static const galleryBackground = Color(0xFFFDFBFB);
  /// Botón “Subir foto” en galería (~#C06070)
  static const galleryUpload = Color(0xFFC06070);
  /// Vista fullscreen foto: marrón cálido (~#2D2621, Lovable)
  static const darkViewerBg = Color(0xFF2D2621);
  /// Campo comentario sobre fondo oscuro
  static const fullscreenInputFill = Color(0xFF3D3530);
  /// Texto secundario sobre fondo oscuro (subtítulos, hints)
  static const viewerTextMuted = Color(0xFFB8B0A8);
}

class AppRadii {
  static const card = BorderRadius.all(Radius.circular(24));
  /// Esquinas solo-imagen en grilla de fotos
  static const galleryTile = BorderRadius.all(Radius.circular(18));
  static const button = BorderRadius.all(Radius.circular(16));
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
    return GoogleFonts.latoTextTheme(b).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }

  /// Títulos de marca / evento (serif).
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get title => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitle => GoogleFonts.lato(
        fontSize: 14,
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
