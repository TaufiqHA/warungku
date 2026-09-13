import 'dart:convert';
import 'dart:io';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/orderan_aktif_card.dart';
import '../widgets/sales_receipt_dialog.dart';

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

class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  static ThermalPrinterService get instance => _instance;

  ThermalPrinterService._internal();

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

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await bluetoothScanner();
    } catch (_) {
      return [];
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

  String _twoColumns(String left, String right, int width) {
    if (left.length + right.length <= width) {
      final spaceCount = width - left.length - right.length;
      return left + (' ' * spaceCount) + right;
    }
    // Jika terlalu panjang, potong left atau wrap
    final available = width - right.length - 1;
    if (available > 0 && left.length > available) {
      final trimmed = left.substring(0, available);
      return '$trimmed $right';
    }
    return '$left $right';
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

  List<int> generateTestReceiptBytes(ThermalPrinterConfig config) {
    final bytes = <int>[];
    final w = config.maxCharsPerLine;

    bytes.addAll(cmdInit);
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(utf8.encode('WARUNGKU\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    bytes.addAll(utf8.encode('UJI COBA PRINTER THERMAL\n'));
    bytes.addAll(utf8.encode('${'-' * w}\n'));
    bytes.addAll(cmdAlignLeft);
    bytes.addAll(utf8.encode('Kertas: ${config.paperWidth}mm ($w kolom)\n'));
    final targetStr = config.isBluetooth
        ? 'Bluetooth: ${config.printerName.isNotEmpty ? config.printerName : config.macAddress}\n'
        : 'Target: ${config.ip}:${config.port}\n';
    bytes.addAll(utf8.encode(targetStr));
    bytes.addAll(utf8.encode('Waktu : ${DateTime.now().toString().substring(0, 19)}\n'));
    bytes.addAll(utf8.encode('${'-' * w}\n'));
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(utf8.encode('PRINTER BERHASIL TERHUBUNG!\n'));
    bytes.addAll(cmdBoldOff);
    bytes.addAll(utf8.encode('${'-' * w}\n'));
    bytes.addAll(cmdFeed3);
    bytes.addAll(cmdCut);

    return bytes;
  }

  List<int> generateSalesReceiptBytes({
    required ThermalPrinterConfig config,
    required String storeName,
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

    // Header Toko
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(utf8.encode('$storeName\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    bytes.addAll(utf8.encode('STRUK PEMBAYARAN\n'));
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // Info Transaksi
    bytes.addAll(cmdAlignLeft);
    bytes.addAll(utf8.encode('${_twoColumns('No. Trx', transactionId, w)}\n'));
    bytes.addAll(utf8.encode('${_twoColumns('Waktu', dateTimeStr, w)}\n'));
    bytes.addAll(utf8.encode('${_twoColumns('Kasir', cashierName, w)}\n'));
    if (customerName.isNotEmpty && customerName != '-') {
      bytes.addAll(utf8.encode('${_twoColumns('Pelanggan', customerName, w)}\n'));
    }
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // Daftar Item
    for (final item in items) {
      bytes.addAll(cmdBoldOn);
      bytes.addAll(utf8.encode('${item.name}\n'));
      bytes.addAll(cmdBoldOff);
      final qtyPrice = '${item.quantity} x ${_formatRupiah(item.price)}';
      final itemTotal = _formatRupiah(item.subtotal);
      bytes.addAll(utf8.encode('${_twoColumns('  $qtyPrice', itemTotal, w)}\n'));
    }
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // Subtotal & Diskon
    bytes.addAll(utf8.encode('${_twoColumns('Subtotal', _formatRupiah(subtotal), w)}\n'));
    if (discountAmount > 0) {
      bytes.addAll(utf8.encode('${_twoColumns('Diskon', '- ${_formatRupiah(discountAmount)}', w)}\n'));
    }

    // Grand Total
    bytes.addAll(cmdBoldOn);
    bytes.addAll(utf8.encode('${_twoColumns('TOTAL', _formatRupiah(grandTotal), w)}\n'));
    bytes.addAll(cmdBoldOff);
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // Metode Bayar
    bytes.addAll(utf8.encode('${_twoColumns('Metode Bayar', paymentMethod, w)}\n'));

    // Footer
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(utf8.encode('\nTerima kasih atas kunjungan Anda!\n'));
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

    // Header Dapur
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdFontTitle);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(utf8.encode('PESANAN DAPUR\n'));
    bytes.addAll(cmdFontNormal);
    bytes.addAll(cmdBoldOff);
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // Metadata
    bytes.addAll(cmdAlignLeft);
    final cust = group.customerName.isNotEmpty && group.customerName != '-'
        ? group.customerName
        : 'Pelanggan';
    bytes.addAll(utf8.encode('Meja/Pelanggan: $cust\n'));
    bytes.addAll(utf8.encode('No. Pesanan   : ${group.transactionId}\n'));
    bytes.addAll(utf8.encode('Waktu         : $dateStr $timeStr\n'));
    bytes.addAll(utf8.encode('${'-' * w}\n'));

    // List Item Dapur
    for (final item in group.items) {
      bytes.addAll(cmdBoldOn);
      final line = _twoColumns(item.namaItem, '${item.jumlah}x', w);
      bytes.addAll(utf8.encode('$line\n'));
      bytes.addAll(cmdBoldOff);
      if (item.catatan.isNotEmpty) {
        bytes.addAll(utf8.encode(' * Note: ${item.catatan}\n'));
      }
    }

    bytes.addAll(utf8.encode('${'-' * w}\n'));
    bytes.addAll(cmdFeed3);
    bytes.addAll(cmdCut);

    return bytes;
  }

  Future<PrintResult> sendToBluetooth(
    List<int> bytes, {
    required String macAddress,
    String? printerName,
  }) async {
    final displayName = printerName != null && printerName.isNotEmpty ? printerName : macAddress;
    if (macAddress.trim().isEmpty) {
      return const PrintResult(false, 'Belum ada printer Bluetooth yang dipilih di Pengaturan.');
    }

    try {
      final isConnected = await bluetoothConnector(macAddress.trim());
      if (!isConnected) {
        return PrintResult(
          false,
          'Gagal terhubung ke printer Bluetooth ($displayName). Pastikan printer menyala & Bluetooth aktif.',
        );
      }

      final isSent = await bluetoothWriter(bytes);
      if (isSent) {
        return PrintResult(
          true,
          'Struk berhasil dicetak via Bluetooth ($displayName)',
        );
      } else {
        return PrintResult(
          false,
          'Gagal mengirim data struk ke printer Bluetooth ($displayName).',
        );
      }
    } catch (e) {
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
    final bytes = generateSalesReceiptBytes(
      config: config,
      storeName: storeName,
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
