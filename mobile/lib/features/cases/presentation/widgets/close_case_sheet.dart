import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/case_actions.dart';

/// Close Case — `POST /collection-cases/{id}/close`
/// (`CloseCollectionCaseRequest`: `closure_outcome` required, free text,
/// max 50 chars). There is no backend-enforced enum for the outcome value
/// (DD-024 is still pending per the controller's own docblock) — this is
/// a plain text field, not a fixed dropdown pretending to be
/// server-validated.
Future<void> showCloseCaseSheet(BuildContext context, String caseId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CloseCaseSheet(caseId: caseId),
  );
}

class _CloseCaseSheet extends ConsumerStatefulWidget {
  final String caseId;

  const _CloseCaseSheet({required this.caseId});

  @override
  ConsumerState<_CloseCaseSheet> createState() => _CloseCaseSheetState();
}

class _CloseCaseSheetState extends ConsumerState<_CloseCaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _outcomeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _outcomeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(caseActionsProvider).close(
            caseId: widget.caseId,
            closureOutcome: _outcomeController.text.trim(),
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
            Text(l10n.closeCaseTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outcomeController,
              maxLength: 50,
              decoration: InputDecoration(labelText: l10n.closeCaseSheetReasonLabel),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? l10n.closeCaseSheetReasonRequiredValidator : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            PrimaryButton(label: l10n.closeCaseTitle, isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
