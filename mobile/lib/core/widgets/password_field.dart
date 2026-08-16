import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Reusable password input (Mobile Fix #7) — hidden by default, with a
/// trailing eye icon that toggles a purely local `obscureText` state.
/// Never touches [controller]'s value or [validator] and never triggers
/// a request — the toggle only changes how the already-entered text
/// renders, nothing about validation, submission, or auth behavior.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleObscureText() => setState(() => _obscureText = !_obscureText);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          tooltip: _obscureText
              ? l10n.passwordFieldShowTooltip
              : l10n.passwordFieldHideTooltip,
          onPressed: _toggleObscureText,
        ),
      ),
      validator: widget.validator,
    );
  }
}
