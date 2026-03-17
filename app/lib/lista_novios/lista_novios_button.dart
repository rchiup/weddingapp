import 'package:flutter/material.dart';

import 'lista_novios_service.dart';

/// Botón reutilizable para abrir lista de novios
class ListaNoviosButton extends StatelessWidget {
  final String url;

  const ListaNoviosButton({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final service = ListaNoviosService();
    return ElevatedButton.icon(
      onPressed: () => service.openUrl(url),
      icon: const Icon(Icons.open_in_browser),
      label: const Text('Ver lista de novios'),
    );
  }
}
