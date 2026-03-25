import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  Uri _googleCalendarUrl({
    required String title,
    required DateTime startLocal,
    required DateTime endLocal,
    String? details,
    String? location,
  }) {
    final startUtc = startLocal.toUtc();
    final endUtc = endLocal.toUtc();
    String fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      final ss = d.second.toString().padLeft(2, '0');
      return '$y$m$day' 'T' '$hh$mm$ss' 'Z';
    }

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${fmt(startUtc)}/${fmt(endUtc)}',
      if ((details ?? '').trim().isNotEmpty) 'details': details!.trim(),
      if ((location ?? '').trim().isNotEmpty) 'location': location!.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<UserContextProvider>();
    final eventName = ctx.eventName ?? 'Evento';
    final date = ctx.eventDate;

    final start = date ?? DateTime.now();
    final end = start.add(const Duration(hours: 4));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '📅 Añadir al calendario',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              eventName,
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              date == null
                  ? 'Fecha no disponible en el evento'
                  : 'Fecha: ${start.day}/${start.month}/${start.year} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.x2),
            CustomButton(
              label: 'Agregar a Google Calendar',
              icon: Icons.open_in_new_rounded,
              backgroundColor: AppColors.joinAccent,
              onPressed: () async {
                final uri = _googleCalendarUrl(
                  title: eventName,
                  startLocal: start,
                  endLocal: end,
                  details: 'Evento creado con Wedding App',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: AppSpacing.x1_5),
            Text(
              'Tip: en iPhone/Apple Calendar puedes abrir Google Calendar y guardarlo, o pedir a los novios el archivo .ics.',
              style: AppTextStyles.subtitle.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

