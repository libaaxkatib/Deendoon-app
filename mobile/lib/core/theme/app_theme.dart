import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'deendoon_colors.dart';

/// The existing, approved dark theme — unchanged from before the Light/
/// System option was added. Still built from the same `AppColors`
/// constants; only new addition is registering `DeendoonColors.dark` as
/// a theme extension so widgets can read colors in a theme-aware way
/// (`context.colors.X`) without this theme's own appearance changing.
ThemeData buildAppDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    extensions: const [DeendoonColors.dark],
    textTheme: const TextTheme(
      displayLarge: AppTypography.display,
      headlineMedium: AppTypography.heading,
      titleMedium: AppTypography.subheading,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(AppTypography.caption),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

/// Light counterpart, added for the Account/Settings Appearance option
/// (Light/Dark/System Default) — same brand primary/accent as the dark
/// theme, same structural shape (same text scale, same button/app-bar/
/// nav-bar theming approach), only the background/surface/text colors
/// invert to `DeendoonColors.light`'s values. Not a redesign — every
/// styling decision here mirrors `buildAppDarkTheme()`'s, just resolved
/// against the light palette.
ThemeData buildAppLightTheme() {
  const colors = DeendoonColors.light;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: colors.primary,
    brightness: Brightness.light,
    primary: colors.primary,
    secondary: colors.accent,
    surface: colors.surface,
    error: colors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: colors.background,
    colorScheme: colorScheme,
    extensions: const [DeendoonColors.light],
    textTheme: TextTheme(
      displayLarge: AppTypography.display.copyWith(color: colors.textPrimary),
      headlineMedium: AppTypography.heading.copyWith(color: colors.textPrimary),
      titleMedium: AppTypography.subheading.copyWith(color: colors.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: colors.textPrimary),
      bodySmall: AppTypography.caption.copyWith(color: colors.textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(AppTypography.caption.copyWith(color: colors.textSecondary)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
