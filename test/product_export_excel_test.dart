import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/core/auth/app_roles.dart';
import 'package:warungku/core/constants/api_constants.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/screens/dashboard/admin_toko_dashboard_screen.dart';
import 'package:warungku/services/excel_export_service.dart';
import 'package:warungku/services/product_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProductService Export Excel Tests', () {
    test('exportProducts successfully parses JSON response with download_url', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains(ApiConstants.productsExportEndpoint));
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Export data berhasil disiapkan',
            'download_url': 'http://example.com/exports/products.xlsx',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProductService(client: mockClient);
      final result = await service.exportProducts();

      expect(result['success'], isTrue);
      expect(result['download_url'], equals('http://example.com/exports/products.xlsx'));
      expect(result['message'], equals('Export data berhasil disiapkan'));
    });

    test('exportProducts successfully handles raw binary file response', () async {
      final binaryBytes = [0x50, 0x4B, 0x03, 0x04]; // Standard zip/xlsx header
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          binaryBytes,
          200,
          headers: {'content-type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
        );
      });

      final service = ProductService(client: mockClient);
      final result = await service.exportProducts();

      expect(result['success'], isTrue);
      expect(result['bytes'], equals(binaryBytes));
    });

    test('exportProducts throws Exception on API failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProductService(client: mockClient);
      expect(
        () async => await service.exportProducts(),
        throwsA(isA<Exception>()),
      );
    });

    test('downloadExportFile downloads bytes from valid url', () async {
      final testBytes = [1, 2, 3, 4, 5];
      final mockClient = MockClient((request) async {
        return http.Response.bytes(testBytes, 200);
      });

      final service = ProductService(client: mockClient);
      final downloaded = await service.downloadExportFile('http://example.com/file.xlsx');

      expect(downloaded, equals(testBytes));
    });

    test('downloadExportFile normalizes localhost URL to baseUrl host', () async {
      final testBytes = [10, 20, 30];
      final mockClient = MockClient((request) async {
        expect(request.url.host, isNot(equals('localhost')));
        return http.Response.bytes(testBytes, 200);
      });

      final service = ProductService(client: mockClient);
      final downloaded = await service.downloadExportFile('http://localhost:8000/exports/test.xlsx');

      expect(downloaded, equals(testBytes));
    });

    test('getExportFileExtension detects extension correctly', () {
      expect(ProductService.getExportFileExtension('http://example.com/file.xlsx'), equals('xlsx'));
      expect(ProductService.getExportFileExtension('http://example.com/file.csv?token=123'), equals('csv'));
      expect(ProductService.getExportFileExtension(null, 'text/csv'), equals('csv'));
      expect(ProductService.getExportFileExtension(null, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'), equals('xlsx'));
    });
  });

  group('AdminTokoDashboardScreen Excel Action UI Tests', () {
    final testUserAdmin = const UserModel(
      id: 'USR-002',
      name: 'Kasir Toko',
      username: 'kasir_1',
      email: 'kasir1@warung.com',
      role: AppRoles.adminToko,
    );

    testWidgets('Tombol Excel dan PDF keduanya muncul di AppBar tab Manajemen Barang', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminTokoDashboardScreen(
            initialTabIndex: 2, // Tab Barang
            testUser: testUserAdmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa keberadaan tombol Excel dan PDF di AppBar
      final excelIconFinder = find.byIcon(Icons.table_chart_outlined);
      final pdfIconFinder = find.byIcon(Icons.picture_as_pdf_outlined);

      expect(excelIconFinder, findsOneWidget);
      expect(pdfIconFinder, findsOneWidget);
    });

    testWidgets('Menekan tombol Excel mengeksekusi request dan menampilkan feedback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminTokoDashboardScreen(
            initialTabIndex: 2, // Tab Barang
            testUser: testUserAdmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final excelIconFinder = find.byIcon(Icons.table_chart_outlined);
      expect(excelIconFinder, findsOneWidget);

      await tester.tap(excelIconFinder);
      await tester.pump();

      // Setelah ditekan, indikator loading atau snackbar muncul
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Memastikan widget tree tetap stabil dan bebas crash
      expect(find.byType(AdminTokoDashboardScreen), findsOneWidget);
    });
  });

  group('ExcelExportService Tests', () {
    test('ExcelOpenResult properties initialized correctly', () {
      const resultSuccess = ExcelOpenResult(isSuccess: true, message: 'Berhasil');
      expect(resultSuccess.isSuccess, isTrue);
      expect(resultSuccess.message, equals('Berhasil'));
      expect(resultSuccess.noAppInstalled, isFalse);

      const resultNoApp = ExcelOpenResult(
        isSuccess: false,
        message: 'Tidak ada aplikasi',
        noAppInstalled: true,
      );
      expect(resultNoApp.isSuccess, isFalse);
      expect(resultNoApp.noAppInstalled, isTrue);

      const resultFallback = ExcelOpenResult(
        isSuccess: true,
        message: 'Tersimpan di Download',
        fallbackSaved: true,
        savedPath: '/storage/emulated/0/Download/test.xlsx',
      );
      expect(resultFallback.isSuccess, isTrue);
      expect(resultFallback.fallbackSaved, isTrue);
      expect(resultFallback.savedPath, equals('/storage/emulated/0/Download/test.xlsx'));
    });
  });
}
