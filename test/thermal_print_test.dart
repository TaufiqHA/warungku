import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warungku/services/bluetooth_permission_service.dart';
import 'package:warungku/services/thermal_printer_service.dart';
import 'package:warungku/widgets/printer_settings_dialog.dart';
import 'package:warungku/widgets/sales_receipt_dialog.dart';

void main() {
  final service = ThermalPrinterService.instance;
  final permissionService = BluetoothPermissionService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // Default: izin diberikan, Bluetooth aktif, printer siap.
    permissionService.requester = () async => BluetoothPermissionStatus.granted;
    permissionService.checker = () async => BluetoothPermissionStatus.granted;

    service.bluetoothEnabledChecker = () async => true;
    service.bluetoothConnectionChecker = () async => false;
    service.bluetoothConnector = (mac) async => true;
    service.bluetoothWriter = (bytes) async => true;
    service.bluetoothScanner = () async => [
      BluetoothInfo(name: 'RPP02N Thermal', macAdress: '66:22:33:44:55:66'),
    ];
    service.bluetoothDisconnector = () async => true;
    service.socketConnector = (host, port, {timeout}) async {
      throw const SocketException('Test mock offline socket');
    };
  });

  tearDown(() {
    permissionService.requester = null;
    permissionService.checker = null;
  });

  const receiptBytes = [0x1B, 0x40, 0x41, 0x42];
  const sampleItems = [
    SalesReceiptItem(name: 'Ayam Geprek', quantity: 2, price: 15000, subtotal: 30000),
  ];

  group('Pencetakan Bluetooth', () {
    test('mengirim struk ke printer terpilih dan melaporkan sukses', () async {
      String? connectedMac;
      List<int>? writtenBytes;

      service.bluetoothConnector = (mac) async {
        connectedMac = mac;
        return true;
      };
      service.bluetoothWriter = (bytes) async {
        writtenBytes = bytes;
        return true;
      };

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
        printerName: 'RPP02N Thermal',
      );

      expect(result.success, true);
      expect(result.message, contains('berhasil dicetak'));
      expect(connectedMac, '66:22:33:44:55:66');
      expect(writtenBytes, receiptBytes);
    });

    test('menolak mencetak saat izin Bluetooth belum diberikan', () async {
      var writerCalled = false;
      permissionService.requester = () async => BluetoothPermissionStatus.denied;
      service.bluetoothWriter = (bytes) async {
        writerCalled = true;
        return true;
      };

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, false);
      expect(result.message, contains('Izin Bluetooth belum diberikan'));
      expect(writerCalled, false);
    });

    test('memberi instruksi pengaturan Android saat izin ditolak', () async {
      permissionService.requester = () async => BluetoothPermissionStatus.denied;

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, false);
      expect(result.message, contains('Pengaturan Android'));
    });

    test('menolak mencetak saat Bluetooth perangkat tidak aktif', () async {
      service.bluetoothEnabledChecker = () async => false;

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, false);
      expect(result.message, contains('Bluetooth perangkat sedang tidak aktif'));
    });

    test('meminta pemilihan printer saat MAC belum diatur', () async {
      final result = await service.sendToBluetooth(receiptBytes, macAddress: '');

      expect(result.success, false);
      expect(result.message, contains('Belum ada printer Bluetooth yang dipilih'));
    });

    test('menyambung ulang lalu mencetak saat koneksi printer basi', () async {
      var connectCount = 0;
      var disconnectCount = 0;
      var writeCount = 0;

      service.bluetoothConnector = (mac) async {
        connectCount++;
        return true;
      };
      service.bluetoothDisconnector = () async {
        disconnectCount++;
        return true;
      };
      service.bluetoothWriter = (bytes) async {
        writeCount++;
        return writeCount > 1; // gagal pada percobaan pertama
      };

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, true);
      expect(connectCount, 2);
      expect(disconnectCount, 1);
      expect(writeCount, 2);
    });

    test('melaporkan kegagalan dan memutus koneksi bila struk tetap gagal terkirim', () async {
      var disconnectCount = 0;
      service.bluetoothWriter = (bytes) async => false;
      service.bluetoothDisconnector = () async {
        disconnectCount++;
        return true;
      };

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, false);
      expect(result.message, contains('gagal dikirim'));
      expect(disconnectCount, greaterThan(0));
    });

    test('melaporkan kegagalan terhubung dengan panduan pairing', () async {
      service.bluetoothConnector = (mac) async => false;

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
        printerName: 'RPP02N Thermal',
      );

      expect(result.success, false);
      expect(result.message, contains('Gagal terhubung'));
      expect(result.message, contains('dipasangkan'));
    });
  });

  group('Status & izin printer', () {
    test('scanPairedDevices mengembalikan pesan izin, bukan daftar kosong', () async {
      permissionService.checker = () async => BluetoothPermissionStatus.denied;

      final result = await service.scanPairedDevices();

      expect(result.devices, isEmpty);
      expect(result.hasError, true);
      expect(result.errorMessage, contains('Izin Bluetooth'));
    });

    test('scanPairedDevices mengembalikan pesan saat Bluetooth nonaktif', () async {
      service.bluetoothEnabledChecker = () async => false;

      final result = await service.scanPairedDevices();

      expect(result.hasError, true);
      expect(result.errorMessage, contains('tidak aktif'));
    });

    test('scanPairedDevices mengembalikan printer terpasang saat izin diberikan', () async {
      final result = await service.scanPairedDevices();

      expect(result.hasError, false);
      expect(result.devices, hasLength(1));
      expect(result.devices.first.name, 'RPP02N Thermal');
    });

    test('connectPrinter melaporkan sukses dan disconnectPrinter memutus koneksi', () async {
      const config = ThermalPrinterConfig(
        connectionType: 'bluetooth',
        macAddress: '66:22:33:44:55:66',
        printerName: 'RPP02N Thermal',
      );

      final connected = await service.connectPrinter(overrideConfig: config);
      expect(connected.success, true);
      expect(connected.message, contains('Terhubung'));

      final disconnected = await service.disconnectPrinter();
      expect(disconnected.success, true);
    });

    test('connectPrinter menolak saat izin Bluetooth ditolak', () async {
      permissionService.requester = () async => BluetoothPermissionStatus.denied;

      final result = await service.connectPrinter(
        overrideConfig: const ThermalPrinterConfig(
          connectionType: 'bluetooth',
          macAddress: '66:22:33:44:55:66',
        ),
      );

      expect(result.success, false);
      expect(result.message, contains('Izin Bluetooth'));
    });

    test('melacak status koneksi setelah mencetak tanpa query plugin', () async {
      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, true);
      expect(service.lastConnectionState, true);
      expect(await service.isPrinterConnected(), false); // override seam pengujian
    });

    test('status koneksi menjadi terputus setelah kegagalan kirim', () async {
      service.bluetoothWriter = (bytes) async => false;

      final result = await service.sendToBluetooth(
        receiptBytes,
        macAddress: '66:22:33:44:55:66',
      );

      expect(result.success, false);
      expect(service.lastConnectionState, false);
    });
  });

  group('Struk kasir thermal', () {
    test('printSalesReceipt memakai nama & alamat warung dari Profil Warung', () async {
      SharedPreferences.setMockInitialValues({
        'warung_name': 'Warung Makan Berkah',
        'warung_address': 'Jl. Raya Kampus No. 12, Sleman, Yogyakarta',
      });

      await service.saveConfig(
        const ThermalPrinterConfig(
          connectionType: 'bluetooth',
          macAddress: '66:22:33:44:55:66',
          printerName: 'RPP02N Thermal',
          paperWidth: 58,
        ),
      );

      String receipt = '';
      service.bluetoothWriter = (bytes) async {
        receipt = utf8.decode(bytes, allowMalformed: true);
        return true;
      };

      final result = await service.printSalesReceipt(
        storeName: 'WARUNGKU',
        transactionId: 'TRX-100',
        dateTimeStr: '18/09/2026 10:00',
        customerName: 'Meja 1',
        cashierName: 'Kasir',
        items: sampleItems,
        subtotal: 30000,
        discountAmount: 0,
        paymentMethod: 'CASH',
      );

      expect(result.success, true);
      expect(receipt, contains('Warung Makan Berkah'));
      expect(receipt, contains('Jl. Raya Kampus No. 12,'));
      expect(receipt, contains('STRUK PEMBAYARAN'));
    });

    test('alamat warung panjang dipecah mengikuti lebar kertas 58mm', () {
      final bytes = service.generateSalesReceiptBytes(
        config: const ThermalPrinterConfig(paperWidth: 58),
        storeName: 'WARUNGKU',
        storeAddress: 'Jl. Raya Kampus No. 12, Sleman, Daerah Istimewa Yogyakarta 55281',
        transactionId: 'TRX-101',
        dateTimeStr: '18/09/2026 10:00',
        customerName: 'Meja 2',
        cashierName: 'Kasir',
        items: sampleItems,
        subtotal: 30000,
        discountAmount: 0,
        paymentMethod: 'CASH',
      );

      final text = utf8.decode(bytes, allowMalformed: true);
      // Alamat dipecah menjadi beberapa baris (tidak dicetak sebagai satu baris panjang).
      expect(text, contains('Jl. Raya Kampus No. 12, Sleman,'));
      expect(text, contains('Daerah Istimewa Yogyakarta 55281'));
      expect(
        text,
        isNot(contains('Jl. Raya Kampus No. 12, Sleman, Daerah Istimewa Yogyakarta 55281')),
      );
    });

    test('karakter non-ASCII ditransliterasi agar tidak tercetak kacau', () {
      final bytes = service.generateSalesReceiptBytes(
        config: const ThermalPrinterConfig(paperWidth: 58),
        storeName: 'Kafé "Nusantara" – 100°',
        transactionId: 'TRX-102',
        dateTimeStr: '18/09/2026 10:00',
        customerName: 'Meja 3',
        cashierName: 'Andi',
        items: sampleItems,
        subtotal: 30000,
        discountAmount: 0,
        paymentMethod: 'CASH',
      );

      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Kafe "Nusantara" - 100 deg'));
      expect(text, isNot(contains('é')));
      expect(text, isNot(contains('–')));
      expect(text, isNot(contains('°')));
    });

    test('nama pelanggan panjang dibungkus, tidak dipotong', () {
      final bytes = service.generateSalesReceiptBytes(
        config: const ThermalPrinterConfig(paperWidth: 58),
        storeName: 'WARUNGKU',
        transactionId: 'TRX-103',
        dateTimeStr: '18/09/2026 10:00',
        customerName: 'Pelanggan Sangat Panjang Sekali Namanya',
        cashierName: 'Kasir',
        items: sampleItems,
        subtotal: 30000,
        discountAmount: 0,
        paymentMethod: 'CASH',
      );

      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Pelanggan Sangat Panjang'));
      expect(text, contains('Sekali'));
      expect(text, contains('Namanya'));
    });
  });

  group('Dialog Pengaturan Printer', () {
    testWidgets('menampilkan status printer, tombol hubungkan, dan banner izin', (WidgetTester tester) async {
      permissionService.checker = () async => BluetoothPermissionStatus.denied;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PrinterSettingsDialog())),
      );
      await tester.pumpAndSettle();

      // Status ringkas satu baris
      expect(find.text('Bluetooth aktif'), findsOneWidget);
      expect(find.text('Izin belum'), findsOneWidget);
      expect(find.text('Terputus'), findsOneWidget);

      // Banner izin + tombol aksi
      expect(find.text('Izin Bluetooth diperlukan'), findsOneWidget);
      expect(find.text('Beri Izin Bluetooth'), findsOneWidget);

      // Tombol koneksi (toggle: 'Hubungkan' saat belum terhubung)
      expect(find.text('Hubungkan'), findsOneWidget);
      expect(find.text('Putuskan'), findsNothing);

      // Setelah izin diberikan (OS mengabulkan permintaan), daftar printer muncul & banner hilang
      permissionService.requester = () async => BluetoothPermissionStatus.granted;
      permissionService.checker = () async => BluetoothPermissionStatus.granted;
      await tester.tap(find.text('Beri Izin Bluetooth'));
      await tester.pumpAndSettle();

      expect(find.text('Izin Bluetooth diperlukan'), findsNothing);
      expect(find.text('RPP02N Thermal (66:22:33:44:55:66)'), findsOneWidget);
    });

    testWidgets('menampilkan status terhubung dan memutus koneksi printer', (WidgetTester tester) async {
      var disconnectCalled = false;
      service.bluetoothConnectionChecker = () async => true;
      service.bluetoothDisconnector = () async {
        disconnectCalled = true;
        return true;
      };

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PrinterSettingsDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terhubung'), findsOneWidget);

      await tester.tap(find.text('Putuskan'));
      await tester.pumpAndSettle();

      expect(disconnectCalled, true);
      expect(find.text('Koneksi printer Bluetooth diputuskan'), findsOneWidget);
    });

    testWidgets('tombol Hubungkan memanggil koneksi printer terpilih', (WidgetTester tester) async {
      String? connectedMac;
      service.bluetoothConnector = (mac) async {
        connectedMac = mac;
        return true;
      };

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PrinterSettingsDialog())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hubungkan'));
      await tester.pumpAndSettle();

      expect(connectedMac, '66:22:33:44:55:66');
      expect(find.textContaining('Terhubung ke printer Bluetooth'), findsOneWidget);
    });
  });
}
