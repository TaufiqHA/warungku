import 'package:flutter_test/flutter_test.dart';
import 'package:warungku/core/network/api_exception.dart';
import 'package:warungku/features/auth/data/models/login_request.dart';
import 'package:warungku/features/auth/data/models/login_response.dart';
import 'package:warungku/features/auth/data/models/user_model.dart';
import 'package:warungku/features/auth/data/models/user_role.dart';
import 'package:warungku/features/auth/data/repositories/auth_repository.dart';
import 'package:warungku/features/auth/presentation/bloc/auth_bloc.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? savedUser;
  String? savedToken;
  bool shouldThrowError = false;
  String errorMessage = 'Kredensial tidak valid';

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage, statusCode: 400);
    }
    final user = UserModel(
      id: 'USR-01',
      name: 'Owner Warung',
      username: request.email,
      email: request.email,
      role: UserRole.owner,
    );
    savedUser = user;
    savedToken = 'jwt_token_valid';
    return LoginResponse(
      token: 'jwt_token_valid',
      user: user,
      message: 'Login berhasil',
    );
  }

  @override
  Future<void> logout() async {
    savedUser = null;
    savedToken = null;
  }

  @override
  Future<UserModel?> getSavedUser() async => savedUser;

  @override
  Future<String?> getSavedToken() async => savedToken;

  @override
  Future<bool> hasActiveSession() async => savedToken != null && savedUser != null;
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthBloc authBloc;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitialState', () {
      expect(authBloc.state, const AuthInitialState());
    });

    test('AuthCheckSessionEvent emits AuthenticatedState when session exists', () async {
      fakeRepository.savedUser = const UserModel(
        id: 'USR-01',
        name: 'Owner Warung',
        username: 'owner',
        email: 'owner@warung.com',
        role: UserRole.owner,
      );
      fakeRepository.savedToken = 'saved_jwt_token';

      final expectedStates = [
        const AuthLoadingState(),
        AuthAuthenticatedState(
          user: fakeRepository.savedUser!,
          token: 'saved_jwt_token',
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckSessionEvent());
    });

    test('AuthCheckSessionEvent emits UnauthenticatedState when session is empty', () async {
      fakeRepository.savedUser = null;
      fakeRepository.savedToken = null;

      final expectedStates = [
        const AuthLoadingState(),
        const AuthUnauthenticatedState(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckSessionEvent());
    });

    test('AuthLoginEvent emits AuthenticatedState on success', () async {
      const request = LoginRequest(
        email: 'owner@warung.com',
        password: 'password123',
      );

      final expectedStates = [
        const AuthLoadingState(),
        const AuthAuthenticatedState(
          user: UserModel(
            id: 'USR-01',
            name: 'Owner Warung',
            username: 'owner@warung.com',
            email: 'owner@warung.com',
            role: UserRole.owner,
          ),
          token: 'jwt_token_valid',
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLoginEvent(request));
    });

    test('AuthLoginEvent emits FailureState on ApiException', () async {
      fakeRepository.shouldThrowError = true;
      fakeRepository.errorMessage = 'Password salah';

      const request = LoginRequest(
        email: 'owner@warung.com',
        password: 'wrong_password',
      );

      final expectedStates = [
        const AuthLoadingState(),
        const AuthFailureState('Password salah'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLoginEvent(request));
    });

    test('AuthLogoutEvent emits UnauthenticatedState and clears session', () async {
      fakeRepository.savedUser = const UserModel(
        id: 'USR-01',
        name: 'Kasir',
        username: 'kasir',
        email: 'kasir@warung.com',
        role: UserRole.adminToko,
      );
      fakeRepository.savedToken = 'active_token';

      final expectedStates = [
        const AuthLoadingState(),
        const AuthUnauthenticatedState(message: 'Anda telah berhasil keluar.'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthLogoutEvent());
    });
  });
}
