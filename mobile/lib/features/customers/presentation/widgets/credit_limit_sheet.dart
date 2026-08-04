import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/customer_actions.dart';

/// Credit Limit quick-edit — the dedicated `PATCH /customers/{id}/credit-limit`
/// endpoint (`UpdateCustomerCreditLimitRequest`: `credit_limit` only), a
/// faster path than opening the full Edit Customer form just to change one
/// field. Same modal-bottom-sheet pattern as `close_case_sheet.dart`.
Future<void> showCreditLimitSheet(BuildContext context, String customerId, String currentCreditLimit) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CreditLimitSheet(customerId: customerId, currentCreditLimit: currentCreditLimit),
  );
}

class _CreditLimitSheet extends ConsumerStatefulWidget {
  final String customerId;
  final String currentCreditLimit;

  const _CreditLimitSheet({required this.customerId, required this.currentCreditLimit});

  @override
  ConsumerState<_CreditLimitSheet> createState() => _CreditLimitSheetState();
}

class _CreditLimitSheetState extends ConsumerState<_CreditLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _creditLimitController = TextEditingController(text: widget.currentCreditLimit);
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
      await ref.read(customerActionsProvider).updateCreditLimit(
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
            Text('Credit Limit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Credit Limit', hintText: '0.00'),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Enter a credit limit';
                final parsed = double.tryParse(trimmed);
                if (parsed == null || parsed < 0) return 'Enter a valid credit limit';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            PrimaryButton(label: 'Save', isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
