import 'package:flutter/material.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/role_guard.dart';
import '../../data/models/auth_model.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/biaya_tab.dart';
import 'tabs/profil_tab.dart';
import '../../widgets/printer_settings_dialog.dart';

class AdminKantorDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final UserModel? testUser;

  const AdminKantorDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.testUser,
  });

  @override
  State<AdminKantorDashboardScreen> createState() => _AdminKantorDashboardScreenState();
}

class _AdminKantorDashboardScreenState extends State<AdminKantorDashboardScreen> {
  late int _currentIndex;

  final List<String> _titles = [
    'Beranda Admin Kantor',
    'Biaya Operasional',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppRoles.adminKantor,
      testUser: widget.testUser,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);

    final tabs = [
      BerandaTab(
        onGoToProfil: () => _switchTab(2),
      ),
      const BiayaTab(),
      ProfilTab(
        onLogout: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    ];

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
          if (_currentIndex == 2)
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
        children: tabs,
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
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'Biaya',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
