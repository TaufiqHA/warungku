import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warungku/features/auth/data/models/login_request.dart';
import 'package:warungku/features/auth/data/models/login_response.dart';
import 'package:warungku/features/auth/data/models/user_model.dart';
import 'package:warungku/features/auth/data/models/user_role.dart';
import 'package:warungku/features/auth/data/repositories/auth_repository.dart';
import 'package:warungku/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warungku/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository implements AuthRepository {
  LoginRequest? lastLoginRequest;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    lastLoginRequest = request;
    return LoginResponse(
      token: 'tok_sample',
      user: UserModel(
        id: '1',
        name: 'Owner',
        username: request.email,
        email: request.email,
        role: UserRole.owner,
      ),
    );
  }

  @override
  Future<void> logout() async {}
  @override
  Future<UserModel?> getSavedUser() async => null;
  @override
  Future<String?> getSavedToken() async => null;
  @override
  Future<bool> hasActiveSession() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all login elements, textfields, button, and demo chips', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);
      expect(find.text('👑 Owner'), findsOneWidget);
      expect(find.text('🏪 Kasir Toko'), findsOneWidget);
      expect(find.text('💼 Admin Kantor'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);

      authBloc.close();
    });

    testWidgets('demo quick-fill chip fills form and allows submit', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Owner demo chip
      await tester.tap(find.text('👑 Owner'));
      await tester.pumpAndSettle();

      expect(find.text('owner@warungku.com'), findsOneWidget);

      // Tap submit
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pump();

      expect(repository.lastLoginRequest?.email, 'owner@warungku.com');
      expect(repository.lastLoginRequest?.password, 'password123');

      // Finish any pending timers/snackbars
      await tester.pumpAndSettle(const Duration(seconds: 4));

      authBloc.close();
    });
  });
}
