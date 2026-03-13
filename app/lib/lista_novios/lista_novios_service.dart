import 'package:url_launcher/url_launcher.dart';

import 'lista_novios_model.dart';

/// Servicio de lista de novios
class ListaNoviosService {
  String buildUrl(ListaNoviosModel model) {
    if (model.overrideUrl != null && model.overrideUrl!.isNotEmpty) {
      return model.overrideUrl!;
    }

    switch (model.provider.toLowerCase()) {
      case 'falabella':
        return 'https://www.falabella.com/falabella-cl/registry?code=${model.code}';
      case 'paris':
        return 'https://www.paris.cl/lista-de-regalos/${model.code}';
      case 'ripley':
        return 'https://simple.ripley.cl/lista-de-regalos/${model.code}';
      default:
        return model.code;
    }
  }

  Future<void> openRegistry(ListaNoviosModel model) async {
    final url = buildUrl(model);
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
