import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/google_registration_input.dart';
import '../widgets/google_register_form.dart';

class GoogleRegisterScreen extends StatelessWidget {
  final GoogleRegistrationInput input;

  const GoogleRegisterScreen({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.googleRegisterTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [GoogleRegisterForm(input: input)],
            ),
          ),
        ),
      ),
    );
  }
}
