import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data ?? {});
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post<Map<String, dynamic>>('/auth/logout');
    } catch (_) {
      // Abaikan error jaringan saat logout remote
    }
  }
}
