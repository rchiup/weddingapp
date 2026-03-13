import 'package:flutter/material.dart';

/// Pantalla de galería de fotos
/// 
/// Muestra todas las fotos del evento en tiempo real,
/// permite subir nuevas fotos y ver detalles de cada foto.
class GalleryScreen extends StatefulWidget {
  final String eventId;

  const GalleryScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          // TODO: Agregar botón para subir foto
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () {
              // TODO: Implementar selector de imagen
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Galería de Fotos - Por implementar'),
      ),
    );
  }
}
