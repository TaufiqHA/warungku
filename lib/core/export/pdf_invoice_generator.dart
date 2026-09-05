import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generator dokumen PDF untuk faktur dan laporan
class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  /// Membuat dokumen PDF faktur pesanan
  static Future<Uint8List> generateInvoicePdf({
    required String storeName,
    required String invoiceCode,
    required String dateStr,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double grandTotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(storeName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('No. Faktur: $invoiceCode'),
              pw.Text('Tanggal: $dateStr'),
              pw.Text('Kasir: $cashierName'),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Menu', 'Jumlah', 'Total'],
                data: items.map((e) => [e['name'], e['qty'], e['price_formatted']]).toList(),
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: Rp ${grandTotal.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
