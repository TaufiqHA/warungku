import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Tab Beranda: Ringkasan operasional harian dan menu cepat adaptif sesuai role
class BerandaTab extends StatelessWidget {
  final UserModel user;
  final void Function(int tabIndex)? onNavigateTab;

  const BerandaTab({
    super.key,
    required this.user,
    this.onNavigateTab,
  });

  AppBadgeVariant _getRoleBadgeVariant() {
    switch (user.role.toJsonValue()) {
      case 'OWNER':
        return AppBadgeVariant.info;
      case 'ADMIN_KANTOR':
        return AppBadgeVariant.warning;
      case 'ADMIN_TOKO':
      default:
        return AppBadgeVariant.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = user.role;
    final isOwner = role.isOwner;
    final isToko = role.isAdminToko;
    final isKantor = role.isAdminKantor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WarungKu POS', style: AppTypography.titleMedium),
            Text(
              Formatters.formatTanggalIndo(DateTime.now()),
              style: AppTypography.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await AppDialog.showConfirmDialog(
                context: context,
                title: 'Konfirmasi Keluar',
                message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
                confirmText: 'Keluar',
                isDanger: true,
              );
              if (confirm == true && context.mounted) {
                context.read<AuthBloc>().add(const AuthLogoutEvent());
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Banner
            AppCard(
              padding: AppSpacing.pMd,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo, ${user.name}', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(user.email, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  AppBadge(
                    text: role.displayName.toUpperCase(),
                    variant: _getRoleBadgeVariant(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Metrics Cards
            if (isOwner || isToko) ...[
              AppCard(
                backgroundColor: AppColors.primary,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppBadge(
                                text: 'PENJUALAN HARI INI',
                                variant: AppBadgeVariant.success,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '0 Transaksi',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Total Pemasukan Kasir',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            Formatters.formatRupiah(0),
                            style: AppTypography.currencyLarge.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: AppSpacing.pMd,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedLg,
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (isOwner || isKantor) ...[
              AppCard(
                backgroundColor: AppColors.dangerContainer.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppBadge(
                                text: 'PENGELUARAN HARI INI',
                                variant: AppBadgeVariant.danger,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '0 Biaya',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Total Biaya Operasional',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            Formatters.formatRupiah(0),
                            style: AppTypography.currencyLarge.copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: AppSpacing.pMd,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedLg,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.danger, size: 36),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            Text('Menu Pintas Cepat', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),

            // Quick Menu Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: [
                if (isOwner || isToko)
                  _buildActionCard(
                    context: context,
                    icon: Icons.point_of_sale_rounded,
                    title: 'Kasir (POS)',
                    subtitle: 'Mulai Transaksi',
                    color: AppColors.primary,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                if (isToko)
                  _buildActionCard(
                    context: context,
                    icon: Icons.kitchen_rounded,
                    title: 'Pesanan Dapur',
                    subtitle: 'Antrean Masak',
                    color: AppColors.warning,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                if (isToko)
                  _buildActionCard(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Kelola Menu',
                    subtitle: 'Katalog Produk',
                    color: AppColors.secondary,
                    onTap: () => onNavigateTab?.call(3),
                  ),
                if (isOwner)
                  _buildActionCard(
                    context: context,
                    icon: Icons.analytics_outlined,
                    title: 'Laba Rugi',
                    subtitle: 'Analisis Finansial',
                    color: AppColors.secondary,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                if (isOwner)
                  _buildActionCard(
                    context: context,
                    icon: Icons.manage_accounts_outlined,
                    title: 'Kelola Pengguna',
                    subtitle: 'Hak Akses Staf',
                    color: AppColors.warning,
                    onTap: () => onNavigateTab?.call(3),
                  ),
                if (isKantor)
                  _buildActionCard(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Pengeluaran',
                    subtitle: 'Catat Biaya',
                    color: AppColors.danger,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                if (isKantor)
                  _buildActionCard(
                    context: context,
                    icon: Icons.assessment_outlined,
                    title: 'Laporan',
                    subtitle: 'Rekap & Export',
                    color: AppColors.primary,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                _buildActionCard(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Profil & Setting',
                  subtitle: 'Akun & Printer',
                  color: AppColors.textSecondary,
                  onTap: () {
                    final targetTab = isOwner ? 4 : (isToko ? 4 : 3);
                    onNavigateTab?.call(targetTab);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.pSm,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(title, style: AppTypography.titleSmall),
          Text(subtitle, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
