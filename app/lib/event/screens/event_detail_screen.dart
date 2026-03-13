import 'package:flutter/material.dart';

/// Pantalla de detalle del evento
/// 
/// Muestra información completa del evento: fecha, lugar,
/// mesas, invitados, y acceso a módulos (matches, chat, galería).
class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Evento'),
      ),
      body: const Center(
        child: Text('Detalle de Evento - Por implementar'),
      ),
    );
  }
}
