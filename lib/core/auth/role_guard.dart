import 'package:flutter/material.dart';
import '../../data/models/auth_model.dart';
import '../../services/token_manager.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'app_roles.dart';

class RoleGuard extends StatefulWidget {
  final String allowedRole;
  final Widget child;
  final UserModel? testUser;

  const RoleGuard({
    super.key,
    required this.allowedRole,
    required this.child,
    this.testUser,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  @override
  void didUpdateWidget(covariant RoleGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.testUser != widget.testUser || oldWidget.allowedRole != widget.allowedRole) {
      _checkRole();
    }
  }

  Future<void> _checkRole() async {
    if (widget.testUser != null) {
      setState(() {
        _user = widget.testUser;
        _isLoading = false;
      });
      return;
    }

    final user = await TokenManager.getUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Jika belum login, redirect ke login
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: AppCard(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Sesi Berakhir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan masuk kembali untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Ke Halaman Login',
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentRole = _user!.role.toUpperCase();
    final requiredRole = widget.allowedRole.toUpperCase();

    // Jika role cocok, tampilkan halaman yang dilindungi
    if (currentRole == requiredRole) {
      return widget.child;
    }

    // Jika role tidak cocok, tampilkan halaman Akses Ditolak
    final theme = Theme.of(context);
    final allowedName = AppRoles.getDisplayName(widget.allowedRole);
    final currentName = AppRoles.getDisplayName(_user!.role);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AppCard(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gpp_bad_outlined,
                      size: 36,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akses Ditolak',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halaman ini khusus untuk $allowedName. Akun Anda terdaftar sebagai $currentName.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Buka Dashboard Saya',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    },
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: 'Keluar',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
