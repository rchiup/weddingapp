import 'package:flutter/material.dart';

import 'app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  /// Sombra más marcada + borde suave (cards del menú principal, etc.)
  final bool elevated;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.card,
        boxShadow: elevated ? AppShadows.lift : AppShadows.soft,
        border: Border.all(
          color: elevated ? AppColors.primary.withOpacity(0.08) : AppColors.border,
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

