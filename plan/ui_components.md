# Registry & Katalog Komponen UI (UI Component Registry)

Dokumen ini berfungsi sebagai katalog sentral untuk seluruh elemen dan komponen UI yang dapat digunakan kembali (*reusable components*) di dalam aplikasi **Warungku**.

> **ATURAN WAJIB**:
> 1. Setiap kali membuat komponen UI baru (Button, TextField, Card, Modal, dll.), catat di dokumen ini.
> 2. Sebelum membuat halaman/fitur baru, periksa daftar komponen di bawah dan gunakan komponen yang sudah ada demi menjaga konsistensi gaya visual (style, padding, warna, typography, corner radius).
> 3. Desain harus minimalis, bersih, dan tanpa teks berlebih.

---

## 1. Standar Gaya Visual (Design Tokens)

- **Border Radius**: 8px - 12px (halus dan modern).
- **Elevasi / Shadow**: Minimal (0 - 2 dp) untuk menjaga kesan flat & clean.
- **Tipografi**:
  - Judul / Header: Ringkas & tegas.
  - Label: Singkat (1 - 2 kata), to-the-point.
  - Hindari kalimat panduan/filler panjang.
- **Padding Standar**: 8dp, 12dp, 16dp, 24dp.

---

## 2. Daftar Komponen Terdaftar (Registered Components)

*(Komponen baru akan dicatat di bawah ini sesuai pembuatan)*

