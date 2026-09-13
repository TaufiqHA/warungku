class ApiConstants {
  //static const String baseUrl = 'http://103.30.146.68';
  static const String baseUrl = 'http://10.107.29.207:8001';
  static const String loginEndpoint = '$baseUrl/api/v1/auth/login';
  static const String logoutEndpoint = '$baseUrl/api/v1/auth/logout';
  static const String profileEndpoint = '$baseUrl/api/v1/users/me';
  static const String productsEndpoint = '$baseUrl/api/v1/products';
  static const String categoriesEndpoint = '$baseUrl/api/v1/categories';
  static const String transactionsEndpoint = '$baseUrl/api/v1/transactions';
  static const String expensesEndpoint = '$baseUrl/api/v1/expenses';
  static const String usersEndpoint = '$baseUrl/api/v1/users';
  static const String settingsWarungEndpoint = '$baseUrl/api/v1/settings/warung';
}
