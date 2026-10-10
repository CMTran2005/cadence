import 'package:flutter/material.dart';

/// Design tokens inspired by anti-slop / taste-skill standards:
/// Deep neutral zinc surfaces, crisp contrast, functional accents.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF09090B); // Zinc 950
  static const Color surface = Color(0xFF121215);    // Dark slate card
  static const Color surfaceElevated = Color(0xFF18181B); // Zinc 900
  static const Color surfaceInteractive = Color(0xFF27272A); // Zinc 800

  // Borders & Dividers
  static const Color border = Color(0xFF27272A); // 1px crisp outline
  static const Color borderSubtle = Color(0xFF1E1E22);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);   // High-contrast
  static const Color textSecondary = Color(0xFFA1A1AA); // Muted readable
  static const Color textTertiary = Color(0xFF71717A);  // Subtle captions

  // Semantic & Financial Accents
  static const Color income = Color(0xFF10B981);       // Emerald 500
  static const Color incomeSubtle = Color(0x1A10B981); // Emerald 10%
  static const Color expense = Color(0xFFF43F5E);      // Rose 500
  static const Color expenseSubtle = Color(0x1AF43F5E);// Rose 10%
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color warningSubtle = Color(0x1AF59E0B);// Amber 10%
  static const Color accent = Color(0xFF6366F1);       // Indigo 500
  static const Color accentSubtle = Color(0x1A6366F1); // Indigo 10%
}
