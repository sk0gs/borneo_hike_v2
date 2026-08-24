import 'package:flutter/material.dart';

class AppTheme {
  final bool isDark;
  final Color bgColor;
  final Color cardColor;
  final Color cardSecondaryColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final Color primaryAccent;

  const AppTheme({
    required this.isDark,
    required this.bgColor,
    required this.cardColor,
    required this.cardSecondaryColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.primaryAccent,
  });

  factory AppTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme(
      isDark: isDark,
      bgColor: isDark ? const Color(0xFF0A1F18) : const Color(0xFFF2F7F4),
      cardColor: isDark ? const Color(0xFF112D24) : Colors.white,
      cardSecondaryColor: isDark ? const Color(0xFF1A3F2E) : const Color(0xFFE8F2EC),
      surfaceColor: isDark ? const Color(0xFF16382C) : const Color(0xFFDEEBE3),
      textColor: isDark ? Colors.white : const Color(0xFF0F291E),
      subTextColor: isDark ? Colors.grey[400]! : const Color(0xFF5A7568),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
      primaryAccent: const Color(0xFF2ECC71),
    );
  }
}
