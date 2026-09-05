import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/widgets.dart';

/// Screen Beranda Dashboard Utama
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              if (confirm == true) {
                await SecureStorageService().deleteToken();
                if (context.mounted) {
                  UiHelpers.showInfoSnackBar(context, 'Anda telah keluar.');
                  context.go(AppRoutes.login);
                }
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
            // Status Bar / Banner
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
                              text: 'ONLINE',
                              variant: AppBadgeVariant.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Kasir Aktif',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Ringkasan Penjualan Hari Ini',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white),
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
                    child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Menu Cepat', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),

            // Quick Menu Action Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: [
                _buildMenuCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Kasir (POS)',
                  subtitle: 'Mulai Transaksi',
                  color: AppColors.primary,
                  onTap: () => UiHelpers.showInfoSnackBar(context, 'Modul POS akan aktif di Fase 4'),
                ),
                _buildMenuCard(
                  icon: Icons.kitchen_rounded,
                  title: 'Pesanan Dapur',
                  subtitle: 'Antrean Masak',
                  color: AppColors.warning,
                  onTap: () => UiHelpers.showInfoSnackBar(context, 'Modul Dapur akan aktif di Fase 4'),
                ),
                _buildMenuCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Kelola Menu',
                  subtitle: 'Daftar Produk',
                  color: AppColors.secondary,
                  onTap: () => UiHelpers.showInfoSnackBar(context, 'Modul Produk akan aktif di Fase 3'),
                ),
                _buildMenuCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Pengeluaran',
                  subtitle: 'Biaya Operasional',
                  color: AppColors.danger,
                  onTap: () => UiHelpers.showInfoSnackBar(context, 'Modul Biaya akan aktif di Fase 3'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
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
