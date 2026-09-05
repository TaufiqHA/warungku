import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:warungku/core/network/api_client.dart';
import 'package:warungku/core/network/api_endpoints.dart';
import 'package:warungku/core/storage/secure_storage_service.dart';
import 'package:warungku/core/storage/sync_queue_service.dart';

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
    if (value != null) _store[key] = value;
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
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  late Directory tempDir;
  late Box unsyncedBox;
  late FakeHttpClientAdapter fakeAdapter;
  late ApiClient apiClient;
  late SyncQueueService syncQueueService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('sync_queue_test_');
    Hive.init(tempDir.path);
    unsyncedBox = await Hive.openBox('unsynced_test_box');

    fakeAdapter = FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    dio.httpClientAdapter = fakeAdapter;

    apiClient = ApiClient(
      secureStorage: SecureStorageService(storage: FakeFlutterSecureStorage()),
      customDio: dio,
    );

    syncQueueService = SyncQueueService(
      apiClient: apiClient,
      unsyncedBox: unsyncedBox,
    );
  });

  tearDown(() async {
    await unsyncedBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SyncQueueService Tests', () {
    test('addToQueue and pendingCount work correctly', () async {
      expect(syncQueueService.pendingCount, 0);

      await syncQueueService.addToQueue('tx_001', {'total': 50000});
      await syncQueueService.addToQueue('tx_002', {'total': 75000});

      expect(syncQueueService.pendingCount, 2);
    });

    test('processQueue successfully syncs all transactions when server responds 200/201', () async {
      await syncQueueService.addToQueue('tx_001', {'total': 50000});
      await syncQueueService.addToQueue('tx_002', {'total': 75000});

      final postedPayloads = <dynamic>[];
      fakeAdapter.handler = (options) {
        postedPayloads.add(options.data);
        return ResponseBody.fromString('{"success": true}', 201);
      };

      final syncedCount = await syncQueueService.processQueue();

      expect(syncedCount, 2);
      expect(syncQueueService.pendingCount, 0);
      expect(postedPayloads.length, 2);
    });

    test('processQueue stops on network error and preserves remaining transactions', () async {
      await syncQueueService.addToQueue('tx_001', {'total': 50000});
      await syncQueueService.addToQueue('tx_002', {'total': 75000});

      int requestCount = 0;
      fakeAdapter.handler = (options) {
        requestCount++;
        if (requestCount == 1) {
          return ResponseBody.fromString('{"success": true}', 200);
        } else {
          return ResponseBody.fromString('{"error": "Network Unavailable"}', 503);
        }
      };

      final syncedCount = await syncQueueService.processQueue();

      expect(syncedCount, 1);
      expect(syncQueueService.pendingCount, 1);
      expect(unsyncedBox.containsKey('tx_002'), isTrue);
    });
  });
}
