import 'package:flutter/material.dart';

/// Brand colors approved for Sprint 10 (Primary #18C7B6, Accent #D4AF37).
/// Background/surface and the §2.9 status vocabulary (success/warning/
/// danger/info) remain the Sprint 8 placeholders — only primary/accent
/// changed, per this sprint's "update ONLY the application theme" scope.
class AppColors {
  const AppColors._();

  static const background = Color(0xFF121417);
  static const surface = Color(0xFF1E2126);

  static const primary = Color(0xFF18C7B6);
  static const accent = Color(0xFFD4AF37);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF6366F1);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9CA3AF);
}
