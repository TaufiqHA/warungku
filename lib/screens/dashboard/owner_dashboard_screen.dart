import 'package:flutter/material.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/role_guard.dart';
import '../../data/models/auth_model.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/laba_rugi_tab.dart';
import 'tabs/penjualan_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/user_management_tab.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/printer_settings_dialog.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final UserModel? testUser;

  const OwnerDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.testUser,
  });

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late int _currentIndex;
  late final Set<int> _visitedTabs;

  final List<String> _titles = [
    'Beranda Owner',
    'Laba Rugi',
    'Penjualan',
    'Profil',
    'Manajemen Pengguna',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _visitedTabs = {_currentIndex};
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() {
        _currentIndex = index;
        _visitedTabs.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppRoles.owner,
      testUser: widget.testUser,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Pengaturan Printer Thermal',
              onPressed: () => PrinterSettingsDialog.show(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _visitedTabs.contains(0)
              ? BerandaTab(
                  onGoToLabaRugi: () => _switchTab(1),
                  onGoToPenjualan: () => _switchTab(2),
                  onGoToProfil: () => _switchTab(3),
                  onGoToUserManagement: () => _switchTab(4),
                  onOpenMonthlyReport: () {
                    Navigator.of(context, rootNavigator: true).pushNamed('/report/monthly');
                  },
                  onQuickLogout: () async {
                    final confirm = await AppDialog.showConfirmation(
                      context: context,
                      title: 'Keluar',
                      message: 'Yakin ingin keluar dari akun Owner?',
                      confirmText: 'Keluar',
                      isDestructive: true,
                    );
                    if (confirm == true) {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    }
                  },
                )
              : const SizedBox.shrink(),
          _visitedTabs.contains(1)
              ? LabaRugiTab(
                  onOpenMonthlyReport: () {
                    Navigator.of(context, rootNavigator: true).pushNamed('/report/monthly');
                  },
                )
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? const PenjualanTab(canAddTransaction: false)
              : const SizedBox.shrink(),
          _visitedTabs.contains(3)
              ? ProfilTab(
                  onLogout: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                )
              : const SizedBox.shrink(),
          _visitedTabs.contains(4)
              ? const UserManagementTab()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        elevation: 2,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Laba Rugi',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Penjualan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: 'Pengguna',
          ),
        ],
      ),
    );
  }
}
