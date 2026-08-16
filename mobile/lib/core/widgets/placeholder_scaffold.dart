import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_typography.dart';
import '../theme/deendoon_colors.dart';

/// "Screen X — coming soon" body reused by all 5 bottom-nav tabs until each
/// module's real content is built in its own follow-up sprint.
class PlaceholderScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const PlaceholderScaffold({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Center(
        child: Text(
          l10n.comingSoonMessage(title),
          style: AppTypography.subheading.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
