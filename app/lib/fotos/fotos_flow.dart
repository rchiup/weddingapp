import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'fotos_export_screen.dart';
import 'fotos_feed_screen.dart';
import 'fotos_upload_screen.dart';
import 'fotos_provider.dart';

/// Entry point del flujo de fotos
///
/// Maneja navegación interna del flujo (galería y subida),
/// sin depender del módulo de solteros.
class FotosFlow extends StatefulWidget {
  const FotosFlow({super.key});

  @override
  State<FotosFlow> createState() => _FotosFlowState();
}

class _FotosFlowState extends State<FotosFlow> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const FotosFeedScreen(),
      const FotosUploadScreen(),
    ];

    return ChangeNotifierProvider(
      create: (_) => FotosProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fotos del evento'),
          leading: IconButton(
            onPressed: () => context.go('/entry'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FotosExportScreen()),
                );
              },
              icon: const Icon(Icons.link),
              tooltip: 'Exportar links',
            ),
          ],
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              label: 'Galería',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              label: 'Subir',
            ),
          ],
        ),
      ),
    );
  }
}
