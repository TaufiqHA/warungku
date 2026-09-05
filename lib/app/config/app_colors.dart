import 'package:flutter/material.dart';

/// Palet warna standar aplikasi WarungKu
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF2563EB); // Blue Warung
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFEFF6FF);

  // Secondary / Accent Colors
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFF2DD4BF);
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondaryContainer = Color(0xFFF0FDFA);

  // Status & Semantic Colors
  static const Color success = Color(0xFF16A34A); // Green Pemasukan / Selesai
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color danger = Color(0xFFDC2626); // Red Pengeluaran / Batal
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFD97706); // Orange Pending
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color info = Color(0xFF0284C7); // Sky Blue Info
  static const Color infoContainer = Color(0xFFE0F2FE);
  static const Color infoText = Color(0xFF0369A1);

  // Neutral & Surfaces (Light Mode)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark Mode Surface & Neutrals
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
