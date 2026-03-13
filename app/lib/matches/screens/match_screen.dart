import 'package:flutter/material.dart';

/// Pantalla principal de matches
/// 
/// Muestra la interfaz tipo Tinder para conectar solteros
/// dentro del evento. Incluye swipe de cards y lista de matches.
class MatchScreen extends StatefulWidget {
  final String eventId;

  const MatchScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar'),
      ),
      body: const Center(
        child: Text('Pantalla de Matches - Por implementar'),
      ),
    );
  }
}
