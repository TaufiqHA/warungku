import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory AppBadge.role(String role) {
    Color bg;
    Color fg;
    switch (role.toUpperCase()) {
      case 'ADMIN_TOKO':
      case 'ADMIN TOKO':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'OWNER':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'ADMIN_KANTOR':
      case 'ADMIN KANTOR':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }
    return AppBadge(
      text: role.replaceAll('_', ' '),
      backgroundColor: bg,
      textColor: fg,
    );
  }

  factory AppBadge.status(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SELESAI':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'READY':
      case 'SIAP':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'PENDING':
      case 'PROSES':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'CANCELLED':
      case 'BATAL':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }
    return AppBadge(
      text: status,
      backgroundColor: bg,
      textColor: fg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fg = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
