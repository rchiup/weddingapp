import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'fotos_provider.dart';

/// Pantalla de subida de fotos del flujo de fotos
///
/// UI básica para seleccionar y subir fotos (sin lógica).
class FotosUploadScreen extends StatelessWidget {
  const FotosUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<FotosProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Sube tus fotos del evento'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.isUploading
                ? null
                : () async {
              if ((userContext.eventId ?? '').isEmpty ||
                  (userContext.userId ?? '').isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes unirte a un evento primero')),
                );
                return;
              }
              final picker = ImagePicker();
              final files = await picker.pickMultiImage();
              if (files.isEmpty) return;
              await provider.uploadPhotos(
                eventId: userContext.eventId ?? '',
                userId: userContext.userId ?? '',
                userName: userContext.userName ?? 'Invitado',
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
            child: const Text('Seleccionar fotos'),
          ),
          if (provider.isUploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: provider.uploadProgress),
          ],
        ],
      ),
    );
  }
}
