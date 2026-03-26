import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
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
  Future<void> _openUpload(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FotosUploadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FotosProvider(),
      child: NestedFlowNavigator(
        child: Builder(
          builder: (nestedContext) => Scaffold(
            backgroundColor: AppColors.galleryBackground,
            appBar: AppBar(
            toolbarHeight: 72,
            title: Consumer<FotosProvider>(
              builder: (context, fotos, _) {
                final sub = fotos.isLoading
                    ? '...'
                    : '${fotos.photoCount} ${fotos.photoCount == 1 ? 'foto' : 'fotos'}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Revive el momento',
                      style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Mira y comparte los recuerdos del dia · $sub',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
            backgroundColor: AppColors.galleryBackground,
            foregroundColor: AppColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => popOrEntry(nestedContext),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
            actions: [
              Consumer<FotosProvider>(
                builder: (context, fotos, _) {
                  final filtering = (fotos.uploaderFilterUserId ?? '').isNotEmpty;
                  return IconButton(
                    tooltip: filtering ? 'Filtrado (Subido por)' : 'Filtrar por “Subido por”',
                    icon: Icon(
                      filtering ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () async {
                      final options = fotos.uploaderOptions;
                      await showModalBottomSheet<void>(
                        context: nestedContext,
                        showDragHandle: true,
                        backgroundColor: AppColors.card,
                        builder: (ctx) {
                          return SafeArea(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.x2,
                                AppSpacing.x1,
                                AppSpacing.x2,
                                AppSpacing.x2,
                              ),
                              children: [
                                Text(
                                  'Filtrar por “Subido por”',
                                  style: AppTextStyles.title.copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Todos'),
                                  trailing: (fotos.uploaderFilterUserId == null)
                                      ? const Icon(Icons.check, color: AppColors.joinAccent)
                                      : null,
                                  onTap: () {
                                    context.read<FotosProvider>().clearUploaderFilter();
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                                const Divider(),
                                for (final o in options)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(o.name),
                                    subtitle: Text('${o.count} ${o.count == 1 ? 'foto' : 'fotos'}'),
                                    trailing: (fotos.uploaderFilterUserId == o.userId)
                                        ? const Icon(Icons.check, color: AppColors.joinAccent)
                                        : null,
                                    onTap: () {
                                      context.read<FotosProvider>().setUploaderFilter(o.userId);
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Consumer<FotosProvider>(
                builder: (context, fotos, _) {
                  return IconButton(
                    onPressed: fotos.toggleGalleryLayout,
                    icon: Icon(
                      fotos.galleryGridMode
                          ? Icons.view_day_outlined
                          : Icons.grid_view_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip:
                        fotos.galleryGridMode ? 'Modo feed (tipo Instagram)' : 'Modo cuadrícula',
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(nestedContext).push(
                    MaterialPageRoute(builder: (_) => const FotosExportScreen()),
                  );
                },
                icon: const Icon(Icons.link, color: AppColors.textPrimary),
                tooltip: 'Exportar links',
              ),
            ],
          ),
            body: FotosFeedScreen(
              onUploadTap: () => _openUpload(nestedContext),
            ),
            // Sin barra inferior: “Subir foto” queda arriba en el feed.
          ),
        ),
      ),
    );
  }
}
