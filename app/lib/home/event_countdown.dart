import 'dart:async';

import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

/// Texto tipo "Faltan 3 meses, 20 días y 6 horas" hasta [target].
String formatCountdownToEvent(DateTime target) {
  final now = DateTime.now();
  var remaining = target.difference(now);

  if (remaining.isNegative) {
    final past = now.difference(target);
    if (past.inHours < 36) {
      return '¡Hoy es el gran día!';
    }
    return 'Un recuerdo hermoso';
  }

  final totalDays = remaining.inDays;
  final totalHours = remaining.inHours;
  final totalMinutes = remaining.inMinutes;

  String meses(int n) => n == 1 ? '1 mes' : '$n meses';
  String dias(int n) => n == 1 ? '1 día' : '$n días';
  String horas(int n) => n == 1 ? '1 hora' : '$n horas';
  String minutos(int n) => n == 1 ? '1 minuto' : '$n minutos';

  if (totalDays >= 45) {
    final m = totalDays ~/ 30;
    final d = totalDays % 30;
    final h = totalHours % 24;
    if (d == 0 && h == 0) {
      return 'Faltan ${meses(m)} para el evento';
    }
    if (h == 0) {
      return 'Faltan ${meses(m)}, ${dias(d)} para el evento';
    }
    return 'Faltan ${meses(m)}, ${dias(d)} y ${horas(h)} para el evento';
  }

  if (totalDays >= 1) {
    final h = totalHours % 24;
    if (h == 0) {
      return 'Faltan ${dias(totalDays)} para el evento';
    }
    return 'Faltan ${dias(totalDays)} y ${horas(h)} para el evento';
  }

  if (totalHours >= 1) {
    final m = totalMinutes % 60;
    if (m == 0) {
      return 'Faltan ${horas(totalHours)} para el evento';
    }
    return 'Faltan ${horas(totalHours)} y ${minutos(m)} para el evento';
  }

  return 'Faltan ${minutos(totalMinutes)} para el evento';
}

/// Se redibuja cada minuto para mantener el contador actualizado.
class EventCountdownChip extends StatefulWidget {
  const EventCountdownChip({
    super.key,
    required this.eventDate,
  });

  final DateTime? eventDate;

  @override
  State<EventCountdownChip> createState() => _EventCountdownChipState();
}

class _EventCountdownChipState extends State<EventCountdownChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.eventDate;
    if (d == null) return const SizedBox.shrink();

    final line = formatCountdownToEvent(d);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.95),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