| Nama Komponen | Lokasi File | Kegunaan | Properti Utama | Digunakan Pada Halaman |
| :--- | :--- | :--- | :--- | :--- |
| `AppButton` | `lib/widgets/app_button.dart` | Tombol aksi primer/sekunder dengan loading state dan kustomisasi warna | `text`, `onPressed`, `isLoading`, `isPrimary`, `icon`, `backgroundColor`, `foregroundColor`, `disabledBackgroundColor` | Login, Kasir, Pengaturan, Form, Transaksi Penjualan |
| `AppTextField` | `lib/widgets/app_text_field.dart` | Input teks seragam dengan border melengkung halus dan fleksibilitas label | `label`, `controller`, `hintText`, `readOnly`, `showLabelAbove`, `keyboardType`, `obscureText`, `prefixIcon`, `suffixIcon`, `validator` | Login, Form Barang, Form Pengguna, Transaksi Penjualan |
| `AppCard` | `lib/widgets/app_card.dart` | Kartu kontainer minimalis dengan border tipis dan elevasi rendah | `child`, `padding`, `margin`, `backgroundColor`, `borderRadius`, `elevation` | Login, Dashboard, Ringkasan Transaksi, Buat Pesanan |
| `AppBadge` | `lib/widgets/app_badge.dart` | Badge status (pesanan/transaksi) dan badge role hak akses | `text`, `backgroundColor`, `textColor`, `icon`, `factory role()`, `factory status()` | Dashboard, Tab Penjualan, Profil |
| `AppDialog` | `lib/widgets/app_dialog.dart` | Modal dialog konfirmasi terstandarisasi untuk aksi kritis | `title`, `message`, `confirmText`, `cancelText`, `isDestructive`, `isLoading` | Dashboard, Logout, Hapus Barang, Batal Transaksi |
| `RoleGuard` | `lib/core/auth/role_guard.dart` | Komponen proteksi hak akses rute berdasarkan role pengguna | `allowedRole`, `child`, `testUser` | AdminTokoDashboard, OwnerDashboard, AdminKantorDashboard |
| `AppAutocompleteField` | `lib/widgets/app_autocomplete_field.dart` | Input pencarian dinamis autocomplete berbasis overlay terikat lebar container | `hintText`, `minChars`, `optionsFilter`, `displayStringForOption`, `optionItemBuilder`, `onSelected`, `onClear` | Transaksi Penjualan, Kasir POS |
| `OrderanAktifCard` | `lib/widgets/orderan_aktif_card.dart` | Kartu pesanan aktif (open bill) bergaya minimalis putih dengan kontrol stepper served qty dan aksi bayar | `group`, `onIncrementServed`, `onDecrementServed`, `onEditItem`, `onPrintDapur`, `onAddItem`, `onPayAndPrint` | BerandaTab |
| `TambahItemPesananDialog` | `lib/widgets/tambah_item_pesanan_dialog.dart` | Modal dialog tambah item pesanan minimalis dengan autocomplete pencarian menu (AppAutocompleteField) & stepper | `customerName`, `products`, `show()` | BerandaTab |
| `PilihMetodePembayaranDialog` | `lib/widgets/pilih_metode_pembayaran_dialog.dart` | Modal dialog pelunasan/pembayaran pesanan dengan diskon (Rp/%) & metode bayar | `totalPesanan`, `show()` | BerandaTab |
| `KitchenReceiptDialog` | `lib/widgets/kitchen_receipt_dialog.dart` | Modal preview struk dapur untuk pesanan aktif dengan cetak manual saat tombol ditekan & thermal printer | `group`, `autoPrint`, `onPrint`, `show()`, `showFromCart()` | BerandaTab (Print Dapur manual), TransaksiPenjualanScreen (POS manual) |
| `DetailTransaksiDialog` | `lib/widgets/detail_transaksi_dialog.dart` | Modal detail transaksi minimalis saat kartu riwayat penjualan ditekan | `trx`, `onPrintAgain`, `onCancel`, `cancelText`, `show()` | PenjualanTab |
| `SalesReceiptDialog` | `lib/widgets/sales_receipt_dialog.dart` | Modal preview struk kasir/penjualan dengan tombol cetak struk thermal Bluetooth/jaringan dan tombol 'Export PDF' Surat Penawaran | `transactionId`, `items`, `subtotal`, `discountAmount`, `paymentMethod`, `confirmButtonText`, `autoPrint`, `onPrint`, `showFromTransaction()`, `showFromOrderGroup()`, `showFromTransactionList()` | BerandaTab (Bayar & Cetak manual via tombol modal), PenjualanTab (Cetak Ulang manual via tombol modal) |
| `QuotationPdfService` | `lib/services/quotation_pdf_service.dart` | Service pembuatan dan pratinjau dokumen PDF Surat Penawaran resmi A4 (Kop Warung, Header Surat Penawaran, Tabel Barang berbingkai, Rekap Total/PPN 11%/Grand Total, dan Tanda Tangan Sales) | `generateQuotationPdfBytes()`, `openOrPrintQuotationPdf()`, `formatRupiah()`, `extractDateOnly()` | Tombol 'Export PDF' pada modal `SalesReceiptDialog` (PenjualanTab & BerandaTab) |
| `RiwayatTransaksiCard` | `lib/widgets/riwayat_transaksi_card.dart` | Kartu riwayat transaksi penjualan minimalis dengan aksi swipe kiri dan tap modal detail | `trx`, `onTap`, `onDelete` | PenjualanTab |
| `PrinterSettingsDialog` | `lib/widgets/printer_settings_dialog.dart` | Modal konfigurasi printer thermal (Bluetooth paired devices & Jaringan IP/Port, Kertas 58/80mm, & Tes Cetak) | `show()` | AppBar Dashboard saat tab Profil aktif (Pojok kanan atas layar Profil) |
| `MonthlyReportScreen` | `lib/screens/report/monthly_report_screen.dart` | Layar evaluasi kinerja bulanan khusus Owner (ringkasan pesanan/omzet/AOV, ranking menu terlaris, rekap harian, cetak laporan PDF) | `initialMonth`, `initialYear` | Navigasi dari LabaRugiTab dan BerandaTab Owner |
| `MonthlyReportPdfService` | `lib/services/monthly_report_pdf_service.dart` | Service pembentukan dan pencetakan dokumen PDF laporan bulanan resmi A4 | `generateMonthlyReportBytes()`, `printMonthlyReport()` | Tombol print App Bar di `MonthlyReportScreen` |
| `QuickActionCard` | `lib/screens/dashboard/tabs/beranda_tab.dart` | Kartu navigasi cepat terdistribusi simetris penuh (Expanded untuk Admin Toko, responsive ConstrainedBox untuk Owner) | `_buildQuickAction(icon, label, onTap)` | BerandaTab (Admin Toko & Owner) |
| `AturUrutanPdfDialog` | `lib/widgets/atur_urutan_pdf_dialog.dart` | Modal dialog interaktif atur urutan kategori/produk & edit nama kategori untuk ekspor katalog PDF | `onLayoutSaved`, `initialProducts`, `show()` | AppBar Dashboard pojok kanan atas saat Tab Manajemen Barang aktif (Admin Toko) |
| `MenuCatalogPdfService` | `lib/services/menu_catalog_pdf_service.dart` | Service pembentukan dan pencetakan dokumen PDF katalog menu A4 2 kolom (Daftar Harga, Meja, format Rp XX K, kotak checklist) | `generateMenuCatalogBytes()`, `printMenuCatalog()`, `formatKPrice()` | Tombol 'Export PDF' pada `AturUrutanPdfDialog` |
| `ExportExcelAction` | `lib/screens/dashboard/admin_toko_dashboard_screen.dart` | Aksi unduh berkas Excel katalog produk via API GET /api/v1/products/export dengan pembukaan langsung di aplikasi viewer | `_handleExportExcel()`, `_isExportingExcel` | AppBar Dashboard pojok kanan atas saat Tab Manajemen Barang aktif (Admin Toko) |
| `ExcelExportService` | `lib/services/excel_export_service.dart` | Service penyimpanan berkas Excel lokal dan pembukaan langsung via OpenFilex (ACTION_VIEW) | `saveAndOpenExcelFile()`, `ExcelOpenResult` | AdminTokoDashboardScreen (`_handleExportExcel`) |

