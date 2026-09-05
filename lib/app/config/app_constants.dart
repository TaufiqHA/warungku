/// Konstanta umum aplikasi WarungKu
class AppConstants {
  AppConstants._();

  static const String appName = 'WarungKu';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyPrinterAddress = 'printer_address';
  static const String keyPrinterName = 'printer_name';
  static const String keyPrinterType = 'printer_type'; // bluetooth / network
  static const String keyPrinterIp = 'printer_ip';
  static const String keyPrinterPort = 'printer_port';

  // Hive Box Names
  static const String boxProducts = 'products_box';
  static const String boxTransactions = 'transactions_box';
  static const String boxExpenses = 'expenses_box';
  static const String boxUnsyncedTransactions = 'unsynced_transactions';
  static const String boxAppSettings = 'app_settings';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
