import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/screens/dashboard/tabs/barang_tab.dart';
import 'package:warungku/widgets/app_dropdown_field.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BarangTab Kategori Dropdown', () {
    Future<void> bukaFormTambahMenu(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BarangTab())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Menu'));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan dropdown kategori pada modal Tambah Menu', (tester) async {
      await bukaFormTambahMenu(tester);

      expect(find.text('Tambah Menu'), findsOneWidget);
      expect(find.byType(AppDropdownField<String>), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);

      // Pastikan field kategori baru belum muncul
      expect(find.text('Nama Kategori Baru'), findsNothing);
    });

    testWidgets('memilih "Tambah Kategori Baru..." memunculkan text field kategori baru', (tester) async {
      await bukaFormTambahMenu(tester);

      // Ketuk dropdown kategori
      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();

      // Pilih opsi Tambah Kategori Baru...
      expect(find.text('Tambah Kategori Baru...'), findsOneWidget);
      await tester.tap(find.text('Tambah Kategori Baru...').last);
      await tester.pumpAndSettle();

      // Field kategori baru sekarang harus muncul
      expect(find.text('Nama Kategori Baru'), findsOneWidget);

      // Validasi saat submit kosong
      final tombolTambah = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tambah'),
      );
      await tester.tap(tombolTambah);
      await tester.pumpAndSettle();

      expect(find.text('Kategori baru wajib diisi'), findsOneWidget);
    });

    testWidgets('mengubah kembali pilihan dari kategori baru ke kategori yang ada menyembunyikan input baru', (tester) async {
      await bukaFormTambahMenu(tester);

      // Buka dropdown dan pilih Tambah Kategori Baru...
      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Kategori Baru...').last);
      await tester.pumpAndSettle();
      expect(find.text('Nama Kategori Baru'), findsOneWidget);

      // Pilih kembali ke 'Minuman'
      await tester.tap(find.byType(AppDropdownField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minuman').last);
      await tester.pumpAndSettle();

      // Input kategori baru hilang
      expect(find.text('Nama Kategori Baru'), findsNothing);
    });
  });
}
