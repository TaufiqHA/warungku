import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// Screen Splash untuk inisialisasi awal dan pengecekan sesi login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final storage = SecureStorageService();
    final token = await storage.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.pLg,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'WarungKu',
              style: AppTypography.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sistem Manajemen Warung & POS',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
