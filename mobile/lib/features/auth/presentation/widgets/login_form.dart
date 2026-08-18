import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/google_auth/google_auth_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/remember_me_preference_storage.dart';
import '../../../../core/storage/remembered_credentials_storage.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/auth_state.dart';
import '../../domain/google_login_result.dart';
import '../../domain/google_registration_input.dart';
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
  bool _isGoogleLoading = false;

  /// Mobile QA Fix — Remember Me (Product Decision: 2026-08-18). Defaults
  /// to unchecked; restored from [RememberMePreferenceStorage] below.
  /// Governs three things together: whether the enclosing [AutofillGroup]
  /// commits or cancels the platform's own credential offer on dispose
  /// (its `onDisposeAction`, set in [build]), whether a successful login
  /// saves [_emailController]/[_passwordController] to
  /// [RememberedCredentialsStorage], and whether this screen restores them
  /// on its next mount.
  bool _rememberMe = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabled = await ref
          .read(rememberMePreferenceStorageProvider)
          .readEnabled();
      if (!mounted) return;
      if (enabled) {
        final credentials = ref.read(rememberedCredentialsStorageProvider);
        final email = await credentials.readEmail();
        final password = await credentials.readPassword();
        if (!mounted) return;
        if (email != null) _emailController.text = email;
        if (password != null) _passwordController.text = password;
      }
      setState(() => _rememberMe = enabled);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setRememberMe(bool? value) {
    final enabled = value ?? false;
    setState(() => _rememberMe = enabled);
    ref.read(rememberMePreferenceStorageProvider).saveEnabled(enabled);
    if (!enabled) {
      ref.read(rememberedCredentialsStorageProvider).clear();
    }
  }

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (_formKey.currentState?.validate() != true) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    await ref.read(authProvider.notifier).login(email, password);
    if (_rememberMe && ref.read(authProvider) is Authenticated) {
      await ref
          .read(rememberedCredentialsStorageProvider)
          .saveCredentials(email: email, password: password);
    }
    // Rebuilding on the new AuthError alone doesn't re-run each field's
    // validator (Flutter only does that on an explicit validate() call) —
    // re-validate so a fresh per-field backend error actually renders.
    if (mounted) _formKey.currentState?.validate();
  }

  /// Mobile Fix #22 — Google Login. `signIn()` returns `null` only on a
  /// user-initiated cancellation (a no-op, not an error); any other
  /// failure — misconfiguration, an invalid/expired token the backend
  /// rejects, an already-linked-by-password email — surfaces as a snackbar
  /// instead of the form's own per-field error UI, since there's no login
  /// form to attach it to.
  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
    final googleAuthService = ref.read(googleAuthServiceProvider);

    if (!googleAuthService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.googleLoginNotConfiguredMessage)),
      );
      return;
    }

    setState(() => _isGoogleLoading = true);
    try {
      final idToken = await googleAuthService.signIn();
      if (idToken == null) return;

      final result = await ref.read(authProvider.notifier).googleLogin(idToken);
      if (!mounted) return;

      if (result is GoogleLoginRegistrationRequired) {
        context.push(
          RoutePaths.googleRegister,
          extra: GoogleRegistrationInput(
            idToken: idToken,
            email: result.email,
            name: result.name,
          ),
        );
      }
      // GoogleLoginAuthenticated: AuthState is now Authenticated — the
      // router's redirect already sends the app to /home on its own.
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.detailedMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.googleLoginFailedMessage)));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
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
      child: AutofillGroup(
        onDisposeAction: _rememberMe
            ? AutofillContextAction.commit
            : AutofillContextAction.cancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
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
              autofillHints: const [AutofillHints.password],
              validator: (value) {
                final backendError = _backendFieldError('password');
                if (backendError != null) return backendError;
                if (value == null || value.isEmpty) {
                  return l10n.authPasswordRequired;
                }
                return null;
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _rememberMe,
              onChanged: _setRememberMe,
              title: Text(l10n.loginRememberMeLabel),
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
              onPressed: _isGoogleLoading ? null : _submit,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.authOrDivider),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: (isLoading || _isGoogleLoading)
                  ? null
                  : _handleGoogleSignIn,
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.googleLoginButton),
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
      ),
    );
  }
}
