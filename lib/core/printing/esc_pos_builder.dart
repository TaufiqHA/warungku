import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Builder untuk menghasilkan byte array perintah ESC/POS printer thermal
class EscPosBuilder {
  EscPosBuilder._();

  /// Menghasilkan byte struk pembayaran kasir (58mm)
  static Future<List<int>> generateReceiptBytes({
    required String storeName,
    required String invoiceCode,
    required String dateStr,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
    String? footerNote,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text('No: $invoiceCode', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Waktu: $dateStr', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Kasir: $cashierName', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    for (var item in items) {
      final name = item['name']?.toString() ?? '';
      final qty = item['qty']?.toString() ?? '1';
      final priceStr = item['price_formatted']?.toString() ?? '';

      bytes += generator.row([
        PosColumn(text: '${qty}x $name', width: 7),
        PosColumn(text: priceStr, width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: 'Rp ${subtotal.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 6),
        PosColumn(text: '-Rp ${discount.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total Bayar', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp ${grandTotal.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Metode: $paymentMethod', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(1);
    bytes += generator.text(
      footerNote ?? 'Terima Kasih atas Kunjungan Anda!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Menghasilkan byte struk pesanan dapur (Kitchen Ticket)
  static Future<List<int>> generateKitchenTicketBytes({
    required String invoiceCode,
    required String dateStr,
    required String? customerName,
    required String? tableNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      '=== TIKET DAPUR ===',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text('No: $invoiceCode', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Waktu: $dateStr', styles: const PosStyles(align: PosAlign.center));
    if (customerName != null && customerName.isNotEmpty) {
      bytes += generator.text('Pelanggan: $customerName', styles: const PosStyles(bold: true));
    }
    if (tableNumber != null && tableNumber.isNotEmpty) {
      bytes += generator.text('Meja: $tableNumber', styles: const PosStyles(bold: true));
    }
    bytes += generator.hr();

    for (var item in items) {
      final name = item['name']?.toString() ?? '';
      final qty = item['qty']?.toString() ?? '1';
      final notes = item['notes']?.toString();

      bytes += generator.text(
        '${qty}x $name',
        styles: const PosStyles(bold: true, height: PosTextSize.size1),
      );
      if (notes != null && notes.isNotEmpty) {
        bytes += generator.text('   * Catatan: $notes');
      }
    }

    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
