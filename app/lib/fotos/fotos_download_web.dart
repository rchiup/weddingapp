import 'dart:html' as html;

Future<void> downloadPhotoImpl(
  String url, {
  required String suggestedFilename,
}) async {
  final href = url.trim();
  if (href.isEmpty) return;

  final request = await html.HttpRequest.request(
    href,
    method: 'GET',
    responseType: 'blob',
  );
  final blob = request.response as html.Blob?;
  if (blob == null) {
    throw Exception('No se pudo preparar la descarga');
  }
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..setAttribute('download', suggestedFilename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  try {
    anchor.click();
  } finally {
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
  }
}

