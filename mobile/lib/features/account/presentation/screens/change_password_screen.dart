import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Real, wired to `POST /change-password` via `AuthRepository`. Mirrors
/// `ChangePasswordRequest`'s exact fields (current_password, password,
/// password_confirmation), same pattern as `ResetPasswordForm`.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  static const _minPasswordLength = 12;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _fieldErrors;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
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
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      setState(() => _successMessage = message);
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  controller: _currentController,
                  labelText: l10n.changePasswordCurrentLabel,
                  validator: (value) {
                    final backendError = ApiException.fieldErrorFor(
                      _fieldErrors,
                      'current_password',
                    );
                    if (backendError != null) return backendError;
                    if (value == null || value.isEmpty) {
                      return l10n.changePasswordCurrentRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _newController,
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
                      return l10n.changePasswordNewRequired;
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
                    if (value != _newController.text) {
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l10n.changePassword,
                  isLoading: _isLoading,
                  onPressed: _successMessage == null ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
