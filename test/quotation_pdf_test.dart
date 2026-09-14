import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/data/models/transaction_model.dart';
import 'package:warungku/services/quotation_pdf_service.dart';
import 'package:warungku/widgets/sales_receipt_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'warung_name': 'WARUNG KITA',
      'warung_address': 'Jl. Raya Warung No. 123',
    });
  });

  group('QuotationPdfService Helper Tests', () {
    test('formatRupiah formats currency correctly', () {
      expect(QuotationPdfService.formatRupiah(40000), equals('Rp. 40.000'));
      expect(QuotationPdfService.formatRupiah(5000), equals('Rp. 5.000'));
      expect(QuotationPdfService.formatRupiah(99900), equals('Rp. 99.900'));
    });

    test('extractDateOnly parses formatted date string or ISO string', () {
      expect(QuotationPdfService.extractDateOnly('13/09/2026 21:58'), equals('13/09/2026'));
      expect(QuotationPdfService.extractDateOnly('2026-09-13T21:58:43.000Z'), equals('13/09/2026'));
    });

    test('generateQuotationPdfBytes produces valid PDF document bytes', () async {
      final items = [
        const SalesReceiptItem(
          name: 'Nasi Ikan Nila Radja (tumis cabe hijau) free teh tawar',
          quantity: 1,
          price: 40000,
          subtotal: 40000,
        ),
        const SalesReceiptItem(
          name: 'Nasi Putih',
          quantity: 1,
          price: 10000,
          subtotal: 10000,
        ),
        const SalesReceiptItem(
          name: 'Teh Tawar',
          quantity: 1,
          price: 5000,
          subtotal: 5000,
        ),
        const SalesReceiptItem(
          name: 'Mix Seafood UK S (Udang, Cumi, Kerang Hijau, Dara, Tahu, Jagung) (Saus Padang/Asam Manis/ Chili Singapore)',
          quantity: 1,
          price: 35000,
          subtotal: 35000,
        ),
      ];

      final bytes = await QuotationPdfService.generateQuotationPdfBytes(
        storeName: 'WARUNG KITA',
        storeAddress: 'Jl. Raya Warung No. 123',
        transactionId: 'TRX-20260913215843',
        dateTimeStr: '13/09/2026 21:58',
        customerName: 'Pelanggan Umum',
        cashierName: 'Admin Warung',
        items: items,
        subtotal: 90000,
      );

      expect(bytes, isNotEmpty);
      // Validasi PDF signature %PDF-
      final headerStr = utf8.decode(bytes.take(5).toList(), allowMalformed: true);
      expect(headerStr, equals('%PDF-'));
    });
  });

  group('SalesReceiptDialog Export PDF UI Tests', () {
    const sampleTrx = TransactionModel(
      id: '1',
      idTransaksi: 'TRX-20260913215843',
      namaItem: 'Nasi Ikan Nila Radja',
      jumlah: 1,
      harga: 40000,
      waktu: '2026-09-13T21:58:43.000Z',
      dicatatOleh: 'Admin Warung',
      catatan: '',
      customerName: 'Pelanggan Umum',
      paymentMethod: 'Cash',
      orderStatus: 'SUCCESS',
    );

    testWidgets('SalesReceiptDialog menampilkan tombol Export PDF di actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SalesReceiptDialog.showFromTransaction(
                  context: context,
                  trx: sampleTrx,
                  confirmButtonText: 'Cetak Ulang',
                ),
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Cek tombol Export PDF muncul
      final exportBtnFinder = find.widgetWithText(OutlinedButton, 'Export PDF');
      expect(exportBtnFinder, findsOneWidget);

      final pdfIconFinder = find.byIcon(Icons.picture_as_pdf_outlined);
      expect(pdfIconFinder, findsOneWidget);

      // Cek tombol Tutup dan Cetak Ulang juga ada
      expect(find.text('Tutup'), findsOneWidget);
      expect(find.text('Cetak Ulang'), findsOneWidget);
    });
  });
}
