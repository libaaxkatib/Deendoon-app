import 'package:flutter/material.dart';

import '../widgets/about_deendoon_section.dart';

/// Dedicated "About Deendoon" destination — reached from the Account
/// menu's "About" item. Holds the app branding/description/version/
/// legal/support content that previously lived at the bottom of the
/// Profile screen; moved here so Profile stays scoped to the user's own
/// account (avatar, name, email, Change Password) rather than app-level
/// information.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [AboutDeendoonSection()],
      ),
    );
  }
}
