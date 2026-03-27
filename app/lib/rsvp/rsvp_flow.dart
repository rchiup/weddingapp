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
    return ChangeNotifierProvider(
      create: (_) => RsvpProvider(),
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
          body: const _RsvpLoadScope(),
        ),
      ),
    );
  }
}

/// Dispara la carga cuando [UserContextProvider] ya tiene evento/usuario (y si cambian).
class _RsvpLoadScope extends StatefulWidget {
  const _RsvpLoadScope();

  @override
  State<_RsvpLoadScope> createState() => _RsvpLoadScopeState();
}

class _RsvpLoadScopeState extends State<_RsvpLoadScope> {
  String? _lastLoadKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uc = context.read<UserContextProvider>();
    final eventId = uc.eventId ?? '';
    final userId = uc.userId ?? '';
    final key = '$eventId|$userId';
    if (key == _lastLoadKey) return;
    _lastLoadKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RsvpProvider>().loadRsvp(eventId: eventId, userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) => const RsvpScreen();
}
