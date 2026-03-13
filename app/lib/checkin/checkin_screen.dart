import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'checkin_service.dart';

/// Pantalla "Ya llegué" - check-in al evento
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final CheckinService _service = CheckinService();
  bool _loading = false;
  bool _done = false;

  Future<void> _doCheckin() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    final userId = userContext.userId;
    final name = userContext.userName ?? 'Invitado';

    if (eventId == null || eventId.isEmpty || userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes unirte a un evento primero')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.checkIn(eventId: eventId, userId: userId, name: name);
      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_done) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              '¡Listo! Ya registraste tu llegada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ] else ...[
            const Text(
              '¿Ya llegaste al evento?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _doCheckin,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.celebration),
              label: Text(_loading ? 'Registrando...' : '🎉 Ya llegué'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/entry'),
            child: const Text('Volver al menú'),
          ),
        ],
      ),
    );
  }
}
