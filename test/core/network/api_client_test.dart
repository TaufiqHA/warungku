import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/core/network/api_client.dart';
import 'package:warungku/core/network/api_endpoints.dart';
import 'package:warungku/core/network/api_exception.dart';
import 'package:warungku/core/storage/secure_storage_service.dart';

/// Fake In-Memory implementation of FlutterSecureStorage for testing
class FakeFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_store);
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store.containsKey(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake HttpClientAdapter for intercepting network calls in Dio
class FakeHttpClientAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString(
      '{"status":"success"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService secureStorageService;
  late FakeHttpClientAdapter fakeAdapter;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    secureStorageService = SecureStorageService(storage: fakeStorage);
    fakeAdapter = FakeHttpClientAdapter();
  });

  group('ApiClient Interceptor Tests', () {
    test('onRequest attaches Authorization header when JWT token is present', () async {
      await secureStorageService.saveToken('test_valid_jwt_token_123');

      RequestOptions? capturedOptions;
      fakeAdapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"message": "ok"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final dio = Dio();
      dio.httpClientAdapter = fakeAdapter;

      final apiClient = ApiClient(
        secureStorage: secureStorageService,
        customDio: dio,
      );

      final response = await apiClient.get<Map<String, dynamic>>('/test');

      expect(response.statusCode, 200);
      expect(capturedOptions, isNotNull);
      expect(
        capturedOptions!.headers['Authorization'],
        'Bearer test_valid_jwt_token_123',
      );
    });

    test('onRequest does NOT attach Authorization header when token is null or empty', () async {
      RequestOptions? capturedOptions;
      fakeAdapter.handler = (options) {
        capturedOptions = options;
        return ResponseBody.fromString(
          '{"message": "ok"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final dio = Dio();
      dio.httpClientAdapter = fakeAdapter;

      final apiClient = ApiClient(
        secureStorage: secureStorageService,
        customDio: dio,
      );

      await apiClient.get<Map<String, dynamic>>('/test');

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('onError on 401 clears secure storage and invokes onUnauthorized callback', () async {
      await secureStorageService.saveToken('expired_token_123');
      expect(await secureStorageService.getToken(), 'expired_token_123');

      bool unauthorizedCallbackTriggered = false;

      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"message": "Unauthorized / Token Expired"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final dio = Dio();
      dio.httpClientAdapter = fakeAdapter;

      final apiClient = ApiClient(
        secureStorage: secureStorageService,
        onUnauthorized: () {
          unauthorizedCallbackTriggered = true;
        },
        customDio: dio,
      );

      await expectLater(
        apiClient.get<dynamic>('/protected-resource'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );

      // Verify token cleared & callback triggered
      expect(await secureStorageService.getToken(), isNull);
      expect(unauthorizedCallbackTriggered, isTrue);
    });

    test('onError on 401 on /auth/login does NOT clear secure storage or invoke onUnauthorized', () async {
      await secureStorageService.saveToken('existing_token_123');

      bool unauthorizedCallbackTriggered = false;

      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"message": "Username atau password salah"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final dio = Dio();
      dio.httpClientAdapter = fakeAdapter;

      final apiClient = ApiClient(
        secureStorage: secureStorageService,
        onUnauthorized: () {
          unauthorizedCallbackTriggered = true;
        },
        customDio: dio,
      );

      await expectLater(
        apiClient.post<dynamic>(ApiEndpoints.login, data: {'email': 'test@example.com'}),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );

      // Verify token NOT cleared & callback NOT triggered on login failure
      expect(await secureStorageService.getToken(), 'existing_token_123');
      expect(unauthorizedCallbackTriggered, isFalse);
    });

    test('onError on non-401 error does NOT clear secure storage', () async {
      await secureStorageService.saveToken('active_token_123');

      fakeAdapter.handler = (options) {
        return ResponseBody.fromString(
          '{"message": "Internal Server Error"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final dio = Dio();
      dio.httpClientAdapter = fakeAdapter;

      final apiClient = ApiClient(
        secureStorage: secureStorageService,
        customDio: dio,
      );

      await expectLater(
        apiClient.get<dynamic>('/server-error'),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );

      // Token should remain intact
      expect(await secureStorageService.getToken(), 'active_token_123');
    });
  });

  group('ApiClient HTTP Methods Tests', () {
    late ApiClient apiClient;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      dio.httpClientAdapter = fakeAdapter;
      apiClient = ApiClient(
        secureStorage: secureStorageService,
        customDio: dio,
      );
    });

    test('get executes GET request successfully', () async {
      fakeAdapter.handler = (options) {
        expect(options.method, 'GET');
        return ResponseBody.fromString('{"data": "sample"}', 200);
      };

      final response = await apiClient.get<dynamic>('/sample');
      expect(response.statusCode, 200);
    });

    test('post executes POST request with payload successfully', () async {
      fakeAdapter.handler = (options) {
        expect(options.method, 'POST');
        expect(options.data, '{"name":"Product A"}');
        return ResponseBody.fromString('{"id": 1}', 201);
      };

      final response = await apiClient.post<dynamic>('/products', data: '{"name":"Product A"}');
      expect(response.statusCode, 201);
    });

    test('put executes PUT request successfully', () async {
      fakeAdapter.handler = (options) {
        expect(options.method, 'PUT');
        return ResponseBody.fromString('{"updated": true}', 200);
      };

      final response = await apiClient.put<dynamic>('/products/1', data: {'price': 10000});
      expect(response.statusCode, 200);
    });

    test('patch executes PATCH request successfully', () async {
      fakeAdapter.handler = (options) {
        expect(options.method, 'PATCH');
        return ResponseBody.fromString('{"patched": true}', 200);
      };

      final response = await apiClient.patch<dynamic>('/products/1', data: {'stock': 5});
      expect(response.statusCode, 200);
    });

    test('delete executes DELETE request successfully', () async {
      fakeAdapter.handler = (options) {
        expect(options.method, 'DELETE');
        return ResponseBody.fromString('{"deleted": true}', 200);
      };

      final response = await apiClient.delete<dynamic>('/products/1');
      expect(response.statusCode, 200);
    });
  });
}
