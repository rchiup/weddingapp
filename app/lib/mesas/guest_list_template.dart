import 'package:excel/excel.dart';

/// Genera la plantilla .xlsx que espera el backend (mismas columnas que name/last_name/...).
Excel buildGuestListTemplateExcel() {
  final excel = Excel.createExcel();
  final keys = excel.tables.keys.toList();
  final previousName = excel.getDefaultSheet() ?? (keys.isNotEmpty ? keys.first : null);
  if (previousName != null && previousName != 'Invitados') {
    excel.rename(previousName, 'Invitados');
  }
  final sheet = excel['Invitados'];
  const headers = ['name', 'last_name', 'email', 'phone', 'table'];
  for (var c = 0; c < headers.length; c++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
        .value = TextCellValue(headers[c]);
  }
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('María');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue('González');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Juan');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = TextCellValue('Pérez');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2)).value = TextCellValue('juan@ejemplo.com');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2)).value = TextCellValue('+56912345678');
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2)).value = TextCellValue('1');
  return excel;
}
