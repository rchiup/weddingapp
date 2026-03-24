import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fondo suave tipo invitación / producto boda.
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
                AppColors.blush,
                AppColors.background,
                Color(0xFFF5EDE8),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: _glowBlob(
            size: 240,
            color: AppColors.primary.withOpacity(0.10),
          ),
        ),
        Positioned(
          bottom: 30,
          left: -90,
          child: _glowBlob(
            size: 260,
            color: AppColors.accentHeaderEnd.withOpacity(0.12),
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

/// Etiqueta de sección discreta.
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
          letterSpacing: 1.1,
          color: AppColors.primary.withOpacity(0.55),
        ),
      ),
    );
  }
}
