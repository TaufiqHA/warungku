import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../app/config/app_constants.dart';

/// Service untuk menyimpan token dan data kredensial sensitif terenkripsi
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyJwtToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyJwtToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.keyJwtToken);
  }

  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: AppConstants.keyUserData, value: userJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.keyUserData);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
