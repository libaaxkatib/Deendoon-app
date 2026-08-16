import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Generic static-content destination for Privacy Policy and Terms &
/// Conditions — reached from `AboutDeendoonSection`. Content is local app
/// copy (`legal_content.dart`), not fetched from the backend, matching
/// this screen's "no backend required" scope.
class LegalContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [Text(content, style: AppTypography.body)],
      ),
    );
  }
}
