import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/login_request.dart';
import '../bloc/auth_bloc.dart';

/// Screen Login pengguna dengan integrasi AuthBloc, validasi form, dan quick demo credentials
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);

    context.read<AuthBloc>().add(
          AuthLoginEvent(LoginRequest(email: email, password: password)),
        );
  }

  void _fillDemoCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoadingState) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
          }
        }

        if (state is AuthFailureState) {
          UiHelpers.showErrorSnackBar(context, state.errorMessage);
        } else if (state is AuthAuthenticatedState) {
          UiHelpers.showSuccessSnackBar(
            context,
            'Selamat datang, ${state.user.name}!',
          );
        }
      },
      builder: (context, state) {
        final isLoading = _isSubmitting && state is AuthLoadingState;

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
                                label: 'Email',
                                hintText: 'contoh@warungku.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Email tidak boleh kosong';
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
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
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
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleLogin,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Quick Fill Demo Credentials
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Pilih Akun Demo Cepat:',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                alignment: WrapAlignment.center,
                                children: [
                                  ActionChip(
                                    label: const Text('👑 Owner'),
                                    onPressed: () => _fillDemoCredentials(
                                      'owner@warungku.com',
                                      'password123',
                                    ),
                                  ),
                                  ActionChip(
                                    label: const Text('🏪 Kasir Toko'),
                                    onPressed: () => _fillDemoCredentials(
                                      'kasir@warungku.com',
                                      'password123',
                                    ),
                                  ),
                                  ActionChip(
                                    label: const Text('💼 Admin Kantor'),
                                    onPressed: () => _fillDemoCredentials(
                                      'kantor@warungku.com',
                                      'password123',
                                    ),
                                  ),
                                ],
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
      },
    );
  }
}
