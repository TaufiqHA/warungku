import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/widgets.dart';

/// Screen Login pengguna dengan validasi dan interaksi UI modern
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulasi autentikasi login (fase berikutnya akan dihubungkan ke AuthBloc & ApiClient)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final storage = SecureStorageService();
    await storage.saveToken('dummy_jwt_token_sample');

    if (!mounted) return;

    setState(() => _isLoading = false);

    UiHelpers.showSuccessSnackBar(context, 'Login berhasil!');
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: AppSpacing.pMd,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppSpacing.roundedLg,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Selamat Datang',
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Masuk untuk mengelola operasional warung Anda',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      padding: AppSpacing.pLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'Username',
                            hintText: 'Masukkan username kasir / admin',
                            controller: _usernameController,
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Username tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Password',
                            hintText: 'Masukkan kata sandi',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            text: 'Masuk Sekarang',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
