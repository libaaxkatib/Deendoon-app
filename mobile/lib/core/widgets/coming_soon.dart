import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Shown when a tap targets a destination screen that hasn't been built
/// yet (its module is out of scope for the current sprint) — keeps every
/// tappable element from the frozen spec wired up without inventing a
/// fake destination screen.
void showComingSoon(BuildContext context, String destination) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(l10n.comingSoonMessage(destination))),
    );
}
