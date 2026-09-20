import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/core/utils/tanggal_formatter.dart';
import 'package:warungku/data/models/auth_model.dart';
import 'package:warungku/main.dart';
import 'package:warungku/screens/dashboard/admin_kantor_dashboard_screen.dart';
import 'package:warungku/screens/dashboard/admin_toko_dashboard_screen.dart';
import 'package:warungku/screens/dashboard/dashboard_dispatcher.dart';
import 'package:warungku/screens/dashboard/owner_dashboard_screen.dart';
import 'package:warungku/screens/dashboard/tabs/barang_tab.dart';
import 'package:warungku/screens/dashboard/tabs/beranda_tab.dart';
import 'package:warungku/screens/dashboard/tabs/laba_rugi_tab.dart';
import 'package:warungku/screens/dashboard/tabs/penjualan_tab.dart';
import 'package:warungku/screens/dashboard/tabs/profil_tab.dart';
import 'package:warungku/services/token_manager.dart';
import 'package:warungku/screens/transaksi/transaksi_penjualan_screen.dart';
import 'package:warungku/data/models/product_model.dart';
import 'package:warungku/data/models/transaction_model.dart';
import 'package:warungku/widgets/app_autocomplete_field.dart';
import 'package:warungku/widgets/orderan_aktif_card.dart';
import 'package:warungku/widgets/tambah_item_pesanan_dialog.dart';
import 'package:warungku/widgets/detail_transaksi_dialog.dart';
import 'package:warungku/widgets/filter_custom_tanggal_dialog.dart';
import 'package:warungku/widgets/sales_receipt_dialog.dart';
import 'package:warungku/data/models/cart_item_model.dart';
import 'package:warungku/data/models/transaction_group_model.dart';
import 'package:warungku/widgets/kitchen_receipt_dialog.dart';
import 'package:warungku/widgets/riwayat_transaksi_card.dart';
import 'package:warungku/services/thermal_printer_service.dart';
import 'package:warungku/widgets/printer_settings_dialog.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThermalPrinterService.instance.socketConnector = (host, port, {timeout}) async {
      throw const SocketException('Test mock offline socket');
    };
    ThermalPrinterService.instance.bluetoothConnector = (mac) async => true;
    ThermalPrinterService.instance.bluetoothWriter = (bytes) async => true;
    ThermalPrinterService.instance.bluetoothScanner = () async => [
      BluetoothInfo(name: 'RPP02N Thermal', macAdress: '66:22:33:44:55:66'),
    ];
  });

  const adminTokoUser = UserModel(
    id: 'USR-001',
    name: 'Kasir Toko',
    username: 'admin_toko',
    email: 'admintoko@warung.com',
    role: 'ADMIN_TOKO',
  );

  const ownerUser = UserModel(
    id: 'USR-002',
    name: 'Pak Owner',
    username: 'owner_boss',
    email: 'owner@warung.com',
    role: 'OWNER',
  );

  const adminKantorUser = UserModel(
    id: 'USR-003',
    name: 'Staf Kantor',
    username: 'admin_kantor',
    email: 'kantor@warung.com',
    role: 'ADMIN_KANTOR',
  );

  testWidgets('Layar Login menampilkan elemen utama dan validasi form', (WidgetTester tester) async {
    await tester.pumpWidget(const WarungkuApp());

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Admin Toko hanya dapat mengakses AdminTokoDashboardScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminTokoDashboardScreen(testUser: adminTokoUser),
      ),
    );
    await tester.pump();

    // Verifikasi judul dan 4 tab
    expect(find.text('Beranda Admin Toko'), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Penjualan'), findsWidgets);
    expect(find.text('Barang'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('Admin Toko yang mencoba membuka OwnerDashboard dicegat oleh RoleGuard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboardScreen(testUser: adminTokoUser),
      ),
    );
    await tester.pump();

    // Verifikasi pesan Akses Ditolak
    expect(find.text('Akses Ditolak'), findsOneWidget);
    expect(find.text('Buka Dashboard Saya'), findsOneWidget);
  });

  testWidgets('Owner hanya dapat mengakses OwnerDashboardScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OwnerDashboardScreen(testUser: ownerUser),
      ),
    );
    await tester.pump();

    // Verifikasi 5 tab owner
    expect(find.text('Beranda Owner'), findsOneWidget);
    expect(find.text('Laba Rugi'), findsWidgets);
    expect(find.text('Pengguna'), findsWidgets);
  });

  testWidgets('Owner yang mencoba membuka AdminKantorDashboard dicegat oleh RoleGuard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminKantorDashboardScreen(testUser: ownerUser),
      ),
    );
    await tester.pump();

    // Verifikasi pencegatan
    expect(find.text('Akses Ditolak'), findsOneWidget);
  });

  testWidgets('Admin Kantor hanya dapat mengakses AdminKantorDashboardScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminKantorDashboardScreen(testUser: adminKantorUser),
      ),
    );
    await tester.pump();

    // Verifikasi 3 tab admin kantor
    expect(find.text('Beranda Admin Kantor'), findsOneWidget);
    expect(find.text('Biaya'), findsWidgets);
  });

  testWidgets('DashboardDispatcher mengarahkan user ke dashboard sesuai rolenya', (WidgetTester tester) async {
    // Skenario Admin Toko
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardDispatcher(key: ValueKey('dispatcher_admin_toko'), testUser: adminTokoUser),
      ),
    );
    await tester.pump();
    expect(find.text('Beranda Admin Toko'), findsOneWidget);

    // Skenario Owner
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardDispatcher(key: ValueKey('dispatcher_owner'), testUser: ownerUser),
      ),
    );
    await tester.pump();
    expect(find.text('Beranda Owner'), findsOneWidget);

    // Skenario Admin Kantor
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardDispatcher(key: ValueKey('dispatcher_admin_kantor'), testUser: adminKantorUser),
      ),
    );
    await tester.pump();
    expect(find.text('Beranda Admin Kantor'), findsOneWidget);
  });

  testWidgets('Tombol Tambah pada Tab Barang memunculkan opsi Tambah Menu dan Tambah Kategori', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BarangTab()),
      ),
    );
    await tester.pump();

    // Verifikasi tombol Tambah
    expect(find.text('Tambah'), findsOneWidget);

    // Klik tombol Tambah
    await tester.tap(find.text('Tambah'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verifikasi munculnya pilihan di bottom sheet
    expect(find.text('Tambah Menu'), findsOneWidget);
    expect(find.text('Tambah Kategori'), findsOneWidget);

    // Klik Tambah Kategori
    await tester.tap(find.text('Tambah Kategori'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verifikasi dialog Tambah Kategori terbuka beserta daftar kategori saat ini
    expect(find.text('Kategori Saat Ini'), findsOneWidget);
    expect(find.text('Nama Kategori Baru'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('Input Transaksi pada PenjualanTab membuka halaman TransaksiPenjualanScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PenjualanTab()),
      ),
    );
    await tester.pump();

    // Verifikasi tombol Input Transaksi
    expect(find.text('Input Transaksi'), findsOneWidget);

    // Klik tombol Input Transaksi
    await tester.tap(find.text('Input Transaksi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verifikasi halaman Transaksi Penjualan terbuka sesuai desain
    expect(find.text('Transaksi Penjualan'), findsOneWidget);
    expect(find.text('Buat Pesanan'), findsOneWidget);
    expect(find.text('Nama Pelanggan / No. Meja'), findsWidgets);
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Harga'), findsWidgets);
    expect(find.text('+ Tambah ke Keranjang'), findsOneWidget);
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.text('Total Harga'), findsOneWidget);
    expect(find.text('Buat Pesanan & Cetak Dapur'), findsOneWidget);
  });

  testWidgets('TransaksiPenjualanScreen menampilkan form pesanan dan tombol Buat Pesanan & Cetak Dapur', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TransaksiPenjualanScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Transaksi Penjualan'), findsOneWidget);
    expect(find.text('Buat Pesanan'), findsOneWidget);
    expect(find.text('+ Tambah ke Keranjang'), findsOneWidget);
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.text('Total Harga'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Buat Pesanan & Cetak Dapur'), findsOneWidget);
  });

  testWidgets('AppAutocompleteField menyaring opsi setelah mengetik minimal 2 karakter', (WidgetTester tester) async {
    final sampleItems = ['Kopi Hitam', 'Kopi Susu', 'Teh Manis'];
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppAutocompleteField<String>(
            hintText: 'Nama Barang',
            minChars: 2,
            optionsFilter: (q) => sampleItems.where((i) => i.toLowerCase().contains(q.toLowerCase())),
            displayStringForOption: (i) => i,
            onSelected: (val) => selected = val,
          ),
        ),
      ),
    );
    await tester.pump();

    // Field terisi hintText
    expect(find.text('Nama Barang'), findsOneWidget);

    // Ketik 1 huruf 'k' -> dropdown belum muncul
    await tester.enterText(find.byType(TextFormField), 'k');
    await tester.pump();
    expect(find.text('Kopi Hitam'), findsNothing);

    // Ketik 'kop' -> dropdown muncul dengan hasil cocok
    await tester.enterText(find.byType(TextFormField), 'kop');
    await tester.pump();
    expect(find.text('Kopi Hitam'), findsOneWidget);
    expect(find.text('Kopi Susu'), findsOneWidget);
    expect(find.text('Teh Manis'), findsNothing);

    // Tap salah satu opsi 'Kopi Susu'
    await tester.tap(find.text('Kopi Susu'));
    await tester.pump();
    expect(selected, 'Kopi Susu');
  });

  testWidgets('OrderanAktifCard menampilkan rincian item, stepper served/total, dan tombol Bayar & Cetak', (WidgetTester tester) async {
    int incrementCount = 0;
    int decrementCount = 0;
    bool payClicked = false;

    final itemRoti = const TransactionModel(
      idTransaksi: 'TRX-001',
      id: 'PRD-001',
      namaItem: 'Roti Bakar',
      jumlah: 3,
      harga: 15000,
      waktu: '2026-09-12T01:00:00Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'CASH',
      orderStatus: 'PENDING',
      customerName: 'Meja 5',
      servedQty: 1,
    );

    final group = OrderanAktifGroup(
      transactionId: 'TRX-001',
      customerName: 'Meja 5',
      waktu: '2026-09-12T01:00:00Z',
      items: [itemRoti],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderanAktifCard(
            group: group,
            onIncrementServed: (_) => incrementCount++,
            onDecrementServed: (_) => decrementCount++,
            onPayAndPrint: () => payClicked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi nama customer dan item
    expect(find.text('Meja 5'), findsOneWidget);
    expect(find.text('3x Roti Bakar'), findsOneWidget);

    // Verifikasi rasio kuantitas tersaji 1 / 3
    expect(find.text('1 / 3'), findsOneWidget);

    // Verifikasi Total Harga: 3 x 15000 = Rp 45.000
    expect(find.textContaining('Rp 45.000'), findsOneWidget);

    // Verifikasi tombol sekunder
    expect(find.text('Print Dapur'), findsOneWidget);
    expect(find.text('+ Item'), findsOneWidget);
    expect(find.text('Bayar & Cetak'), findsOneWidget);

    // Klik tombol plus (+) pada stepper
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(incrementCount, 1);

    // Klik tombol minus (-) pada stepper
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(decrementCount, 1);

    // Verifikasi badge status 'Disiapkan' karena belum semua item tersaji
    expect(find.text('Disiapkan'), findsOneWidget);

    // Saat pesanan belum siap bayar, tombol 'Bayar & Cetak' disabled sehingga klik tidak memicu callback
    await tester.tap(find.text('Bayar & Cetak'));
    await tester.pump();
    expect(payClicked, false);

    // Sekarang pump ulang dengan grup yang sudah selesai disajikan (servedQty: 3 dari 3)
    final itemRotiSelesai = const TransactionModel(
      idTransaksi: 'TRX-001',
      id: 'PRD-001',
      namaItem: 'Roti Bakar',
      jumlah: 3,
      harga: 15000,
      waktu: '2026-09-12T01:00:00Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'CASH',
      orderStatus: 'PENDING',
      customerName: 'Meja 5',
      servedQty: 3,
    );

    final groupSiapBayar = OrderanAktifGroup(
      transactionId: 'TRX-001',
      customerName: 'Meja 5',
      waktu: '2026-09-12T01:00:00Z',
      items: [itemRotiSelesai],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderanAktifCard(
            group: groupSiapBayar,
            onPayAndPrint: () => payClicked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi badge status 'Siap Bayar'
    expect(find.text('Siap Bayar'), findsOneWidget);

    // Saat pesanan sudah siap bayar, tombol 'Bayar & Cetak' aktif dan klik memicu callback
    await tester.tap(find.text('Bayar & Cetak'));
    await tester.pump();
    expect(payClicked, true);
  });

  testWidgets('TambahItemPesananDialog menampilkan autocomplete cari menu dan modal minimalis', (WidgetTester tester) async {
    const sampleProducts = [
      ProductModel(id: '1', name: 'Kopi Tubruk', category: 'Minuman', price: 8000),
      ProductModel(id: '2', name: 'Roti Bakar', category: 'Makanan', price: 15000),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TambahItemPesananDialog(
            customerName: 'Meja 1',
            products: sampleProducts,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi judul modal dan subtitle minimalis
    expect(find.text('Tambah Item Pesanan'), findsOneWidget);
    expect(find.text('Pilih menu tambahan untuk: Meja 1'), findsOneWidget);

    // Verifikasi field cari menu autocomplete
    expect(find.text('Cari menu...'), findsOneWidget);

    // Ketik 1 huruf 'k' -> dropdown belum muncul
    await tester.enterText(find.byType(TextFormField), 'k');
    await tester.pump();
    expect(find.text('Kopi Tubruk'), findsNothing);

    // Ketik minimal 2 karakter 'kop' -> dropdown muncul
    await tester.enterText(find.byType(TextFormField), 'kop');
    await tester.pump();
    expect(find.text('Kopi Tubruk'), findsOneWidget);

    // Pilih menu 'Kopi Tubruk'
    await tester.tap(find.text('Kopi Tubruk'));
    await tester.pump();

    // Verifikasi harga tertera
    expect(find.textContaining('Rp 8.000'), findsWidgets);

    // Verifikasi stepper dan tombol aksi
    expect(find.text('Jumlah:'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan Tambahan'), findsOneWidget);
  });

  testWidgets('DetailTransaksiDialog menampilkan rincian transaksi minimalis dan tombol aksi', (WidgetTester tester) async {
    bool cancelClicked = false;

    const sampleTrx = TransactionModel(
      idTransaksi: 'TRX-20260911202742',
      id: 'PRD-001',
      namaItem: 'Pisang Goreng Keju',
      jumlah: 1,
      harga: 20000,
      waktu: '2026-09-11T15:16:15.000000Z',
      dicatatOleh: 'Sambal Radja',
      catatan: 'Tidak terlalu manis',
      paymentMethod: 'Cash',
      orderStatus: 'COMPLETED',
      customerName: 'take away',
      servedQty: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailTransaksiDialog(
            trx: sampleTrx,
            onCancel: () => cancelClicked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi judul dan nama menu
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Pisang Goreng Keju'), findsOneWidget);

    // Verifikasi baris informasi
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('1 porsi'), findsOneWidget);
    expect(find.text('Harga Satuan'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Rp 20.000'), findsNWidgets(2));
    expect(find.text('Dicatat oleh'), findsOneWidget);
    expect(find.text('Sambal Radja'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('take away'), findsOneWidget);
    expect(find.text('Metode Bayar'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    // Verifikasi tombol aksi
    expect(find.text('Cetak Ulang'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);

    // Tap Batalkan
    await tester.tap(find.text('Batalkan'));
    await tester.pump();
    expect(cancelClicked, true);
  });

  testWidgets('SalesReceiptDialog.fromTransaction menampilkan struk pratinjau besar dan memicu callback print saat Cetak ditekan', (WidgetTester tester) async {
    bool printTriggered = false;

    const sampleTrx = TransactionModel(
      idTransaksi: 'TRX-998877',
      id: 'PRD-001',
      namaItem: 'Ayam Geprek Sambal Matah',
      jumlah: 2,
      harga: 25000,
      waktu: '2026-09-12T10:00:00.000000Z',
      dicatatOleh: 'Kasir Satu',
      catatan: '',
      paymentMethod: 'QRIS',
      orderStatus: 'COMPLETED',
      customerName: 'Meja 05',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesReceiptDialog.fromTransaction(
            trx: sampleTrx,
            onPrint: () => printTriggered = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi header struk
    expect(find.text('Pratinjau Struk'), findsOneWidget);
    expect(find.text('WARUNGKU'), findsOneWidget);
    expect(find.text('STRUK PEMBAYARAN'), findsOneWidget);

    // Verifikasi info transaksi
    expect(find.text('TRX-998877'), findsOneWidget);
    expect(find.text('Kasir Satu'), findsOneWidget);
    expect(find.text('Meja 05'), findsOneWidget);

    // Verifikasi rincian item & perhitungan
    expect(find.text('Ayam Geprek Sambal Matah'), findsOneWidget);
    expect(find.text('2 x Rp 25.000'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsNWidgets(3)); // item subtotal, subtotal ringkasan, dan TOTAL
    expect(find.text('QRIS'), findsOneWidget);

    // Verifikasi tombol Tutup dan Cetak
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Cetak'), findsOneWidget);

    // Tap Cetak
    await tester.tap(find.text('Cetak'));
    await tester.pump();
    expect(printTriggered, true);
  });

  testWidgets('SalesReceiptDialog.fromOrderGroup menampilkan rincian multi-item dan diskon', (WidgetTester tester) async {
    final group = OrderanAktifGroup(
      transactionId: 'TRX-ORD-123',
      customerName: 'Budi Santoso',
      waktu: '2026-09-12T11:30:00.000000Z',
      items: const [
        TransactionModel(
          idTransaksi: 'TRX-ORD-123',
          id: 'PRD-1',
          namaItem: 'Nasi Goreng Spesial',
          jumlah: 2,
          harga: 20000,
          waktu: '2026-09-12T11:30:00.000000Z',
          dicatatOleh: 'Kasir Dua',
          catatan: '',
          paymentMethod: 'Cash',
          orderStatus: 'COMPLETED',
          customerName: 'Budi Santoso',
        ),
        TransactionModel(
          idTransaksi: 'TRX-ORD-123',
          id: 'PRD-2',
          namaItem: 'Es Teh Manis',
          jumlah: 2,
          harga: 5000,
          waktu: '2026-09-12T11:30:00.000000Z',
          dicatatOleh: 'Kasir Dua',
          catatan: '',
          paymentMethod: 'Cash',
          orderStatus: 'COMPLETED',
          customerName: 'Budi Santoso',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesReceiptDialog.fromOrderGroup(
            group: group,
            paymentMethod: 'Cash',
            discountAmount: 5000,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi item
    expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
    expect(find.text('2 x Rp 20.000'), findsOneWidget);
    expect(find.text('Es Teh Manis'), findsOneWidget);
    expect(find.text('2 x Rp 5.000'), findsOneWidget);

    // Verifikasi subtotal Rp 50.000, diskon - Rp 5.000, dan total Rp 45.000
    expect(find.text('Rp 50.000'), findsOneWidget);
    expect(find.text('- Rp 5.000'), findsOneWidget);
    expect(find.text('Rp 45.000'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
  });

  testWidgets('RiwayatTransaksiCard tidak menampilkan tombol Batal dan mendukung swipe ke kiri untuk hapus', (WidgetTester tester) async {
    bool cardTapped = false;
    bool deleteTriggered = false;

    const sampleTrx = TransactionModel(
      idTransaksi: 'TRX-20260912-8899',
      id: 'PRD-010',
      namaItem: 'Sate Ayam Madura',
      jumlah: 2,
      harga: 25000,
      waktu: '2026-09-12T12:00:00.000000Z',
      dicatatOleh: 'Kasir Satu',
      catatan: 'Bumbu kacang dipisah',
      paymentMethod: 'QRIS',
      orderStatus: 'COMPLETED',
      customerName: 'Meja 08 (Bpk. Agus)',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiwayatTransaksiCard(
            trx: sampleTrx,
            onTap: () => cardTapped = true,
            onDelete: () async {
              deleteTriggered = true;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi header: Nama Pelanggan dan Nomor Transaksi
    expect(find.text('Meja 08 (Bpk. Agus)'), findsOneWidget);
    expect(find.text('TRX-20260912-8899'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);

    // Verifikasi body: Menu & Subtitle
    expect(find.text('Sate Ayam Madura'), findsOneWidget);
    expect(find.text('2 x Rp 25.000 • QRIS'), findsOneWidget);
    expect(find.text('Catatan: Bumbu kacang dipisah'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);

    // Verifikasi tombol Batal TIDAK ADA lagi pada kartu
    expect(find.text('Batal'), findsNothing);

    // Verifikasi komponen Dismissible hadir
    expect(find.byType(Dismissible), findsOneWidget);

    // Tap kartu -> memicu onTap
    await tester.tap(find.text('Sate Ayam Madura'));
    await tester.pump();
    expect(cardTapped, true);

    // Swipe ke kiri (endToStart) untuk menghapus
    await tester.drag(find.text('Sate Ayam Madura'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    expect(deleteTriggered, true);
  });

  test('ThermalPrinterService menghasilkan byte ESC/POS yang valid untuk struk 58mm dan 80mm', () {
    const config58 = ThermalPrinterConfig(ip: '127.0.0.1', port: 9100, paperWidth: 58);
    const config80 = ThermalPrinterConfig(ip: '127.0.0.1', port: 9100, paperWidth: 80);

    final service = ThermalPrinterService.instance;

    // Test print bytes
    final testBytes = service.generateTestReceiptBytes(config58);
    expect(testBytes.isNotEmpty, true);
    expect(testBytes.contains(0x1B), true); // ESC
    expect(testBytes.contains(0x40), true); // @

    // Sales receipt bytes
    final salesBytes = service.generateSalesReceiptBytes(
      config: config80,
      storeName: 'WARUNGKU',
      transactionId: 'TRX-100',
      dateTimeStr: '12/09/2026 10:00',
      customerName: 'Meja 1',
      cashierName: 'Kasir',
      items: const [
        SalesReceiptItem(name: 'Ayam Bakar', quantity: 2, price: 20000, subtotal: 40000),
      ],
      subtotal: 40000,
      discountAmount: 5000,
      paymentMethod: 'QRIS',
    );
    expect(salesBytes.isNotEmpty, true);
    expect(salesBytes.contains(0x1D), true); // GS (Cut paper)
  });

  testWidgets('PrinterSettingsDialog menampilkan opsi konfigurasi Bluetooth, IP/port, pilihan kertas, dan tombol aksi', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrinterSettingsDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi judul
    expect(find.text('Pengaturan Printer Thermal'), findsOneWidget);

    // Verifikasi chip pilihan mode koneksi
    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('Jaringan (IP)'), findsOneWidget);

    // Mode Bluetooth (default) menampilkan daftar perangkat Bluetooth terpasang
    expect(find.text('Perangkat Bluetooth Terpasang'), findsOneWidget);
    expect(find.text('RPP02N Thermal (66:22:33:44:55:66)'), findsOneWidget);

    // Beralih ke mode Jaringan (IP)
    await tester.tap(find.text('Jaringan (IP)'));
    await tester.pump();

    // Verifikasi field konfigurasi IP dan Port
    expect(find.text('Alamat IP Printer'), findsOneWidget);
    expect(find.text('Port Printer (Default 9100)'), findsOneWidget);

    // Verifikasi pilihan kertas 58mm & 80mm
    expect(find.text('58 mm (Standar)'), findsOneWidget);
    expect(find.text('80 mm (Lebar)'), findsOneWidget);

    // Verifikasi tombol
    expect(find.text('Tes Cetak Thermal'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Ganti ke 80mm
    await tester.tap(find.text('80 mm (Lebar)'));
    await tester.pump();
  });

  testWidgets('SalesReceiptDialog memiliki header minimalis dan tombol tutup', (WidgetTester tester) async {
    const sampleTrx = TransactionModel(
      idTransaksi: 'TRX-PRN-01',
      id: 'PRD-01',
      namaItem: 'Mie Goreng Aceh',
      jumlah: 1,
      harga: 18000,
      waktu: '2026-09-12T10:00:00.000000Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'Cash',
      orderStatus: 'COMPLETED',
      customerName: 'Meja 2',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesReceiptDialog.fromTransaction(trx: sampleTrx),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi dialog memiliki judul dan tombol tutup (tanpa tombol setting berlebih di header)
    expect(find.text('Pratinjau Struk'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('Tombol pengaturan printer thermal hanya di AppBar pojok kanan atas dan bersih dari card profile', (WidgetTester tester) async {
    // 1. Verifikasi pada ProfilTab langsung: tidak ada tombol printer di dalam card profile
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfilTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Kartu profil bebas dari tombol printer
    expect(find.byIcon(Icons.print_rounded), findsNothing);

    // 2. Verifikasi pada AppBar Dashboard Admin Toko saat tab Profil aktif
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminTokoDashboardScreen(
          testUser: adminTokoUser,
          initialTabIndex: 3, // Tab Profil
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsWidgets);
    // Tombol icon printer ada di AppBar
    final appBarPrinterIcon = find.byIcon(Icons.print_rounded);
    expect(appBarPrinterIcon, findsOneWidget);

    // Tap icon printer di AppBar membuka PrinterSettingsDialog
    await tester.tap(appBarPrinterIcon);
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Printer Thermal'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('KitchenReceiptDialog.showFromCart menampilkan rincian item dapur dan tombol Cetak', (WidgetTester tester) async {
    bool printTriggered = false;
    final dummyProduct = ProductModel(
      id: 'PRD-101',
      name: 'Ayam Bakar Madu',
      price: 25000,
      category: 'Makanan',
    );
    final dummyCart = [
      CartItemModel(
        product: dummyProduct,
        quantity: 2,
        unitPrice: 25000,
        notes: 'Pedas sedang',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => KitchenReceiptDialog.showFromCart(
                context: context,
                transactionId: 'TRX-KIT-01',
                customerName: 'Meja 10',
                cartItems: dummyCart,
                autoPrint: false,
                onPrint: () => printTriggered = true,
              ),
              child: const Text('Open Kitchen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Kitchen'));
    await tester.pumpAndSettle();

    expect(find.text('PESANAN DAPUR'), findsOneWidget);
    expect(find.text('Meja / Pelanggan: Meja 10'), findsOneWidget);
    expect(find.text('Ayam Bakar Madu'), findsOneWidget);
    expect(find.text('2x'), findsOneWidget);
    expect(find.text(' * Pedas sedang'), findsOneWidget);

    // Tap tombol Cetak
    await tester.tap(find.text('Cetak'));
    await tester.pump();
    expect(printTriggered, true);
  });

  testWidgets('SalesReceiptDialog.fromTransactionList mendukung multi-item dan tombol Cetak Ulang', (WidgetTester tester) async {
    bool printTriggered = false;
    const items = [
      TransactionModel(
        idTransaksi: 'TRX-REP-01',
        id: 'PRD-1',
        namaItem: 'Sate Ayam',
        jumlah: 2,
        harga: 20000,
        waktu: '2026-09-12T12:00:00.000000Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'Tunai',
        orderStatus: 'COMPLETED',
        customerName: 'Pak Joko',
      ),
      TransactionModel(
        idTransaksi: 'TRX-REP-01',
        id: 'PRD-2',
        namaItem: 'Es Jeruk',
        jumlah: 2,
        harga: 5000,
        waktu: '2026-09-12T12:00:00.000000Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'Tunai',
        orderStatus: 'COMPLETED',
        customerName: 'Pak Joko',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesReceiptDialog.fromTransactionList(
            items: items,
            confirmButtonText: 'Cetak Ulang',
            onPrint: () => printTriggered = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sate Ayam'), findsOneWidget);
    expect(find.text('Es Jeruk'), findsOneWidget);
    expect(find.text('Rp 40.000'), findsOneWidget); // Subtotal Sate Ayam
    expect(find.text('Rp 10.000'), findsOneWidget); // Subtotal Es Jeruk
    expect(find.text('Rp 50.000'), findsNWidgets(2)); // Subtotal & TOTAL ringkasan
    expect(find.text('Cetak Ulang'), findsOneWidget);

    await tester.tap(find.text('Cetak Ulang'));
    await tester.pump();
    expect(printTriggered, true);
  });

  testWidgets('RiwayatTransaksiCard bersih tanpa icon print dan alur cetak via modal cetak ulang', (WidgetTester tester) async {
    bool detailOpened = false;
    const trx = TransactionModel(
      idTransaksi: 'TRX-ICN-01',
      id: 'PRD-1',
      namaItem: 'Kopi Tubruk',
      jumlah: 1,
      harga: 8000,
      waktu: '2026-09-12T13:00:00.000000Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'QRIS',
      orderStatus: 'COMPLETED',
      customerName: 'Pelanggan Meja 4',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiwayatTransaksiCard(
            trx: trx,
            onTap: () => detailOpened = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Verifikasi kartu transaksi tidak memuat tombol print (bersih dan minimalis)
    expect(find.byIcon(Icons.print_outlined), findsNothing);

    // 2. Tap kartu membuka callback detail transaksi
    await tester.tap(find.text('Pelanggan Meja 4'));
    await tester.pump();
    expect(detailOpened, true);
  });

  testWidgets('BerandaTab untuk Admin Toko menyusun 3 menu aksi cepat secara simetris dan merata', (WidgetTester tester) async {
    bool penjualanTapped = false;
    bool barangTapped = false;
    bool profilTapped = false;

    await TokenManager.saveSession(token: 'mock_token', user: adminTokoUser);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BerandaTab(
            onGoToPenjualan: () => penjualanTapped = true,
            onGoToBarang: () => barangTapped = true,
            onGoToProfil: () => profilTapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verifikasi 3 menu cepat ditemukan
    expect(find.text('Penjualan'), findsOneWidget);
    expect(find.text('Barang'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Verifikasi menu tidak menampilkan menu khusus owner
    expect(find.text('Laba Rugi'), findsNothing);
    expect(find.text('Lap. Bulanan'), findsNothing);
    expect(find.text('Pengguna'), findsNothing);

    // Tap masing-masing menu untuk memverifikasi callback
    await tester.tap(find.text('Penjualan'));
    await tester.pump();
    expect(penjualanTapped, true);

    await tester.tap(find.text('Barang'));
    await tester.pump();
    expect(barangTapped, true);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(profilTapped, true);
  });

  test('TransactionGroup.fromTransactionList mengelompokkan item dengan idTransaksi sama ke satu bill', () {
    final rawList = [
      const TransactionModel(
        idTransaksi: 'TRX-20260919-01',
        id: '1',
        namaItem: 'Ikan Kerapu Tumis Size M',
        jumlah: 1,
        harga: 55000,
        waktu: '2026-09-19T13:48:50Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Indah',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-20260919-01',
        id: '2',
        namaItem: 'Kelapa bulat',
        jumlah: 1,
        harga: 20000,
        waktu: '2026-09-19T13:48:50Z',
        dicatatOleh: 'Admin Toko',
        catatan: 'Dingin',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Indah',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-20260919-01',
        id: '3',
        namaItem: 'Jus Mangga',
        jumlah: 2,
        harga: 15000,
        waktu: '2026-09-19T13:48:50Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Indah',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-20260919-02',
        id: '4',
        namaItem: 'Ayam Goreng',
        jumlah: 1,
        harga: 25000,
        waktu: '2026-09-19T14:00:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'QRIS',
        orderStatus: 'COMPLETED',
        customerName: 'Budi',
      ),
    ];

    final groups = TransactionGroup.fromTransactionList(rawList);

    // Harus terkelompok menjadi 2 transaksi (Indah dan Budi), bukan 4 baris item terpisah
    expect(groups.length, 2);

    final indahGroup = groups.firstWhere((g) => g.idTransaksi == 'TRX-20260919-01');
    expect(indahGroup.customerName, 'Indah');
    expect(indahGroup.items.length, 3);
    expect(indahGroup.totalQuantity, 4); // 1 + 1 + 2
    expect(indahGroup.totalHarga, 105000.0); // 55000 + 20000 + 30000
    expect(indahGroup.isMultiItem, true);

    final budiGroup = groups.firstWhere((g) => g.idTransaksi == 'TRX-20260919-02');
    expect(budiGroup.customerName, 'Budi');
    expect(budiGroup.items.length, 1);
    expect(budiGroup.totalQuantity, 1);
    expect(budiGroup.totalHarga, 25000.0);
    expect(budiGroup.isMultiItem, false);
  });

  testWidgets('RiwayatTransaksiCard menampilkan daftar item dan total belanja untuk multi-item bill', (WidgetTester tester) async {
    final group = TransactionGroup(
      idTransaksi: 'TRX-MULTI-01',
      customerName: 'Indah',
      waktu: '2026-09-19T13:48:50Z',
      dicatatOleh: 'Admin Toko',
      paymentMethod: 'CASH',
      orderStatus: 'COMPLETED',
      items: const [
        TransactionModel(
          idTransaksi: 'TRX-MULTI-01',
          id: '1',
          namaItem: 'Ikan Kerapu Tumis Size M',
          jumlah: 1,
          harga: 55000,
          waktu: '2026-09-19T13:48:50Z',
          dicatatOleh: 'Admin Toko',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Indah',
        ),
        TransactionModel(
          idTransaksi: 'TRX-MULTI-01',
          id: '2',
          namaItem: 'Kelapa bulat',
          jumlah: 1,
          harga: 20000,
          waktu: '2026-09-19T13:48:50Z',
          dicatatOleh: 'Admin Toko',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Indah',
        ),
        TransactionModel(
          idTransaksi: 'TRX-MULTI-01',
          id: '3',
          namaItem: 'Jus Mangga',
          jumlah: 1,
          harga: 20000,
          waktu: '2026-09-19T13:48:50Z',
          dicatatOleh: 'Admin Toko',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Indah',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiwayatTransaksiCard(group: group),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi header
    expect(find.text('Indah'), findsOneWidget);
    expect(find.text('TRX-MULTI-01'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);

    // Verifikasi item ditampilkan semua di kartu
    expect(find.text('1x Ikan Kerapu Tumis Size M'), findsOneWidget);
    expect(find.text('1x Kelapa bulat'), findsOneWidget);
    expect(find.text('1x Jus Mangga'), findsOneWidget);

    // Verifikasi subtotal item
    expect(find.text('Rp 55.000'), findsOneWidget);
    expect(find.text('Rp 20.000'), findsNWidgets(2));

    // Verifikasi total belanja gabungan
    expect(find.text('3 item • CASH'), findsOneWidget);
    expect(find.text('Rp 95.000'), findsOneWidget);
  });

  testWidgets('DetailTransaksiDialog menampilkan rincian multi-item bill', (WidgetTester tester) async {
    final group = TransactionGroup(
      idTransaksi: 'TRX-MULTI-01',
      customerName: 'Indah',
      waktu: '2026-09-19T13:48:50.000000Z',
      dicatatOleh: 'Admin Toko',
      paymentMethod: 'CASH',
      orderStatus: 'COMPLETED',
      catatan: 'Catatan umum',
      items: const [
        TransactionModel(
          idTransaksi: 'TRX-MULTI-01',
          id: '1',
          namaItem: 'Ikan Kerapu Tumis Size M',
          jumlah: 1,
          harga: 55000,
          waktu: '2026-09-19T13:48:50.000000Z',
          dicatatOleh: 'Admin Toko',
          catatan: 'Pedas',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Indah',
        ),
        TransactionModel(
          idTransaksi: 'TRX-MULTI-01',
          id: '2',
          namaItem: 'Kelapa bulat',
          jumlah: 2,
          harga: 20000,
          waktu: '2026-09-19T13:48:50.000000Z',
          dicatatOleh: 'Admin Toko',
          catatan: '',
          paymentMethod: 'CASH',
          orderStatus: 'COMPLETED',
          customerName: 'Indah',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailTransaksiDialog(group: group),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi modal detail
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('TRX-MULTI-01'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Indah'), findsOneWidget);
    expect(find.text('Admin Toko'), findsOneWidget);
    expect(find.text('Daftar Menu (2 item)'), findsOneWidget);
    expect(find.text('Ikan Kerapu Tumis Size M'), findsOneWidget);
    expect(find.text('Kelapa bulat'), findsOneWidget);
    expect(find.text('Catatan: Pedas'), findsOneWidget);
    expect(find.text('Total Belanja (3 porsi)'), findsOneWidget);
    expect(find.text('Rp 95.000'), findsOneWidget);
  });

  testWidgets('LabaRugiTab menampilkan seluruh 9 urutan elemen UI sesuai acuan minimalis', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool openedMonthly = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabaRugiTab(
            onOpenMonthlyReport: () {
              openedMonthly = true;
            },
          ),
        ),
      ),
    );

    // Initial pump & settle (mock data load)
    await tester.pumpAndSettle();

    // 1. Header Halaman
    expect(find.text('Laporan Keuangan'), findsOneWidget);
    expect(find.text('Analisis Performa Warung'), findsOneWidget);

    // 2. Banner Card Laporan Bulanan per Item & Tombol
    expect(find.text('Laporan Bulanan per Item'), findsOneWidget);
    expect(find.text('Lihat rincian penjualan harian untuk setiap barang.'), findsOneWidget);
    final openItemBtn = find.text('Buka Laporan Item');
    expect(openItemBtn, findsOneWidget);
    await tester.tap(openItemBtn);
    expect(openedMonthly, isTrue);

    // 3. Ringkasan Laba-Rugi + Tombol PDF
    expect(find.text('Ringkasan Laba-Rugi'), findsOneWidget);
    expect(find.byTooltip('Export PDF'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);

    // 4. ChoiceChips Filter Periode
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Bulan Ini'), findsWidgets);
    expect(find.text('Pilih Tanggal'), findsOneWidget);

    // 5. Card Rekap Performa
    expect(find.text('Total Penjualan'), findsOneWidget);
    expect(find.text('Total Pengeluaran'), findsOneWidget);
    expect(find.text('Laba Bersih:'), findsOneWidget);

    // 6. Section Rincian Harian
    expect(find.text('Rincian Harian'), findsOneWidget);

    // 7. Section Rincian Pengeluaran
    expect(find.text('Rincian Pengeluaran'), findsOneWidget);

    // 8. Section Daftar Transaksi Per Struk
    expect(find.textContaining('Daftar Transaksi Per Struk'), findsOneWidget);

    // 9. Section Menu Terlaris
    expect(find.textContaining('Menu Terlaris'), findsOneWidget);

    // Tap chip Pilih Tanggal -> memunculkan modal dialog Filter Custom Tanggal & Jenis Data
    await tester.ensureVisible(find.text('Pilih Tanggal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Tanggal'));
    await tester.pumpAndSettle();

    expect(find.text('Filter Custom Tanggal & Jenis Data'), findsOneWidget);
    expect(find.text('Tanggal Mulai *'), findsOneWidget);
    expect(find.text('Tanggal Selesai *'), findsOneWidget);
    expect(find.text('Jenis Data'), findsOneWidget);
    expect(find.text('Tampilkan Semua'), findsOneWidget);
    expect(find.text('Pengeluaran Saja'), findsOneWidget);
    expect(find.text('Pemasukan Saja'), findsOneWidget);
    expect(find.text('Laba Rugi Saja'), findsOneWidget);
    expect(find.text('Rincian Menu Terlaris'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Terapkan'), findsOneWidget);

    // Tap Batal menutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Custom Tanggal & Jenis Data'), findsNothing);
  });

  testWidgets('FilterCustomTanggalDialog mengembalikan hasil tanggal dan jenis data terpilih saat Terapkan ditekan', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    FilterCustomTanggalResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FilterCustomTanggalDialog.show(
                  context: context,
                  initialStartDate: DateTime(2026, 9, 1),
                  initialEndDate: DateTime(2026, 9, 19),
                  initialDataType: 'Tampilkan Semua',
                );
              },
              child: const Text('Buka Filter'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Filter Custom Tanggal & Jenis Data'), findsOneWidget);
    expect(find.text('1 September 2026'), findsOneWidget);
    expect(find.text('19 September 2026'), findsOneWidget);

    // Pilih opsi radio Pengeluaran Saja
    await tester.tap(find.text('Pengeluaran Saja'));
    await tester.pumpAndSettle();

    // Tekan Terapkan
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dataType, 'Pengeluaran Saja');
    expect(result!.startDate, DateTime(2026, 9, 1));
    expect(result!.endDate, DateTime(2026, 9, 19));
  });

  test('TransactionModel status helper dan parsing key status mengenali berbagai alias status', () {
    final t1 = TransactionModel.fromJson({'status': 'COMPLETED'});
    expect(t1.isCompleted, isTrue);
    expect(t1.isPending, isFalse);
    expect(t1.isCancelled, isFalse);

    final t2 = TransactionModel.fromJson({'order_status': 'SELESAI'});
    expect(t2.isCompleted, isTrue);

    final t3 = TransactionModel.fromJson({'orderStatus': 'PENDING'});
    expect(t3.isPending, isTrue);
    expect(t3.isCompleted, isFalse);

    final t4 = TransactionModel.fromJson({'status': 'PROSES'});
    expect(t4.isPending, isTrue);
    expect(t4.isCompleted, isFalse);

    final t5 = TransactionModel.fromJson({'status': 'CANCELLED'});
    expect(t5.isCancelled, isTrue);
    expect(t5.isCompleted, isFalse);

    final t6 = TransactionModel.fromJson({'order_status': 'BATAL'});
    expect(t6.isCancelled, isTrue);
    expect(t6.isCompleted, isFalse);

    final t7 = TransactionModel.fromJson({'status': 'READY'});
    expect(t7.isPending, isTrue);
    expect(t7.isCompleted, isFalse);

    final t8 = TransactionModel.fromJson({'order_status': 'SIAP'});
    expect(t8.isPending, isTrue);
    expect(t8.isCompleted, isFalse);
  });

  test('Perhitungan omzet dan jumlah transaksi bill konsisten untuk multi-item dan status pesanan', () {
    final rawList = [
      // Transaksi 1: COMPLETED, 2 item (Total Rp 30.000)
      const TransactionModel(
        idTransaksi: 'TRX-01',
        id: '1',
        namaItem: 'Nasi Ayam',
        jumlah: 1,
        harga: 20000,
        waktu: '2026-09-20T10:00:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Budi',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-01',
        id: '2',
        namaItem: 'Es Teh',
        jumlah: 1,
        harga: 10000,
        waktu: '2026-09-20T10:00:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Budi',
      ),
      // Transaksi 2: SELESAI, 1 item (Total Rp 25.000)
      const TransactionModel(
        idTransaksi: 'TRX-02',
        id: '3',
        namaItem: 'Bebek Goreng',
        jumlah: 1,
        harga: 25000,
        waktu: '2026-09-20T11:00:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'QRIS',
        orderStatus: 'SELESAI',
        customerName: 'Siti',
      ),
      // Transaksi 3: PENDING / PROSES (Active Order, belum selesai)
      const TransactionModel(
        idTransaksi: 'TRX-03',
        id: '4',
        namaItem: 'Kopi Susu',
        jumlah: 2,
        harga: 15000,
        waktu: '2026-09-20T11:30:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'PENDING',
        customerName: 'Ahmad',
      ),
      // Transaksi 4: CANCELLED (Dibatalkan)
      const TransactionModel(
        idTransaksi: 'TRX-04',
        id: '5',
        namaItem: 'Mie Goreng',
        jumlah: 1,
        harga: 18000,
        waktu: '2026-09-20T12:00:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'CANCELLED',
        customerName: 'Rian',
      ),
      // Transaksi 5: READY (Siap saji/antrean aktif, belum selesai)
      const TransactionModel(
        idTransaksi: 'TRX-05',
        id: '6',
        namaItem: 'Soto Ayam',
        jumlah: 1,
        harga: 22000,
        waktu: '2026-09-20T12:15:00Z',
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'READY',
        customerName: 'Dewi',
      ),
    ];

    // 1. Filter transaksi non-pending (seperti di PenjualanTab dan BerandaTab)
    final nonPending = rawList.where((t) => !t.isPending).toList();
    final groups = TransactionGroup.fromTransactionList(nonPending);

    // 2. Transaksi selesai (isCompleted)
    final completedGroups = groups.where((g) => g.isCompleted).toList();

    // Pastikan hanya TRX-01 dan TRX-02 yang terhitung selesai (bukan pending TRX-03 dan bukan cancelled TRX-04)
    expect(completedGroups.length, 2);
    expect(completedGroups.map((g) => g.idTransaksi), containsAll(['TRX-01', 'TRX-02']));

    // Total omzet bill selesai: Rp 30.000 (TRX-01) + Rp 25.000 (TRX-02) = Rp 55.000
    final totalOmzet = completedGroups.fold(0.0, (acc, g) => acc + g.totalHarga);
    expect(totalOmzet, 55000.0);
  });

  test('TanggalFormatter.isToday dan filter transaksi hari ini mengabaikan transaksi kemarin dan menghitung per bill', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    expect(TanggalFormatter.isToday(now.toIso8601String()), isTrue);
    expect(TanggalFormatter.isToday(yesterday.toIso8601String()), isFalse);

    final rawList = [
      // Pembelian 1 Hari Ini: 3 menu item (Bill TRX-TODAY-01)
      TransactionModel(
        idTransaksi: 'TRX-TODAY-01',
        id: '1',
        namaItem: 'Ayam Penyet',
        jumlah: 1,
        harga: 25000,
        waktu: now.toIso8601String(),
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Meja 1',
      ),
      TransactionModel(
        idTransaksi: 'TRX-TODAY-01',
        id: '2',
        namaItem: 'Es Jeruk',
        jumlah: 1,
        harga: 7000,
        waktu: now.toIso8601String(),
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Meja 1',
      ),
      TransactionModel(
        idTransaksi: 'TRX-TODAY-01',
        id: '3',
        namaItem: 'Kerupuk',
        jumlah: 2,
        harga: 2000,
        waktu: now.toIso8601String(),
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Meja 1',
      ),
      // Pembelian 2 Hari Ini: 1 menu item (Bill TRX-TODAY-02)
      TransactionModel(
        idTransaksi: 'TRX-TODAY-02',
        id: '4',
        namaItem: 'Nasi Goreng Spesial',
        jumlah: 1,
        harga: 28000,
        waktu: now.toIso8601String(),
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'QRIS',
        orderStatus: 'COMPLETED',
        customerName: 'Meja 2',
      ),
      // Pembelian Kemarin: COMPLETED (Bill TRX-YESTERDAY)
      TransactionModel(
        idTransaksi: 'TRX-YESTERDAY',
        id: '5',
        namaItem: 'Bebek Bakar',
        jumlah: 1,
        harga: 35000,
        waktu: yesterday.toIso8601String(),
        dicatatOleh: 'Admin Toko',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'Kemarin',
      ),
    ];

    // Filter ketat hanya transaksi hari ini
    final todayOnly = rawList.where((t) => TanggalFormatter.isToday(t.waktu)).toList();
    expect(todayOnly.length, 4); // 4 baris item hari ini (TRX-YESTERDAY diabaikan)

    // Dikelompokkan per bill transaksi (per pembelian)
    final nonPending = todayOnly.where((t) => !t.isPending).toList();
    final todayGroups = TransactionGroup.fromTransactionList(nonPending);
    final completedGroups = todayGroups.where((g) => g.isCompleted).toList();

    // Jumlah transaksi adalah 2 bill pembelian yang dibuat hari ini, BUKAN 4 menu yang dipesan
    expect(completedGroups.length, 2);
    expect(completedGroups.map((g) => g.idTransaksi), containsAll(['TRX-TODAY-01', 'TRX-TODAY-02']));

    // Total omzet hari ini: (25.000 + 7.000 + 4.000) + 28.000 = 64.000 (tidak termasuk 35.000 kemarin)
    final totalTodayOmzet = completedGroups.fold(0.0, (sum, g) => sum + g.totalHarga);
    expect(totalTodayOmzet, 64000.0);
  });

  test('TransactionModel dan TransactionGroup mendukung status sampai READY dan isActiveOrder', () {
    final tPending = TransactionModel.fromJson({'orderStatus': 'PENDING'});
    expect(tPending.isActiveOrder, isTrue);
    expect(tPending.isReady, isFalse);
    expect(tPending.isCompleted, isFalse);

    final tProses = TransactionModel.fromJson({'orderStatus': 'PROSES'});
    expect(tProses.isActiveOrder, isTrue);
    expect(tProses.isReady, isFalse);

    final tProcessing = TransactionModel.fromJson({'orderStatus': 'PROCESSING'});
    expect(tProcessing.isActiveOrder, isTrue);
    expect(tProcessing.isReady, isFalse);

    final tReady = TransactionModel.fromJson({'orderStatus': 'READY'});
    expect(tReady.isActiveOrder, isTrue);
    expect(tReady.isReady, isTrue);
    expect(tReady.isCompleted, isFalse);

    final tSiap = TransactionModel.fromJson({'orderStatus': 'SIAP'});
    expect(tSiap.isActiveOrder, isTrue);
    expect(tSiap.isReady, isTrue);

    final tCompleted = TransactionModel.fromJson({'orderStatus': 'COMPLETED'});
    expect(tCompleted.isActiveOrder, isFalse);
    expect(tCompleted.isReady, isFalse);
    expect(tCompleted.isCompleted, isTrue);

    final tCancelled = TransactionModel.fromJson({'orderStatus': 'CANCELLED'});
    expect(tCancelled.isActiveOrder, isFalse);
    expect(tCancelled.isReady, isFalse);
    expect(tCancelled.isCancelled, isTrue);

    // Verifikasi pada TransactionGroup
    final gReady = TransactionGroup.fromSingleTransaction(tReady);
    expect(gReady.isActiveOrder, isTrue);
    expect(gReady.isReady, isTrue);
  });

  testWidgets('OrderanAktifCard dengan status READY menampilkan badge Siap Saji dan mengaktifkan Bayar & Cetak', (WidgetTester tester) async {
    bool payClicked = false;

    final itemReady = const TransactionModel(
      idTransaksi: 'TRX-READY-01',
      id: 'PRD-01',
      namaItem: 'Mie Goreng Spesial',
      jumlah: 2,
      harga: 18000,
      waktu: '2026-09-20T12:00:00Z',
      dicatatOleh: 'Kasir',
      catatan: '',
      paymentMethod: 'CASH',
      orderStatus: 'READY',
      customerName: 'Meja 7',
      servedQty: 0, // Belum dicentang per item, tetapi status order dari dapur sudah READY
    );

    final groupReady = OrderanAktifGroup(
      transactionId: 'TRX-READY-01',
      customerName: 'Meja 7',
      waktu: '2026-09-20T12:00:00Z',
      orderStatus: 'READY',
      items: [itemReady],
    );

    expect(groupReady.isReady, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderanAktifCard(
            group: groupReady,
            onPayAndPrint: () => payClicked = true,
          ),
        ),
      ),
    );
    await tester.pump();

    // Badge status harus menampilkan 'Siap Saji'
    expect(find.text('Siap Saji'), findsOneWidget);

    // Tombol Bayar & Cetak harus aktif dan bisa diklik
    await tester.tap(find.text('Bayar & Cetak'));
    await tester.pump();
    expect(payClicked, isTrue);
  });

  test('Pemisahan Orderan Aktif di Beranda mencakup status sampai READY dan mengecualikan COMPLETED/CANCELLED', () {
    final rawList = [
      const TransactionModel(
        idTransaksi: 'TRX-P1',
        id: '1',
        namaItem: 'Kopi',
        jumlah: 1,
        harga: 10000,
        waktu: '2026-09-20T10:00:00Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'PENDING',
        customerName: 'A',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-P2',
        id: '2',
        namaItem: 'Teh',
        jumlah: 1,
        harga: 5000,
        waktu: '2026-09-20T10:05:00Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'PROSES',
        customerName: 'B',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-P3',
        id: '3',
        namaItem: 'Roti',
        jumlah: 1,
        harga: 12000,
        waktu: '2026-09-20T10:10:00Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'READY',
        customerName: 'C',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-P4',
        id: '4',
        namaItem: 'Nasi',
        jumlah: 1,
        harga: 20000,
        waktu: '2026-09-20T10:15:00Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'COMPLETED',
        customerName: 'D',
      ),
      const TransactionModel(
        idTransaksi: 'TRX-P5',
        id: '5',
        namaItem: 'Air',
        jumlah: 1,
        harga: 3000,
        waktu: '2026-09-20T10:20:00Z',
        dicatatOleh: 'Kasir',
        catatan: '',
        paymentMethod: 'CASH',
        orderStatus: 'CANCELLED',
        customerName: 'E',
      ),
    ];

    // Filter aktif: status sampai READY (selain COMPLETED dan CANCELLED)
    final activeOnly = rawList.where((t) => t.isActiveOrder).toList();
    expect(activeOnly.length, 3);
    expect(activeOnly.map((t) => t.idTransaksi), containsAll(['TRX-P1', 'TRX-P2', 'TRX-P3']));
    expect(activeOnly.map((t) => t.idTransaksi), isNot(contains('TRX-P4')));
    expect(activeOnly.map((t) => t.idTransaksi), isNot(contains('TRX-P5')));
  });
}








