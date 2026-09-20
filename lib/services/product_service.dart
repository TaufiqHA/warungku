import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> saveCategoriesLayout(List<Map<String, dynamic>> categories) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.categoriesLayoutEndpoint),
        headers: headers,
        body: jsonEncode({'categories': categories}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Gagal menyimpan urutan kategori');
        } catch (e) {
          if (e is Exception && e.toString().contains('Gagal menyimpan')) rethrow;
          throw Exception('Gagal menyimpan urutan kategori (${response.statusCode})');
        }
      }
    } on SocketException {
      // Offline-first resilience
    } on TimeoutException {
      // Timeout resilience
    } catch (e) {
      if (e is Exception && !e.toString().contains('Gagal menyimpan')) {
        // Network/parse issue
      } else {
        rethrow;
      }
    }
  }

  Future<void> saveProductsLayout(List<Map<String, dynamic>> products) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.productsLayoutEndpoint),
        headers: headers,
        body: jsonEncode({'products': products}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Gagal menyimpan urutan produk');
        } catch (e) {
          if (e is Exception && e.toString().contains('Gagal menyimpan')) rethrow;
          throw Exception('Gagal menyimpan urutan produk (${response.statusCode})');
        }
      }
    } on SocketException {
      // Offline-first resilience
    } on TimeoutException {
      // Timeout resilience
    } catch (e) {
      if (e is Exception && !e.toString().contains('Gagal menyimpan')) {
        // Network/parse issue
      } else {
        rethrow;
      }
    }
  }

  static const String _layoutPrefsKey = 'menu_pdf_layout_config';

  Future<Map<String, dynamic>> loadLocalLayoutConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_layoutPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  Future<void> saveLocalLayoutConfig({
    required List<String> categoryOrder,
    required Map<String, String> categoryNames,
    required Map<String, List<String>> productOrderPerCategory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'categoryOrder': categoryOrder,
      'categoryNames': categoryNames,
      'productOrderPerCategory': productOrderPerCategory,
    };
    await prefs.setString(_layoutPrefsKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> exportProducts({
    String? search,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = <String, String>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
      };

      final uri = Uri.parse(ApiConstants.productsExportEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json') || response.body.trim().startsWith('{')) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          final downloadUrl = body['download_url'] ?? body['data']?['download_url'];
          return {
            'success': body['success'] ?? true,
            'message': body['message'] ?? 'Export data berhasil disiapkan',
            if (downloadUrl != null) 'download_url': downloadUrl.toString(),
          };
        } else {
          return {
            'success': true,
            'message': 'File Excel berhasil diunduh',
            'bytes': response.bodyBytes,
          };
        }
      } else {
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Gagal mengekspor data produk (${response.statusCode})');
        } catch (e) {
          if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
          throw Exception('Gagal mengekspor data produk (${response.statusCode})');
        }
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses ekspor produk.');
    }
  }

  Future<Uint8List> downloadExportFile(String downloadUrl) async {
    try {
      final headers = await _authHeaders();
      String url = downloadUrl;
      if (!url.startsWith('http')) {
        url = '${ApiConstants.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
      } else {
        final parsedUri = Uri.parse(url);
        if (parsedUri.host == 'localhost' || parsedUri.host == '127.0.0.1') {
          final baseUri = Uri.parse(ApiConstants.baseUrl);
          url = parsedUri.replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      }

      final response = await _client.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Gagal mengunduh file Excel (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server saat mengunduh berkas.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengunduh file Excel.');
    }
  }

  static String getExportFileExtension(String? downloadUrl, [String? contentType]) {
    if (downloadUrl != null) {
      final cleanUrl = downloadUrl.split('?').first.toLowerCase();
      if (cleanUrl.endsWith('.csv')) return 'csv';
      if (cleanUrl.endsWith('.xlsx')) return 'xlsx';
      if (cleanUrl.endsWith('.xls')) return 'xls';
    }
    if (contentType != null) {
      final ct = contentType.toLowerCase();
      if (ct.contains('csv')) return 'csv';
      if (ct.contains('spreadsheet') || ct.contains('excel')) return 'xlsx';
    }
    return 'xlsx';
  }
}
