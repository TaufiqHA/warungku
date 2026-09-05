import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warungku/features/auth/data/models/login_request.dart';
import 'package:warungku/features/auth/data/models/login_response.dart';
import 'package:warungku/features/auth/data/models/user_model.dart';
import 'package:warungku/features/auth/data/repositories/auth_repository.dart';
import 'package:warungku/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warungku/features/auth/presentation/screens/splash_screen.dart';

class MockAuthRepository implements AuthRepository {
  int checkSessionCallCount = 0;

  @override
  Future<LoginResponse> login(LoginRequest request) async => throw UnimplementedError();
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

  group('SplashScreen Widget Tests', () {
    testWidgets('renders branding title, subtitle, and loading indicator', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('WarungKu'), findsOneWidget);
      expect(find.text('Sistem Manajemen Warung & POS'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));

      authBloc.close();
    });

    testWidgets('cancels splash timer cleanly upon early disposal', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Disposes widget before 1200ms
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: Scaffold(body: Text('Replaced Screen')),
          ),
        ),
      );

      // Advance time past 1200ms
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Replaced Screen'), findsOneWidget);

      authBloc.close();
    });
  });
}
