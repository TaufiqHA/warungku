import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';
import '../../app/config/app_typography.dart';
import 'app_button.dart';

/// Reusable Empty State Widget
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionButtonText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.pLg,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButtonText != null && onActionPressed != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: actionButtonText!,
                onPressed: onActionPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
