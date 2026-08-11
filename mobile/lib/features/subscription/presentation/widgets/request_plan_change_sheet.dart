import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/subscription_plan.dart';
import '../providers/subscription_actions.dart';

/// Confirm + collect `payment_reference` for `POST /subscription/
/// upgrade-request` (`SubscriptionUpgradeRequestRequest`: both fields
/// required, `payment_reference` max 100 chars) — same modal-bottom-sheet
/// shape as `showPromiseToPaySheet`: local loading/error state, pops with
/// `true` only on a real success, leaves the sheet open with an inline
/// error otherwise. No "Upgrade"/"Downgrade" wording anywhere — a plan
/// change request is valid in either price direction, and nothing here
/// assumes one.
Future<bool?> showRequestPlanChangeSheet(BuildContext context, SubscriptionPlan plan) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RequestPlanChangeSheet(plan: plan),
  );
}

class _RequestPlanChangeSheet extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;

  const _RequestPlanChangeSheet({required this.plan});

  @override
  ConsumerState<_RequestPlanChangeSheet> createState() => _RequestPlanChangeSheetState();
}

class _RequestPlanChangeSheetState extends ConsumerState<_RequestPlanChangeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _paymentReferenceController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _paymentReferenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(subscriptionActionsProvider).requestUpgrade(
            requestedPlanId: widget.plan.id,
            paymentReference: _paymentReferenceController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.subscriptionRequestPlanChangeSheetTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.subscriptionRequestPlanChangeDescription(widget.plan.name, widget.plan.monthlyPrice),
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentReferenceController,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.subscriptionPaymentReferenceLabel),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return l10n.subscriptionPaymentReferenceRequiredValidator;
                if (trimmed.length > 100) return l10n.subscriptionPaymentReferenceMaxLengthValidator;
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            PrimaryButton(label: l10n.professionalCollectionSubmitButton, isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
