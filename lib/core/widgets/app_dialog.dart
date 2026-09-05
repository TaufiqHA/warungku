import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';
import '../../app/config/app_typography.dart';
import 'app_button.dart';

/// Helper untuk menampilkan Dialog konfirmasi konsisten
class AppDialog {
  AppDialog._();

  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        backgroundColor: AppColors.surface,
        titlePadding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Text(title, style: AppTypography.titleMedium),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: cancelText,
                  height: 44,
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: confirmText,
                  height: 44,
                  variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
