import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/screens/dashboard/tabs/penjualan_tab.dart';
import 'package:warungku/services/transaction_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TransactionService.clearCache();
  });

  const adminToko = UserModel(
    id: 'USR-ADMIN-01',
    name: 'Kasir Warung',
    username: 'kasir1',
    email: 'kasir@warungku.com',
    role: 'ADMIN_TOKO',
  );

  const owner = UserModel(
    id: 'USR-OWNER-01',
    name: 'Pak Hendra (Owner)',
    username: 'owner1',
    email: 'owner@warungku.com',
    role: 'OWNER',
  );

  final mockTrxList = [
    {
      'id': 'TRX-20260923001',
      'idTransaksi': 'TRX-20260923001',
      'nama_item': 'Paket Ayam Geprek',
      'jumlah': 1,
      'harga': 20000,
      'status': 'COMPLETED',
      'payment_method': 'CASH',
      'waktu': DateTime.now().toIso8601String(),
      'customer_name': 'Mas Budi',
    }
  ];

  TransactionService createMockService() {
    final client = MockClient((request) async {
      if (request.url.path.contains('/transactions')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': mockTrxList,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{"success": false}', 404);
    });
    return TransactionService(client: client);
  }

  group('PenjualanTab Proteksi Hapus Transaksi Berdasarkan Role', () {
    testWidgets('Admin Toko (canDeleteTransaction: false) tidak dapat menghapus transaksi', (tester) async {
      final service = createMockService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenjualanTab(
              canAddTransaction: true,
              canDeleteTransaction: false,
              testUser: adminToko,
              transactionService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transaksi tampil di daftar
      expect(find.text('Mas Budi'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsWidgets);

      // Dismissible (swipe-to-delete) tidak boleh ada untuk Admin Toko
      expect(find.byType(Dismissible), findsNothing);

      // Ketuk kartu untuk membuka DetailTransaksiDialog
      await tester.tap(find.text('Mas Budi'));
      await tester.pumpAndSettle();

      // Modal detail muncul
      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text('Cetak Ulang'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tombol Hapus / Batalkan tidak boleh ada
      expect(find.text('Hapus Transaksi'), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
    });

    testWidgets('Owner (canDeleteTransaction: true) dapat menghapus transaksi', (tester) async {
      final service = createMockService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenjualanTab(
              canAddTransaction: false,
              canDeleteTransaction: true,
              testUser: owner,
              transactionService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Transaksi tampil di daftar
      expect(find.text('Mas Budi'), findsOneWidget);

      // Dismissible (swipe-to-delete) harus ada untuk Owner
      expect(find.byType(Dismissible), findsOneWidget);

      // Ketuk kartu untuk membuka DetailTransaksiDialog
      await tester.tap(find.text('Mas Budi'));
      await tester.pumpAndSettle();

      // Modal detail muncul dengan opsi Hapus Transaksi
      expect(find.text('Detail Transaksi'), findsOneWidget);
      expect(find.text('Hapus Transaksi'), findsOneWidget);
    });
  });
}
