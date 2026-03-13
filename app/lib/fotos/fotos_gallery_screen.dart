import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'fotos_provider.dart';

/// Pantalla de galería del flujo de fotos
///
/// Muestra un grid mock de fotos del evento.
class FotosGalleryScreen extends StatelessWidget {
  const FotosGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<FotosProvider>().photos;

    if (photos.isEmpty) {
      return const Center(
        child: Text('Aún no hay fotos subidas'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final file = photos[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(file.path, fit: BoxFit.cover)
                : Image.file(File(file.path), fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
