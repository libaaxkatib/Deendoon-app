import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/customer_actions.dart';

/// FR-012/SCR-008 — Change Customer Status. `UpdateCustomerStatusRequest`:
/// `customer_status` required, one of the real 7-value CHECK constraint
/// set (not a free-text field) — same modal-bottom-sheet pattern as
/// `credit_limit_sheet.dart`, a `RadioListTile` group instead of a text
/// field since the value set is fixed and small.
const customerStatusOptions = <String, String>{
  'active': 'Active',
  'good_standing': 'Good Standing',
  'late_payer': 'Late Payer',
  'high_risk': 'High Risk',
  'in_collection': 'In Collection',
  'recovered': 'Recovered',
  'blocked': 'Blocked',
};

Future<void> showCustomerStatusSheet(BuildContext context, String customerId, String currentStatus) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CustomerStatusSheet(customerId: customerId, currentStatus: currentStatus),
  );
}

class _CustomerStatusSheet extends ConsumerStatefulWidget {
  final String customerId;
  final String currentStatus;

  const _CustomerStatusSheet({required this.customerId, required this.currentStatus});

  @override
  ConsumerState<_CustomerStatusSheet> createState() => _CustomerStatusSheetState();
}

class _CustomerStatusSheetState extends ConsumerState<_CustomerStatusSheet> {
  late String _selected = widget.currentStatus;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(customerActionsProvider).updateStatus(id: widget.customerId, customerStatus: _selected);
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
          Text('Customer Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value!),
            child: Column(
              children: [
                for (final entry in customerStatusOptions.entries)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    value: entry.key,
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: 'Save', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }
}
