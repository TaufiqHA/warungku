import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/expense_model.dart';
import '../data/models/transaction_group_model.dart';

class LabaRugiPdfService {
  static const List<String> _bulanList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format nominal rupiah dengan titik ribuan dan awalan 'Rp. ' / '-Rp. '.
  static String formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absInt = amount.abs().toInt().toString();
    final buffer = StringBuffer(isNegative ? '-Rp. ' : 'Rp. ');
    for (int i = 0; i < absInt.length; i++) {
      if (i > 0 && (absInt.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(absInt[i]);
    }
    return buffer.toString();
  }

  /// Format tanggal cetak dalam bahasa Indonesia (contoh: 21 September 2026 16:56).
  static String formatTanggalCetak(DateTime dt) {
    final day = dt.day;
    final month = _bulanList[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
  }

  /// Menghasilkan byte dokumen PDF Laporan Ringkasan Laba-Rugi.
  static Future<Uint8List> generateLabaRugiPdfBytes({
    required String filterTitle,
    required double totalRevenue,
    required double totalExpense,
    required List<TransactionGroup> groups,
    List<ExpenseModel> expenses = const [],
    DateTime? printDateTime,
  }) async {
    final pdf = pw.Document();
    final now = printDateTime ?? DateTime.now();
    final netProfit = totalRevenue - totalExpense;

    // Kumpulkan seluruh item transaksi selesai secara urut
    final List<List<String>> salesRows = [];
    for (final group in groups) {
      for (final item in group.items) {
        salesRows.add([
          group.idTransaksi,
          item.waktu,
          item.namaItem,
          item.jumlah.toString(),
          formatCurrency(item.totalHarga),
        ]);
      }
    }

    // Kumpulkan rincian pengeluaran
    final List<List<String>> expenseRows = [];
    for (int i = 0; i < expenses.length; i++) {
      final exp = expenses[i];
      expenseRows.add([
        (i + 1).toString(),
        exp.tanggal,
        exp.kategori,
        exp.keterangan.isEmpty ? '-' : exp.keterangan,
        formatCurrency(exp.jumlah),
      ]);
    }

    final totalRows = salesRows.length + expenseRows.length;
    final maxPages = math.max(100, (totalRows ~/ 15) + 50);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: maxPages,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        build: (pw.Context context) {
          return [
            // 1. Header Laporan
            pw.Center(
              child: pw.Text(
                'LAPORAN RINGKASAN LABA-RUGI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Periode/Filter: $filterTitle',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Tanggal Cetak
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Tanggal Cetak: ${formatTanggalCetak(now)}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // 3. Tabel Ringkasan Laba-Rugi
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.black,
                width: 0.8,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.5),
                1: pw.FlexColumnWidth(2.0),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        'TOTAL PENDAPATAN (PENJUALAN)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        formatCurrency(totalRevenue),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        'TOTAL PENGELUARAN',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        formatCurrency(totalExpense),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        'LABA BERSIH',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: pw.Text(
                        formatCurrency(netProfit),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // 4. Rincian Transaksi Penjualan
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Rincian Transaksi Penjualan',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            if (salesRows.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                decoration: pw.BoxDecoration(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Tidak ada data transaksi penjualan pada periode ini',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.6,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerAlignment: pw.Alignment.center,
                headerHeight: 20,
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2),
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(3.8),
                  3: pw.FlexColumnWidth(0.8),
                  4: pw.FlexColumnWidth(2.0),
                },
                headers: const ['No TRX', 'Waktu', 'Item', 'Qty', 'Jumlah'],
                data: salesRows,
              ),

            // 5. Seksi Rincian Pengeluaran (Bila ada data pengeluaran)
            if (expenseRows.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Rincian Pengeluaran',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: PdfColors.black,
                  width: 0.6,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerAlignment: pw.Alignment.center,
                headerHeight: 20,
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                cellAlignments: const {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.8),
                  1: pw.FlexColumnWidth(2.2),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(4.2),
                  4: pw.FlexColumnWidth(2.0),
                },
                headers: const ['No', 'Tanggal', 'Kategori', 'Keterangan', 'Jumlah'],
                data: expenseRows,
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Menjalankan pratinjau dan pencetakan PDF Laba Rugi via dialog native printing
  static Future<void> printLabaRugiReport({
    required String filterTitle,
    required double totalRevenue,
    required double totalExpense,
    required List<TransactionGroup> groups,
    List<ExpenseModel> expenses = const [],
    DateTime? printDateTime,
  }) async {
    final sanitizedTitle = filterTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'Laporan_Laba_Rugi_$sanitizedTitle.pdf';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async {
        return generateLabaRugiPdfBytes(
          filterTitle: filterTitle,
          totalRevenue: totalRevenue,
          totalExpense: totalExpense,
          groups: groups,
          expenses: expenses,
          printDateTime: printDateTime,
        );
      },
    );
  }
}
