import 'package:hive_flutter/hive_flutter.dart';
import '../../app/config/app_constants.dart';

/// Service untuk inisialisasi dan akses Hive Local Storage Box
class LocalStorageService {
  LocalStorageService._();

  /// Inisialisasi Hive dan membuka semua box utama
  static Future<void> init([String? subDir]) async {
    if (subDir != null) {
      Hive.init(subDir);
    } else {
      await Hive.initFlutter();
    }

    final boxesToOpen = [
      AppConstants.boxProducts,
      AppConstants.boxTransactions,
      AppConstants.boxExpenses,
      AppConstants.boxUnsyncedTransactions,
      AppConstants.boxAppSettings,
    ];

    for (final boxName in boxesToOpen) {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
    }
  }

  /// Getter untuk Box Katalog Produk
  static Box get productsBox => Hive.box(AppConstants.boxProducts);

  /// Getter untuk Box Transaksi POS & Penjualan
  static Box get transactionsBox => Hive.box(AppConstants.boxTransactions);

  /// Getter untuk Box Pengeluaran / Biaya Operasional
  static Box get expensesBox => Hive.box(AppConstants.boxExpenses);

  /// Getter untuk Antrean Transaksi Offline (Unsynced)
  static Box get unsyncedBox => Hive.box(AppConstants.boxUnsyncedTransactions);

  /// Getter untuk Box Pengaturan Aplikasi / Printer
  static Box get settingsBox => Hive.box(AppConstants.boxAppSettings);

  /// Membersihkan data cache lokal (misal saat logout)
  static Future<void> clearCache({bool preserveSettings = true}) async {
    if (Hive.isBoxOpen(AppConstants.boxProducts)) {
      await productsBox.clear();
    }
    if (Hive.isBoxOpen(AppConstants.boxTransactions)) {
      await transactionsBox.clear();
    }
    if (Hive.isBoxOpen(AppConstants.boxExpenses)) {
      await expensesBox.clear();
    }
    if (Hive.isBoxOpen(AppConstants.boxUnsyncedTransactions)) {
      await unsyncedBox.clear();
    }
    if (!preserveSettings && Hive.isBoxOpen(AppConstants.boxAppSettings)) {
      await settingsBox.clear();
    }
  }

  /// Menutup seluruh Hive box
  static Future<void> close() async {
    await Hive.close();
  }
}
