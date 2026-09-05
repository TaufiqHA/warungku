import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/core/storage/local_storage_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    await LocalStorageService.init(tempDir.path);
  });

  tearDown(() async {
    await LocalStorageService.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalStorageService Hive Boxes Tests', () {
    test('all 5 Hive boxes are initialized and open', () {
      expect(LocalStorageService.productsBox.isOpen, isTrue);
      expect(LocalStorageService.transactionsBox.isOpen, isTrue);
      expect(LocalStorageService.expensesBox.isOpen, isTrue);
      expect(LocalStorageService.unsyncedBox.isOpen, isTrue);
      expect(LocalStorageService.settingsBox.isOpen, isTrue);
    });

    test('productsBox read, write, and delete operations work', () async {
      final box = LocalStorageService.productsBox;
      await box.put('prod_1', {'name': 'Nasi Goreng', 'price': 15000});

      expect(box.get('prod_1'), {'name': 'Nasi Goreng', 'price': 15000});
      expect(box.length, 1);

      await box.delete('prod_1');
      expect(box.get('prod_1'), isNull);
      expect(box.isEmpty, isTrue);
    });

    test('transactionsBox read, write, and delete operations work', () async {
      final box = LocalStorageService.transactionsBox;
      await box.put('trx_1001', {'total': 30000, 'items': 2});

      expect(box.get('trx_1001'), {'total': 30000, 'items': 2});
      expect(box.length, 1);
    });

    test('expensesBox read, write, and delete operations work', () async {
      final box = LocalStorageService.expensesBox;
      await box.put('exp_501', {'category': 'Bahan Baku', 'amount': 75000});

      expect(box.get('exp_501'), {'category': 'Bahan Baku', 'amount': 75000});
      expect(box.length, 1);
    });

    test('unsyncedBox read, write, and delete operations work', () async {
      final box = LocalStorageService.unsyncedBox;
      await box.put('unsynced_1', {'trxId': 'offline_1', 'amount': 25000});

      expect(box.get('unsynced_1'), {'trxId': 'offline_1', 'amount': 25000});
      expect(box.length, 1);
    });

    test('settingsBox stores printer and app preferences', () async {
      final box = LocalStorageService.settingsBox;
      await box.put('printer_mac', '00:11:22:33:44:55');
      await box.put('auto_print', true);

      expect(box.get('printer_mac'), '00:11:22:33:44:55');
      expect(box.get('auto_print'), isTrue);
    });

    test('clearCache clears data boxes and optionally preserves settingsBox', () async {
      await LocalStorageService.productsBox.put('p1', 'Product 1');
      await LocalStorageService.transactionsBox.put('t1', 'Trx 1');
      await LocalStorageService.expensesBox.put('e1', 'Exp 1');
      await LocalStorageService.unsyncedBox.put('u1', 'Unsynced 1');
      await LocalStorageService.settingsBox.put('theme', 'dark');

      // Clear cache preserving settings
      await LocalStorageService.clearCache(preserveSettings: true);

      expect(LocalStorageService.productsBox.isEmpty, isTrue);
      expect(LocalStorageService.transactionsBox.isEmpty, isTrue);
      expect(LocalStorageService.expensesBox.isEmpty, isTrue);
      expect(LocalStorageService.unsyncedBox.isEmpty, isTrue);
      expect(LocalStorageService.settingsBox.get('theme'), 'dark');

      // Clear cache including settings
      await LocalStorageService.clearCache(preserveSettings: false);
      expect(LocalStorageService.settingsBox.isEmpty, isTrue);
    });
  });
}
