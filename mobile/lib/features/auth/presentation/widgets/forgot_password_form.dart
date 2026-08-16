import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
  Map<String, dynamic>? _fieldErrors;

  @override
  void dispose() {
    _emailController.dispose();
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
          .forgotPassword(_emailController.text.trim());
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
          // Field-mappable errors already render on the email field above —
          // this fallback is only for errors that aren't per-field.
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
            label: l10n.forgotPasswordSubmitButton,
            isLoading: _isLoading,
            onPressed: _successMessage == null ? _submit : null,
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push(
                  RoutePaths.resetPassword,
                  extra: _emailController.text.trim(),
                ),
                child: Text(l10n.forgotPasswordHaveCodeLink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
