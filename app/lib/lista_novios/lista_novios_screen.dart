import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'lista_novios_button.dart';
import 'lista_novios_model.dart';

/// Pantalla de lista de novios
class ListaNoviosScreen extends StatelessWidget {
  const ListaNoviosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserContextProvider>().settings;
    final model = ListaNoviosModel(
      provider: settings.giftRegistryProvider,
      code: settings.giftRegistryCode,
      overrideUrl: settings.giftRegistryUrlOverride,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de novios'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
            ListaNoviosButton(model: model),
          ],
        ),
      ),
    );
  }
}
