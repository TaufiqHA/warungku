import 'package:dio/dio.dart';

/// Exception handler terstruktur untuk HTTP & API error
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Koneksi ke server timeout. Silakan periksa jaringan internet Anda.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Terjadi kesalahan pada server ($statusCode)';
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
          data: responseData,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Permintaan dibatalkan.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'Tidak ada koneksi internet. Silakan cek koneksi Anda.');
      default:
        return ApiException(message: 'Terjadi kesalahan tidak terduga: ${error.message}');
    }
  }

  @override
  String toString() => message;
}