---

## 3. Log Pembuatan & Perubahan Komponen

- `2026-09-14`: Penambahan tombol 'Export PDF' pada modal struk `SalesReceiptDialog` dan implementasi service dokumen PDF Surat Penawaran A4 (`QuotationPdfService`). Dokumen didesain persis dengan format cetak penawaran resmi: kop toko & pelanggan di kiri, header SURAT PENAWARAN & metadata box di kanan, tabel barang bergaris penuh (No, Nama Barang, Qty, @Harga, @Diskon, Jumlah), kotak rincian Total, PPN 11%, dan Grand Total di kanan bawah, serta blok tanda tangan Sales. Dokumen langsung dibuka via aplikasi PDF viewer bawaan HP (`OpenFilex.open` / `ACTION_VIEW`) dengan fallback pencetakan via `Printing.layoutPdf`.

- `2026-09-14`: Pembaruan penanganan berkas Excel hasil unduhan (`ExcelExportService` & `AdminTokoDashboardScreen`): backend API (`ProductController::export`) kini langsung memproduksi dokumen spreadsheet resmi Microsoft Excel OpenXML (`.xlsx`) via `PhpOffice\PhpSpreadsheet` dengan styling header tebal dan kolom auto-size terpisah (Kolom A s/d I). Aplikasi Flutter menyertakan deteksi ekstensi berkas, normalisasi host LAN `localhost`, MIME type resmi spreadsheet (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`), serta direktif `sep=,\n` pada offline fallback CSV agar data tidak pernah lagi menumpuk di Kolom A saat dibuka via WPS Office / Excel.
- `2026-09-14`: Pembaruan penanganan berkas Excel hasil unduhan (`ExcelExportService`): berkas `.xlsx` kini langsung dibuka / ditampilkan menggunakan aplikasi pembaca spreadsheet di perangkat (seperti Google Sheets / Microsoft Excel / WPS Office via `ACTION_VIEW`), bukan lagi diteruskan ke share sheet sistem.
- `2026-09-14`: Penambahan tombol Export Excel di pojok kanan atas halaman Manajemen Barang Admin Toko, terintegrasi dengan endpoint API `GET /api/v1/products/export`, indikator loading, dan penanganan unduh berkas `.xlsx`.
- `2026-09-14`: Penambahan tombol PDF di pojok kanan atas halaman Manajemen Barang Admin Toko, modal dialog `AturUrutanPdfDialog` (geser urutan kategori & produk, tombol edit nama kategori, tombol aksi pill Simpan Layout & Export PDF), serta service pencetakan PDF katalog menu 2 kolom `MenuCatalogPdfService` dengan format Daftar Harga, kotak nomor meja, dan kotak isian kuantitas/checklist.

- `2026-09-11`: Inisialisasi registry komponen UI.
- `2026-09-11`: Penambahan komponen inti `AppButton`, `AppTextField`, dan `AppCard` untuk kebutuhan Halaman Login.
- `2026-09-11`: Penambahan `AppBadge` dan `AppDialog` untuk kebutuhan Dashboard Admin Toko.
- `2026-09-11`: Penambahan komponen proteksi hak akses `RoleGuard` untuk pemisahan akses dashboard Admin Toko, Owner, dan Admin Kantor.
- `2026-09-12`: Pembaruan `AppButton` (dukungan `backgroundColor`, `foregroundColor`, `disabledBackgroundColor`) dan `AppTextField` (dukungan `hintText`, `readOnly`, `showLabelAbove`) untuk halaman mandiri Transaksi Penjualan POS.
- `2026-09-12`: Penambahan `AppAutocompleteField` untuk pencarian dinamis nama barang dengan pemunculan dropdown minimal 2 karakter (seperti "kop" atau "kopi").
- `2026-09-12`: Penambahan `OrderanAktifCard`, `TambahItemPesananDialog`, `PilihMetodePembayaranDialog`, dan `KitchenReceiptDialog` untuk fitur Orderan Aktif (Open Bill), stepper penyajian pesanan, penambahan item, dan checkout pembayaran.
- `2026-09-12`: Redesain `OrderanAktifCard` dengan gaya visual minimalis (latar surface putih, border tipis outlineVariant, stepper netral, tombol rounded proporsional) serta penataan layout BerandaTab menggantikan Transaksi Selesai Terkini.
- `2026-09-12`: Redesain `TambahItemPesananDialog` dengan integrasi `AppAutocompleteField` (mekanisme pencarian dropdown minimal 2 karakter) dan tipografi minimalis yang proporsional.
- `2026-09-12`: Penambahan `DetailTransaksiDialog` untuk menampilkan modal rincian transaksi lengkap bergaya minimalis saat kartu penjualan ditekan.
- `2026-09-12`: Penambahan `SalesReceiptDialog` untuk pratinjau struk pembayaran kasir berukuran besar dan lapang sebelum dicetak pada fitur Bayar & Cetak dan Cetak Ulang riwayat penjualan.
- `2026-09-12`: Pembuatan komponen modular `RiwayatTransaksiCard` dengan penempatan nama pelanggan dan nomor transaksi pada header kartu, serta penyederhanaan subtitle item.
- `2026-09-12`: Penghapusan tombol fisik Batal pada `RiwayatTransaksiCard` dan penggantian dengan gesture geser (swipe ke kiri / `Dismissible`) berlatar merah dengan konfirmasi dialog sebelum eksekusi `deleteTransaction`.
- `2026-09-12`: Pembaruan `OrderanAktifCard` di mana tombol "Bayar & Cetak" dinonaktifkan (disabled / tidak dapat diklik dengan visual abu-abu netral) jika pesanan belum siap bayar (`isAllServed == false`), dan otomatis aktif hijau ketika seluruh item selesai disajikan (`isAllServed == true`).
- `2026-09-12`: Penambahan komponen dialog konfigurasi printer thermal `PrinterSettingsDialog` dan integrasi engine pencetakan ESC/POS thermal (`ThermalPrinterService`) pada struk kasir & dapur.
- `2026-09-12`: Integrasi penuh pencetakan printer thermal pada Cetak Dapur (`KitchenReceiptDialog.showFromCart` saat Buat Pesanan POS), Bayar & Cetak langsung otomatis di `BerandaTab`, dan Cetak Ulang multi-item pada `PenjualanTab` & `RiwayatTransaksiCard`.
- `2026-09-12`: Penambahan dukungan koneksi **Bluetooth Thermal Printer** (`print_bluetooth_thermal`), pemindaian perangkat terpasang (*paired devices*), izin Android Bluetooth, dan integrasi pemilihan printer Bluetooth pada `PrinterSettingsDialog` & `ThermalPrinterService`.
- `2026-09-12`: Pemindahan tombol konfigurasi printer thermal ke **Halaman Profil di pojok kanan atas** (pada AppBar Dashboard saat tab Profil aktif). Pembersihan header dialog struk kasir & dapur dari icon settings untuk menjaga desain minimalis.
- `2026-09-12`: Penerapan `autoPrint: true` secara menyeluruh pada SEMUA alur cetak aplikasi: Cetak Dapur POS, Cetak Dapur Orderan Aktif di Beranda, Bayar & Cetak pesanan aktif, Cetak Ulang riwayat transaksi, dan Cetak Ulang detail transaksi.
- `2026-09-12`: Penghapusan tombol pengaturan printer di dalam kartu identitas akun (`AppCard` di `ProfilTab`) agar tampilan kartu kembali bersih, simetris, dan terpusat tanpa redundansi dengan tombol printer di AppBar.
- `2026-09-12`: Penghapusan tombol print pada `RiwayatTransaksiCard` dan penonaktifan auto-print saat modal cetak ulang struk dibuka. Pencetakan thermal kini baru dilakukan setelah tombol konfirmasi "Cetak Ulang" di dalam modal ditekan pengguna.
- `2026-09-12`: Penonaktifan auto-print pada cetak struk dapur (`KitchenReceiptDialog`). Pencetakan struk dapur kini baru dimulai setelah tombol konfirmasi "Cetak" di dalam modal ditekan oleh pengguna.
- `2026-09-12`: Penonaktifan cetak otomatis langsung pada alur Bayar & Cetak di `BerandaTab`. Pencetakan struk pembayaran ke printer thermal Bluetooth kini baru dimulai setelah tombol konfirmasi "Cetak" di dalam modal pratinjau struk ditekan oleh kasir.
- `2026-09-13`: Penambahan layar evaluasi kinerja bulanan `MonthlyReportScreen` khusus role Owner dengan metrik performa bulanan, top selling menu ranking, dan breakdown kalender harian.
- `2026-09-13`: Pembaruan `BerandaTab` dengan tombol logout cepat di kartu sambutan serta shortcut dinamis khusus Owner (Laba Rugi, Penjualan, Lap. Bulanan, Pengguna, Profil).
- `2026-09-13`: Penyempurnaan `LabaRugiTab` dengan integrasi `ExpenseService` riil, filter rentang tanggal (termasuk custom DateRangePicker), rincian beban per pos kategori, akordeon riwayat per tanggal, dan tombol akses cepat ke Laporan Bulanan.
- `2026-09-13`: Pembaruan `UserManagementTab` terhubung ke `UserService.getUsers()` dan modal dialog edit user dengan fitur reset password staf.
- `2026-09-13`: Penambahan formulir pengaturan identitas warung (Nama, Alamat, Email Toko) di `ProfilTab` khusus untuk akun ber-role Owner.
- `2026-09-13`: Pembatasan hak akses transaksi untuk role Owner: menonaktifkan FAB Input Transaksi pada PenjualanTab (`canAddTransaction: false`), menonaktifkan tambah item pada pesanan aktif BerandaTab, memproteksi TransaksiPenjualanScreen dari akses Owner, dan memastikan aksi hapus transaksi permanen via swipe/detail tetap aktif.
- `2026-09-13`: Implementasi pencetakan PDF khusus untuk Laporan Bulanan (`MonthlyReportPdfService`) dengan format A4 rapi dan minimalis (ringkasan kinerja, tabel menu terlaris, rekap harian), serta mempertahankan printer thermal Bluetooth untuk struk kasir dan dapur.
- `2026-09-13`: Optimasi performa dan pengurangan request API seluruh layar Owner: Lazy Tab Loading pada `OwnerDashboardScreen` (hanya instansiasi tab saat diklik), Auto-Load Riwayat Penjualan per Tanggal & Beban Pengeluaran secara paralel saat `LabaRugiTab` diakses tanpa tombol manual, in-memory TTL caching (60 detik) pada `TransactionService`, `ExpenseService`, `UserService`, dan `ProductService`, serta instant local computation pada `MonthlyReportScreen`.
- `2026-09-13`: Redesain kartu navigasi cepat (*Quick Actions*) pada `BerandaTab` khusus Admin Toko. Menghilangkan ruang kosong di sebelah kanan dengan menerapkan pembagian lebar penuh merata dan simetris (`Expanded(child: _buildQuickAction)`) untuk 3 menu (Penjualan, Barang, Profil), serta mempertahankan responsivitas menu Owner (5 menu) via `ConstrainedBox(minWidth: constraints.maxWidth)`.








