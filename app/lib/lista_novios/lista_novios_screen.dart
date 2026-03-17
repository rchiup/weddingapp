import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'lista_novios_button.dart';
import 'novios_registry_service.dart';

/// Pantalla de lista de novios
class ListaNoviosScreen extends StatelessWidget {
  const ListaNoviosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventId = context.watch<UserContextProvider>().eventId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de novios'),
        leading: IconButton(
          onPressed: () => context.go('/entry'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Regalos para los novios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Presiona el botón para abrir la lista de regalos.'),
            const SizedBox(height: 16),
            FutureBuilder<String?>(
              future: eventId.isEmpty
                  ? Future.value(null)
                  : NoviosRegistryService().getRegistryUrl(eventId),
              builder: (_, snap) {
                final url = snap.data;
                final loading = snap.connectionState == ConnectionState.waiting;
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (url == null || url.isEmpty) {
                  return const Text(
                    'Aún no está publicada la lista de regalos.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return ListaNoviosButton(url: url);
              },
            ),
          ],
        ),
      ),
    );
  }
}
