import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/data/models/expense_model.dart';
import 'package:warungku/data/models/transaction_group_model.dart';
import 'package:warungku/data/models/transaction_model.dart';
import 'package:warungku/services/laba_rugi_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LabaRugiPdfService Helper Tests', () {
    test('formatCurrency formats positive and negative amounts correctly', () {
      expect(LabaRugiPdfService.formatCurrency(37833000), equals('Rp. 37.833.000'));
      expect(LabaRugiPdfService.formatCurrency(60398500), equals('Rp. 60.398.500'));
      expect(LabaRugiPdfService.formatCurrency(-22565500), equals('-Rp. 22.565.500'));
      expect(LabaRugiPdfService.formatCurrency(0), equals('Rp. 0'));
      expect(LabaRugiPdfService.formatCurrency(25000), equals('Rp. 25.000'));
    });

    test('formatTanggalCetak formats date and time in Indonesian', () {
      final dt = DateTime(2026, 9, 21, 16, 56);
      expect(LabaRugiPdfService.formatTanggalCetak(dt), equals('21 September 2026 16:56'));
    });
  });

  group('LabaRugiPdfService PDF Generation Tests', () {
    test('generateLabaRugiPdfBytes produces valid PDF byte stream with items', () async {
      final groups = [
        const TransactionGroup(
          idTransaksi: 'TRX-20260921140504',
          customerName: 'Pelanggan 1',
          waktu: '2026-09-21T07:05:12.000000Z',
          dicatatOleh: 'Kasir',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          items: [
            TransactionModel(
              idTransaksi: 'TRX-20260921140504',
              id: '1',
              namaItem: 'Mix Gorengan',
              jumlah: 1,
              harga: 25000,
              waktu: '2026-09-21T07:05:12.000000Z',
              dicatatOleh: 'Kasir',
              catatan: '',
              paymentMethod: 'CASH',
              orderStatus: 'COMPLETED',
              customerName: 'Pelanggan 1',
            ),
            TransactionModel(
              idTransaksi: 'TRX-20260921140504',
              id: '2',
              namaItem: 'Martabak Telur',
              jumlah: 1,
              harga: 25000,
              waktu: '2026-09-21T07:05:12.000000Z',
              dicatatOleh: 'Kasir',
              catatan: '',
              paymentMethod: 'CASH',
              orderStatus: 'COMPLETED',
              customerName: 'Pelanggan 1',
            ),
          ],
        ),
      ];

      final expenses = [
        const ExpenseModel(
          id: '1',
          kategori: 'Operasional',
          keterangan: 'Beli gas elpiji',
          jumlah: 45000,
          tanggal: '2026-09-21',
          pembuat: 'Owner',
        ),
      ];

      final bytes = await LabaRugiPdfService.generateLabaRugiPdfBytes(
        filterTitle: 'Bulan Ini',
        totalRevenue: 50000,
        totalExpense: 45000,
        groups: groups,
        expenses: expenses,
        printDateTime: DateTime(2026, 9, 21, 16, 56),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLabaRugiPdfBytes handles empty data gracefully', () async {
      final bytes = await LabaRugiPdfService.generateLabaRugiPdfBytes(
        filterTitle: 'Hari Ini',
        totalRevenue: 0,
        totalExpense: 0,
        groups: const [],
        expenses: const [],
        printDateTime: DateTime(2026, 9, 21, 16, 56),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLabaRugiPdfBytes handles deficit/rugi correctly', () async {
      final bytes = await LabaRugiPdfService.generateLabaRugiPdfBytes(
        filterTitle: 'Bulan Ini',
        totalRevenue: 37833000,
        totalExpense: 60398500,
        groups: const [],
        expenses: const [],
        printDateTime: DateTime(2026, 9, 21, 16, 56),
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLabaRugiPdfBytes handles multi-page long list', () async {
      final items = List.generate(
        60,
        (i) => TransactionModel(
          idTransaksi: 'TRX-202609210000$i',
          id: '$i',
          namaItem: 'Menu Spesial Nomor $i dengan deskripsi agak panjang',
          jumlah: (i % 3) + 1,
          harga: 15000,
          waktu: '2026-09-21T07:00:00.000000Z',
          dicatatOleh: 'Kasir',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Pelanggan $i',
        ),
      );

      final groups = [
        TransactionGroup(
          idTransaksi: 'TRX-BATCH',
          customerName: 'Pelanggan',
          waktu: '2026-09-21T07:00:00.000000Z',
          dicatatOleh: 'Kasir',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          items: items,
        ),
      ];

      final bytes = await LabaRugiPdfService.generateLabaRugiPdfBytes(
        filterTitle: 'Bulan Ini',
        totalRevenue: 1000000,
        totalExpense: 500000,
        groups: groups,
        expenses: const [],
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLabaRugiPdfBytes handles very large dataset exceeding 20 pages without PdfTooBigPageException', () async {
      // 800 items spans well over 20 pages in A4 format (which previously threw PdfTooBigPageException)
      final items = List.generate(
        800,
        (i) => TransactionModel(
          idTransaksi: 'TRX-BIG-${i.toString().padLeft(4, '0')}',
          id: '$i',
          namaItem: 'Menu Spesial Nomor $i',
          jumlah: 1,
          harga: 20000,
          waktu: '2026-09-21T07:00:00.000000Z',
          dicatatOleh: 'Kasir',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Pelanggan $i',
        ),
      );

      final groups = [
        TransactionGroup(
          idTransaksi: 'TRX-LARGE-BATCH',
          customerName: 'Pelanggan Besar',
          waktu: '2026-09-21T07:00:00.000000Z',
          dicatatOleh: 'Kasir',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          items: items,
        ),
      ];

      final bytes = await LabaRugiPdfService.generateLabaRugiPdfBytes(
        filterTitle: 'Semua',
        totalRevenue: 16000000,
        totalExpense: 0,
        groups: groups,
        expenses: const [],
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });
}
