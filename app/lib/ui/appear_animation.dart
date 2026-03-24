import 'package:flutter/material.dart';

/// Entrada suave tipo “pop” (escala + opacidad), con retardo por índice.
class StaggerAppear extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggerAppear({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggerAppear> createState() => _StaggerAppearState();
}

class _StaggerAppearState extends State<StaggerAppear> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    final delayMs = 45 * (widget.index.clamp(0, 14));
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
