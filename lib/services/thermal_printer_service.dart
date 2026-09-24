import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/orderan_aktif_card.dart';
import '../widgets/sales_receipt_dialog.dart';
import 'bluetooth_permission_service.dart';

class ThermalPrinterConfig {
  final String connectionType; // 'bluetooth' or 'network'
  final String macAddress;
  final String printerName;
  final String ip;
  final int port;
  final int paperWidth; // 58 or 80 mm
  final bool isEnabled;

  const ThermalPrinterConfig({
    this.connectionType = 'bluetooth',
    this.macAddress = '',
    this.printerName = '',
    this.ip = '10.0.2.2',
    this.port = 9100,
    this.paperWidth = 58,
    this.isEnabled = true,
  });

  bool get isBluetooth => connectionType == 'bluetooth';
  int get maxCharsPerLine => paperWidth == 80 ? 48 : 32;

  factory ThermalPrinterConfig.fromPrefs(SharedPreferences prefs) {
    return ThermalPrinterConfig(
      connectionType: prefs.getString('thermal_printer_conn_type') ?? 'bluetooth',
      macAddress: prefs.getString('thermal_printer_mac') ?? '',
      printerName: prefs.getString('thermal_printer_name') ?? '',
      ip: prefs.getString('thermal_printer_ip') ?? '10.0.2.2',
      port: prefs.getInt('thermal_printer_port') ?? 9100,
      paperWidth: prefs.getInt('thermal_printer_paper') ?? 58,
      isEnabled: prefs.getBool('thermal_printer_enabled') ?? true,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('thermal_printer_conn_type', connectionType);
    await prefs.setString('thermal_printer_mac', macAddress);
    await prefs.setString('thermal_printer_name', printerName);
    await prefs.setString('thermal_printer_ip', ip);
    await prefs.setInt('thermal_printer_port', port);
    await prefs.setInt('thermal_printer_paper', paperWidth);
    await prefs.setBool('thermal_printer_enabled', isEnabled);
  }
}

class PrintResult {
  final bool success;
  final String message;

  const PrintResult(this.success, this.message);
}

/// Hasil pemindaian perangkat Bluetooth terpasang beserta pesan kegagalannya.
class PairedDevicesResult {
  final List<BluetoothInfo> devices;
  final String? errorMessage;

  const PairedDevicesResult({this.devices = const [], this.errorMessage});

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  static ThermalPrinterService get instance => _instance;

  ThermalPrinterService._internal() {
    bluetoothConnectionChecker = () async => _lastConnectionState;
  }

  /// Status koneksi printer terakhir yang dilacak service sendiri.
  ///
  /// Tidak memakai `PrintBluetoothThermal.connectionStatus` karena plugin
  /// mengimplementasikan method itu dengan menulis satu byte spasi ke printer
  /// (lihat `checkConnectionStatus()` pada plugin) — efek samping yang tidak
  /// diinginkan untuk sekadar indikator UI.
  bool _lastConnectionState = false;

  /// Status koneksi terakhir yang diketahui (untuk indikator UI & pengujian).
  bool get lastConnectionState => _lastConnectionState;

  /// Socket connector abstraction for testability
  Future<Socket> Function(String host, int port, {Duration? timeout}) socketConnector = Socket.connect;

