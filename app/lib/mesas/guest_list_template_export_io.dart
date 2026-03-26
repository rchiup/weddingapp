import 'dart:io' show File;

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadOrShareGuestListTemplate(Excel Function() build) async {
  const fileName = 'plantilla_invitados.xlsx';
  final bytes = build().encode();
  if (bytes == null || bytes.isEmpty) {
    throw StateError('No se pudo generar el archivo Excel');
  }
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$fileName';
  await File(path).writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          path,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: fileName,
        ),
      ],
      subject: 'Plantilla lista de invitados',
    ),
  );
}
