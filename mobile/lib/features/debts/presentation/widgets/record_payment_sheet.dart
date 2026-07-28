import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/debt_actions.dart';

/// Record Payment — `POST /debts/{id}/payments`
/// (`RecordPaymentRequest`: amount, payment_date, payment_method?,
/// reference_notes?).
Future<void> showRecordPaymentSheet(BuildContext context, String debtId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordPaymentSheet(debtId: debtId),
  );
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final String debtId;

  const _RecordPaymentSheet({required this.debtId});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _methodController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
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
      await ref.read(debtActionsProvider).recordPayment(
            debtId: widget.debtId,
            amount: _amountController.text.trim(),
            paymentDate: _paymentDate.toIso8601String().split('T').first,
            paymentMethod: _methodController.text.trim().isEmpty ? null : _methodController.text.trim(),
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
            Text('Record Payment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payment Date'),
              subtitle: Text(_paymentDate.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _methodController,
              decoration: const InputDecoration(labelText: 'Payment Method (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save Payment', isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
