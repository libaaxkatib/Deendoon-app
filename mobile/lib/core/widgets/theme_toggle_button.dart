import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_mode_provider.dart';

/// Compact one-tap Light/Dark toggle for the main app header — a faster
/// path than Settings → Appearance, which remains the only place to pick
/// System Default (this toggle only flips between Light and Dark).
///
/// Icon shows what tapping switches *to*, matching the requested spec:
/// moon while Light is active (tap to go dark), sun while Dark is active
/// (tap to go light). While in System mode, "currently active" is
/// resolved against the device's actual current brightness so the icon
/// still makes sense — tapping it in that case doesn't silently discard
/// the System preference by accident; it's the same explicit action as
/// picking Light/Dark from the Settings dropdown (which also leaves
/// System mode), just one tap instead of opening a menu. Settings →
/// Appearance is unaffected and still offers Light/Dark/System at any
/// time.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDarkNow = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    return IconButton(
      icon: Icon(isDarkNow ? Icons.wb_sunny_rounded : Icons.nightlight_round),
      tooltip: isDarkNow ? l10n.themeSwitchToLight : l10n.themeSwitchToDark,
      onPressed: () {
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(isDarkNow ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}
