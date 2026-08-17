import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/auth_state.dart';
import '../../domain/google_registration_input.dart';
import '../providers/auth_provider.dart';

/// Mobile Fix #22 — Google Login, step 2. Collects the one field a Google
/// ID token can never supply (`business_name`) and re-sends the same
/// [GoogleRegistrationInput.idToken] the backend already verified once in
/// `googleLogin()` — `AuthController::googleRegister` independently
/// re-verifies it rather than trusting anything from that earlier call.
class GoogleRegisterForm extends ConsumerStatefulWidget {
  final GoogleRegistrationInput input;

  const GoogleRegisterForm({super.key, required this.input});

  @override
  ConsumerState<GoogleRegisterForm> createState() =>
      _GoogleRegisterFormState();
}

class _GoogleRegisterFormState extends ConsumerState<GoogleRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (_formKey.currentState?.validate() != true) return;
    await ref
        .read(authProvider.notifier)
        .completeGoogleRegistration(
          idToken: widget.input.idToken,
          businessName: _businessNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
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
          Text(
            l10n.googleRegisterInstructions(widget.input.email),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: l10n.googleRegisterPhoneLabel,
            ),
            validator: (_) => _backendFieldError('phone'),
          ),
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
            label: l10n.googleRegisterSubmitButton,
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
