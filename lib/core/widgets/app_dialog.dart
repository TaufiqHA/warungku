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
        title: Text(title, style: AppTypography.titleMedium),
        content: Text(message, style: AppTypography.bodyMedium),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          AppButton(
            text: confirmText,
            height: 40,
            variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
