import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Calls `POST /forgot-password` directly through `AuthRepository` — no
/// global session state is affected, so this manages its own local
/// loading/result state rather than going through `authProvider`.
class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
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
      final message = await ref
          .read(authRepositoryProvider)
          .forgotPassword(_emailController.text.trim());
      setState(() => _successMessage = message);
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
            enabled: _successMessage == null,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
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
            label: 'Send Reset Link',
            isLoading: _isLoading,
            onPressed: _successMessage == null ? _submit : null,
          ),
        ],
      ),
    );
  }
}
