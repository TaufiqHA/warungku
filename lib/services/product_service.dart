import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/product_model.dart';
import 'cache_entry.dart';
import 'token_manager.dart';

class ProductService {
  final http.Client _client;

  static CacheEntry<List<ProductModel>>? _cache;
  static const Duration defaultCacheTtl = Duration(seconds: 60);

  static void clearCache() {
    _cache = null;
  }

  ProductService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ProductModel>> getProducts({
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
        Uri.parse(ApiConstants.productsEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        final result = list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
        _cache = CacheEntry(result);
        return result;
      } else {
        throw Exception('Gagal memuat produk (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses data produk.');
    }
  }

  Future<ProductModel> addProduct({
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.productsEndpoint),
        headers: headers,
        body: jsonEncode({
          'name': name.trim(),
          'price': price,
          'category': category.trim(),
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        clearCache();
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return ProductModel.fromJson(data);
      } else {
        throw Exception(body['message'] ?? 'Gagal menambah produk');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menambah produk.');
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    required String category,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.put(
        Uri.parse('${ApiConstants.productsEndpoint}/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name.trim(),
          'price': price,
          'category': category.trim(),
        }),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal mengubah produk');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengubah produk.');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.productsEndpoint}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menghapus produk');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghapus produk.');
    }
  }

  Future<void> addCategory({required String name}) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.categoriesEndpoint),
        headers: headers,
        body: jsonEncode({'name': name.trim()}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(body['message'] ?? 'Gagal menambahkan kategori');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menambahkan kategori.');
    }
  }
}
