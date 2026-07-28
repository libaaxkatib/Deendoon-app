import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/debt_actions.dart';

/// Promise to Pay — `POST /debts/{id}/promise-to-pay`
/// (`RecordPromiseToPayRequest`: promised_date, must be today or later).
Future<void> showPromiseToPaySheet(BuildContext context, String debtId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PromiseToPaySheet(debtId: debtId),
  );
}

class _PromiseToPaySheet extends ConsumerStatefulWidget {
  final String debtId;

  const _PromiseToPaySheet({required this.debtId});

  @override
  ConsumerState<_PromiseToPaySheet> createState() => _PromiseToPaySheetState();
}

class _PromiseToPaySheetState extends ConsumerState<_PromiseToPaySheet> {
  DateTime _promisedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _promisedDate.isBefore(today) ? today : _promisedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _promisedDate = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(debtActionsProvider).promiseToPay(
            debtId: widget.debtId,
            promisedDate: _promisedDate.toIso8601String().split('T').first,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Promise to Pay', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promised Date'),
            subtitle: Text(_promisedDate.toIso8601String().split('T').first),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: _pickDate,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save Promise', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }
}
