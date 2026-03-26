import 'package:excel/excel.dart';

/// El paquete `excel` dispara la descarga del navegador con [Excel.save].
Future<void> downloadOrShareGuestListTemplate(Excel Function() build) async {
  build().save(fileName: 'plantilla_invitados.xlsx');
}
