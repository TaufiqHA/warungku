import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/screens/dashboard/owner_dashboard_screen.dart';
import 'package:warungku/screens/dashboard/tabs/beranda_tab.dart';
import 'package:warungku/screens/dashboard/tabs/laba_rugi_tab.dart';
import 'package:warungku/screens/dashboard/tabs/profil_tab.dart';
import 'package:warungku/screens/dashboard/tabs/user_management_tab.dart';
import 'package:warungku/screens/dashboard/tabs/penjualan_tab.dart';
import 'package:warungku/screens/report/monthly_report_screen.dart';
import 'package:warungku/screens/transaksi/transaksi_penjualan_screen.dart';
import 'package:warungku/services/thermal_printer_service.dart';
import 'package:warungku/services/token_manager.dart';
import 'package:warungku/widgets/detail_transaksi_dialog.dart';
import 'package:warungku/data/models/transaction_model.dart';
import 'package:warungku/data/models/transaction_group_model.dart';
import 'package:warungku/widgets/riwayat_transaksi_card.dart';

/// `19 Sep 2026, 13:22` dalam zona waktu perangkat, dihitung manual agar isi
/// kartu tetap teruji tanpa memakai ulang formatter produksi.
String waktuLokalLengkap(String iso) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final dt = DateTime.parse(iso).toLocal();
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ThermalPrinterService.instance.socketConnector = (host, port, {timeout}) async {
      throw const SocketException('Test mock offline');
    };
  });

  const ownerUser = UserModel(
    id: 'USR-OWNER-01',
    name: 'Bpk. Hendra (Owner)',
    username: 'hendra_owner',
    email: 'hendra@warungku.com',
    role: 'OWNER',
  );

  testWidgets('OwnerDashboardScreen menampilkan 5 tab owner dan header yang sesuai', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboardScreen(testUser: ownerUser),
      ),
    );
    await tester.pump();

    // Verifikasi judul AppBar awal
    expect(find.text('Beranda Owner'), findsOneWidget);

    // Verifikasi 5 tab destinasi di BottomNavigationBar
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Laba Rugi'), findsWidgets);
    expect(find.text('Penjualan'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Pengguna'), findsWidgets);
  });

  testWidgets('BerandaTab untuk Owner menampilkan shortcut lengkap dan tombol logout cepat', (WidgetTester tester) async {
    bool labaRugiTapped = false;
    bool monthlyReportTapped = false;
    bool quickLogoutTapped = false;

    await TokenManager.saveSession(token: 'mock_token', user: ownerUser);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BerandaTab(
            onGoToLabaRugi: () => labaRugiTapped = true,
            onOpenMonthlyReport: () => monthlyReportTapped = true,
            onQuickLogout: () => quickLogoutTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi nama owner dan badge
    expect(find.text('Bpk. Hendra (Owner)'), findsOneWidget);
    expect(find.text('OWNER'), findsOneWidget);

    // Verifikasi tombol logout cepat
    final logoutBtn = find.byIcon(Icons.logout_rounded);
    expect(logoutBtn, findsOneWidget);
    await tester.tap(logoutBtn);
    await tester.pump();
    expect(quickLogoutTapped, true);

    // Verifikasi shortcuts owner
    expect(find.text('Laba Rugi'), findsOneWidget);
    expect(find.text('Lap. Bulanan'), findsOneWidget);

    await tester.tap(find.text('Laba Rugi'));
    await tester.pump();
    expect(labaRugiTapped, true);

    await tester.tap(find.text('Lap. Bulanan'));
    await tester.pump();
    expect(monthlyReportTapped, true);
  });

  testWidgets('LabaRugiTab menampilkan neraca laba bersih, filter periode, rincian beban, dan tombol laporan bulanan', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool openReportClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabaRugiTab(
            onOpenMonthlyReport: () => openReportClicked = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi filter chips
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsWidgets);
    expect(find.text('Pilih Tanggal'), findsOneWidget);

    // Verifikasi kartu neraca
    expect(find.textContaining('Laba Bersih'), findsOneWidget);
    expect(find.text('Total Penjualan'), findsOneWidget);
    expect(find.text('Total Pengeluaran'), findsOneWidget);

    // Verifikasi rincian pengeluaran per tanggal
    expect(find.text('Rincian Pengeluaran'), findsOneWidget);

    // Verifikasi tombol Buka Laporan Item
    expect(find.text('Laporan Bulanan per Item'), findsOneWidget);
    final openBtn = find.text('Buka Laporan Item');
    expect(openBtn, findsOneWidget);

    await tester.tap(openBtn);
    await tester.pump();
    expect(openReportClicked, true);
  });

  testWidgets('MonthlyReportScreen menampilkan filter bulan, metrik ringkasan bulanan, dan ranking menu', (WidgetTester tester) async {
    await TokenManager.saveSession(token: 'mock_token', user: ownerUser);

    await tester.pumpWidget(
      const MaterialApp(
        home: MonthlyReportScreen(
          initialMonth: 9,
          initialYear: 2026,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi header dan pemilih
    expect(find.text('Laporan Bulanan'), findsOneWidget);
    expect(find.text('September'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Semua Menu'), findsOneWidget);

    // Verifikasi metrik ringkasan
    expect(find.text('Total Order'), findsOneWidget);
    expect(find.text('Total Omzet'), findsOneWidget);
    expect(find.text('Rata-rata Penjualan per Order (AOV)'), findsOneWidget);

    // Verifikasi bagian Menu Terlaris dan Rincian Penjualan Harian
    expect(find.text('Menu Terlaris (Top Selling)'), findsOneWidget);
    expect(find.text('Rincian Penjualan Harian'), findsOneWidget);

    // Verifikasi interaktivitas baris tanggal
    final dayRow = find.textContaining('Sep');
    expect(dayRow, findsWidgets);
    await tester.tap(dayRow.first);
    await tester.pumpAndSettle();
  });

  testWidgets('UserManagementTab memuat daftar user dan modal edit akun dengan field password', (WidgetTester tester) async {
    await TokenManager.saveSession(token: 'mock_token', user: ownerUser);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserManagementTab(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi judul & daftar akun
    expect(find.text('Daftar Pengguna Sistem'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsWidgets);

    // Buka edit dialog pada salah satu user
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi field formulir edit
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password Baru (Opsional)'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Tutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('ProfilTab untuk Owner menampilkan formulir Profil Warung lengkap', (WidgetTester tester) async {
    await TokenManager.saveSession(token: 'mock_token', user: ownerUser);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfilTab(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi nama dan role
    expect(find.text('Bpk. Hendra (Owner)'), findsWidgets);
    expect(find.text('OWNER'), findsOneWidget);

    // Verifikasi bagian Profil Warung hadir untuk role Owner
    expect(find.text('Profil Warung'), findsOneWidget);
    expect(find.text('Nama Warung'), findsOneWidget);
    expect(find.text('Alamat Warung'), findsOneWidget);
    expect(find.text('Email Kontak'), findsOneWidget);
    expect(find.text('Simpan Profil'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('PenjualanTab untuk Owner (canAddTransaction: false) tidak menampilkan tombol Input Transaksi dan default filter Minggu Ini', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PenjualanTab(canAddTransaction: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi bahwa tombol Input Transaksi tidak ada pada layar
    expect(find.text('Input Transaksi'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Verifikasi filter default otomatis Minggu Ini untuk Owner
    expect(find.text('Minggu Ini'), findsOneWidget);
    expect(find.text('Total Penjualan (Minggu Ini)'), findsOneWidget);

    // Buka sheet filter via AppFilterPill
    await tester.tap(find.text('Minggu Ini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifikasi sheet filter terbuka dengan opsi periode
    expect(find.text('Periode Penjualan'), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    // Pilih opsi 'Bulan Ini'
    await tester.tap(find.text('Bulan Ini'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi header layar Penjualan Harian dan tombol refresh
    expect(find.text('Penjualan Harian'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsWidgets);

    // Verifikasi filter berubah
    expect(find.text('Total Penjualan (Bulan Ini)'), findsOneWidget);
  });

  testWidgets('RiwayatTransaksiCard compact menampilkan avatar receipt, rincian waktu & item, badge bayar, dan panah detail', (WidgetTester tester) async {
    final group = TransactionGroup(
      idTransaksi: 'TRX-OWNER-COMPACT-01',
      customerName: 'Kak Jimmy',
      waktu: '2026-09-19T13:22:51Z',
      dicatatOleh: 'Admin Toko',
      paymentMethod: 'CASH',
      orderStatus: 'COMPLETED',
      items: const [
        TransactionModel(
          idTransaksi: 'TRX-OWNER-COMPACT-01',
          id: '1',
          namaItem: 'Ayam Geprek Sambal Korek',
          jumlah: 2,
          harga: 15000,
          waktu: '2026-09-19T13:22:51Z',
          dicatatOleh: 'Admin Toko',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Kak Jimmy',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiwayatTransaksiCard(group: group, isCompact: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kak Jimmy'), findsOneWidget);
    expect(find.text('TRX-OWNER-COMPACT-01'), findsOneWidget);
    expect(
      find.textContaining(waktuLokalLengkap('2026-09-19T13:22:51Z')),
      findsOneWidget,
    );
    expect(find.textContaining('2 item'), findsOneWidget);
    expect(find.text('CASH'), findsOneWidget);
    expect(find.text('Rp 30.000'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
  });

  testWidgets('TransaksiPenjualanScreen menampilkan Akses Ditolak jika dibuka oleh role Owner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TransaksiPenjualanScreen(testUser: ownerUser),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi tampilan blokir akses
    expect(find.text('Akses Ditolak'), findsOneWidget);
    expect(find.textContaining('Owner tidak dapat menambahkan transaksi'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });

  testWidgets('DetailTransaksiDialog untuk Owner menampilkan tombol Hapus Transaksi', (WidgetTester tester) async {
    bool deleteClicked = false;
    const dummyTrx = TransactionModel(
      idTransaksi: 'TRX-OWNER-DEL',
      id: 'PRD-1',
      namaItem: 'Kopi Susu Gula Aren',
      jumlah: 2,
      harga: 15000,
      waktu: '2026-09-13T10:00:00Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'Cash',
      orderStatus: 'COMPLETED',
      customerName: 'Meja 3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DetailTransaksiDialog.show(
                context: context,
                trx: dummyTrx,
                cancelText: 'Hapus Transaksi',
                onCancel: () => deleteClicked = true,
              ),
              child: const Text('Buka Detail'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Buka Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Hapus Transaksi'), findsOneWidget);

    await tester.tap(find.text('Hapus Transaksi'));
    await tester.pumpAndSettle();
    expect(deleteClicked, true);
  });

  testWidgets('OwnerDashboardScreen menerapkan lazy loading tab (hanya instansiasi tab saat diklik)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboardScreen(testUser: ownerUser),
      ),
    );
    await tester.pump();

    // Awal: Hanya BerandaTab yang diinstansiasi (tab lain belum pernah dibuat sama sekali)
    expect(find.byType(BerandaTab), findsOneWidget);
    expect(find.byType(LabaRugiTab, skipOffstage: false), findsNothing);
    expect(find.byType(PenjualanTab, skipOffstage: false), findsNothing);
    expect(find.byType(ProfilTab, skipOffstage: false), findsNothing);
    expect(find.byType(UserManagementTab, skipOffstage: false), findsNothing);

    // Klik tab Laba Rugi pada NavigationBar -> baru diinstansiasi
    final navBarLabaRugi = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Laba Rugi'),
    );
    await tester.tap(navBarLabaRugi);
    await tester.pump();

    expect(find.byType(LabaRugiTab), findsOneWidget); // Tab aktif terlihat
    expect(find.byType(BerandaTab, skipOffstage: false), findsOneWidget); // Tetap dipertahankan di IndexedStack
    expect(find.byType(PenjualanTab, skipOffstage: false), findsNothing); // Masih belum diinstansiasi
    expect(find.byType(ProfilTab, skipOffstage: false), findsNothing);
    expect(find.byType(UserManagementTab, skipOffstage: false), findsNothing);

    // Klik tab Pengguna pada NavigationBar -> baru diinstansiasi
    final navBarPengguna = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Pengguna'),
    );
    await tester.tap(navBarPengguna);
    await tester.pump();

    expect(find.byType(UserManagementTab), findsOneWidget); // Tab aktif terlihat
    expect(find.byType(LabaRugiTab, skipOffstage: false), findsOneWidget); // Tetap dipertahankan
    expect(find.byType(PenjualanTab, skipOffstage: false), findsNothing); // Tetap tidak pernah diinstansiasi
  });

  testWidgets('LabaRugiTab otomatis memuat dan menampilkan Rincian Harian saat diakses', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LabaRugiTab(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verifikasi seksi Rincian Harian otomatis tampil tanpa tombol manual
    expect(find.text('Rincian Harian'), findsOneWidget);
    expect(find.text('Muat Data Penjualan'), findsNothing);
  });
}
