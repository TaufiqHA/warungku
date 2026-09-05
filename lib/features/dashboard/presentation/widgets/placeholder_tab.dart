import 'package:flutter/material.dart';
import '../../../../app/config/app_colors.dart';
import '../../../../app/config/app_spacing.dart';
import '../../../../app/config/app_typography.dart';
import '../../../../core/widgets/widgets.dart';

/// Reusable Placeholder Tab untuk modul yang akan diintegrasikan di sprint lanjutan
class PlaceholderTab extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String sprintInfo;
  final Color iconColor;

  const PlaceholderTab({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.sprintInfo,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTypography.titleLarge),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AppCard(
              padding: AppSpacing.pXl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: AppSpacing.pLg,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: iconColor),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppBadge(
                    text: sprintInfo,
                    variant: AppBadgeVariant.info,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
