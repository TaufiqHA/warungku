import 'package:dio/dio.dart';
import '../../app/config/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Base HTTP Client berbasis Dio dengan Auth Interceptor & Error Handling
class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  ApiClient({
    required this.secureStorage,
    Dio? customDio,
  }) : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Sesi kedaluwarsa, hapus token
            await secureStorage.clearAll();
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Helper GET Request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Helper POST Request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Helper PUT Request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Helper DELETE Request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
