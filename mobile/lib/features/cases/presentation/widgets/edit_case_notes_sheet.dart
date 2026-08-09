import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/case_actions.dart';

/// Edit Notes — `PUT /collection-cases/{id}` (`UpdateCollectionCaseRequest`:
/// `notes` nullable free text, no length limit server-side). Notes is
/// editable regardless of Case status — `CollectionCasePolicy::manage`
/// only checks role and the Customer's read-only state, not `case_status`.
Future<void> showEditCaseNotesSheet(BuildContext context, String caseId, {String? currentNotes}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditCaseNotesSheet(caseId: caseId, currentNotes: currentNotes),
  );
}

class _EditCaseNotesSheet extends ConsumerStatefulWidget {
  final String caseId;
  final String? currentNotes;

  const _EditCaseNotesSheet({required this.caseId, required this.currentNotes});

  @override
  ConsumerState<_EditCaseNotesSheet> createState() => _EditCaseNotesSheetState();
}

class _EditCaseNotesSheetState extends ConsumerState<_EditCaseNotesSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _notesController = TextEditingController(text: widget.currentNotes ?? '');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trimmed = _notesController.text.trim();
      await ref.read(caseActionsProvider).updateNotes(
            caseId: widget.caseId,
            notes: trimmed.isEmpty ? null : trimmed,
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
            Text('Edit Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 5,
              minLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            PrimaryButton(label: 'Save Notes', isLoading: _isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
