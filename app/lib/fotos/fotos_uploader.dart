import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'fotos_storage_service.dart';

/// Uploader de fotos con progreso
class FotosUploader {
  final FotosStorageService _storageService = FotosStorageService();

  Future<String> upload({
    required String eventId,
    required String photoId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final task = await _storageService.uploadPhoto(
      eventId: eventId,
      photoId: photoId,
      file: file,
    );

    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes == 0) return;
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress?.call(progress);
    });

    await task;
    return _storageService.getDownloadUrl(eventId: eventId, photoId: photoId);
  }
}
