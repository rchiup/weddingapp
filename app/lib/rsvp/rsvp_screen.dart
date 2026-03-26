import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'rsvp_details_screen.dart';
import 'rsvp_provider.dart';
import '../user_context/user_context_provider.dart';

Future<void> _openRsvpDetailsAndOfferSongs(
  BuildContext context, {
  required bool attending,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => RsvpDetailsScreen(attending: attending),
    ),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¿Querés sugerir una canción infaltable?'),
        action: SnackBarAction(
          label: 'Ir',
          onPressed: () => context.push('/songs'),
        ),
      ),
    );
  }
}

/// Pantalla principal de RSVP
///
/// Permite elegir si asiste o no, y continuar a detalles.
class RsvpScreen extends StatelessWidget {
  const RsvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RsvpProvider>();
    final userContext = context.watch<UserContextProvider>();
    final current = provider.rsvp;
    final isActive = userContext.eventActive;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Asistirás al evento?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (provider.isFetching) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Cargando tu RSVP…',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: isActive && !provider.isFetching
                ? () => _openRsvpDetailsAndOfferSongs(context, attending: true)
                : null,
            child: const Text('Sí, asistiré'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: isActive && !provider.isFetching
                ? () => _openRsvpDetailsAndOfferSongs(context, attending: false)
                : null,
            child: const Text('No podré asistir'),
          ),
          if (!isActive) ...[
            const SizedBox(height: 8),
            const Text(
              'El evento está cerrado y no permite editar RSVP.',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          if (current != null) ...[
            const Text(
              'Tu estado actual:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(current.attending ? 'Asistiré' : 'No asistiré'),
            Text('Acompañante: ${current.plusOne ? "Sí" : "No"}'),
            if (current.dietaryPreference != 'none')
              Text(
                'Menú: ${current.dietaryPreference == 'vegan' ? 'Vegano' : 'Vegetariano'}',
              ),
            if (current.allergies)
              Text(
                current.allergiesNotes.isNotEmpty
                    ? 'Alergias: ${current.allergiesNotes}'
                    : 'Alergias: Sí',
              ),
            if (current.dietaryNotes.isNotEmpty)
              Text('Notas: ${current.dietaryNotes}'),
          ],
        ],
      ),
    );
  }
}
