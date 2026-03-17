import 'package:url_launcher/url_launcher.dart';

/// Servicio de lista de novios
class ListaNoviosService {
  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
