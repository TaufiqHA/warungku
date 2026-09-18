import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/data/models/expense_model.dart';
import 'package:warungku/screens/dashboard/admin_kantor_dashboard_screen.dart';
import 'package:warungku/screens/dashboard/tabs/beranda_kantor_tab.dart';
import 'package:warungku/screens/dashboard/tabs/biaya_tab.dart';
import 'package:warungku/screens/dashboard/tabs/profil_tab.dart';
import 'package:warungku/services/thermal_printer_service.dart';
import 'package:warungku/services/token_manager.dart';
import 'package:warungku/widgets/app_filter_pill.dart';
import 'package:warungku/widgets/biaya_card.dart';
import 'package:warungku/widgets/form_biaya_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThermalPrinterService.instance.socketConnector = (host, port, {timeout}) async {
      throw const SocketException('Test mock offline');
    };
  });

  const adminKantorUser = UserModel(
    id: 'USR-KANTOR-01',
    name: 'Bu Sari (Admin Kantor)',
    username: 'sari_kantor',
    email: 'sari@warungku.com',
    role: 'ADMIN_KANTOR',
  );

  testWidgets('AdminKantorDashboardScreen menampilkan 3 tab dan menerapkan lazy loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminKantorDashboardScreen(testUser: adminKantorUser),
      ),
    );
    await tester.pump();

    // Header & destinasi navigasi dasar
    expect(find.text('Beranda Admin Kantor'), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Biaya'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

    // Hanya tab beranda yang diinstansiasi sejak awal
    expect(find.byType(BerandaKantorTab), findsOneWidget);
    expect(find.byType(BiayaTab, skipOffstage: false), findsNothing);
    expect(find.byType(ProfilTab, skipOffstage: false), findsNothing);

    // Buka tab Biaya Operasional -> judul AppBar & tab dibuat
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Biaya'),
    ));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Biaya Operasional'),
      ),
      findsOneWidget,
    );
    expect(find.byType(BiayaTab), findsOneWidget);
  });

  testWidgets('BerandaKantorTab menampilkan sambutan, metrik beban, rincian pos, dan jalan pintas', (WidgetTester tester) async {
    bool biayaTapped = false;
    bool profilTapped = false;

    await TokenManager.saveSession(token: 'mock_token', user: adminKantorUser);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BerandaKantorTab(
            onGoToBiaya: () => biayaTapped = true,
            onGoToProfil: () => profilTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Kartu sambutan: nama pengguna + badge role
    expect(find.text('Bu Sari (Admin Kantor)'), findsOneWidget);
    expect(find.text('ADMIN KANTOR'), findsOneWidget);

    // Metrik beban pengeluaran
    expect(find.text('Biaya Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);

    // Rincian pos bulan berjalan & daftar pengeluaran terakhir
    expect(find.text('Rincian Pos Biaya'), findsOneWidget);
    expect(find.text('Pengeluaran Terakhir'), findsOneWidget);

    // Jalan pintas menu
    await tester.tap(find.text('Biaya'));
    await tester.pump();
    expect(biayaTapped, true);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(profilTapped, true);
  });

  testWidgets('BiayaTab menampilkan filter ringkas (pill periode & kategori), kartu total, dan tombol tambah', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BiayaTab(),
        ),
      ),
    );
    await tester.pump();

    // Satu baris filter: pill periode (default Bulan Ini) & kategori (default Semua)
    expect(find.byType(AppFilterPill), findsNWidgets(2));
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    // Opsi periode dibuka lewat bottom sheet
    await tester.tap(find.text('Bulan Ini'));
    await tester.pumpAndSettle();

    expect(find.text('Periode'), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Lalu'), findsOneWidget);
    expect(find.text('Pilih Rentang'), findsOneWidget);

    // Pilih 'Hari Ini' -> sheet tertutup & pill periode ikut berubah
    await tester.tap(find.text('Hari Ini'));
    await tester.pumpAndSettle();

    expect(find.text('Periode'), findsNothing);
    expect(find.text('Hari Ini'), findsOneWidget);

    // Opsi kategori dibuka lewat pill kedua
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Bahan Baku'), findsOneWidget);
    expect(find.text('Biaya Operasional'), findsOneWidget);
    expect(find.text('Biaya dll'), findsOneWidget);

    await tester.tap(find.text('Bahan Baku'));
    await tester.pumpAndSettle();

    expect(find.text('Kategori'), findsNothing);
    expect(find.text('Bahan Baku'), findsOneWidget);

    // Kartu total pengeluaran terfilter
    expect(find.text('Total Pengeluaran'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);

    // Daftar riwayat & tombol tambah
    expect(find.text('Riwayat Pengeluaran'), findsOneWidget);
    expect(find.text('Tambah'), findsOneWidget);
  });

  testWidgets('BiayaTab membuka formulir tambah biaya lengkap dengan field wajib', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BiayaTab(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    // Field formulir tambah biaya
    expect(find.text('Tambah Biaya'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Keterangan'), findsOneWidget);
    expect(find.text('Jumlah (Rp)'), findsOneWidget);
    expect(find.text('Tanggal'), findsOneWidget);
    expect(find.text('Pembuat'), findsOneWidget);
    expect(find.text('Simpan Biaya'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Tutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Biaya'), findsNothing);
  });

  testWidgets('FormBiayaDialog memvalidasi field wajib dan mengembalikan data biaya', (WidgetTester tester) async {
    BiayaFormResult? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                captured = await FormBiayaDialog.show(
                  context: context,
                  pembuat: 'Bu Sari',
                );
              },
              child: const Text('Buka Form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Form'));
    await tester.pumpAndSettle();

    // Simpan tanpa mengisi -> validasi muncul
    await tester.tap(find.text('Simpan Biaya'));
    await tester.pump();
    expect(find.text('Keterangan wajib diisi'), findsOneWidget);
    expect(find.text('Jumlah wajib diisi'), findsOneWidget);

    // Pembuat terisi otomatis dari pengguna aktif
    expect(find.text('Bu Sari'), findsOneWidget);

    // Isi formulir dengan kategori non-default
    await tester.tap(find.text('Biaya Operasional'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Token listrik warung',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '150000');
    await tester.pump();

    await tester.tap(find.text('Simpan Biaya'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.kategori, 'Biaya Operasional');
    expect(captured!.keterangan, 'Token listrik warung');
    expect(captured!.jumlah, 150000);
  });

  testWidgets('BiayaCard menampilkan rincian pengeluaran dan aksi ubah/hapus', (WidgetTester tester) async {
    bool editTapped = false;
    bool deleteTapped = false;
    bool cardTapped = false;

    const expense = ExpenseModel(
      id: 'EXP-001',
      kategori: 'Bahan Baku',
      keterangan: 'Belanja Beras 25kg dan Minyak Goreng',
      jumlah: 350000,
      tanggal: '11 Sep 2026',
      pembuat: 'Admin Kantor',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BiayaCard(
            expense: expense,
            onTap: () => cardTapped = true,
            onEdit: () => editTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Belanja Beras 25kg dan Minyak Goreng'), findsOneWidget);
    expect(find.text('Bahan Baku'), findsOneWidget);
    expect(find.text('11 Sep 2026'), findsOneWidget);
    expect(find.text('Rp 350.000'), findsOneWidget);
    expect(find.text('Admin Kantor'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    expect(editTapped, true);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(deleteTapped, true);

    await tester.tap(find.text('Belanja Beras 25kg dan Minyak Goreng'));
    await tester.pump();
    expect(cardTapped, true);
  });

  testWidgets('BiayaCard tanpa callback tampil read-only tanpa tombol aksi', (WidgetTester tester) async {
    const expense = ExpenseModel(
      id: 'EXP-002',
      kategori: 'Utilitas',
      keterangan: 'Token Listrik Warung',
      jumlah: 100000,
      tanggal: '10 Sep 2026',
      pembuat: 'Owner',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BiayaCard(expense: expense),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Token Listrik Warung'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
