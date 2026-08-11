import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/storage_addon.dart';
import '../providers/subscription_actions.dart';

/// Confirm + collect `payment_reference` for `POST /subscription/
/// storage-addon-request` (`StorageAddonRequestRequest`: `storage_package`
/// one of 10gb/25gb/50gb/100gb, `payment_reference` required, max 100
/// chars) — same modal-bottom-sheet shape as
/// `showRequestPlanChangeSheet`/`showPromiseToPaySheet`.
///
/// Returns the real created `StorageAddon` (not just `true`) on success,
/// since it's the only way the caller ever learns this request's real id —
/// there is no Business-Owner-facing endpoint that lists pending Storage
/// Add-on requests (`SubscriptionController::storage()`'s `purchased_addons`
/// is active-only), so a Cancel action can only ever be offered for a
/// request created in the current session, using the id this call returns.
Future<StorageAddon?> showRequestStorageAddonSheet(BuildContext context, String storagePackage, String packageLabel) {
  return showModalBottomSheet<StorageAddon>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RequestStorageAddonSheet(storagePackage: storagePackage, packageLabel: packageLabel),
  );
}

class _RequestStorageAddonSheet extends ConsumerStatefulWidget {
  final String storagePackage;
  final String packageLabel;

  const _RequestStorageAddonSheet({required this.storagePackage, required this.packageLabel});

  @override
  ConsumerState<_RequestStorageAddonSheet> createState() => _RequestStorageAddonSheetState();
}

class _RequestStorageAddonSheetState extends ConsumerState<_RequestStorageAddonSheet> {
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
      final addon = await ref.read(subscriptionActionsProvider).requestStorageAddon(
            storagePackage: widget.storagePackage,
            paymentReference: _paymentReferenceController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(addon);
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
            Text(l10n.storageRequestAddonSheetTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.storageRequestAddonDescription(widget.packageLabel),
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
