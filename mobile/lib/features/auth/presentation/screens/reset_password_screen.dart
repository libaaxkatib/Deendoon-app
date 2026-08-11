import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/reset_password_form.dart';

class ResetPasswordScreen extends StatelessWidget {
  /// Pre-fills the email field when reached from a successful Forgot
  /// Password submission (`context.push(RoutePaths.resetPassword, extra:
  /// email)`) — null when reached any other way (e.g. a future deep link),
  /// in which case the field starts empty as before.
  final String? initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ResetPasswordForm(initialEmail: initialEmail),
        ),
      ),
    );
  }
}
