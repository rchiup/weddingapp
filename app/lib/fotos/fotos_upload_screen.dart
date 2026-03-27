import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import 'fotos_provider.dart';

/// Pantalla de subida de fotos del flujo de fotos
///
/// UI básica para seleccionar y subir fotos (visibilidad pública o solo novios).
class FotosUploadScreen extends StatefulWidget {
  const FotosUploadScreen({super.key});

  @override
  State<FotosUploadScreen> createState() => _FotosUploadScreenState();
}

class _FotosUploadScreenState extends State<FotosUploadScreen> {
  bool _onlyNovios = false;

  Future<List<XFile>> _pickImages() async {
    // Web/desktop: file_picker es más estable para selección múltiple.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return const <XFile>[];
      final files = <XFile>[];
      for (final f in result.files) {
        if (kIsWeb) {
          final Uint8List? bytes = f.bytes;
          if (bytes == null) continue;
          files.add(
            XFile.fromData(
              bytes,
              name: (f.name.isEmpty ? 'upload.jpg' : f.name),
              mimeType: f.extension == null ? null : 'image/${f.extension}',
            ),
          );
        } else if (f.path != null && f.path!.isNotEmpty) {
          files.add(XFile(f.path!, name: f.name));
        }
      }
      return files;
    }

    // Mobile: image_picker nativo.
    final picker = ImagePicker();
    return picker.pickMultiImage();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<FotosProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Subir recuerdo', style: AppTextStyles.title.copyWith(fontSize: 18)),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x2),
          children: [
            CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sube tus fotos del evento', style: AppTextStyles.title.copyWith(fontSize: 16)),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          'Elige visibilidad y selecciona tus fotos.',
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            CustomCard(
              child: SwitchListTile(
                value: _onlyNovios,
                onChanged: provider.isUploading ? null : (v) => setState(() => _onlyNovios = v),
                title: const Text('Solo novios'),
                subtitle: const Text('Si lo activas, solo lo verán los novios (y tú).'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            CustomButton(
              label: 'Seleccionar fotos',
              icon: Icons.photo_library_outlined,
              loading: provider.isUploading,
              onPressed: provider.isUploading
                  ? null
                  : () async {
                      if ((userContext.eventId ?? '').isEmpty || (userContext.userId ?? '').isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debes unirte a un evento primero')),
                        );
                        return;
                      }
                      List<XFile> files = const <XFile>[];
                      try {
                        files = await _pickImages();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir el selector: $e')),
                        );
                        return;
                      }
                      if (files.isEmpty || !context.mounted) return;
                      await provider.uploadPhotos(
                        eventId: userContext.eventId ?? '',
                        userId: userContext.userId ?? '',
                        userName: userContext.isAdmin
                            ? 'Novios'
                            : (userContext.userName ?? 'Invitado'),
                        visibility: _onlyNovios ? 'novios' : 'public',
                        files: files,
                      );
                      if (!context.mounted) return;
                      final message = provider.errorMessage == null
                          ? '${files.length} foto(s) subidas'
                          : provider.errorMessage!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
            ),
            if (provider.isUploading) ...[
              const SizedBox(height: AppSpacing.x2),
              ClipRRect(
                borderRadius: AppRadii.button,
                child: LinearProgressIndicator(value: provider.uploadProgress),
              ),
            ],
            const SizedBox(height: AppSpacing.x2),
            CustomCard(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_back_outlined,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    size: 30,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Selecciona una o varias fotos para comenzar.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
