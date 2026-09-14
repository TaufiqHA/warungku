class ApiConstants {
  //static const String baseUrl = 'http://103.30.146.68';
  static const String baseUrl = 'http://192.168.1.199:8001';
  static const String loginEndpoint = '$baseUrl/api/v1/auth/login';
  static const String logoutEndpoint = '$baseUrl/api/v1/auth/logout';
  static const String profileEndpoint = '$baseUrl/api/v1/users/me';
  static const String productsEndpoint = '$baseUrl/api/v1/products';
  static const String categoriesEndpoint = '$baseUrl/api/v1/categories';
  static const String transactionsEndpoint = '$baseUrl/api/v1/transactions';
  static const String expensesEndpoint = '$baseUrl/api/v1/expenses';
  static const String usersEndpoint = '$baseUrl/api/v1/users';
  static const String settingsWarungEndpoint =
      '$baseUrl/api/v1/settings/warung';
  static const String categoriesLayoutEndpoint =
      '$baseUrl/api/v1/categories/layout';
  static const String productsLayoutEndpoint =
      '$baseUrl/api/v1/products/layout';
  static const String productsExportEndpoint =
      '$baseUrl/api/v1/products/export';
}
