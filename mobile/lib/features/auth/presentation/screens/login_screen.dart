import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Deendoon', style: AppTypography.display, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Smart Debt Recovery Assistant',
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
