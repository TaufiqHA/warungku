import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';
import '../../app/config/app_typography.dart';

enum AppBadgeVariant { success, danger, warning, info, neutral }

/// Reusable Badge / Pill Status Component
class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (variant) {
      case AppBadgeVariant.success:
        bgColor = AppColors.successContainer;
        fgColor = AppColors.successText;
        break;
      case AppBadgeVariant.danger:
        bgColor = AppColors.dangerContainer;
        fgColor = AppColors.dangerText;
        break;
      case AppBadgeVariant.warning:
        bgColor = AppColors.warningContainer;
        fgColor = AppColors.warningText;
        break;
      case AppBadgeVariant.info:
        bgColor = AppColors.infoContainer;
        fgColor = AppColors.infoText;
        break;
      case AppBadgeVariant.neutral:
        bgColor = AppColors.surfaceVariant;
        fgColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
