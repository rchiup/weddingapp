import 'package:flutter/material.dart';

/// Pantalla de administración del evento
/// 
/// Permite a los administradores gestionar invitados,
/// mesas, permisos, y configuración del evento.
class AdminScreen extends StatelessWidget {
  final String eventId;

  const AdminScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
      ),
      body: const Center(
        child: Text('Pantalla de Administración - Por implementar'),
      ),
    );
  }
}
