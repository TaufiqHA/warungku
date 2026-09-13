import 'package:flutter/material.dart';
import '../../core/auth/app_roles.dart';
import '../../data/models/auth_model.dart';
import '../../services/token_manager.dart';
import 'admin_kantor_dashboard_screen.dart';
import 'admin_toko_dashboard_screen.dart';
import 'owner_dashboard_screen.dart';

class DashboardDispatcher extends StatefulWidget {
  final UserModel? testUser;

  const DashboardDispatcher({
    super.key,
    this.testUser,
  });

  @override
  State<DashboardDispatcher> createState() => _DashboardDispatcherState();
}

class _DashboardDispatcherState extends State<DashboardDispatcher> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.testUser != widget.testUser) {
      _determineDashboard();
    }
  }

  Future<void> _determineDashboard() async {
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

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _user!.role.toUpperCase();

    switch (role) {
      case AppRoles.owner:
        return OwnerDashboardScreen(testUser: _user);
      case AppRoles.adminToko:
        return AdminTokoDashboardScreen(testUser: _user);
      case AppRoles.adminKantor:
        return AdminKantorDashboardScreen(testUser: _user);
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Role tidak valid: ${_user!.role}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
