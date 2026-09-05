# Core Apps Specification - Flutter Rewrite

Dokumen ini mendokumentasikan spesifikasi teknis dan implementasi **Core Layer** aplikasi **Manajemen Warung** di Flutter.

---

## 1. Daftar Dependencies (`pubspec.yaml`)

```yaml
name: manajemen_warung
description: "Aplikasi Manajemen Warung & Point of Sale (POS) Cross-Platform"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management & Architecture
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Routing & Navigation
  go_router: ^14.0.0

  # Networking & Serialization
  dio: ^5.4.1
  json_annotation: ^4.8.1

  # Local & Secure Storage
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # Thermal Printer (Bluetooth ESC/POS & Network)
  print_bluetooth_thermal: ^1.1.1
  esc_pos_utils_plus: ^2.0.1

  # PDF & Document Generation
  pdf: ^3.10.8
  printing: ^5.12.0
  excel: ^4.0.3
  open_filex: ^4.4.0
  path_provider: ^2.1.2

  # UI Components & Styling
  google_fonts: ^6.1.0
  fl_chart: ^0.66.2
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  flutter_svg: ^2.0.9

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.0
```

---

## 2. Core Network Layer (`Dio` Client & Interceptor)

### 2.1 Konfigurasi Base API Client
```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.warung.com/v1';
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({required this.secureStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired / Unauthorized -> trigger logout event
            await secureStorage.deleteAll();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
```

---

## 3. Core Storage & Offline Sync Engine

Aplikasi mendukung mode *offline-first* ketika jaringan terputus:
1. **Token & Kredensial**: Disimpan di `FlutterSecureStorage`.
2. **Katalog Produk & Transaksi**: Di-cache di `Hive` box (`products_box`, `transactions_box`, `expenses_box`).
3. **Offline Sync Queue**:
   - Jika `POST /transactions` gagal karena koneksi putus, request disimpan ke antrean lokal `unsynced_transactions`.
   - Ketika koneksi kembali online, worker `SyncService` akan mengeksekusi antrean transaksi secara berurutan (*FIFO*).

```dart
// lib/core/storage/sync_queue_service.dart
class SyncQueueService {
  final ApiClient apiClient;
  final Box unsyncedBox;

  SyncQueueService({required this.apiClient, required this.unsyncedBox});

  Future<void> processQueue() async {
    final pendingTransactions = unsyncedBox.values.toList();
    for (var tx in pendingTransactions) {
      try {
        final response = await apiClient.dio.post('/transactions', data: tx.toJson());
        if (response.statusCode == 200 || response.statusCode == 201) {
          await unsyncedBox.delete(tx.idTransaksi);
        }
      } catch (e) {
        // Tunda dan ulangi di siklus sinkronisasi berikutnya
        break;
      }
    }
  }
}
```

---

## 4. Hardware Thermal Printer Engine (ESC/POS)

Mendukung dua saluran pencetakan:
1. **Bluetooth SPP**: Menggunakan UUID Serial Port Profile (`00001101-0000-1000-8000-00805F9B34FB`) untuk printer thermal 58mm / 80mm.
2. **Network / LAN Thermal Printer**: Menggunakan koneksi TCP Socket (`Socket.connect(ip, port)`).

### 4.1 ESC/POS Byte Generator
```dart
// lib/core/printing/esc_pos_builder.dart
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class EscPosBuilder {
  static Future<List<int>> generateReceiptBytes({
    required String storeName,
    required String invoiceCode,
    required String dateStr,
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text('No: $invoiceCode', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Waktu: $dateStr', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    for (var item in items) {
      bytes += generator.row([
        PosColumn(text: '${item['qty']}x ${item['name']}', width: 7),
        PosColumn(text: item['price_formatted'], width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: 'Rp $subtotal', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 6),
        PosColumn(text: '-Rp $discount', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total Bayar', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp $grandTotal', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Metode: $paymentMethod', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.feed(2);
    bytes += generator.text('Terima Kasih atas Kunjungan Anda!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
```

### 4.2 Network LAN Printer Socket
```dart
// lib/core/printing/network_printer_service.dart
import 'dart:io';

class NetworkPrinterService {
  static Future<bool> printOverSocket({
    required String ipAddress,
    required int port,
    required List<int> bytes,
  }) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 500));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 5. Export Utilities (PDF & Excel Spreadsheet)

### 5.1 PDF Document Generator
- Menggunakan package `pdf` dan `printing` untuk membuat layout faktur atau laporan laba-rugi berstandar A4 atau ukuran struk.
- Mendukung *Preview Modal* dan langsung dikirim ke printer sistem (*Android Print Spooler / iOS AirPrint*) atau disimpan ke file lokal melalui `path_provider`.

### 5.2 Excel Generator
- Menggunakan package `excel` untuk menghasilkan format `.xlsx`.
- Sheet 1: **Rekap Transaksi Penjualan** (Kode Transaksi, Waktu, Kasir, Item, Total, Metode Bayar, Diskon).
- Sheet 2: **Rekap Biaya Operasional** (Tanggal, Kategori, Keterangan, Nominal, Pembuat).

---

## 6. Theme & Formatting System

### 6.1 Theme & Colors (`AppTheme`)
- **Primary Color**: `Color(0xFF2563EB)` (Blue Warung)
- **Secondary / Accent**: `Color(0xFF0D9488)` (Teal)
- **Success Color**: `Color(0xFF16A34A)` (Green Badge & Total Pemasukan)
- **Danger Color**: `Color(0xFFDC2626)` (Red Badge & Total Pengeluaran)
- **Warning Color**: `Color(0xFFD97706)` (Orange PENDING status)
- **Surface & Background**: `Color(0xFFF8FAFC)` / `Color(0xFFFFFFFF)`

### 6.2 Formatters (`Currency` & `DateTime`)
```dart
// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatRupiah(num amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatTanggalIndo(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatJam(DateTime dateTime) {
    return DateFormat('HH:mm', 'id_ID').format(dateTime);
  }
}
```
