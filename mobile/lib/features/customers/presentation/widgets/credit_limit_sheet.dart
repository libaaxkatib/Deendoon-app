import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/bottom_sheet_content.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/customer_actions.dart';

/// Credit Limit quick-edit — the dedicated `PATCH /customers/{id}/credit-limit`
/// endpoint (`UpdateCustomerCreditLimitRequest`: `credit_limit` only), a
/// faster path than opening the full Edit Customer form just to change one
/// field. Same modal-bottom-sheet pattern as `close_case_sheet.dart`.
Future<void> showCreditLimitSheet(
  BuildContext context,
  String customerId,
  String currentCreditLimit,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CreditLimitSheet(
      customerId: customerId,
      currentCreditLimit: currentCreditLimit,
    ),
  );
}

class _CreditLimitSheet extends ConsumerStatefulWidget {
  final String customerId;
  final String currentCreditLimit;

  const _CreditLimitSheet({
    required this.customerId,
    required this.currentCreditLimit,
  });

  @override
  ConsumerState<_CreditLimitSheet> createState() => _CreditLimitSheetState();
}

class _CreditLimitSheetState extends ConsumerState<_CreditLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _creditLimitController = TextEditingController(
    text: widget.currentCreditLimit,
  );
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _creditLimitController.dispose();
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
          .read(customerActionsProvider)
          .updateCreditLimit(
            id: widget.customerId,
            creditLimit: _creditLimitController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BottomSheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.creditLimitSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.creditLimitLabel,
                hintText: l10n.creditLimitHint,
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return l10n.creditLimitRequiredValidator;
                final parsed = double.tryParse(trimmed);
                if (parsed == null || parsed < 0) {
                  return l10n.creditLimitInvalidValidator;
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: l10n.commonSave,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
