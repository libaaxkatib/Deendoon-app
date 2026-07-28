import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// "Screen X — coming soon" body reused by all 5 bottom-nav tabs until each
/// module's real content is built in its own follow-up sprint.
class PlaceholderScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const PlaceholderScaffold({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Center(
        child: Text('$title — coming soon', style: AppTypography.subheading),
      ),
    );
  }
}
