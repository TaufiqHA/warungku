import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:warungku/features/auth/data/models/login_request.dart';
import 'package:warungku/features/auth/data/models/login_response.dart';
import 'package:warungku/features/auth/data/models/user_model.dart';
import 'package:warungku/features/auth/data/models/user_role.dart';
import 'package:warungku/features/auth/data/repositories/auth_repository.dart';
import 'package:warungku/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warungku/features/dashboard/presentation/screens/dashboard_shell.dart';

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

  group('DashboardShell Dynamic Bottom Navigation Tests', () {
    testWidgets('renders 5 tabs correctly for OWNER role', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      const ownerUser = UserModel(
        id: '1',
        name: 'Pak Bos Owner',
        username: 'owner',
        email: 'owner@warungku.com',
        role: UserRole.owner,
      );

      authBloc.emit(const AuthAuthenticatedState(user: ownerUser, token: 'tok_1'));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: DashboardShell(initialUser: ownerUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify greetings and role badge
      expect(find.text('Halo, Pak Bos Owner'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);

      // Verify Navigation Destinations for Owner
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Laba Rugi'), findsWidgets);
      expect(find.text('POS'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Test tapping tab 1 (Laba Rugi)
      await tester.tap(find.byIcon(Icons.analytics_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Laba Rugi & Analitik'), findsWidgets);

      authBloc.close();
    });

    testWidgets('renders 5 tabs correctly for ADMIN_TOKO (Kasir) role', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      const kasirUser = UserModel(
        id: '2',
        name: 'Mbak Rina Kasir',
        username: 'kasir',
        email: 'kasir@warungku.com',
        role: UserRole.adminToko,
      );

      authBloc.emit(const AuthAuthenticatedState(user: kasirUser, token: 'tok_2'));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: DashboardShell(initialUser: kasirUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Mbak Rina Kasir'), findsOneWidget);
      expect(find.text('ADMIN TOKO'), findsOneWidget);

      // Verify Navigation Destinations for Admin Toko
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('POS'), findsOneWidget);
      expect(find.text('Dapur'), findsOneWidget);
      expect(find.text('Barang'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Test tapping tab 2 (Dapur)
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Pesanan Dapur (Active Orders)'), findsWidgets);

      authBloc.close();
    });

    testWidgets('renders 4 tabs correctly for ADMIN_KANTOR (Keuangan) role', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repository = MockAuthRepository();
      final authBloc = AuthBloc(authRepository: repository);

      const kantorUser = UserModel(
        id: '3',
        name: 'Mas Joko Kantor',
        username: 'kantor',
        email: 'kantor@warungku.com',
        role: UserRole.adminKantor,
      );

      authBloc.emit(const AuthAuthenticatedState(user: kantorUser, token: 'tok_3'));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: DashboardShell(initialUser: kantorUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Mas Joko Kantor'), findsOneWidget);
      expect(find.text('ADMIN KANTOR'), findsOneWidget);

      // Verify Navigation Destinations for Admin Kantor
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Biaya'), findsOneWidget);
      expect(find.text('Laporan'), findsWidgets);
      expect(find.text('Profil'), findsOneWidget);

      // Test tapping tab 1 (Biaya)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Biaya Operasional'), findsWidgets);

      authBloc.close();
    });
  });
}
