import 'package:url_launcher/url_launcher.dart';

Future<void> downloadPhotoImpl(
  String url, {
  required String suggestedFilename,
}) async {
  final href = url.trim();
  if (href.isEmpty) return;
  final uri = Uri.parse(href);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

