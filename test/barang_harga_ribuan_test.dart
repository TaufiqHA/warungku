import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/core/utils/angka_ribuan.dart';
import 'package:warungku/screens/dashboard/tabs/barang_tab.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TextEditingValue nilai(String text) =>
      TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

  group('AngkaRibuan', () {
    test('memformat angka dengan titik pemisah ribuan', () {
      expect(AngkaRibuan.format(0), '0');
      expect(AngkaRibuan.format(500), '500');
      expect(AngkaRibuan.format(15000), '15.000');
      expect(AngkaRibuan.format(1234567), '1.234.567');
      expect(AngkaRibuan.format(1234567890), '1.234.567.890');
    });

    test('membaca kembali nominal bertitik menjadi angka', () {
      expect(AngkaRibuan.parse('15.000'), 15000);
      expect(AngkaRibuan.parse('1.234.567'), 1234567);
      expect(AngkaRibuan.parse('15'), 15);
      expect(AngkaRibuan.parse(''), isNull);
      expect(AngkaRibuan.parse(null), isNull);
      expect(AngkaRibuan.parse('abc'), isNull);
    });

    test('toDigits membuang pemisah untuk payload API', () {
      expect(AngkaRibuan.toDigits('15.000'), '15000');
      expect(AngkaRibuan.toDigits(''), '');
    });
  });

  group('RibuanInputFormatter', () {
    const formatter = RibuanInputFormatter();

    test('menyisipkan titik saat pengguna mengetik angka', () {
      expect(formatter.formatEditUpdate(nilai(''), nilai('1')).text, '1');
      expect(formatter.formatEditUpdate(nilai('1'), nilai('15')).text, '15');
      expect(formatter.formatEditUpdate(nilai('15'), nilai('150')).text, '150');
      expect(formatter.formatEditUpdate(nilai('150'), nilai('1500')).text, '1.500');
      expect(formatter.formatEditUpdate(nilai('1.500'), nilai('1.5000')).text, '15.000');
      expect(formatter.formatEditUpdate(nilai('15.000'), nilai('15.0000')).text, '150.000');
    });

    test('membuang karakter selain angka dan nol di depan', () {
      expect(formatter.formatEditUpdate(nilai(''), nilai('a1b5c')).text, '15');
      expect(formatter.formatEditUpdate(nilai(''), nilai('Rp 20.000')).text, '20.000');
      expect(formatter.formatEditUpdate(nilai(''), nilai('015000')).text, '15.000');
    });

    test('mengosongkan field saat tidak ada angka', () {
      expect(formatter.formatEditUpdate(nilai('15.000'), nilai('')).text, '');
      expect(formatter.formatEditUpdate(nilai('15.000'), nilai('abc')).text, '');
    });

    test('kursor selalu di akhir teks', () {
      final result = formatter.formatEditUpdate(nilai('1.500'), nilai('1.5000'));
      expect(result.selection.baseOffset, result.text.length);
    });
  });

  group('Modal Tambah Menu', () {
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

    /// Tombol konfirmasi di dalam dialog (menghindari tombol FAB 'Tambah').
    Finder tombolDialog(String text) => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(text),
        );

    String hargaFieldText(WidgetTester tester) =>
        tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller?.text ?? '';

    testWidgets('field harga menampilkan titik pemisah ribuan otomatis', (WidgetTester tester) async {
      await bukaFormTambahMenu(tester);

      expect(find.text('Harga (Rp)'), findsOneWidget);
      expect(find.text('15.000'), findsOneWidget); // hint contoh format

      await tester.enterText(find.byType(TextFormField).at(1), '15000');
      await tester.pump();

      // Nilai yang tampil sudah bertitik, bukan 15000
      expect(hargaFieldText(tester), '15.000');
      expect(find.text('15000'), findsNothing);
    });

    testWidgets('harga bertitik tersimpan sebagai angka penuh (validasi lolos)', (WidgetTester tester) async {
      await bukaFormTambahMenu(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Es Teh Manis');
      await tester.enterText(find.byType(TextFormField).at(1), '4000');
      await tester.pump();

      expect(hargaFieldText(tester), '4.000');

      await tester.tap(tombolDialog('Tambah'));
      await tester.pumpAndSettle();

      // Validasi lolos -> dialog tertutup & tidak ada pesan error harga
      expect(find.text('Harus berupa angka'), findsNothing);
      expect(find.text('Harga wajib diisi'), findsNothing);
      expect(find.text('Tambah Menu'), findsNothing);
    });

    testWidgets('input huruf ditolak dan harga kosong memunculkan validasi', (WidgetTester tester) async {
      await bukaFormTambahMenu(tester);

      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.pump();

      // Semua karakter non-angka dibuang sehingga field kosong
      expect(hargaFieldText(tester), '');

      await tester.tap(tombolDialog('Tambah'));
      await tester.pump();

      expect(find.text('Harga wajib diisi'), findsOneWidget);
      expect(find.text('Tambah Menu'), findsOneWidget); // dialog tetap terbuka
    });
  });
}
