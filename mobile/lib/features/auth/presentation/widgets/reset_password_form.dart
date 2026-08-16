import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Calls `POST /reset-password` directly through `AuthRepository`. Mirrors
/// `ResetPasswordRequest`'s exact fields — email, token, password,
/// password_confirmation. There is no deep-link handling in this app, so
/// the token emailed to the user is entered manually rather than parsed
/// from a link.
class ResetPasswordForm extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ResetPasswordForm({super.key, this.initialEmail});

  @override
  ConsumerState<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Mirrors the server-side policy (AppServiceProvider: Password::min(12),
  // no composition rules) — client-side is a UX nicety, the server remains
  // the source of truth.
  static const _minPasswordLength = 12;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _fieldErrors;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = null);
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
          );
      setState(() => _successMessage = message);
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) context.go(RoutePaths.login);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.detailedMessage;
        _fieldErrors = e.fieldErrors;
      });
      _formKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.authEmailLabel),
            validator: (value) {
              final backendError = ApiException.fieldErrorFor(
                _fieldErrors,
                'email',
              );
              if (backendError != null) return backendError;
              if (value == null || value.trim().isEmpty) {
                return l10n.authEmailRequired;
              }
              if (!_emailPattern.hasMatch(value.trim())) {
                return l10n.authEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: l10n.resetPasswordCodeLabel,
              helperText: l10n.resetPasswordCodeHelper,
            ),
            validator: (value) {
              final backendError = ApiException.fieldErrorFor(
                _fieldErrors,
                'token',
              );
              if (backendError != null) return backendError;
              if (value == null || value.trim().isEmpty) {
                return l10n.resetPasswordCodeRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            labelText: l10n.resetPasswordNewPasswordLabel,
            validator: (value) {
              final backendPasswordError =
                  ApiException.splitConfirmedFieldError(
                    _fieldErrors,
                    'password',
                  );
              final backendError =
                  backendPasswordError.other ??
                  backendPasswordError.confirmationMismatch;
              if (backendError != null) return backendError;
              if (value == null || value.isEmpty) {
                return l10n.authPasswordRequired;
              }
              if (value.length < _minPasswordLength) {
                return l10n.authPasswordMinLength(_minPasswordLength);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmController,
            labelText: l10n.resetPasswordConfirmLabel,
            validator: (value) {
              final backendError = ApiException.splitConfirmedFieldError(
                _fieldErrors,
                'password',
              ).confirmationMismatch;
              if (backendError != null) return backendError;
              if (value != _passwordController.text) {
                return l10n.authPasswordsMismatch;
              }
              return null;
            },
          ),
          // See ForgotPasswordForm: only shown for errors that aren't per-field.
          if (_errorMessage != null &&
              (_fieldErrors == null || _fieldErrors!.isEmpty)) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Text(_successMessage!, style: const TextStyle(color: Colors.green)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.resetPasswordSubmitButton,
            isLoading: _isLoading,
            onPressed: _successMessage == null ? _submit : null,
          ),
        ],
      ),
    );
  }
}
