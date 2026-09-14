import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/sales_receipt_dialog.dart';

class QuotationPdfService {
  /// Format angka ke representasi mata uang Rupiah standar (contoh: Rp. 40.000)
  static String formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer('Rp. ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Ekstraksi tanggal DD/MM/YYYY dari string waktu transaksi
  static String extractDateOnly(String dateTimeStr) {
    try {
      final parts = dateTimeStr.split(' ');
      if (parts.isNotEmpty && parts.first.contains('/')) {
        return parts.first;
      }
      final dt = DateTime.parse(dateTimeStr);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    } catch (_) {
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      return '$day/$month/${now.year}';
    }
  }

  /// Menghasilkan byte dokumen PDF Surat Penawaran A4 sesuai gambar referensi
  static Future<Uint8List> generateQuotationPdfBytes({
    required String storeName,
    String? storeAddress,
    required String transactionId,
    required String dateTimeStr,
    required String customerName,
    required String cashierName,
    required List<SalesReceiptItem> items,
    required double subtotal,
    double discountAmount = 0.0,
    double ppnPercent = 11.0,
  }) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final dateOnly = extractDateOnly(dateTimeStr);
    final effectiveCustomer = customerName.isNotEmpty && customerName != '-' ? customerName : 'Pelanggan Umum';
    final effectiveStoreAddress = storeAddress != null && storeAddress.isNotEmpty
        ? storeAddress
        : 'Jl. Raya Warung No. 123';
    final effectiveCashier = cashierName.isNotEmpty ? cashierName : 'Admin Warung';

    final effectiveSubtotal = subtotal > 0 ? subtotal : items.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final ppnAmount = (effectiveSubtotal * (ppnPercent / 100)).roundToDouble();
    final grandTotal = effectiveSubtotal + ppnAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. HEADER SECTION (Kop Toko & Surat Penawaran)
              // ==========================================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Sisi Kiri: Toko & Kepada Yth
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          storeName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Text(
                          'Kepada Yth:',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          effectiveCustomer,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          effectiveStoreAddress,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sisi Kanan: SURAT PENAWARAN & Tabel Metadata
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SURAT PENAWARAN',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                        columnWidths: const {
                          0: pw.FixedColumnWidth(86),
                          1: pw.FixedColumnWidth(64),
                          2: pw.FixedColumnWidth(76),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              _buildMetaCell('Kode', isHeader: true),
                              _buildMetaCell('Tanggal', isHeader: true),
                              _buildMetaCell('Sales', isHeader: true),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              _buildMetaCell(transactionId),
                              _buildMetaCell(dateOnly),
                              _buildMetaCell(effectiveCashier),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // ==========================================
              // 2. ITEMS TABLE (Tabel Bergaris Penuh)
              // ==========================================
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: const {
                  0: pw.FixedColumnWidth(28), // No
                  1: pw.FlexColumnWidth(4.5), // Nama Barang
                  2: pw.FixedColumnWidth(42), // Qty
                  3: pw.FixedColumnWidth(68), // @Harga
                  4: pw.FixedColumnWidth(54), // @Diskon
                  5: pw.FixedColumnWidth(76), // Jumlah
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    children: [
                      _buildHeaderCell('No', align: pw.TextAlign.center),
                      _buildHeaderCell('Nama Barang', align: pw.TextAlign.center),
                      _buildHeaderCell('Qty', align: pw.TextAlign.center),
                      _buildHeaderCell('@Harga', align: pw.TextAlign.center),
                      _buildHeaderCell('@Diskon', align: pw.TextAlign.center),
                      _buildHeaderCell('Jumlah', align: pw.TextAlign.center),
                    ],
                  ),

                  // Data Rows
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    return pw.TableRow(
                      children: [
                        _buildDataCell('${index + 1}', align: pw.TextAlign.center),
                        _buildDataCell(item.name, align: pw.TextAlign.left),
                        _buildDataCell('${item.quantity} bh', align: pw.TextAlign.center),
                        _buildDataCell(formatRupiah(item.price), align: pw.TextAlign.right),
                        _buildDataCell('0.0%', align: pw.TextAlign.center),
                        _buildDataCell(formatRupiah(item.subtotal), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              // ==========================================
              // 3. SUMMARY ROWS (Total, PPN 11%, Grand Total)
              // Terintegrasi di bawah kolom @Harga, @Diskon, & Jumlah
              // ==========================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(122), // Lebar gabungan @Harga + @Diskon (68 + 54)
                      1: pw.FixedColumnWidth(76),  // Lebar Jumlah
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          _buildSummaryLabelCell('Total'),
                          _buildSummaryValueCell(formatRupiah(effectiveSubtotal)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildSummaryLabelCell('PPN 11%'),
                          _buildSummaryValueCell(formatRupiah(ppnAmount)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildSummaryLabelCell('Grand\nTotal', isBold: true),
                          _buildSummaryValueCell(formatRupiah(grandTotal), isBold: true),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ==========================================
              // 4. FOOTER & TANDA TANGAN (Kiri: Keterangan, Kanan: Hormat Kami)
              // ==========================================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Sisi Kiri: Keterangan
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Keterangan:',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Terima kasih atas kunjungan Anda.',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),

                  // Sisi Kanan: Hormat Kami & Tanda Tangan
                  pw.Container(
                    width: 140,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Hormat Kami,',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.SizedBox(height: 42),
                        pw.Text(
                          effectiveCashier,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Sales',
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Membuka file PDF langsung di perangkat ponsel (dan fallback ke layout pratinjau)
  static Future<void> openOrPrintQuotationPdf({
    required String storeName,
    String? storeAddress,
    required String transactionId,
    required String dateTimeStr,
    required String customerName,
    required String cashierName,
    required List<SalesReceiptItem> items,
    required double subtotal,
    double discountAmount = 0.0,
    double ppnPercent = 11.0,
  }) async {
    final bytes = await generateQuotationPdfBytes(
      storeName: storeName,
      storeAddress: storeAddress,
      transactionId: transactionId,
      dateTimeStr: dateTimeStr,
      customerName: customerName,
      cashierName: cashierName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      ppnPercent: ppnPercent,
    );

    final cleanTrx = transactionId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'Penawaran_$cleanTrx.pdf';

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // Coba juga simpan salinan ke folder Download publik Android
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final downloadFile = File('${downloadDir.path}/$fileName');
          await downloadFile.writeAsBytes(bytes, flush: true);
        }
      } catch (_) {}

      final openResult = await OpenFilex.open(filePath, type: 'application/pdf');
      if (openResult.type != ResultType.done) {
        // Fallback ke Printing.layoutPdf jika tidak ada app pembuka
        await Printing.layoutPdf(
          name: fileName,
          onLayout: (_) async => bytes,
        );
      }
    } catch (_) {
      // Fallback jika OpenFilex error
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (_) async => bytes,
      );
    }
  }

  // Helper cell builders
  static pw.Widget _buildMetaCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryLabelCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isBold ? 10 : 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryValueCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: isBold ? 10.5 : 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
