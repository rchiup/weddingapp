import 'package:flutter/material.dart';

/// Pantalla de galería (MVP visual)
///
/// Muestra una grilla de fotos mock y un botón para subir foto.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockPhotos = List.generate(12, (index) => index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_a_photo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: mockPhotos.length,
          itemBuilder: (context, index) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_outlined),
            );
          },
        ),
      ),
    );
  }
}
