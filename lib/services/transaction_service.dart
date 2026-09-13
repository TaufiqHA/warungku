import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/transaction_model.dart';
import 'cache_entry.dart';
import 'token_manager.dart';

class TransactionService {
  final http.Client _client;

  static final Map<String, CacheEntry<List<TransactionModel>>> _cache = {};
  static const Duration defaultCacheTtl = Duration(seconds: 60);

  static void clearCache() {
    _cache.clear();
  }

  TransactionService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<TransactionModel>> getTransactions({
    String? filter,
    bool forceRefresh = false,
    Duration? cacheTtl,
  }) async {
    final cacheKey = filter ?? 'all';
    final ttl = cacheTtl ?? defaultCacheTtl;
    if (!forceRefresh && _cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid(ttl)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final headers = await _authHeaders();
      String url = ApiConstants.transactionsEndpoint;
      if (filter != null && filter.isNotEmpty && filter != 'Semua') {
        url += '?filter=${Uri.encodeComponent(filter)}';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        final result = list.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
        _cache[cacheKey] = CacheEntry(result);
        return result;
      } else {
        throw Exception('Gagal memuat transaksi (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses data transaksi.');
    }
  }

  String _normalizePaymentMethod(String method) {
    final upper = method.trim().toUpperCase();
    if (upper == 'TUNAI' || upper == 'CASH') return 'CASH';
    if (upper == 'TRANSFER') return 'TRANSFER';
    if (upper == 'QRIS') return 'QRIS';
    return 'CASH';
  }

  String _parseErrorMessage(Map<String, dynamic> body, String defaultMessage) {
    String message = body['message'] as String? ?? defaultMessage;
    if (body['errors'] != null && body['errors'] is Map) {
      final errorsMap = body['errors'] as Map;
      final details = <String>[];
      errorsMap.forEach((_, val) {
        if (val is List) {
          details.addAll(val.map((e) => e.toString()));
        } else if (val != null) {
          details.add(val.toString());
        }
      });
      if (details.isNotEmpty) {
        message = '$message: ${details.join(', ')}';
      }
    }
    return message;
  }

  Future<void> createTransaction({
    required String namaItem,
    required int jumlah,
    required double harga,
    required String paymentMethod,
    required String customerName,
    String catatan = '',
  }) async {
    try {
      final headers = await _authHeaders();
      final user = await TokenManager.getUser();
      final now = DateTime.now();
      final trxId = 'TRX-${now.millisecondsSinceEpoch}';
      final normalizedPayment = _normalizePaymentMethod(paymentMethod);

      final payload = {
        'idTransaksi': trxId,
        'namaItem': namaItem,
        'jumlah': jumlah,
        'harga': harga,
        'waktu': now.toIso8601String(),
        'dicatatOleh': user?.name ?? 'Admin Toko',
        'catatan': catatan,
        'payment_method': normalizedPayment,
        'orderStatus': 'COMPLETED',
        'customerName': customerName.isEmpty ? '-' : customerName,
        'customer_name': customerName.isEmpty ? '-' : customerName,
        'items': [
          {
            'namaItem': namaItem,
            'jumlah': jumlah,
            'quantity': jumlah,
            'harga': harga,
            'unit_price': harga,
            'subtotal': harga * jumlah,
            'catatan': catatan,
            'servedQty': 0,
          }
        ],
      };

      final response = await _client.post(
        Uri.parse(ApiConstants.transactionsEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(_parseErrorMessage(body, 'Gagal menyimpan transaksi'));
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menyimpan transaksi.');
    }
  }

  Future<String> createOrder({
    required String customerName,
    required List<CartItemModel> items,
    String paymentMethod = 'CASH',
    String orderStatus = 'PENDING',
    String catatan = '',
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang belanja tidak boleh kosong.');
    }

    try {
      final headers = await _authHeaders();
      final user = await TokenManager.getUser();
      final now = DateTime.now();
      final trxId = 'TRX-${now.millisecondsSinceEpoch}';
      final normalizedPayment = _normalizePaymentMethod(paymentMethod);

      final totalQty = items.fold<int>(0, (sum, item) => sum + item.quantity);
      final totalPrice = items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
      final itemSummary = items.map((e) => '${e.product.name} (x${e.quantity})').join(', ');

      final payload = {
        'idTransaksi': trxId,
        'waktu': now.toIso8601String(),
        'dicatatOleh': user?.name ?? 'Admin Toko',
        'payment_method': normalizedPayment,
        'customerName': customerName.isEmpty ? '-' : customerName,
        'customer_name': customerName.isEmpty ? '-' : customerName,
        'orderStatus': orderStatus,
        'status': orderStatus,
        'catatan': catatan,
        'items': items.map((e) => e.toJson()).toList(),
        // Backward-compatible fields
        'namaItem': itemSummary,
        'jumlah': totalQty,
        'harga': totalPrice,
      };

      final response = await _client.post(
        Uri.parse(ApiConstants.transactionsEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(_parseErrorMessage(body, 'Gagal memproses pesanan'));
      }

      clearCache();
      return trxId;
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses pesanan.');
    }
  }

  Future<void> cancelTransaction(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.patch(
        Uri.parse('${ApiConstants.transactionsEndpoint}/$id/cancel'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal membatalkan transaksi');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal membatalkan transaksi.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.transactionsEndpoint}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menghapus transaksi');
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghapus transaksi.');
    }
  }

  Future<void> updateServedQty(String transactionId, String productId, int servedQty) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.patch(
        Uri.parse('${ApiConstants.transactionsEndpoint}/$transactionId/items/$productId/served'),
        headers: headers,
        body: jsonEncode({'served_qty': servedQty}),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(_parseErrorMessage(body, 'Gagal memperbarui kuantitas tersaji'));
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memperbarui kuantitas tersaji.');
    }
  }

  Future<void> addTransactionItem(
    String transactionId, {
    required String productId,
    required int quantity,
    required double unitPrice,
    required double subtotal,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _client.post(
        Uri.parse('${ApiConstants.transactionsEndpoint}/$transactionId/items'),
        headers: headers,
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'subtotal': subtotal,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(_parseErrorMessage(body, 'Gagal menambahkan menu'));
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menambahkan menu.');
    }
  }

  Future<void> completeTransaction(
    String transactionId, {
    required String paymentMethod,
    double discountAmount = 0,
  }) async {
    try {
      final headers = await _authHeaders();
      final normalized = _normalizePaymentMethod(paymentMethod);
      final response = await _client.patch(
        Uri.parse('${ApiConstants.transactionsEndpoint}/$transactionId/status'),
        headers: headers,
        body: jsonEncode({
          'status': 'COMPLETED',
          'payment_method': normalized,
          'discount_amount': discountAmount.toInt(),
        }),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(_parseErrorMessage(body, 'Gagal menyelesaikan transaksi'));
      }
      clearCache();
    } on SocketException {
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menyelesaikan transaksi.');
    }
  }
}

