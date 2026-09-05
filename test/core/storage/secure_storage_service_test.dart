import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/core/storage/secure_storage_service.dart';

/// Fake In-Memory FlutterSecureStorage
class FakeFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

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
      _data[key] = value;
    } else {
      _data.remove(key);
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
    return _data[key];
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
    _data.remove(key);
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
    _data.clear();
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
    return Map.from(_data);
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
    return _data.containsKey(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late SecureStorageService secureStorage;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    secureStorage = SecureStorageService(storage: fakeStorage);
  });

  group('SecureStorageService Tests', () {
    test('saveToken, getToken, hasToken, and deleteToken work properly', () async {
      expect(await secureStorage.hasToken(), isFalse);
      expect(await secureStorage.getToken(), isNull);

      await secureStorage.saveToken('sample_jwt_12345');
      expect(await secureStorage.hasToken(), isTrue);
      expect(await secureStorage.getToken(), 'sample_jwt_12345');

      await secureStorage.deleteToken();
      expect(await secureStorage.hasToken(), isFalse);
      expect(await secureStorage.getToken(), isNull);
    });

    test('saveRefreshToken, getRefreshToken, and deleteRefreshToken work properly', () async {
      expect(await secureStorage.getRefreshToken(), isNull);

      await secureStorage.saveRefreshToken('sample_refresh_token_67890');
      expect(await secureStorage.getRefreshToken(), 'sample_refresh_token_67890');

      await secureStorage.deleteRefreshToken();
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('saveUserData, getUserData, and deleteUserData work properly', () async {
      expect(await secureStorage.getUserData(), isNull);

      const userJson = '{"id":"1","nama":"Kasir Warung","role":"ADMIN_TOKO"}';
      await secureStorage.saveUserData(userJson);
      expect(await secureStorage.getUserData(), userJson);

      await secureStorage.deleteUserData();
      expect(await secureStorage.getUserData(), isNull);
    });

    test('clearAll clears all keys from secure storage', () async {
      await secureStorage.saveToken('jwt_token_sample');
      await secureStorage.saveRefreshToken('refresh_token_sample');
      await secureStorage.saveUserData('{"user":"data"}');

      expect(await secureStorage.hasToken(), isTrue);
      expect(await secureStorage.getRefreshToken(), isNotNull);
      expect(await secureStorage.getUserData(), isNotNull);

      await secureStorage.clearAll();

      expect(await secureStorage.hasToken(), isFalse);
      expect(await secureStorage.getRefreshToken(), isNull);
      expect(await secureStorage.getUserData(), isNull);
    });
  });
}
