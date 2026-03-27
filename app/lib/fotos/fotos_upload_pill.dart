import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';

/// Botón pill “Subir recuerdo” con hover suave (web/desktop).
class FotosUploadPill extends StatefulWidget {
  const FotosUploadPill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<FotosUploadPill> createState() => _FotosUploadPillState();
}

class _FotosUploadPillState extends State<FotosUploadPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.06),
                blurRadius: _hover ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: '+ Subir recuerdo',
                icon: Icons.photo_camera_outlined,
                backgroundColor: AppColors.galleryUpload,
                usePillShape: true,
                onPressed: widget.onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
