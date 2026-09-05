import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku/app/routes/app_router.dart';
import 'package:warungku/app/routes/app_routes.dart';
import 'package:warungku/features/auth/data/models/login_request.dart';
import 'package:warungku/features/auth/data/models/login_response.dart';
import 'package:warungku/features/auth/data/models/user_model.dart';
import 'package:warungku/features/auth/data/models/user_role.dart';
import 'package:warungku/features/auth/data/repositories/auth_repository.dart';
import 'package:warungku/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? user;
  String? token;

  @override
  Future<LoginResponse> login(LoginRequest request) async => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<UserModel?> getSavedUser() async => user;
  @override
  Future<String?> getSavedToken() async => token;
  @override
  Future<bool> hasActiveSession() async => user != null && token != null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });
  group('AppRouter Route Guards & Redirection Tests', () {
    testWidgets('Unauthenticated user is redirected to /login when accessing /dashboard', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      authBloc.emit(const AuthUnauthenticatedState());

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);

      authBloc.close();
    });

    testWidgets('Authenticated user on /login is redirected to /dashboard', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      authBloc.emit(const AuthAuthenticatedState(
        user: UserModel(
          id: '1',
          name: 'Owner',
          username: 'owner',
          email: 'owner@warung.com',
          role: UserRole.owner,
        ),
        token: 'token_123',
      ));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.dashboard);

      authBloc.close();
    });

    testWidgets('ADMIN_TOKO accessing /reports is redirected to /dashboard (RBAC)', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      authBloc.emit(const AuthAuthenticatedState(
        user: UserModel(
          id: '2',
          name: 'Kasir Toko',
          username: 'kasir',
          email: 'kasir@warung.com',
          role: UserRole.adminToko,
        ),
        token: 'token_kasir',
      ));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.reports);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.dashboard);

      authBloc.close();
    });

    testWidgets('ADMIN_KANTOR accessing /pos is redirected to /dashboard (RBAC)', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      authBloc.emit(const AuthAuthenticatedState(
        user: UserModel(
          id: '3',
          name: 'Admin Kantor',
          username: 'kantor',
          email: 'kantor@warung.com',
          role: UserRole.adminKantor,
        ),
        token: 'token_kantor',
      ));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.pos);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.dashboard);

      authBloc.close();
    });

    testWidgets('OWNER can access all modules (e.g. /reports)', (tester) async {
      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      authBloc.emit(const AuthAuthenticatedState(
        user: UserModel(
          id: '1',
          name: 'Owner Warung',
          username: 'owner',
          email: 'owner@warung.com',
          role: UserRole.owner,
        ),
        token: 'token_owner',
      ));

      final router = AppRouter.createRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.reports);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.reports);

      authBloc.close();
    });
  });
}
