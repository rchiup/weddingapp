import 'fotos_download_stub.dart'
    if (dart.library.html) 'fotos_download_web.dart'
    if (dart.library.io) 'fotos_download_mobile.dart';

Future<void> downloadPhoto(
  String url, {
  required String suggestedFilename,
}) =>
    downloadPhotoImpl(url, suggestedFilename: suggestedFilename);

