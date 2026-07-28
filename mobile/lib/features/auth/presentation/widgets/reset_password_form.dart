import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../app/router/route_paths.dart';
import '../providers/auth_provider.dart';

/// Calls `POST /reset-password` directly through `AuthRepository`. Mirrors
/// `ResetPasswordRequest`'s exact fields — email, token, password,
/// password_confirmation. There is no deep-link handling in this app, so
/// the token emailed to the user is entered manually rather than parsed
/// from a link.
class ResetPasswordForm extends ConsumerStatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  ConsumerState<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await ref.read(authRepositoryProvider).resetPassword(
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
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Reset Code',
              helperText: 'The code sent to your email',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Reset code is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < _minPasswordLength) {
                return 'Password must be at least $_minPasswordLength characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password'),
            validator: (value) {
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          if (_errorMessage != null) ...[
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
            label: 'Reset Password',
            isLoading: _isLoading,
            onPressed: _successMessage == null ? _submit : null,
          ),
        ],
      ),
    );
  }
}
