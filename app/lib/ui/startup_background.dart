import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fondo full-screen estilo producto tech: gradiente suave + halos de marca.
/// Usar detrás del contenido principal (menú, onboarding, etc.).
class StartupBackground extends StatelessWidget {
  final Widget child;

  const StartupBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF4F2FF),
                AppColors.background,
                Color(0xFFEEF6FF),
              ],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -80,
          child: _glowBlob(
            size: 260,
            color: AppColors.primary.withOpacity(0.14),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -100,
          child: _glowBlob(
            size: 280,
            color: const Color(0xFF6366F1).withOpacity(0.10),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.35,
          right: -40,
          child: _glowBlob(
            size: 120,
            color: AppColors.primary.withOpacity(0.06),
          ),
        ),
        child,
      ],
    );
  }

  static Widget _glowBlob({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 0.65],
          ),
        ),
      ),
    );
  }
}

/// Título de sección tipo dashboard (mayúsculas, tracking).
class StartupSectionLabel extends StatelessWidget {
  final String text;
  final bool denseTop;

  const StartupSectionLabel({super.key, required this.text, this.denseTop = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4,
        bottom: AppSpacing.x1,
        top: denseTop ? 4 : AppSpacing.x2,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.subtitle.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.15,
          color: AppColors.primary.withOpacity(0.55),
        ),
      ),
    );
  }
}
