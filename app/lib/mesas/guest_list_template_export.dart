import 'package:excel/excel.dart';

import 'guest_list_template_export_stub.dart'
    if (dart.library.html) 'guest_list_template_export_web.dart'
    if (dart.library.io) 'guest_list_template_export_io.dart' as exp;

/// Web: descarga `plantilla_invitados.xlsx`. Móvil/desktop: compartir archivo.
Future<void> downloadOrShareGuestListTemplate(Excel Function() build) =>
    exp.downloadOrShareGuestListTemplate(build);
