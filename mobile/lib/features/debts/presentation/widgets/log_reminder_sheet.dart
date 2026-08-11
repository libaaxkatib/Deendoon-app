import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_actions.dart';

/// Log Manual Reminder (FR-030) — one shared sheet for all three real,
/// backend-supported channels (`POST /debts/{id}/reminders/{whatsapp,sms,
/// call}`), each taking an optional `details` field only (nullable per
/// `SendManualReminderRequest`/`LogCallRequest` — a call with no
/// answer/outcome is still a valid recordable attempt). Same modal-bottom-
/// sheet pattern as `close_case_sheet.dart`/`credit_limit_sheet.dart`.
///
/// Known behaviour: this does not send a WhatsApp message, send an SMS
/// message, or place a phone call. It only records that the communication
/// attempt happened, using the released backend endpoints. Actual message
/// delivery remains the responsibility of Reminder Center scheduling or
/// external communication channels — this is not that workflow.
Future<void> showLogReminderSheet(BuildContext context, String debtId, String channel) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LogReminderSheet(debtId: debtId, channel: channel),
  );
}

class _LogReminderSheet extends ConsumerStatefulWidget {
  final String debtId;
  final String channel;

  const _LogReminderSheet({required this.debtId, required this.channel});

  @override
  ConsumerState<_LogReminderSheet> createState() => _LogReminderSheetState();
}

class _LogReminderSheetState extends ConsumerState<_LogReminderSheet> {
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

    final details = _detailsController.text.trim();
    final actions = ref.read(debtActionsProvider);
    try {
      switch (widget.channel) {
        case 'whatsapp':
          await actions.logWhatsAppReminder(debtId: widget.debtId, details: details.isEmpty ? null : details);
        case 'sms':
          await actions.logSmsReminder(debtId: widget.debtId, details: details.isEmpty ? null : details);
        case 'call':
          await actions.logCallReminder(debtId: widget.debtId, details: details.isEmpty ? null : details);
      }
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
    final channelLabels = <String, String>{
      'whatsapp': l10n.debtTimelineStageWhatsappReminder,
      'sms': l10n.debtTimelineStageSmsReminder,
      'call': l10n.logReminderCallLabel,
    };
    final label = channelLabels[widget.channel] ?? widget.channel;

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
          Text(l10n.logReminderSheetTitle(label), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.logReminderDetailsLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: l10n.logReminderSheetTitle(label), isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }
}
