import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';

/// Add Case's entry point — a bottom sheet offering the two supported
/// starting points, same `showModalBottomSheet` pattern as
/// `record_payment_sheet.dart`/`close_case_sheet.dart`. Returns which path
/// the user chose (`'existing'`/`'new'`) so the caller can drive the rest
/// of the wizard; returns `null` if dismissed without a choice.
Future<String?> showAddCaseEntrySheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddCaseEntrySheet(),
  );
}

class _AddCaseEntrySheet extends StatelessWidget {
  const _AddCaseEntrySheet();

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
          Text('Add Case', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Existing Customer',
            onPressed: () => Navigator.of(context).pop('existing'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop('new'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('New Customer'),
            ),
          ),
        ],
      ),
    );
  }
}
