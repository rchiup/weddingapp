import 'package:flutter/material.dart';

/// Pantalla de lista de eventos
/// 
/// Muestra todos los eventos de matrimonio a los que
/// el usuario tiene acceso (como invitado o organizador).
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Eventos'),
      ),
      body: const Center(
        child: Text('Lista de Eventos - Por implementar'),
      ),
    );
  }
}
