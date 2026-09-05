import 'dart:convert';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> logout();
  Future<UserModel?> getSavedUser();
  Future<String?> getSavedToken();
  Future<bool> hasActiveSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await remoteDataSource.login(request);
    await secureStorage.saveToken(response.token);
    if (response.refreshToken != null) {
      await secureStorage.saveRefreshToken(response.refreshToken!);
    }
    await secureStorage.saveUserData(jsonEncode(response.user.toJson()));
    return response;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await secureStorage.clearAll();
    await LocalStorageService.clearCache(preserveSettings: true);
  }

  @override
  Future<UserModel?> getSavedUser() async {
    final userJson = await secureStorage.getUserData();
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getSavedToken() async {
    return await secureStorage.getToken();
  }

  @override
  Future<bool> hasActiveSession() async {
    final token = await secureStorage.getToken();
    final user = await getSavedUser();
    return token != null && token.isNotEmpty && user != null;
  }
}
