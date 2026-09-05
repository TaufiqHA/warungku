import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 konsisten untuk aplikasi WarungKu
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerContainer,
        onErrorContainer: AppColors.dangerText,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          textStyle: AppTypography.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
          textStyle: AppTypography.labelMedium.copyWith(color: AppColors.primary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        disabledColor: AppColors.border,
        selectedColor: AppColors.primaryContainer,
        secondarySelectedColor: AppColors.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium,
        brightness: Brightness.light,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
