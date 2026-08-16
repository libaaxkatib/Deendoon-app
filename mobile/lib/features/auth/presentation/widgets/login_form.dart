import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (_formKey.currentState?.validate() != true) return;
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    // Rebuilding on the new AuthError alone doesn't re-run each field's
    // validator (Flutter only does that on an explicit validate() call) —
    // re-validate so a fresh per-field backend error actually renders.
    if (mounted) _formKey.currentState?.validate();
  }

  /// Reads backend field errors fresh (not the build-time [authState]
  /// closure) so a `clearError()` called just before `validate()` inside
  /// [_submit] is visible immediately, even though the widget hasn't
  /// rebuilt yet — see Mobile Fix #10.
  String? _backendFieldError(String key) {
    final state = ref.read(authProvider);
    return state is AuthError
        ? ApiException.fieldErrorFor(state.fieldErrors, key)
        : null;
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
              final backendError = _backendFieldError('password');
              if (backendError != null) return backendError;
              if (value == null || value.isEmpty) {
                return l10n.authPasswordRequired;
              }
              return null;
            },
          ),
          // Field-mappable errors already render on their own field above —
          // this fallback is only for errors that aren't per-field (e.g.
          // wrong credentials, rate limiting, a 5xx), so the same text
          // isn't shown twice.
          if (authState is AuthError &&
              (authState.fieldErrors == null ||
                  authState.fieldErrors!.isEmpty)) ...[
            const SizedBox(height: 12),
            Text(
              authState.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.forgotPassword),
              child: Text(l10n.loginForgotPasswordLink),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.loginSubmitButton,
            isLoading: isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.push(RoutePaths.register),
              child: Text(l10n.loginCreateAccountPrompt),
            ),
          ),
        ],
      ),
    );
  }
}
