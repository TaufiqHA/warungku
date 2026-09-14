import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/core/auth/app_roles.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/data/models/product_model.dart';
import 'package:warungku/screens/dashboard/admin_toko_dashboard_screen.dart';
import 'package:warungku/services/menu_catalog_pdf_service.dart';
import 'package:warungku/widgets/atur_urutan_pdf_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MenuCatalogPdfService Tests', () {
    test('formatKPrice formats values correctly as Rp. XX K', () {
      expect(MenuCatalogPdfService.formatKPrice(45000), equals('Rp. 45 K'));
      expect(MenuCatalogPdfService.formatKPrice(6000), equals('Rp. 6 K'));
      expect(MenuCatalogPdfService.formatKPrice(2500), equals('Rp. 2.5 K'));
      expect(MenuCatalogPdfService.formatKPrice(500), equals('Rp. 500'));
      expect(MenuCatalogPdfService.formatKPrice(10000), equals('Rp. 10 K'));
    });

    test('generateMenuCatalogBytes produces valid PDF bytes with categories', () async {
      final sampleData = [
        CategoryMenuData(
          categoryName: 'Lainnya',
          products: [
            const ProductModel(id: '1', name: 'Ikan Gurame Bakar', price: 45000, category: 'Lainnya'),
            const ProductModel(id: '2', name: 'Kerang Dara Rebus', price: 25000, category: 'Lainnya'),
          ],
        ),
        CategoryMenuData(
          categoryName: 'Makanan Ringan',
          products: [
            const ProductModel(id: '3', name: 'Singkong Original', price: 6000, category: 'Makanan Ringan'),
            const ProductModel(id: '4', name: 'Kebab Mayo', price: 20000, category: 'Makanan Ringan'),
          ],
        ),
        CategoryMenuData(
          categoryName: 'Minuman Kopi',
          products: [
            const ProductModel(id: '5', name: 'Kopi Nescafe', price: 10000, category: 'Minuman Kopi'),
          ],
        ),
      ];

      final bytes = await MenuCatalogPdfService.generateMenuCatalogBytes(categoryData: sampleData);
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateMenuCatalogBytes handles single large category gracefully', () async {
      final manyProducts = List.generate(
        20,
        (index) => ProductModel(
          id: 'p_$index',
          name: 'Menu Item #$index',
          price: (index + 1) * 5000,
          category: 'Umum',
        ),
      );

      final sampleData = [
        CategoryMenuData(categoryName: 'Umum', products: manyProducts),
      ];

      final bytes = await MenuCatalogPdfService.generateMenuCatalogBytes(categoryData: sampleData);
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);

      final header = utf8.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });
  });

  group('AturUrutanPdfDialog & AdminToko UI Tests', () {
    final testUserAdmin = const UserModel(
      id: 'USR-002',
      name: 'Kasir Toko',
      username: 'kasir_1',
      email: 'kasir1@warung.com',
      role: AppRoles.adminToko,
    );

    final testProducts = [
      const ProductModel(id: '1', name: 'Ikan Gurame Bakar', price: 45000, category: 'Lainnya'),
      const ProductModel(id: '2', name: 'Kerang Dara Rebus', price: 25000, category: 'Lainnya'),
      const ProductModel(id: '3', name: 'Singkong Original', price: 6000, category: 'Makanan Ringan'),
    ];

    testWidgets('Tombol PDF muncul di AppBar Admin Toko saat tab Manajemen Barang aktif', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminTokoDashboardScreen(
            initialTabIndex: 2, // Tab Barang
            testUser: testUserAdmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cek AppBar actions: tombol PDF terlihat
      final pdfIconFinder = find.byIcon(Icons.picture_as_pdf_outlined);
      expect(pdfIconFinder, findsOneWidget);

      // Klik tombol PDF, dialog AturUrutanPdfDialog harus terbuka
      await tester.tap(pdfIconFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Atur Urutan & Nama'), findsOneWidget);
      expect(find.text('Simpan Layout'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('AturUrutanPdfDialog menampilkan daftar kategori, item, dan tombol reorder', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AturUrutanPdfDialog(
              initialProducts: testProducts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa judul dan kategori
      expect(find.textContaining('Atur Urutan & Nama'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);
      expect(find.text('Makanan Ringan'), findsOneWidget);

      // Memeriksa item-item di dalam kategori
      expect(find.text('Ikan Gurame Bakar'), findsOneWidget);
      expect(find.text('Kerang Dara Rebus'), findsOneWidget);
      expect(find.text('Singkong Original'), findsOneWidget);

      // Memeriksa tombol aksi
      expect(find.text('Simpan Layout'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Uji tekan tombol Simpan Layout
      await tester.tap(find.text('Simpan Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Layout berhasil disimpan'), findsOneWidget);
    });

    testWidgets('AturUrutanPdfDialog dapat mengubah nama kategori via tombol edit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AturUrutanPdfDialog(
              initialProducts: testProducts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Terdapat tombol edit icon
      final editIconFinders = find.byIcon(Icons.edit);
      expect(editIconFinders, findsWidgets);

      // Tentukan klik tombol edit pertama (kategori Lainnya)
      await tester.tap(editIconFinders.first);
      await tester.pumpAndSettle();

      // Muncul dialog Ubah Nama Kategori
      expect(find.text('Ubah Nama Kategori'), findsOneWidget);

      // Masukkan nama baru
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'Spesial Dapur');
      await tester.pumpAndSettle();

      // Tekan Simpan di dialog ubah nama
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Nama kategori pada dialog utama berubah
      expect(find.text('Spesial Dapur'), findsOneWidget);
    });
  });
}
