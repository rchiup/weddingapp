import 'admin_export_csv_stub.dart'
    if (dart.library.html) 'admin_export_csv_web.dart'
    if (dart.library.io) 'admin_export_csv_mobile.dart';

/// Exporta un CSV con la implementación adecuada por plataforma.
Future<void> exportCsv(String filename, String content) =>
    exportCsvImpl(filename, content);
