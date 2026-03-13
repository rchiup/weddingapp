import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio de Storage para fotos
class FotosStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference _photoRef(String eventId, String photoId) {
    return _storage.ref().child('events/$eventId/photos/$photoId.jpg');
  }

  Future<UploadTask> uploadPhoto({
    required String eventId,
    required String photoId,
    required XFile file,
  }) async {
    final ref = _photoRef(eventId, photoId);
    final bytes = await file.readAsBytes();
    return ref.putData(bytes);
  }

  Future<String> getDownloadUrl({
    required String eventId,
    required String photoId,
  }) {
    final ref = _photoRef(eventId, photoId);
    return ref.getDownloadURL();
  }
}
