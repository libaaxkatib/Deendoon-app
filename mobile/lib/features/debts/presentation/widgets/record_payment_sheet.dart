import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/bottom_sheet_content.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_actions.dart';

/// Record Payment — `POST /debts/{id}/payments`
/// (`RecordPaymentRequest`: amount, payment_date, payment_method?,
/// reference_notes?).
Future<void> showRecordPaymentSheet(
  BuildContext context,
  String debtId,
  String customerId,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordPaymentSheet(debtId: debtId, customerId: customerId),
  );
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final String debtId;
  final String customerId;

  const _RecordPaymentSheet({required this.debtId, required this.customerId});

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _methodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(debtActionsProvider)
          .recordPayment(
            debtId: widget.debtId,
            customerId: widget.customerId,
            amount: _amountController.text.trim(),
            paymentDate: _paymentDate.toIso8601String().split('T').first,
            paymentMethod: _methodController.text.trim().isEmpty
                ? null
                : _methodController.text.trim(),
            referenceNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
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
              l10n.quickActionRecordPayment,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.addEditDebtAmountLabel,
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return l10n.addEditDebtAmountInvalidValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recordPaymentDateLabel),
              subtitle: Text(_paymentDate.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _methodController,
              decoration: InputDecoration(
                labelText: l10n.recordPaymentMethodLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.recordPaymentNotesLabel,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.recordPaymentSaveButton,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
