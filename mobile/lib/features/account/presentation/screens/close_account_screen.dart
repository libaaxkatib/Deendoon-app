import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Self-service "Close Account" — `POST /account/close`
/// (`AccountClosureService::close()`): archives the Business Owner and
/// suspends their tenant, keeping every business/financial/document
/// record intact. Reversible only by Deendoon Support/a Platform
/// Administrator, never by the Business Owner themselves — the warning
/// text below and the confirmation dialog both say this plainly.
///
/// Two layers of confirmation, matching what already exists elsewhere in
/// this app rather than inventing a new pattern: password re-entry (the
/// same ownership-proof `ChangePasswordScreen` already uses) plus a
/// Cancel/Confirm `AlertDialog` (the same pattern
/// `ReminderDetailScreen`'s delete action already uses).
class CloseAccountScreen extends ConsumerStatefulWidget {
  const CloseAccountScreen({super.key});

  @override
  ConsumerState<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends ConsumerState<CloseAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = null);
    if (_formKey.currentState?.validate() != true) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.closeAccountConfirmDialogTitle),
        content: Text(l10n.closeAccountConfirmDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.closeAccountConfirmButton,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .closeAccount(_passwordController.text);
      // No explicit navigation: closeAccount() transitions authProvider to
      // Unauthenticated, and the router's own redirect (already reactive
      // to auth state, same as forceLogout()) takes it from here.
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.detailedMessage;
          _fieldErrors = e.fieldErrors;
        });
        _formKey.currentState?.validate();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.closeAccountTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.closeAccountWarningHeading,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.closeAccountWarningBody),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _passwordController,
                  labelText: l10n.closeAccountPasswordLabel,
                  validator: (value) {
                    final backendError = ApiException.fieldErrorFor(
                      _fieldErrors,
                      'password',
                    );
                    if (backendError != null) return backendError;
                    if (value == null || value.isEmpty) {
                      return l10n.closeAccountPasswordRequired;
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
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l10n.closeAccountButton,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
