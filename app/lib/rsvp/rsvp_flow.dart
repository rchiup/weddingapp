import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'rsvp_provider.dart';
import 'rsvp_screen.dart';
import '../user_context/user_context_provider.dart';

/// Entry point del flujo RSVP
///
/// Aísla el módulo de confirmación de asistencia.
class RsvpFlow extends StatelessWidget {
  const RsvpFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';

    return ChangeNotifierProvider(
      create: (_) => RsvpProvider()..loadRsvp(eventId: eventId, userId: userId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmar asistencia'),
          leading: IconButton(
            onPressed: () => context.go('/entry'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
        ),
        body: const RsvpScreen(),
      ),
    );
  }
}
