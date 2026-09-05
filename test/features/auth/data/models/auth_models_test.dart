import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/features/auth/data/models/models.dart';

void main() {
  group('UserRole Enum Tests', () {
    test('fromString parses various role string formats correctly', () {
      expect(UserRole.fromString('OWNER'), UserRole.owner);
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('ADMIN_TOKO'), UserRole.adminToko);
      expect(UserRole.fromString('admin toko'), UserRole.adminToko);
      expect(UserRole.fromString('ADMIN_KANTOR'), UserRole.adminKantor);
      expect(UserRole.fromString('admin kantor'), UserRole.adminKantor);
      expect(UserRole.fromString('UNKNOWN_ROLE'), UserRole.adminToko);
      expect(UserRole.fromString(null), UserRole.adminToko);
    });

    test('toJsonValue returns expected backend string', () {
      expect(UserRole.owner.toJsonValue(), 'OWNER');
      expect(UserRole.adminToko.toJsonValue(), 'ADMIN_TOKO');
      expect(UserRole.adminKantor.toJsonValue(), 'ADMIN_KANTOR');
    });

    test('role boolean getters return correct flags', () {
      expect(UserRole.owner.isOwner, isTrue);
      expect(UserRole.owner.isAdminToko, isFalse);
      expect(UserRole.owner.isAdminKantor, isFalse);

      expect(UserRole.adminToko.isAdminToko, isTrue);
      expect(UserRole.adminToko.isOwner, isFalse);

      expect(UserRole.adminKantor.isAdminKantor, isTrue);
      expect(UserRole.adminKantor.isOwner, isFalse);
    });
  });

  group('UserModel DTO Tests', () {
    test('fromJson creates valid UserModel instance', () {
      final json = {
        'id': 'USR-001',
        'name': 'Budi Santoso',
        'username': 'budi123',
        'email': 'budi@warung.com',
        'role': 'OWNER',
        'status': 'ACTIVE',
        'avatarUrl': 'https://example.com/avatar.jpg',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'USR-001');
      expect(user.name, 'Budi Santoso');
      expect(user.username, 'budi123');
      expect(user.email, 'budi@warung.com');
      expect(user.role, UserRole.owner);
      expect(user.status, 'ACTIVE');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('fromJson handles alternative field names and default values', () {
      final json = {
        'id': 100,
        'nama': 'Siti Aminah',
        'username': 'siti',
        'email': 'siti@warung.com',
        'role': 'ADMIN_TOKO',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '100');
      expect(user.name, 'Siti Aminah');
      expect(user.role, UserRole.adminToko);
      expect(user.status, 'ACTIVE');
      expect(user.avatarUrl, isNull);
    });

    test('toJson serializes UserModel correctly', () {
      const user = UserModel(
        id: 'USR-002',
        name: 'Andi Kasir',
        username: 'andi',
        email: 'andi@warung.com',
        role: UserRole.adminToko,
        status: 'ACTIVE',
      );

      final json = user.toJson();

      expect(json['id'], 'USR-002');
      expect(json['name'], 'Andi Kasir');
      expect(json['role'], 'ADMIN_TOKO');
      expect(json['status'], 'ACTIVE');
      expect(json.containsKey('avatarUrl'), isFalse);
    });

    test('copyWith creates modified clone correctly', () {
      const user = UserModel(
        id: 'USR-001',
        name: 'User Lama',
        username: 'user',
        email: 'user@warung.com',
        role: UserRole.adminToko,
      );

      final updated = user.copyWith(
        name: 'User Baru',
        role: UserRole.adminKantor,
      );

      expect(updated.id, 'USR-001');
      expect(updated.name, 'User Baru');
      expect(updated.role, UserRole.adminKantor);
      expect(updated.email, 'user@warung.com');
    });

    test('Equatable equality works for UserModel', () {
      const user1 = UserModel(
        id: 'USR-001',
        name: 'Budi',
        username: 'budi',
        email: 'budi@warung.com',
        role: UserRole.owner,
      );
      const user2 = UserModel(
        id: 'USR-001',
        name: 'Budi',
        username: 'budi',
        email: 'budi@warung.com',
        role: UserRole.owner,
      );
      const user3 = UserModel(
        id: 'USR-002',
        name: 'Budi',
        username: 'budi',
        email: 'budi@warung.com',
        role: UserRole.owner,
      );

      expect(user1, equals(user2));
      expect(user1 == user3, isFalse);
    });
  });

  group('LoginRequest DTO Tests', () {
    test('fromJson and toJson work correctly', () {
      final json = {
        'email': 'admin@warung.com',
        'password': 'secretPassword123',
      };

      final request = LoginRequest.fromJson(json);

      expect(request.email, 'admin@warung.com');
      expect(request.password, 'secretPassword123');

      final serialized = request.toJson();
      expect(serialized['email'], 'admin@warung.com');
      expect(serialized['password'], 'secretPassword123');
    });

    test('fromJson supports username field fallback', () {
      final json = {
        'username': 'admin_warung',
        'password': 'pass',
      };

      final request = LoginRequest.fromJson(json);
      expect(request.email, 'admin_warung');
    });
  });

  group('LoginResponse DTO Tests', () {
    test('fromJson parses direct payload with token and user object', () {
      final json = {
        'token': 'jwt_access_token_xyz',
        'refreshToken': 'jwt_refresh_token_abc',
        'message': 'Login berhasil',
        'user': {
          'id': 'USR-101',
          'name': 'Doni Owner',
          'username': 'doni',
          'email': 'doni@warung.com',
          'role': 'OWNER',
          'status': 'ACTIVE',
        },
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, 'jwt_access_token_xyz');
      expect(response.refreshToken, 'jwt_refresh_token_abc');
      expect(response.message, 'Login berhasil');
      expect(response.user.id, 'USR-101');
      expect(response.user.name, 'Doni Owner');
      expect(response.user.role, UserRole.owner);
    });

    test('fromJson parses nested data wrapper payload', () {
      final json = {
        'message': 'Success',
        'data': {
          'jwt_token': 'jwt_token_inside_data',
          'refresh_token': 'refresh_inside_data',
          'user': {
            'id': 'USR-202',
            'name': 'Rina Kasir',
            'username': 'rina',
            'email': 'rina@warung.com',
            'role': 'ADMIN_TOKO',
          },
        },
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, 'jwt_token_inside_data');
      expect(response.refreshToken, 'refresh_inside_data');
      expect(response.user.name, 'Rina Kasir');
      expect(response.user.role, UserRole.adminToko);
    });

    test('toJson serializes LoginResponse correctly', () {
      const response = LoginResponse(
        token: 'token_sample',
        refreshToken: 'refresh_sample',
        message: 'OK',
        user: UserModel(
          id: 'USR-303',
          name: 'Joko',
          username: 'joko',
          email: 'joko@warung.com',
          role: UserRole.adminKantor,
        ),
      );

      final json = response.toJson();

      expect(json['token'], 'token_sample');
      expect(json['refreshToken'], 'refresh_sample');
      expect(json['message'], 'OK');
      expect(json['user']['name'], 'Joko');
      expect(json['user']['role'], 'ADMIN_KANTOR');
    });
  });
}
