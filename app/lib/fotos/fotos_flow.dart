import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'fotos_export_screen.dart';
import 'fotos_feed_screen.dart';
import 'fotos_gallery_decor.dart';
import 'fotos_photo_filter.dart';
import 'fotos_provider.dart';

/// Entry point del flujo de fotos
class FotosFlow extends StatefulWidget {
  const FotosFlow({super.key});

  @override
  State<FotosFlow> createState() => _FotosFlowState();
}

class _FotosFlowState extends State<FotosFlow> {
  Future<String?> _pickVisibility(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppSpacing.x2, AppSpacing.x1, AppSpacing.x2, AppSpacing.x2),
          children: [
            Text('¿Quién puede ver este recuerdo?', style: AppTextStyles.title.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.x1),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Todos'),
              subtitle: const Text('Invitados y novios'),
              onTap: () => Navigator.of(ctx).pop('public'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Solo novios'),
              subtitle: const Text('Privado para los novios'),
              onTap: () => Navigator.of(ctx).pop('novios'),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  Future<List<XFile>> _pickMediaFiles() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return const <XFile>[];
      final files = <XFile>[];
      for (final f in result.files) {
        if (kIsWeb) {
          final bytes = f.bytes;
          if (bytes == null) continue;
          files.add(
            XFile.fromData(
              bytes,
              name: f.name.isEmpty ? 'upload.bin' : f.name,
              mimeType: _mimeTypeForExtension(f.extension),
            ),
          );
        } else if (f.path != null && f.path!.isNotEmpty) {
          files.add(XFile(f.path!, name: f.name));
        }
      }
      return files;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm'],
      allowMultiple: true,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return const <XFile>[];
    return result.files
        .where((f) => (f.path ?? '').isNotEmpty)
        .map((f) => XFile(f.path!, name: f.name))
        .toList();
  }

  String? _mimeTypeForExtension(String? ext) {
    final e = (ext ?? '').toLowerCase();
    switch (e) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return null;
    }
  }

  Future<void> _quickUpload(BuildContext context) async {
    final userContext = context.read<UserContextProvider>();
    final provider = context.read<FotosProvider>();
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    if (eventId.isEmpty || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes unirte a un evento primero')),
      );
      return;
    }

    final visibility = await _pickVisibility(context);
    if (!context.mounted || visibility == null) return;

    List<XFile> files = const <XFile>[];
    try {
      files = await _pickMediaFiles();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el selector: $e')),
      );
      return;
    }
    if (!context.mounted || files.isEmpty) return;

    await provider.uploadPhotos(
      eventId: eventId,
      userId: userId,
      userName: userContext.isAdmin ? 'Novios' : (userContext.userName ?? 'Invitado'),
      visibility: visibility,
      files: files,
    );
    if (!context.mounted) return;
    final message =
        provider.errorMessage == null ? '${files.length} archivo(s) subidos' : provider.errorMessage!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FotosProvider(),
      child: NestedFlowNavigator(
        child: Builder(
          builder: (nestedContext) => Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
            toolbarHeight: 72,
            title: Consumer<FotosProvider>(
              builder: (context, fotos, _) {
                final shown = filterEventPhotosForDisplay(fotos.photos).length;
                final sub = fotos.isLoading
                    ? '...'
                    : '$shown ${shown == 1 ? 'foto' : 'fotos'}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Galería',
                      style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kGalleryBgTop, kGalleryBgBottom],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
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
            body: FotosGalleryBackground(
              child: FotosFeedScreen(
                onUploadTap: () => _quickUpload(nestedContext),
              ),
            ),
            // Sin barra inferior: “Subir foto” queda arriba en el feed.
          ),
        ),
      ),
    );
  }
}
