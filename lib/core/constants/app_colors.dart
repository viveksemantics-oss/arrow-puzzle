import 'package:flutter/material.dart';

/// Minimalist, premium color palette for Eklavya's Aim.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFE8EEF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Arrow & Geometry
  static const Color arrowPrimary = Color(0xFF1E2229);
  static const Color arrowSecondary = Color(0xFF4A5568);
  static const Color gridLine = Color(0xFFE2E8F0);
  static const Color gridBackground = Color(0xFFF8FAFC);

  // Accent & Feedback
  static const Color accent = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color hint = Color(0xFFF59E0B); // Amber glow for hints
  static const Color hintGlow = Color(0x33F59E0B);
  static const Color success = Color(0xFF10B981); // Emerald green for complete
  static const Color error = Color(0xFFEF4444); // Rose red for blocked
  static const Color blockedPath = Color(0x26EF4444);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Buttons & Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color buttonBackground = Color(0xFFFFFFFF);
  static const Color buttonDark = Color(0xFF1E2229);
  static const Color buttonTextDark = Color(0xFFFFFFFF);

  // Shadows
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}
