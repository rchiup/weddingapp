import 'dart:html' as html;

Future<void> downloadPhotoImpl(
  String url, {
  required String suggestedFilename,
}) async {
  final href = url.trim();
  if (href.isEmpty) return;

  final anchor = html.AnchorElement(href: href)
    ..setAttribute('download', suggestedFilename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