  /// Bluetooth connector abstraction for testability
  Future<bool> Function(String mac) bluetoothConnector = (mac) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: mac);
  };

  /// Bluetooth writer abstraction for testability
  Future<bool> Function(List<int> bytes) bluetoothWriter = (bytes) async {
    return await PrintBluetoothThermal.writeBytes(bytes);
  };

  /// Bluetooth paired scanner abstraction for testability
  Future<List<BluetoothInfo>> Function() bluetoothScanner = () async {
    return await PrintBluetoothThermal.pairedBluetooths;
  };

  /// Bluetooth disconnect abstraction for testability
  Future<bool> Function() bluetoothDisconnector = () async {
    return await PrintBluetoothThermal.disconnect;
  };

  /// Status adapter Bluetooth perangkat (nyala / mati).
  Future<bool> Function() bluetoothEnabledChecker = () async {
    try {
      // Plugin print_bluetooth_thermal hanya mendukung Android/Windows; pada
      // platform lain (mis. pengujian desktop) status dianggap aktif.
      if (!Platform.isAndroid) return true;
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('ThermalPrinterService.bluetoothEnabled: $e');
      return true;
    }
  };

  /// Status koneksi printer untuk indikator UI.
  ///
  /// Seam pengujian dapat mengganti fungsi ini; nilai bawaan mengembalikan
  /// [lastConnectionState] tanpa menyentuh plugin.
  late Future<bool> Function() bluetoothConnectionChecker;

  /// Pengelola izin Bluetooth runtime.
  BluetoothPermissionService permissionService = BluetoothPermissionService.instance;

  // ESC/POS Command Constants
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02]; // ESC a 2
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> cmdFontNormal = [0x1D, 0x21, 0x00]; // GS ! 0
  static const List<int> cmdFontTitle = [0x1D, 0x21, 0x11]; // Double size
  static const List<int> cmdCut = [0x1D, 0x56, 0x41, 0x03]; // GS V 65 3
  static const List<int> cmdFeed3 = [0x1B, 0x64, 0x03]; // ESC d 3
  // Batalkan mode karakter Kanji/China (FS .) dan pilih code page Latin
  // PC1252 (ESC t 16). Tanpa ini, byte non-ASCII yang lolos (mis. emoji)
  // ditafsirkan printer sebagai aksara China.
  static const List<int> cmdCancelChinese = [0x1C, 0x2E]; // FS .
  static const List<int> cmdLatinCodePage = [0x1B, 0x74, 0x10]; // ESC t 16

  Future<List<BluetoothInfo>> getPairedDevices({bool requestPermission = false}) async {
    final result = await scanPairedDevices(requestPermission: requestPermission);
    return result.devices;
  }

  /// Memindai printer Bluetooth yang sudah dipasangkan (paired) ke perangkat.
  ///
  /// Mengembalikan pesan kesalahan yang spesifik (izin ditolak / Bluetooth mati)
  /// sehingga UI bisa menampilkan penyebabnya, bukan sekadar "belum ada printer".
  Future<PairedDevicesResult> scanPairedDevices({bool requestPermission = false}) async {
    final permission = requestPermission
        ? await permissionService.request()
        : await permissionService.check();

    if (permission != BluetoothPermissionStatus.granted) {
      return PairedDevicesResult(errorMessage: BluetoothPermissionService.message(permission));
    }

    if (!await bluetoothEnabledChecker()) {
      return const PairedDevicesResult(
        errorMessage: 'Bluetooth perangkat sedang tidak aktif. Nyalakan Bluetooth lalu pindai ulang.',
      );
    }

    try {
      final devices = await bluetoothScanner();
      return PairedDevicesResult(devices: devices);
    } catch (e) {
      return PairedDevicesResult(errorMessage: 'Gagal memindai perangkat Bluetooth: $e');
    }
  }

  /// Status adaptor Bluetooth perangkat.
  Future<bool> isBluetoothEnabled() => bluetoothEnabledChecker();

  /// Status koneksi socket ke printer (indikator UI).
  Future<bool> isPrinterConnected() => bluetoothConnectionChecker();

  /// Status izin Bluetooth tanpa memunculkan dialog.
  Future<BluetoothPermissionStatus> checkPermission() => permissionService.check();

  /// Meminta izin Bluetooth (memunculkan dialog sistem bila perlu).
  Future<BluetoothPermissionStatus> requestPermission() => permissionService.request();

  /// Menyambungkan printer Bluetooth terpilih tanpa mencetak (untuk pengujian).
  Future<PrintResult> connectPrinter({ThermalPrinterConfig? overrideConfig}) async {
    final config = overrideConfig ?? await getConfig();

    if (!config.isBluetooth) {
      return const PrintResult(false, 'Mode printer aktif adalah Jaringan (IP), bukan Bluetooth.');
    }

    final mac = config.macAddress.trim();
    final displayName = config.printerName.isNotEmpty ? config.printerName : mac;
    if (mac.isEmpty) {
      return const PrintResult(false, 'Pilih printer Bluetooth terlebih dahulu.');
    }

    final permission = await permissionService.request();
    if (permission != BluetoothPermissionStatus.granted) {
      return PrintResult(false, BluetoothPermissionService.message(permission));
    }

    if (!await bluetoothEnabledChecker()) {
      return const PrintResult(false, 'Bluetooth perangkat sedang tidak aktif. Nyalakan Bluetooth lalu coba lagi.');
    }

    try {
      final isConnected = await bluetoothConnector(mac);
      _lastConnectionState = isConnected;
      if (isConnected) {
        return PrintResult(true, 'Terhubung ke printer Bluetooth ($displayName)');
      }
      return PrintResult(
        false,
        'Gagal terhubung ke ($displayName). Pastikan printer menyala, sudah dipasangkan (pair) di Bluetooth HP, dan tidak dipakai perangkat lain.',
      );
    } catch (e) {
      _lastConnectionState = false;
      return PrintResult(false, 'Error koneksi Bluetooth printer: ${e.toString()}');
    }
  }

  /// Memutuskan koneksi printer Bluetooth yang sedang aktif.
  Future<PrintResult> disconnectPrinter() async {
    try {
      await bluetoothDisconnector();
      _lastConnectionState = false;
      return const PrintResult(true, 'Koneksi printer Bluetooth diputuskan');
    } catch (e) {
      return PrintResult(false, 'Gagal memutuskan koneksi printer: ${e.toString()}');
    }
  }

  Future<void> _safeDisconnect() async {
    try {
      await bluetoothDisconnector();
    } catch (e) {
      debugPrint('ThermalPrinterService._safeDisconnect: $e');
    } finally {
      _lastConnectionState = false;
    }
  }

  Future<ThermalPrinterConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return ThermalPrinterConfig.fromPrefs(prefs);
  }

  Future<void> saveConfig(ThermalPrinterConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await config.saveToPrefs(prefs);
  }

  /// Menyusun dua kolom selebar [width].
  ///
  /// Bila tidak muat dalam satu baris, kolom kiri dipecah ke beberapa baris lalu
  /// kolom kanan diletakkan rata kanan pada baris berikutnya — tidak ada teks
  /// yang dipotong.
  String _twoColumns(String left, String right, int width) {
    final leftText = _asciiSafe(left);
    final rightText = _asciiSafe(right).trim();
    if (leftText.length + rightText.length <= width) {
      return leftText + (' ' * (width - leftText.length - rightText.length)) + rightText;
    }

    final lines = <String>[..._wrapText(leftText, width)];
    for (final line in _wrapText(rightText, width)) {
      lines.add(line.length < width ? (' ' * (width - line.length)) + line : line);
    }
    return lines.join('\n');
  }

  /// Memecah teks menjadi baris-baris selebar [width] karakter kertas.
  ///
  /// Kata tunggal yang lebih panjang dari [width] dipotong paksa agar tidak ada
  /// karakter yang hilang.
  List<String> _wrapText(String text, int width) {
    final clean = _asciiSafe(text).trim();
    if (clean.isEmpty || width <= 0) return const [];

    final lines = <String>[];
    var current = '';

    for (final word in clean.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;

      if (current.isNotEmpty && current.length + 1 + word.length <= width) {
        current = '$current $word';
        continue;
      }
      if (current.isNotEmpty) {
        lines.add(current);
        current = '';
      }
      if (word.length <= width) {
        current = word;
        continue;
      }
      var rest = word;
      while (rest.length > width) {
        lines.add(rest.substring(0, width));
        rest = rest.substring(width);
      }
      current = rest;
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  String _formatRupiah(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Byte teks yang aman untuk printer thermal (lihat [_asciiSafe]).
  List<int> _textToBytes(String text) => utf8.encode(_asciiSafe(text));

  /// Mengubah teks menjadi ASCII-aman.
  ///
  /// Printer thermal umumnya memakai code page CP437/GBK secara default, sehingga
  /// byte UTF-8 multi-byte untuk karakter non-ASCII tercetak kacau. Karena ASCII
  /// identik di semua code page, karakter Latin-1 ditransliterasi (é→e, ñ→n,
  /// tanda kutip pintar → ASCII) sedangkan emoji/simbol/karakter tak dikenal
  /// dibuang agar tidak tercetak sebagai aksara China.
  static String _asciiSafe(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune < 0x80) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(_asciiFallback[rune] ?? '');
      }
    }
    return buffer.toString();
  }

  static const Map<int, String> _asciiFallback = {
    0x00A0: ' ',
    0x00AB: '"',
    0x00BB: '"',
    0x00B0: ' deg',
    0x00B7: '.',
    0x00D7: 'x',
    0x00F7: '/',
    0x2010: '-',
    0x2011: '-',
    0x2012: '-',
    0x2013: '-',
    0x2014: '-',
    0x2015: '-',
    0x2018: "'",
    0x2019: "'",
    0x201A: "'",
    0x201B: "'",
    0x201C: '"',
    0x201D: '"',
    0x201E: '"',
    0x201F: '"',
    0x2022: '*',
    0x2026: '...',
    0x2032: "'",
    0x2033: '"',
    0x20AC: 'EUR',
    0x2122: '(TM)',
    0x00C0: 'A',
    0x00C1: 'A',
    0x00C2: 'A',
    0x00C3: 'A',
    0x00C4: 'A',
    0x00C5: 'A',
    0x00C6: 'AE',
    0x00C7: 'C',
    0x00C8: 'E',
    0x00C9: 'E',
    0x00CA: 'E',
    0x00CB: 'E',
    0x00CC: 'I',
    0x00CD: 'I',
    0x00CE: 'I',
    0x00CF: 'I',
    0x00D0: 'D',
    0x00D1: 'N',
    0x00D2: 'O',
    0x00D3: 'O',
    0x00D4: 'O',
    0x00D5: 'O',
    0x00D6: 'O',
    0x00D8: 'O',
    0x00D9: 'U',
    0x00DA: 'U',
    0x00DB: 'U',
    0x00DC: 'U',
    0x00DD: 'Y',
    0x00DE: 'TH',
    0x00DF: 'ss',
    0x00E0: 'a',
    0x00E1: 'a',
    0x00E2: 'a',
    0x00E3: 'a',
    0x00E4: 'a',
    0x00E5: 'a',
    0x00E6: 'ae',
    0x00E7: 'c',
    0x00E8: 'e',
    0x00E9: 'e',
    0x00EA: 'e',
    0x00EB: 'e',
    0x00EC: 'i',
    0x00ED: 'i',
    0x00EE: 'i',
    0x00EF: 'i',
    0x00F0: 'd',
    0x00F1: 'n',
    0x00F2: 'o',
    0x00F3: 'o',
    0x00F4: 'o',
    0x00F5: 'o',
    0x00F6: 'o',
    0x00F8: 'o',
    0x00F9: 'u',
    0x00FA: 'u',
    0x00FB: 'u',
    0x00FC: 'u',
    0x00FD: 'y',
    0x00FE: 'th',
    0x00FF: 'y',
  };

  List<int> generateTestReceiptBytes(ThermalPrinterConfig config) {
    final bytes = <int>[];
    final w = config.maxCharsPerLine;

    bytes.addAll(cmdInit);
    bytes.addAll(cmdCancelChinese);
    bytes.addAll(cmdLatinCodePage);
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(_textToBytes('WARUNGKU\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    bytes.addAll(_textToBytes('UJI COBA PRINTER THERMAL\n'));
    bytes.addAll(_textToBytes('${'-' * w}\n'));
    bytes.addAll(cmdAlignLeft);
    bytes.addAll(_textToBytes('Kertas: ${config.paperWidth}mm ($w kolom)\n'));
    final targetStr = config.isBluetooth
        ? 'Bluetooth: ${config.printerName.isNotEmpty ? config.printerName : config.macAddress}\n'
        : 'Target: ${config.ip}:${config.port}\n';
    bytes.addAll(_textToBytes(targetStr));
    bytes.addAll(_textToBytes('Waktu : ${DateTime.now().toString().substring(0, 19)}\n'));
    bytes.addAll(_textToBytes('${'-' * w}\n'));
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(_textToBytes('PRINTER BERHASIL TERHUBUNG!\n'));
    bytes.addAll(cmdBoldOff);
    bytes.addAll(_textToBytes('${'-' * w}\n'));
    bytes.addAll(cmdFeed3);
    bytes.addAll(cmdCut);

    return bytes;
  }

  List<int> generateSalesReceiptBytes({
    required ThermalPrinterConfig config,
    required String storeName,
    String? storeAddress,
    required String transactionId,
    required String dateTimeStr,
    required String customerName,
    required String cashierName,
    required List<SalesReceiptItem> items,
    required double subtotal,
    required double discountAmount,
    required String paymentMethod,
  }) {
    final bytes = <int>[];
    final w = config.maxCharsPerLine;
    final grandTotal = (subtotal - discountAmount).clamp(0.0, double.infinity);

    bytes.addAll(cmdInit);
    bytes.addAll(cmdCancelChinese);
    bytes.addAll(cmdLatinCodePage);

    // Header Toko (nama + alamat dari Profil Warung)
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(_textToBytes('$storeName\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    for (final line in _wrapText(storeAddress ?? '', w)) {
      bytes.addAll(_textToBytes('$line\n'));
    }
    bytes.addAll(_textToBytes('STRUK PEMBAYARAN\n'));
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // Info Transaksi
    bytes.addAll(cmdAlignLeft);
    bytes.addAll(_textToBytes('${_twoColumns('No. Trx', transactionId, w)}\n'));
    bytes.addAll(_textToBytes('${_twoColumns('Waktu', dateTimeStr, w)}\n'));
    bytes.addAll(_textToBytes('${_twoColumns('Kasir', cashierName, w)}\n'));
    if (customerName.isNotEmpty && customerName != '-') {
      bytes.addAll(_textToBytes('${_twoColumns('Pelanggan', customerName, w)}\n'));
    }
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // Daftar Item
    for (final item in items) {
      bytes.addAll(cmdBoldOn);
      // Nama menu panjang dibungkus agar tidak terpotong di kertas.
      for (final line in _wrapText(item.name, w)) {
        bytes.addAll(_textToBytes('$line\n'));
      }
      bytes.addAll(cmdBoldOff);
      final qtyPrice = '${item.quantity} x ${_formatRupiah(item.price)}';
      final itemTotal = _formatRupiah(item.subtotal);
      bytes.addAll(_textToBytes('${_twoColumns('  $qtyPrice', itemTotal, w)}\n'));
    }
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // Subtotal & Diskon
    bytes.addAll(_textToBytes('${_twoColumns('Subtotal', _formatRupiah(subtotal), w)}\n'));
    if (discountAmount > 0) {
      bytes.addAll(_textToBytes('${_twoColumns('Diskon', '- ${_formatRupiah(discountAmount)}', w)}\n'));
    }

    // Grand Total
    bytes.addAll(cmdBoldOn);
    bytes.addAll(_textToBytes('${_twoColumns('TOTAL', _formatRupiah(grandTotal), w)}\n'));
    bytes.addAll(cmdBoldOff);
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // Metode Bayar
    bytes.addAll(_textToBytes('${_twoColumns('Metode Bayar', paymentMethod, w)}\n'));

    // Footer
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(_textToBytes('\nTerima kasih atas kunjungan Anda!\n'));
    bytes.addAll(cmdFeed3);
    bytes.addAll(cmdCut);

    return bytes;
  }

  List<int> generateKitchenReceiptBytes({
    required ThermalPrinterConfig config,
    required OrderanAktifGroup group,
  }) {
    final bytes = <int>[];
    final w = config.maxCharsPerLine;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day}/${now.month}/${now.year}';

    bytes.addAll(cmdInit);
    bytes.addAll(cmdCancelChinese);
    bytes.addAll(cmdLatinCodePage);

    // Header Dapur
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(_textToBytes('PESANAN DAPUR\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // Metadata
    bytes.addAll(cmdAlignLeft);
    final cust = group.customerName.isNotEmpty && group.customerName != '-'
        ? group.customerName
        : 'Pelanggan';
    bytes.addAll(_textToBytes('Meja/Pelanggan: $cust\n'));
    bytes.addAll(_textToBytes('No. Pesanan   : ${group.transactionId}\n'));
    bytes.addAll(_textToBytes('Waktu         : $dateStr $timeStr\n'));
    bytes.addAll(_textToBytes('${'-' * w}\n'));

    // List Item Dapur
    for (final item in group.items) {
      bytes.addAll(cmdBoldOn);
      // Kuantitas dijadikan awalan agar nama menu panjang membungkus penuh
      // (tidak terpotong) dan tidak menyisakan "1x" menggantung di baris sendiri.
      for (final line in _wrapText('${item.jumlah}x ${item.namaItem}', w)) {
        bytes.addAll(_textToBytes('$line\n'));
      }
      bytes.addAll(cmdBoldOff);
      if (item.catatan.isNotEmpty) {
        bytes.addAll(_textToBytes(' * Note: ${item.catatan}\n'));
      }
    }

    bytes.addAll(_textToBytes('${'-' * w}\n'));
    bytes.addAll(cmdFeed3);
    bytes.addAll(cmdCut);

    return bytes;
  }

  Future<PrintResult> sendToBluetooth(
    List<int> bytes, {
    required String macAddress,
    String? printerName,
  }) async {
    final mac = macAddress.trim();
    final displayName = printerName != null && printerName.isNotEmpty ? printerName : mac;

    if (mac.isEmpty) {
      return const PrintResult(
        false,
        'Belum ada printer Bluetooth yang dipilih. Buka Pengaturan Printer Thermal di halaman Profil.',
      );
    }

    // 1. Izin runtime (Android 12+). Tanpa ini plugin menolak connect & daftar printer.
    final permission = await permissionService.request();
    if (permission != BluetoothPermissionStatus.granted) {
      return PrintResult(false, BluetoothPermissionService.message(permission));
    }

    // 2. Adaptor Bluetooth harus menyala.
    if (!await bluetoothEnabledChecker()) {
      return const PrintResult(
        false,
        'Bluetooth perangkat sedang tidak aktif. Nyalakan Bluetooth lalu cetak ulang.',
      );
    }

    try {
      // 3. Sambungkan (native plugin otomatis menutup socket lama lebih dulu).
      final isConnected = await bluetoothConnector(mac);
      _lastConnectionState = isConnected;
      if (!isConnected) {
        return PrintResult(
          false,
          'Gagal terhubung ke printer Bluetooth ($displayName). Pastikan printer menyala, sudah dipasangkan (pair) di Bluetooth HP, dan tidak sedang dipakai perangkat lain.',
        );
      }

      // 4. Kirim data struk. Plugin sudah memecah kiriman per 16 KB.
      // Catatan: plugin `print_bluetooth_thermal` menambahkan satu byte newline
      // di awal setiap `writeBytes` (lihat handleWriteBytes pada plugin), jadi
      // struk memuat satu baris kosong di atas yang tidak bisa dihilangkan dari
      // sisi aplikasi tanpa mem-fork plugin.
      var isSent = await bluetoothWriter(bytes);

      if (!isSent) {
        // Koneksi basi (printer baru dinyalakan / socket mati) -> sambung ulang & kirim sekali lagi.
        await _safeDisconnect();
        final isReconnected = await bluetoothConnector(mac);
        _lastConnectionState = isReconnected;
        if (isReconnected) {
          isSent = await bluetoothWriter(bytes);
        }
      }

      if (isSent) {
        _lastConnectionState = true;
        return PrintResult(
          true,
          'Struk berhasil dicetak via Bluetooth ($displayName)',
        );
      }

      await _safeDisconnect();
      return PrintResult(
        false,
        'Data struk gagal dikirim ke ($displayName). Coba matikan lalu nyalakan ulang printer, kemudian cetak lagi.',
      );
    } catch (e) {
      await _safeDisconnect();
      return PrintResult(
        false,
        'Error koneksi Bluetooth printer: ${e.toString()}',
      );
    }
  }

  Future<PrintResult> sendToPrinter(List<int> bytes, {ThermalPrinterConfig? overrideConfig}) async {
    final config = overrideConfig ?? await getConfig();

    if (config.isBluetooth) {
      return sendToBluetooth(
        bytes,
        macAddress: config.macAddress,
        printerName: config.printerName,
      );
    }

    try {
      final socket = await socketConnector(
        config.ip,
        config.port,
        timeout: const Duration(seconds: 4),
      );

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return PrintResult(
        true,
        'Struk berhasil dicetak ke Printer Thermal (${config.ip}:${config.port})',
      );
    } on SocketException catch (e) {
      return PrintResult(
        false,
        'Printer thermal (${config.ip}:${config.port}) tidak merespons: ${e.osError?.message ?? e.message}',
      );
    } catch (e) {
      return PrintResult(
        false,
        'Gagal mencetak ke printer thermal: ${e.toString()}',
      );
    }
  }

  Future<PrintResult> testPrint({ThermalPrinterConfig? customConfig}) async {
    final cfg = customConfig ?? await getConfig();
    final bytes = generateTestReceiptBytes(cfg);
    return sendToPrinter(bytes, overrideConfig: cfg);
  }

  Future<PrintResult> printSalesReceipt({
    required String storeName,
    required String transactionId,
    required String dateTimeStr,
    required String customerName,
    required String cashierName,
    required List<SalesReceiptItem> items,
    required double subtotal,
    required double discountAmount,
    required String paymentMethod,
  }) async {
    final config = await getConfig();
    // Kop struk mengikuti identitas warung yang tersimpan (Profil Warung).
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('warung_name')?.trim();
    final savedAddress = prefs.getString('warung_address')?.trim();
    final resolvedName = (savedName != null && savedName.isNotEmpty) ? savedName : storeName;

    final bytes = generateSalesReceiptBytes(
      config: config,
      storeName: resolvedName,
      storeAddress: (savedAddress != null && savedAddress.isNotEmpty) ? savedAddress : null,
      transactionId: transactionId,
      dateTimeStr: dateTimeStr,
      customerName: customerName,
      cashierName: cashierName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod,
    );
    return sendToPrinter(bytes, overrideConfig: config);
  }

  Future<PrintResult> printKitchenReceipt(OrderanAktifGroup group) async {
    final config = await getConfig();
    final bytes = generateKitchenReceiptBytes(
      config: config,
      group: group,
    );
    return sendToPrinter(bytes, overrideConfig: config);
  }
}
