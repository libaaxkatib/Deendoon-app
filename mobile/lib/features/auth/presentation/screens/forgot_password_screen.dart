import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../widgets/forgot_password_form.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the email associated with your account and we\'ll '
                  'send you a link to reset your password.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 24),
                const ForgotPasswordForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
