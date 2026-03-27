import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colores de fondo galería (papel elegante, sin competir con las fotos).
const Color kGalleryBgTop = Color(0xFFF8F5F2);
const Color kGalleryBgBottom = Color(0xFFF3EFEA);

/// Grano / papel muy sutil (sin imágenes externas).
class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final dot = Paint()..color = const Color(0xFF2E343D).withValues(alpha: 0.035);
    final n = (size.width * size.height / 900).clamp(80, 420).toInt();
    for (var i = 0; i < n; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.45 + rnd.nextDouble() * 0.35, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fondo: gradiente suave + textura casi invisible.
class FotosGalleryBackground extends StatelessWidget {
  const FotosGalleryBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGalleryBgTop, kGalleryBgBottom],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _PaperGrainPainter()),
        ),
        child,
      ],
    );
  }
}
