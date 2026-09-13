import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/auth_model.dart';
import 'cache_entry.dart';
import 'token_manager.dart';

class UserService {
  final http.Client _client;

  static CacheEntry<List<UserModel>>? _cache;
  static const Duration defaultCacheTtl = Duration(seconds: 60);

  static void clearCache() {
    _cache = null;
  }

  UserService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserModel>> getUsers({
    bool forceRefresh = false,
    Duration? cacheTtl,
  }) async {
    final ttl = cacheTtl ?? defaultCacheTtl;
    if (!forceRefresh && _cache != null && _cache!.isValid(ttl)) {
      return _cache!.data;
    }

    try {
      final headers = await _authHeaders();
      final response = await _client.get(
        Uri.parse(ApiConstants.usersEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        final result = list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
        _cache = CacheEntry(result);
        return result;
      } else {
        throw Exception('Gagal memuat pengguna (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses data pengguna.');
    }
  }

  Future<UserModel> updateUser(
    String id, {
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final headers = await _authHeaders();
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
      };
      if (password != null && password.trim().isNotEmpty) {
        payload['password'] = password.trim();
      }

      final response = await _client.put(
        Uri.parse('${ApiConstants.usersEndpoint}/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        clearCache();
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return UserModel.fromJson(data);
      } else {
        throw Exception(body['message'] ?? 'Gagal memperbarui pengguna');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memperbarui data pengguna.');
    }
  }
}
