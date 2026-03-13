import 'package:flutter/material.dart';

/// Pantalla de lista de conversaciones
/// 
/// Muestra todas las conversaciones activas del usuario
/// con sus matches del evento.
class ChatListScreen extends StatelessWidget {
  final String eventId;

  const ChatListScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: const Center(
        child: Text('Lista de Chats - Por implementar'),
      ),
    );
  }
}
