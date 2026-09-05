import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';
import '../../app/config/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, danger, text }

/// Reusable Button Component dengan dukungan varian, icon, dan state loading
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = disabled ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.primary;
        fgColor = AppColors.textOnPrimary;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        bgColor = disabled ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.secondary;
        fgColor = AppColors.textOnPrimary;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = disabled ? AppColors.textMuted : AppColors.textPrimary;
        borderSide = BorderSide(color: disabled ? AppColors.divider : AppColors.border, width: 1.5);
        break;
      case AppButtonVariant.danger:
        bgColor = disabled ? AppColors.textMuted.withValues(alpha: 0.3) : AppColors.danger;
        fgColor = AppColors.textOnPrimary;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = disabled ? AppColors.textMuted : AppColors.primary;
        borderSide = BorderSide.none;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: fgColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: AppTypography.labelLarge.copyWith(color: fgColor),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 18, color: fgColor),
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: borderSide,
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
