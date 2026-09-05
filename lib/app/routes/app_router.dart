import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/user_role.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_shell.dart';
import 'app_routes.dart';

/// Helper Stream Listenable untuk memicu evaluasi redirect GoRouter saat BLoC state berubah
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Konfigurasi GoRouter dengan Route Guards & Role-Based Redirection
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.uri.path;

        final isGoingToSplash = location == AppRoutes.splash;
        final isGoingToLogin = location == AppRoutes.login;

        // 1. Jika masih tahap inisialisasi sesi di splash screen
        if (authState is AuthInitialState || authState is AuthLoadingState) {
          return isGoingToSplash ? null : null;
        }

        // 2. Jika Pengguna Belum Login (Unauthenticated / Failure)
        if (authState is AuthUnauthenticatedState || authState is AuthFailureState) {
          if (!isGoingToLogin) {
            return AppRoutes.login;
          }
          return null;
        }

        // 3. Jika Pengguna Sudah Login (Authenticated)
        if (authState is AuthAuthenticatedState) {
          // Jika berada di splash atau login -> arahkan ke Dashboard
          if (isGoingToSplash || isGoingToLogin) {
            return AppRoutes.dashboard;
          }

          final role = authState.user.role;

          // Role-based Access Control (RBAC) Guard
          return _evaluateRoleAccess(role, location);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardShell(),
        ),
        // Rute placeholder modul spesifik
        GoRoute(
          path: AppRoutes.pos,
          name: 'pos',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.activeOrders,
          name: 'activeOrders',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.products,
          name: 'products',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          name: 'expenses',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          name: 'reports',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.userManagement,
          name: 'userManagement',
          builder: (context, state) => const DashboardShell(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const DashboardShell(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Halaman tidak ditemukan: ${state.uri}'),
        ),
      ),
    );
  }

  /// Memeriksa apakah role pengguna berhak mengakses rute tujuan
  static String? _evaluateRoleAccess(UserRole role, String location) {
    switch (role) {
      case UserRole.owner:
        // Owner memiliki akses penuh ke seluruh rute
        return null;

      case UserRole.adminToko:
        // Admin Toko hanya memiliki akses ke POS, Dapur, Produk, Pengaturan, dan Dashboard
        final allowedRoutes = [
          AppRoutes.dashboard,
          AppRoutes.pos,
          AppRoutes.activeOrders,
          AppRoutes.products,
          AppRoutes.settings,
        ];
        if (!allowedRoutes.contains(location)) {
          return AppRoutes.dashboard;
        }
        return null;

      case UserRole.adminKantor:
        // Admin Kantor hanya memiliki akses ke Pengeluaran, Laporan, Pengaturan, dan Dashboard
        final allowedRoutes = [
          AppRoutes.dashboard,
          AppRoutes.expenses,
          AppRoutes.reports,
          AppRoutes.settings,
        ];
        if (!allowedRoutes.contains(location)) {
          return AppRoutes.dashboard;
        }
        return null;
    }
  }
}
