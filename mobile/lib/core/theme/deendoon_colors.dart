import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware semantic colors, resolved via `Theme.of(context)` rather
/// than the compile-time-fixed `AppColors` constants. `AppColors` itself
/// is untouched and remains the literal source of truth for the dark
/// palette (`DeendoonColors.dark` mirrors it exactly) — this extension
/// only adds a second, light variant and a context-based way to pick
/// between them, without changing what the dark theme actually looks
/// like.
@immutable
class DeendoonColors extends ThemeExtension<DeendoonColors> {
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;

  const DeendoonColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
  });

  /// The existing, approved dark identity — every value copied verbatim
  /// from `AppColors`, so switching to this extension changes nothing
  /// about how the app currently looks.
  static const dark = DeendoonColors(
    background: AppColors.background,
    surface: AppColors.surface,
    primary: AppColors.primary,
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
  );

  /// The light counterpart, using the same brand primary (teal/turquoise)
  /// and accent (gold) as the dark theme — only background/surface/text
  /// invert from dark-on-light to light-on-dark, mirroring the dark
  /// theme's own background-darker/surface-one-step-lighter structure
  /// (here: background a light neutral gray, surface pure white — cards
  /// popping against the page, the same separation relationship the dark
  /// theme uses, just at the light end of the scale). Status colors
  /// (success/warning/danger/info) are reused unchanged — all four are
  /// mid-saturation, mid-lightness colors with enough contrast on both a
  /// near-black and a near-white surface, so no new status palette is
  /// needed.
  static const light = DeendoonColors(
    background: Color(0xFFF2F3F5),
    surface: Color(0xFFFFFFFF),
    primary: AppColors.primary,
    accent: AppColors.accent,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    textPrimary: Color(0xFF1A2233),
    textSecondary: Color(0xFF6B7280),
  );

  @override
  DeendoonColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return DeendoonColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  DeendoonColors lerp(ThemeExtension<DeendoonColors>? other, double t) {
    if (other is! DeendoonColors) return this;
    return DeendoonColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

/// Ergonomic, theme-aware access point: `context.colors.textPrimary`
/// instead of `Theme.of(context).extension<DeendoonColors>()!.textPrimary`.
/// Falls back to `DeendoonColors.dark` (this app's pre-existing, unchanged
/// palette) if the current `ThemeData` has no `DeendoonColors` extension
/// registered — e.g. widget tests that construct a bare `ThemeData()`
/// directly rather than going through `buildAppDarkTheme()`/
/// `buildAppLightTheme()`. The real app always registers one of the two,
/// so this fallback only matters for test harnesses, not production.
extension DeendoonColorsX on BuildContext {
  DeendoonColors get colors => Theme.of(this).extension<DeendoonColors>() ?? DeendoonColors.dark;
}
