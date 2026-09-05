import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';
import '../../app/config/app_typography.dart';

/// Reusable Loading State Widget
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
