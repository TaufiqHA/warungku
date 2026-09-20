import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../data/models/auth_model.dart';
import 'expense_service.dart';
import 'product_service.dart';
import 'token_manager.dart';
import 'transaction_service.dart';
import 'user_service.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.loginEndpoint);
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = LoginResponse.fromJson(body);

      if (response.statusCode == 200 && result.success && result.token != null && result.user != null) {
        await TokenManager.saveSession(
          token: result.token!,
          user: result.user!,
        );
        return result;
      } else {
        final message = result.message.isNotEmpty
            ? result.message
            : 'Email atau kata sandi salah';
        throw Exception(message);
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet.');
    } on TimeoutException {
      throw Exception('Koneksi waktu habis. Silakan coba lagi.');
    } on FormatException {
      throw Exception('Respon server tidak valid.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan tidak terduga.');
    }
  }

  Future<void> logout() async {
    try {
      final token = await TokenManager.getToken();
      if (token != null && token.isNotEmpty) {
        await _client.post(
          Uri.parse(ApiConstants.logoutEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Abaikan kegagalan jaringan saat logout agar sesi tetap dibersihkan
    } finally {
      TransactionService.clearCache();
      ProductService.clearCache();
      ExpenseService.clearCache();
      UserService.clearCache();
      await TokenManager.clearSession();
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _client.get(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final user = UserModel.fromJson(data);
          final currentToken = await TokenManager.getToken() ?? '';
          await TokenManager.saveSession(token: currentToken, user: user);
          return user;
        }
      }
    } catch (_) {}
    return await TokenManager.getUser();
  }

  Future<void> updateProfile({required String name}) async {
    try {
      final token = await TokenManager.getToken();
      final response = await _client.put(
        Uri.parse(ApiConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name.trim()}),
      );

      if (response.statusCode == 200) {
        final currentUser = await TokenManager.getUser();
        if (currentUser != null) {
          final updated = UserModel(
            id: currentUser.id,
            name: name.trim(),
            username: currentUser.username,
            email: currentUser.email,
            role: currentUser.role,
          );
          final currentToken = await TokenManager.getToken() ?? '';
          await TokenManager.saveSession(token: currentToken, user: updated);
        }
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal memperbarui profil');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memperbarui profil.');
    }
  }

  Future<void> updateWarungSettings({
    required String name,
    required String address,
    required String email,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final response = await _client.put(
        Uri.parse(ApiConstants.settingsWarungEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name.trim(),
          'address': address.trim(),
          'email': email.trim(),
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('warung_name', name.trim());
      await prefs.setString('warung_address', address.trim());
      await prefs.setString('warung_email', email.trim());

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menyimpan pengaturan warung');
      }
    } on SocketException {
      // Simpan lokal jika offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('warung_name', name.trim());
      await prefs.setString('warung_address', address.trim());
      await prefs.setString('warung_email', email.trim());
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menyimpan profil warung.');
    }
  }

  Future<Map<String, String>> getWarungSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('warung_name') ?? 'WARUNGKU',
      'address': prefs.getString('warung_address') ?? 'Jl. Raya Utama No. 1',
      'email': prefs.getString('warung_email') ?? 'info@warungku.com',
    };
  }
}
