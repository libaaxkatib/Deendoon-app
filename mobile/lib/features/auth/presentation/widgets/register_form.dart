import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _minPasswordLength = 12; // AuthController: Password::min(12)

  @override
  void dispose() {
    _businessNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (_formKey.currentState?.validate() != true) return;
    await ref
        .read(authProvider.notifier)
        .register(
          businessName: _businessNameController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );
    // See LoginForm._submit: rebuilding alone doesn't re-run validators.
    if (mounted) _formKey.currentState?.validate();
  }

  /// Reads backend field errors fresh — see LoginForm._backendFieldError.
  String? _backendFieldError(String key) {
    final state = ref.read(authProvider);
    return state is AuthError
        ? ApiException.fieldErrorFor(state.fieldErrors, key)
        : null;
  }

  ({String? confirmationMismatch, String? other}) _backendPasswordError() {
    final state = ref.read(authProvider);
    if (state is! AuthError) return (confirmationMismatch: null, other: null);
    return ApiException.splitConfirmedFieldError(state.fieldErrors, 'password');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState is Authenticating;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              labelText: l10n.registerBusinessNameLabel,
            ),
            validator: (value) {
              final backendError = _backendFieldError('business_name');
              if (backendError != null) return backendError;
              if (value == null || value.trim().isEmpty) {
                return l10n.registerBusinessNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.registerFullNameLabel),
            validator: (value) {
              final backendError = _backendFieldError('name');
              if (backendError != null) return backendError;
              if (value == null || value.trim().isEmpty) {
                return l10n.registerFullNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 30,
            decoration: InputDecoration(labelText: l10n.registerPhoneLabel),
            validator: (value) {
              final backendError = _backendFieldError('phone');
              if (backendError != null) return backendError;
              if (value == null || value.trim().isEmpty) {
                return l10n.registerPhoneValidatorRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.authEmailLabel),
            validator: (value) {
              final backendError = _backendFieldError('email');
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
          PasswordField(
            controller: _passwordController,
            labelText: l10n.authPasswordLabel,
            validator: (value) {
              final backendPasswordError = _backendPasswordError();
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
            labelText: l10n.registerConfirmPasswordLabel,
            validator: (value) {
              final backendError = _backendPasswordError().confirmationMismatch;
              if (backendError != null) return backendError;
              if (value == null || value.isEmpty) {
                return l10n.registerConfirmPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.authPasswordsMismatch;
              }
              return null;
            },
          ),
          // See LoginForm: only shown for errors that aren't per-field.
          if (authState is AuthError &&
              (authState.fieldErrors == null ||
                  authState.fieldErrors!.isEmpty)) ...[
            const SizedBox(height: 12),
            Text(
              authState.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.registerSubmitButton,
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
