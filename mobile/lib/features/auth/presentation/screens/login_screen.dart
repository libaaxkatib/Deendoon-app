import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  /// Threaded through to [LoginForm] — see its own doc comment. Defaults
  /// to hidden; only test code opts back in.
  final bool googleLoginEnabled;

  const LoginScreen({super.key, this.googleLoginEnabled = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.loginAppName,
                  style: AppTypography.display,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginTagline,
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                LoginForm(googleLoginEnabled: googleLoginEnabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
