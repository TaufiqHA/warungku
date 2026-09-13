import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/expense_model.dart';
import 'cache_entry.dart';
import 'token_manager.dart';

class ExpenseService {
  final http.Client _client;

  static final Map<String, CacheEntry<List<ExpenseModel>>> _cache = {};
  static const Duration defaultCacheTtl = Duration(seconds: 60);

  static void clearCache() {
    _cache.clear();
  }

  ExpenseService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ExpenseModel>> getExpenses({
    String? filter,
    String? startDate,
    String? endDate,
    bool forceRefresh = false,
    Duration? cacheTtl,
  }) async {
    final cacheKey = '${filter ?? ''}_${startDate ?? ''}_${endDate ?? ''}';
    final ttl = cacheTtl ?? defaultCacheTtl;
    if (!forceRefresh && _cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(ttl)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final queryParams = <String, String>{};
      if (filter != null && filter.isNotEmpty) queryParams['filter'] = filter;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

      final uri = Uri.parse(ApiConstants.expensesEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final headers = await _authHeaders();
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        final result = list.map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>)).toList();
        _cache[cacheKey] = CacheEntry(result);
        return result;
      } else {
        throw Exception('Gagal memuat pengeluaran (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses data pengeluaran.');
    }
  }

  Future<ExpenseModel> addExpense({
    required String kategori,
    required String keterangan,
    required double jumlah,
    required String tanggal,
    required String pembuat,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse(ApiConstants.expensesEndpoint),
        headers: headers,
        body: jsonEncode({
          'kategori': kategori.trim(),
          'keterangan': keterangan.trim(),
          'jumlah': jumlah,
          'tanggal': tanggal.trim(),
          'pembuat': pembuat.trim(),
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        clearCache();
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return ExpenseModel.fromJson(data);
      } else {
        throw Exception(body['message'] ?? 'Gagal menambah pengeluaran');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menambah pengeluaran.');
    }
  }

  Future<void> updateExpense({
    required String id,
    required String kategori,
    required String keterangan,
    required double jumlah,
    required String tanggal,
    required String pembuat,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.put(
        Uri.parse('${ApiConstants.expensesEndpoint}/$id'),
        headers: headers,
        body: jsonEncode({
          'kategori': kategori.trim(),
          'keterangan': keterangan.trim(),
          'jumlah': jumlah,
          'tanggal': tanggal.trim(),
          'pembuat': pembuat.trim(),
        }),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal mengubah pengeluaran');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengubah pengeluaran.');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.expensesEndpoint}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menghapus pengeluaran');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghapus pengeluaran.');
    }
  }
}
