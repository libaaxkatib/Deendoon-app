import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../account/presentation/providers/business_profile_providers.dart';
import '../../domain/subscription_plan.dart';
import '../providers/subscription_actions.dart';

/// Manual Mobile-Money Subscription Payment Flow (Product Owner decision;
/// Transaction Reference removed per real-device testing feedback).
/// "Choose Plan -> Payment Information" step. Collects only the
/// mobile-money phone number the payment will be sent from
/// (`payment_phone`, required) — no transaction reference is collected
/// here; `paymentReference` is always sent as `null`
/// (`SubscriptionUpgradeRequestRequest` already validates it as nullable,
/// so this is a pure UI simplification, not a backend change). The
/// selected Plan and Amount are auto-populated from [plan] and shown
/// read-only — the user never re-enters them — and the tenant's own
/// Business Name (from `businessProfileProvider`) is shown read-only for
/// confirmation, never collected as input.
///
/// On success this only ever creates a Pending Subscription Change
/// Request (`SubscriptionActions.requestUpgrade`, unchanged) and replaces
/// itself with `PaymentSavedScreen` — it never assumes or simulates a
/// successful payment.
class PaymentInformationScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const PaymentInformationScreen({super.key, required this.plan});

  @override
  ConsumerState<PaymentInformationScreen> createState() =>
      _PaymentInformationScreenState();
}

class _PaymentInformationScreenState
    extends ConsumerState<PaymentInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentPhoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(subscriptionActionsProvider)
          .requestUpgrade(
            requestedPlanId: widget.plan.id,
            paymentPhone: _paymentPhoneController.text.trim(),
            paymentReference: null,
          );
      if (!mounted) return;
      context.pushReplacement('/account/subscription/payment-saved');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentInformationTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final businessProfileAsync = ref.watch(
                      businessProfileProvider,
                    );
                    return _ReadOnlyField(
                      label: l10n.paymentInformationBusinessNameLabel,
                      value: businessProfileAsync.when(
                        data: (profile) => profile.businessName,
                        loading: () => '…',
                        error: (_, _) => '—',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: l10n.paymentInformationPlanLabel,
                  value: widget.plan.name,
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: l10n.paymentInformationAmountLabel,
                  value: widget.plan.monthlyPrice,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _paymentPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: l10n.paymentInformationPhoneLabel,
                    hintText: l10n.paymentInformationPhoneHint,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return l10n.paymentInformationPhoneRequiredValidator;
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  label: l10n.paymentInformationContinueButton,
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

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body.copyWith(color: context.colors.textPrimary),
        ),
      ],
    );
  }
}
