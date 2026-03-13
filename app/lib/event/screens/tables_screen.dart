import 'package:flutter/material.dart';

/// Pantalla de mesas del evento
/// 
/// Muestra la distribución de mesas y los invitados
/// asignados a cada mesa. Permite visualizar el layout
/// del salón de eventos.
class TablesScreen extends StatelessWidget {
  final String eventId;

  const TablesScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: const Center(
        child: Text('Pantalla de Mesas - Por implementar'),
      ),
    );
  }
}
