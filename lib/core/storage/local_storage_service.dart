import 'package:hive_flutter/hive_flutter.dart';
import '../../app/config/app_constants.dart';

/// Service untuk inisialisasi dan akses Hive Local Storage Box
class LocalStorageService {
  LocalStorageService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.boxProducts),
      Hive.openBox(AppConstants.boxTransactions),
      Hive.openBox(AppConstants.boxExpenses),
      Hive.openBox(AppConstants.boxUnsyncedTransactions),
      Hive.openBox(AppConstants.boxAppSettings),
    ]);
  }

  static Box get productsBox => Hive.box(AppConstants.boxProducts);
  static Box get transactionsBox => Hive.box(AppConstants.boxTransactions);
  static Box get expensesBox => Hive.box(AppConstants.boxExpenses);
  static Box get unsyncedBox => Hive.box(AppConstants.boxUnsyncedTransactions);
  static Box get settingsBox => Hive.box(AppConstants.boxAppSettings);
}
