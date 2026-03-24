import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/startup_background.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'fotos_export_screen.dart';
import 'fotos_feed_screen.dart';
import 'fotos_provider.dart';
import 'fotos_upload_screen.dart';

/// Entry point del flujo de fotos
class FotosFlow extends StatefulWidget {
  const FotosFlow({super.key});

  @override
  State<FotosFlow> createState() => _FotosFlowState();
}

class _FotosFlowState extends State<FotosFlow> {
  int _currentIndex = 0;

  void openUploadTab() => setState(() => _currentIndex = 1);

  @override
  Widget build(BuildContext context) {
    final screens = [
      FotosFeedScreen(onUploadTap: openUploadTab),
      const FotosUploadScreen(),
    ];

    return ChangeNotifierProvider(
      create: (_) => FotosProvider(),
      child: NestedFlowNavigator(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Fotos del evento', style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () => popOrEntry(context),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
            actions: [
              Consumer<FotosProvider>(
                builder: (context, fotos, _) {
                  if (_currentIndex != 0) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: fotos.toggleGalleryLayout,
                    icon: Icon(
                      fotos.galleryGridMode
                          ? Icons.view_day_outlined
                          : Icons.grid_view_rounded,
                    ),
                    tooltip:
                        fotos.galleryGridMode ? 'Modo feed (tipo Instagram)' : 'Modo cuadrícula',
                  );
                },
              ),
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
          body: StartupBackground(
            child: screens[_currentIndex],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.card,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            elevation: 8,
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
      ),
    );
  }
}
