import 'package:flutter/material.dart';

/// PLACEHOLDER palette — derived qualitatively from `Mobile_UI_V1_Frozen.md`
/// §2.1 ("near-black charcoal background", "bright green primary accent",
/// risk-level/reminder-type color coding). No real brand hex values exist
/// anywhere in the repo; replace these when real brand assets are handed off.
class AppColors {
  const AppColors._();

  static const background = Color(0xFF121417);
  static const surface = Color(0xFF1E2126);

  static const primary = Color(0xFF22C55E);
  static const success = primary;
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF6366F1);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9CA3AF);
}
