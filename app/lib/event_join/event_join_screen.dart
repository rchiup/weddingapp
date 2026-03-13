import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'event_join_provider.dart';
import 'event_join_validator.dart';

/// Pantalla de unión por código de evento
class EventJoinScreen extends StatefulWidget {
  const EventJoinScreen({super.key});

  @override
  State<EventJoinScreen> createState() => _EventJoinScreenState();
}

class _EventJoinScreenState extends State<EventJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventJoinProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Unirme a un evento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código del evento',
                border: OutlineInputBorder(),
              ),
              validator: EventJoinValidator.validateCode,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    final userContext = context.read<UserContextProvider>();
                    final ok = await provider.joinByCode(
                      code: _codeController.text,
                      userContext: userContext,
                    );
                    if (!mounted) return;
                    if (ok) {
                      context.go('/entry');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(provider.errorMessage ?? 'Error')),
                      );
                    }
                  },
            child: provider.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unirme'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Implementar scan QR opcional
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR (opcional)'),
          ),
        ],
      ),
    );
  }
}
