import 'package:flutter/material.dart';

import 'app_theme.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  /// Si no es null, sustituye [AppColors.primary] (p. ej. pantalla join Lovable).
  final Color? backgroundColor;
  /// Bordes totalmente redondeados (p. ej. CTA “Subir foto” en galería Lovable).
  final bool usePillShape;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
    this.usePillShape = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading != widget.loading) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final baseColor = widget.backgroundColor ?? AppColors.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? baseColor : baseColor.withOpacity(0.35),
          borderRadius: widget.usePillShape ? AppRadii.pill : AppRadii.button,
          boxShadow: _pressed ? [] : AppShadows.soft,
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.85,
          child: widget.loading
              ? SizedBox(
                  key: const ValueKey<String>('custom_btn_loading'),
                  width: 18,
                  height: 18,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  key: const ValueKey<String>('custom_btn_label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

