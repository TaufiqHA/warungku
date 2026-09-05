/// Daftar endpoint REST API WarungKu
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.warung.com/v1';

  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Products
  static const String products = '/products';
  static const String categories = '/categories';

  // Transactions & POS
  static const String transactions = '/transactions';
  static const String activeOrders = '/transactions/active';

  // Expenses
  static const String expenses = '/expenses';

  // Reports
  static const String profitLossReport = '/reports/profit-loss';
  static const String salesChart = '/reports/sales-chart';
  static const String bestSellers = '/reports/best-sellers';

  // Store & Settings
  static const String storeSettings = '/settings/store';
  static const String users = '/users';
}
