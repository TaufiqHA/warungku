import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/product_model.dart';

class CategoryMenuData {
  final String categoryName;
  final List<ProductModel> products;

  const CategoryMenuData({
    required this.categoryName,
    required this.products,
  });
}

class MenuCatalogPdfService {
  /// Format harga ke format "Rp. XX K" persis seperti di gambar referensi
  static String formatKPrice(double price) {
    if (price >= 1000) {
      final thousands = price / 1000;
      if (thousands == thousands.roundToDouble()) {
        return 'Rp. ${thousands.toInt()} K';
      } else {
        return 'Rp. ${thousands.toStringAsFixed(1)} K';
      }
    } else {
      return 'Rp. ${price.toInt()}';
    }
  }

  /// Membangun widget header dokumen (Daftar Harga & Kotak Nomor Meja)
  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DAFTAR HARGA',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'MAKANAN DAN MINUMAN',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MEJA :',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(
              width: 50,
              height: 22,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Membangun daftar baris kategori beserta item-itemnya
  static List<pw.Widget> _buildCategoryWidgets(
    List<CategoryMenuData> categories, {
    bool isLeftColumn = true,
  }) {
    final widgets = <pw.Widget>[];

    for (int c = 0; c < categories.length; c++) {
      final cat = categories[c];
      // Judul Kategori
      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(top: c == 0 ? 0 : 12, bottom: 4),
          child: pw.Text(
            cat.categoryName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      // Daftar item produk
      for (int i = 0; i < cat.products.length; i++) {
        final product = cat.products[i];
        final isLast = i == cat.products.length - 1;

        widgets.add(
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 18),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '${i + 1} ${product.name}',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  formatKPrice(product.price),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 22,
                  height: 18,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: const pw.BorderSide(color: PdfColors.black, width: 0.7),
                      right: const pw.BorderSide(color: PdfColors.black, width: 0.7),
                      top: const pw.BorderSide(color: PdfColors.black, width: 0.7),
                      bottom: isLast
                          ? const pw.BorderSide(color: PdfColors.black, width: 0.7)
                          : pw.BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Membuat byte PDF untuk katalog menu format 2 kolom
  static Future<Uint8List> generateMenuCatalogBytes({
    required List<CategoryMenuData> categoryData,
  }) async {
    final pdf = pw.Document();

    // Membagi kategori ke dalam 2 kolom (kiri & kanan) secara proporsional
    List<CategoryMenuData> leftCategories = [];
    List<CategoryMenuData> rightCategories = [];

    if (categoryData.isEmpty) {
      // Tidak ada data
    } else if (categoryData.length == 1) {
      final singleCat = categoryData.first;
      if (singleCat.products.length > 15) {
        final half = (singleCat.products.length / 2).ceil();
        leftCategories = [
          CategoryMenuData(
            categoryName: singleCat.categoryName,
            products: singleCat.products.sublist(0, half),
          ),
        ];
        rightCategories = [
          CategoryMenuData(
            categoryName: '${singleCat.categoryName} (Lanjutan)',
            products: singleCat.products.sublist(half),
          ),
        ];
      } else {
        leftCategories = [singleCat];
      }
    } else {
      // Cari titik bagi terbaik berdasarkan jumlah item
      int bestSplitIndex = 0;
      int minDiff = 999999;
      final totalProducts = categoryData.fold<int>(0, (sum, c) => sum + c.products.length);

      int currentLeftCount = 0;
      for (int i = 0; i < categoryData.length - 1; i++) {
        currentLeftCount += categoryData[i].products.length;
        final currentRightCount = totalProducts - currentLeftCount;
        final diff = (currentLeftCount - currentRightCount).abs();

        if (diff < minDiff) {
          minDiff = diff;
          bestSplitIndex = i;
        }
      }

      leftCategories = categoryData.sublist(0, bestSplitIndex + 1);
      rightCategories = categoryData.sublist(bestSplitIndex + 1);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (pw.Context context) {
          return [
            // 1. Header Halaman Pertama
            _buildHeader(),
            pw.SizedBox(height: 14),

            // 2. Partisi 2 Kolom (Kiri dan Kanan)
            pw.Partitions(
              children: [
                // Kolom Kiri
                pw.Partition(
                  flex: 1,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: _buildCategoryWidgets(leftCategories, isLeftColumn: true),
                    ),
                  ),
                ),
                // Kolom Kanan
                pw.Partition(
                  flex: 1,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: _buildCategoryWidgets(rightCategories, isLeftColumn: false),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Membuka pratinjau cetak PDF katalog menu
  static Future<void> printMenuCatalog({
    required List<CategoryMenuData> categoryData,
  }) async {
    await Printing.layoutPdf(
      name: 'Daftar_Harga_Makanan_dan_Minuman.pdf',
      onLayout: (PdfPageFormat format) async {
        return generateMenuCatalogBytes(categoryData: categoryData);
      },
    );
  }
}
