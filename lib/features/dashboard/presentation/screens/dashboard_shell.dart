import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/config/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/beranda_tab.dart';
import '../widgets/placeholder_tab.dart';

/// Container Shell utama dengan Bottom Navigation Bar dinamis berbasis UserRole
class DashboardShell extends StatefulWidget {
  final UserModel? initialUser;

  const DashboardShell({super.key, this.initialUser});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserModel user = widget.initialUser ??
            const UserModel(
              id: '0',
              name: 'Kasir',
              username: 'kasir',
              email: 'kasir@warungku.com',
              role: UserRole.adminToko,
            );

        if (state is AuthAuthenticatedState) {
          user = state.user;
        }

        final role = user.role;
        final tabConfig = _buildTabConfig(user, role);

        // Pastikan current index berada dalam range tab yang tersedia
        final activeIndex = _currentIndex < tabConfig.tabs.length ? _currentIndex : 0;

        return Scaffold(
          body: IndexedStack(
            index: activeIndex,
            children: tabConfig.tabs,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: activeIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: AppColors.surface,
            elevation: 8,
            indicatorColor: AppColors.primaryContainer,
            destinations: tabConfig.destinations,
          ),
        );
      },
    );
  }

  _ShellTabConfig _buildTabConfig(UserModel user, UserRole role) {
    switch (role) {
      case UserRole.owner:
        return _ShellTabConfig(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
              label: 'Laba Rugi',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
              label: 'User',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
          tabs: [
            BerandaTab(
              user: user,
              onNavigateTab: (idx) => setState(() => _currentIndex = idx),
            ),
            const PlaceholderTab(
              title: 'Laba Rugi & Analitik',
              description: 'Omset penjualan, total biaya operasional, dan grafik laba bersih harian/bulanan.',
              icon: Icons.analytics_outlined,
              sprintInfo: 'Fitur Utama Sprint 6',
              iconColor: AppColors.secondary,
            ),
            const PlaceholderTab(
              title: 'Penjualan (POS Kasir)',
              description: 'Katalog menu produk, pemilihan varian, keranjang, dan multi-channel payment checkout.',
              icon: Icons.point_of_sale_rounded,
              sprintInfo: 'Fitur Utama Sprint 3',
              iconColor: AppColors.primary,
            ),
            const PlaceholderTab(
              title: 'Manajemen Pengguna',
              description: 'Kelola akun staf kasir dan admin kantor warung.',
              icon: Icons.manage_accounts_outlined,
              sprintInfo: 'Fitur Utama Sprint 6',
              iconColor: AppColors.warning,
            ),
            const PlaceholderTab(
              title: 'Profil & Pengaturan Toko',
              description: 'Detail toko, profil kasir/owner, konfigurasi printer thermal Bluetooth & LAN.',
              icon: Icons.person_outline_rounded,
              sprintInfo: 'Fitur Utama Sprint 5 & 6',
              iconColor: AppColors.textSecondary,
            ),
          ],
        );

      case UserRole.adminToko:
        return _ShellTabConfig(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen_rounded, color: AppColors.warning),
              label: 'Dapur',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.secondary),
              label: 'Barang',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
          tabs: [
            BerandaTab(
              user: user,
              onNavigateTab: (idx) => setState(() => _currentIndex = idx),
            ),
            const PlaceholderTab(
              title: 'Penjualan (POS Kasir)',
              description: 'Katalog menu, keranjang belanja, diskon persen/nominal, dan cetak struk kasir.',
              icon: Icons.point_of_sale_rounded,
              sprintInfo: 'Fitur Utama Sprint 3',
              iconColor: AppColors.primary,
            ),
            const PlaceholderTab(
              title: 'Pesanan Dapur (Active Orders)',
              description: 'Monitoring antrean pesanan masak dan Served Quantity Tracker porsi siap saji.',
              icon: Icons.kitchen_rounded,
              sprintInfo: 'Fitur Utama Sprint 4',
              iconColor: AppColors.warning,
            ),
            const PlaceholderTab(
              title: 'Manajemen Barang / Menu',
              description: 'Daftar produk makanan, minuman, snack, upload foto barang, dan ketersediaan stok.',
              icon: Icons.inventory_2_outlined,
              sprintInfo: 'Fitur Utama Sprint 2',
              iconColor: AppColors.secondary,
            ),
            const PlaceholderTab(
              title: 'Profil Kasir & Printer',
              description: 'Pengaturan koneksi printer struk thermal dan preferensi pencetakan.',
              icon: Icons.person_outline_rounded,
              sprintInfo: 'Fitur Utama Sprint 5',
              iconColor: AppColors.textSecondary,
            ),
          ],
        );

      case UserRole.adminKantor:
        return _ShellTabConfig(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.danger),
              label: 'Biaya',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded, color: AppColors.primary),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
          tabs: [
            BerandaTab(
              user: user,
              onNavigateTab: (idx) => setState(() => _currentIndex = idx),
            ),
            const PlaceholderTab(
              title: 'Biaya Operasional',
              description: 'Pencatatan belanja bahan baku, biaya utilitas listrik/air, gaji karyawan, dan filter periode.',
              icon: Icons.receipt_long_outlined,
              sprintInfo: 'Fitur Utama Sprint 2',
              iconColor: AppColors.danger,
            ),
            const PlaceholderTab(
              title: 'Laporan Finansial & Export',
              description: 'Rekap transaksi dan ekspor dokumen format PDF atau Excel Spreadsheet (.xlsx).',
              icon: Icons.assessment_outlined,
              sprintInfo: 'Fitur Utama Sprint 5 & 6',
              iconColor: AppColors.primary,
            ),
            const PlaceholderTab(
              title: 'Profil & Pengaturan Akun',
              description: 'Pengaturan akun dan preferensi pelaporan.',
              icon: Icons.person_outline_rounded,
              sprintInfo: 'Fitur Utama Sprint 1',
              iconColor: AppColors.textSecondary,
            ),
          ],
        );
    }
  }
}

class _ShellTabConfig {
  final List<NavigationDestination> destinations;
  final List<Widget> tabs;

  _ShellTabConfig({
    required this.destinations,
    required this.tabs,
  });
}
