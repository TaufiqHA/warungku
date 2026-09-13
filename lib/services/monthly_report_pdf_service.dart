import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyReportPdfService {
  static String _formatRupiah(double value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  /// Membuat Uint8List byte PDF dari data laporan bulanan
  static Future<Uint8List> generateMonthlyReportBytes({
    required int month,
    required int year,
    required String monthName,
    required int totalOrder,
    required double totalOmzet,
    required double averageOrderValue,
    required List<Map<String, dynamic>> topSellingMenu,
    required Map<int, Map<String, dynamic>> dailyBreakdown,
    String storeName = 'Warungku',
    String? filteredItem,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final printDateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final isFiltered = filteredItem != null && filteredItem.isNotEmpty && filteredItem != 'Semua Menu';
    final reportTitle = isFiltered ? 'Laporan Penjualan: $filteredItem' : 'Laporan Penjualan Bulanan';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey200, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Warungku POS - Dokumen Resmi',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      storeName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      reportTitle,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '$monthName $year',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Dicetak: $printDateStr',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 16),

            // 2. Ringkasan Metrik
            pw.Text(
              'RINGKASAN KINERJA',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildSummaryCard('Total Pesanan', '$totalOrder Transaksi'),
                pw.SizedBox(width: 12),
                _buildSummaryCard('Total Omzet', _formatRupiah(totalOmzet)),
                pw.SizedBox(width: 12),
                _buildSummaryCard('Rata-rata Pesanan', _formatRupiah(averageOrderValue)),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. Menu Terlaris
            pw.Text(
              'PERINGKAT MENU TERLARIS',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 8),
            if (topSellingMenu.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Tidak ada penjualan menu pada bulan ini',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                headers: ['#', 'Nama Menu', 'Porsi Terjual', 'Kontribusi Omzet'],
                data: List.generate(
                  topSellingMenu.length > 10 ? 10 : topSellingMenu.length,
                  (index) {
                    final item = topSellingMenu[index];
                    return [
                      '${index + 1}',
                      item['name']?.toString() ?? '-',
                      '${item['qty']} porsi',
                      _formatRupiah((item['omzet'] as num?)?.toDouble() ?? 0.0),
                    ];
                  },
                ),
              ),
            pw.SizedBox(height: 24),

            // 4. Rekap Harian
            pw.Text(
              'REKAP TRANSAKSI HARIAN',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildDailyTable(dailyBreakdown, monthName),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDailyTable(
    Map<int, Map<String, dynamic>> dailyBreakdown,
    String monthName,
  ) {
    final days = dailyBreakdown.keys.toList()..sort();
    if (days.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Center(
          child: pw.Text(
            'Tidak ada data transaksi harian',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      );
    }

    final tableData = <List<String>>[];
    for (final day in days) {
      final data = dailyBreakdown[day]!;
      final orderCount = data['orderCount'] ?? 0;
      final omzet = (data['omzet'] as num?)?.toDouble() ?? 0.0;
      if (orderCount > 0 || omzet > 0) {
        tableData.add([
          '$day $monthName',
          '$orderCount Transaksi',
          _formatRupiah(omzet),
        ]);
      }
    }

    if (tableData.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Center(
          child: pw.Text(
            'Belum ada transaksi berhasil pada bulan ini',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      headers: ['Tanggal', 'Jumlah Transaksi', 'Omzet Harian'],
      data: tableData,
    );
  }

  /// Membuka pratinjau cetak bawaan sistem operasi / PDF viewer
  static Future<void> printMonthlyReport({
    required int month,
    required int year,
    required String monthName,
    required int totalOrder,
    required double totalOmzet,
    required double averageOrderValue,
    required List<Map<String, dynamic>> topSellingMenu,
    required Map<int, Map<String, dynamic>> dailyBreakdown,
    String storeName = 'Warungku',
    String? filteredItem,
  }) async {
    final fileName = (filteredItem != null && filteredItem.isNotEmpty && filteredItem != 'Semua Menu')
        ? 'Laporan_${filteredItem.replaceAll(' ', '_')}_${monthName}_$year.pdf'
        : 'Laporan_Bulanan_${monthName}_$year.pdf';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async {
        return generateMonthlyReportBytes(
          month: month,
          year: year,
          monthName: monthName,
          totalOrder: totalOrder,
          totalOmzet: totalOmzet,
          averageOrderValue: averageOrderValue,
          topSellingMenu: topSellingMenu,
          dailyBreakdown: dailyBreakdown,
          storeName: storeName,
          filteredItem: filteredItem,
        );
      },
    );
  }
}
