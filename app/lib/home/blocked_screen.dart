import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de bloqueo por guard
class BlockedScreen extends StatelessWidget {
  final String? reason;

  const BlockedScreen({super.key, this.reason});

  String _titleForReason() {
    switch (reason) {
      case 'join_required':
        return 'Necesitas unirte a un evento';
      case 'solteros_disabled':
        return 'Solteros no está habilitado';
      case 'fotos_disabled':
        return 'Fotos no está habilitado';
      case 'mesas_disabled':
        return 'Mesas no está disponible';
      case 'lista_disabled':
        return 'Lista de novios no disponible';
      case 'admin_required':
        return 'Acceso restringido';
      default:
        return 'Acceso no disponible';
    }
  }

  String _messageForReason() {
    switch (reason) {
      case 'join_required':
        return 'Debes unirte a un evento antes de continuar.';
      case 'admin_required':
        return 'Solo administradores pueden acceder.';
      default:
        return 'La función no está habilitada para este evento.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso bloqueado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              _titleForReason(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _messageForReason(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/event_join'),
              child: const Text('Unirme a un evento'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/entry'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
