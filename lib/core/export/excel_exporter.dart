import 'package:excel/excel.dart';

/// Generator file spreadsheet Excel (.xlsx) untuk laporan dan transaksi
class ExcelExporter {
  ExcelExporter._();

  /// Menghasilkan byte Excel spreadsheet rekap data
  static List<int>? exportTransactionsToExcel({
    required List<Map<String, dynamic>> transactions,
  }) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    // Header baris
    sheet.appendRow([
      TextCellValue('No. Transaksi'),
      TextCellValue('Waktu'),
      TextCellValue('Kasir'),
      TextCellValue('Total Bayar'),
      TextCellValue('Metode'),
      TextCellValue('Status'),
    ]);

    for (var tx in transactions) {
      sheet.appendRow([
        TextCellValue(tx['invoice_code']?.toString() ?? ''),
        TextCellValue(tx['date']?.toString() ?? ''),
        TextCellValue(tx['cashier']?.toString() ?? ''),
        TextCellValue(tx['total']?.toString() ?? ''),
        TextCellValue(tx['payment_method']?.toString() ?? ''),
        TextCellValue(tx['status']?.toString() ?? ''),
      ]);
    }

    return excel.encode();
  }
}
