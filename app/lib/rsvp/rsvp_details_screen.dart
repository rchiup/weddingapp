import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'rsvp_provider.dart';
import '../user_context/user_context_provider.dart';

/// Pantalla de detalles de RSVP
///
/// Permite indicar acompañante y restricciones alimentarias.
class RsvpDetailsScreen extends StatefulWidget {
  final bool attending;

  const RsvpDetailsScreen({super.key, required this.attending});

  @override
  State<RsvpDetailsScreen> createState() => _RsvpDetailsScreenState();
}

class _RsvpDetailsScreenState extends State<RsvpDetailsScreen> {
  bool _plusOne = false;
  final _dietaryController = TextEditingController();

  @override
  void dispose() {
    _dietaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RsvpProvider>();
    final userContext = context.watch<UserContextProvider>();
    final isActive = userContext.eventActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles RSVP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.attending ? 'Confirmas asistencia' : 'Confirmas que no asistes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voy con acompañante'),
              value: _plusOne,
              onChanged: (value) => setState(() => _plusOne = value),
            ),
            TextField(
              controller: _dietaryController,
              decoration: const InputDecoration(
                labelText: 'Restricciones alimentarias (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.isLoading || !isActive
                  ? null
                  : () async {
                      final eventId = userContext.eventId ?? '';
                      final userId = userContext.userId ?? '';
                      await provider.saveRsvp(
                        eventId: eventId,
                        userId: userId,
                        attending: widget.attending,
                        plusOne: _plusOne,
                        dietaryNotes: _dietaryController.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isActive ? 'Guardar RSVP' : 'Evento cerrado'),
            ),
          ],
        ),
      ),
    );
  }
}
