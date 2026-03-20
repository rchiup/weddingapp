import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'rsvp_provider.dart';
import 'rsvp_screen.dart';

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
      child: NestedFlowNavigator(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Confirmar asistencia'),
            leading: IconButton(
              onPressed: () => popOrEntry(context),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
          ),
          body: const RsvpScreen(),
        ),
      ),
    );
  }
}
