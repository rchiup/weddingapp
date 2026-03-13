import 'package:flutter/material.dart';

/// Pantalla de detalle de chat
/// 
/// Muestra la conversación completa con un match,
/// incluyendo mensajes en tiempo real y campo de envío.
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String matchName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.matchName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matchName),
      ),
      body: const Center(
        child: Text('Detalle de Chat - Por implementar'),
      ),
    );
  }
}
