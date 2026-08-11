import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/case_actions.dart';

/// Backs Add Follow-up, Mark Contacted, and Record Visit — all three are
/// the exact same real endpoint, `POST /collection-cases/{id}/activities`
/// (`RecordCollectionActivityRequest`: one optional free-text `details`
/// field, max 1000 chars). The backend writes every call under the same
/// generic `action_type='collection_activity'` — it cannot structurally
/// distinguish a follow-up from a contact from a visit. The `label`
/// prefix below (e.g. "Contacted — ") is a client-side convention only,
/// baked into the free-text `details` so the real Timeline stays
/// readable — it is not a backend-enforced field (see the Sprint 13
/// summary's "Missing Backend Support Required").
Future<void> showRecordActivitySheet(BuildContext context, String caseId, {required String title, String? label}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordActivitySheet(caseId: caseId, title: title, label: label),
  );
}

class _RecordActivitySheet extends ConsumerStatefulWidget {
  final String caseId;
  final String title;
  final String? label;

  const _RecordActivitySheet({required this.caseId, required this.title, required this.label});

  @override
  ConsumerState<_RecordActivitySheet> createState() => _RecordActivitySheetState();
}

class _RecordActivitySheetState extends ConsumerState<_RecordActivitySheet> {
  final _detailsController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final text = _detailsController.text.trim();
    final details = widget.label == null
        ? (text.isEmpty ? null : text)
        : (text.isEmpty ? widget.label : '${widget.label} — $text');

    try {
      await ref.read(caseActionsProvider).recordActivity(caseId: widget.caseId, details: details);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            maxLength: 1000,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.recordPaymentNotesLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: l10n.commonSave, isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }
}
