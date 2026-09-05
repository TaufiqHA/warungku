import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_spacing.dart';

/// Reusable Card Container Component
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.pMd,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppSpacing.roundedMd;

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: child,
    );

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
