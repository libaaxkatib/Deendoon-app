import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../debts/presentation/widgets/log_reminder_sheet.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_detail_providers.dart';
import '../providers/related_entity_provider.dart';
import '../widgets/reminder_type_icon.dart';

/// Reminder Details (§7.4): header with edit/delete icons; icon, title,
/// related entity name, due label; details list (Type, Due Date, Amount
/// Due, Related Case, Created By, Created On); Notes.
///
/// Deendoon V1 Reminder Workflow Update — actions below Notes are gated by
/// the two operational V1 reminder groupings:
/// - Client Visit (`type == 'client_visit'`): Navigate, Check In, Log
///   Visit Outcome, Mark as Completed. Must never show Phone Call/
///   WhatsApp/SMS.
/// - Follow-up (every other type): Phone Call, WhatsApp, SMS, plus the
///   existing Mark as Completed/Reschedule (unchanged, generic — not part
///   of this workflow update).
///
/// Navigate and Phone Call (non-debt case) are real device actions (maps/
/// dialer via `url_launcher`) using data already available (customer
/// name/phone/address) — no backend call involved either way. Navigate
/// prefers the customer's real `address` (Item 13) over a name-only text
/// search when one is on file. Phone Call for a
/// debt-related reminder reuses the existing, real, backend-persisted
/// FR-030 Log Reminder sheet (`POST /debts/{id}/reminders/call`) rather
/// than inventing a new logging path. Check In (P2.2) persists for real via
/// `PATCH /reminders/{id}/check-in`, storing `checked_in_at` on the
/// Reminder. Log Visit Outcome (final polish pass) now
/// persists for real: it reuses the existing `notes` field via the
/// already-real `PUT /reminders/{id}` endpoint (the same call Reschedule
/// makes for other fields) — no new backend API. `Created By` is shown as
/// a raw user id — there is no endpoint reachable by non-admin roles to
/// resolve a user id to a name (same gap as Assigned Officer on Collection
/// Cases, Sprint 13).
class ReminderDetailScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  ConsumerState<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  static const _amountDueTypes = {'payment_due', 'promise_to_pay'};

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reminderDetailDeleteDialogTitle),
        content: Text(l10n.reminderDetailDeleteDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.reminderDetailDeleteButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(reminderActionsProvider).delete(widget.reminderId);
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reminderActionsProvider).complete(widget.reminderId);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Opens the device's maps app. Prefers the customer's real `address`
  /// (Item 13) for a precise location; falls back to a text search on the
  /// customer's name when no address is on file (an older customer record,
  /// or one created without one — `address` is optional).
  Future<void> _navigate(BuildContext context, String? customerName, String? customerAddress) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final query = (customerAddress != null && customerAddress.trim().isNotEmpty) ? customerAddress : customerName;
    if (query == null || query.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDetailNoAddressMessage)));
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDetailMapsOpenError)));
    }
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reminderActionsProvider).checkIn(widget.reminderId);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _logVisitOutcome(BuildContext context, String? existingNotes) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LogVisitOutcomeSheet(reminderId: widget.reminderId, initialNotes: existingNotes),
    );
  }

  /// Snooze (P2.3): a quick reschedule shortcut distinct from both the full
  /// Reschedule form (Edit icon/Reschedule button — type, amount, timing
  /// rule, delivery methods, notes) and from Delete — it only ever pushes
  /// `due_date` forward via the same real `PUT /reminders/{id}` endpoint,
  /// leaving every other field untouched (`UpdateReminderRequest`'s fields
  /// are all `sometimes`).
  Future<void> _snooze(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SnoozeReminderSheet(reminderId: widget.reminderId),
    );
  }

  /// Places a call. When the reminder is debt-related, reuses the
  /// existing, real, backend-persisted FR-030 Log Reminder sheet
  /// (`POST /debts/{id}/reminders/call`) so the attempt is actually
  /// recorded. Otherwise falls back to launching the device dialer
  /// directly with the resolved customer's phone number (real action, no
  /// persistence — there is no non-debt call-logging endpoint).
  Future<void> _placeCall(BuildContext context, String relatedEntityType, String relatedEntityId, String? phone) async {
    if (relatedEntityType == 'debt') {
      await showLogReminderSheet(context, relatedEntityId, 'call');
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (phone == null || phone.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderNoPhoneNumberMessage)));
      return;
    }
    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderCouldNotOpenDialerMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reminderAsync = ref.watch(reminderDetailProvider(widget.reminderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminderDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: reminderAsync.valueOrNull == null
                ? null
                : () => context.push('/reminders/${widget.reminderId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: reminderAsync.valueOrNull == null ? null : () => _delete(context, ref),
          ),
        ],
      ),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RetrySection(
              message: l10n.reminderDetailLoadError,
              onRetry: () => ref.invalidate(reminderDetailProvider(widget.reminderId)),
            ),
          ),
        ),
        data: (reminder) {
          final relatedAsync =
              ref.watch(relatedEntityProvider('${reminder.relatedEntityType}:${reminder.relatedEntityId}'));
          final isCompleted = reminder.status == 'completed';
          final isClientVisit = reminder.type == 'client_visit';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ReminderTypeIcon(type: reminder.type, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reminder.title, style: AppTypography.subheading.copyWith(color: context.colors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          relatedAsync.valueOrNull?.name ?? '…',
                          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatFriendlyDateTimeFromIso(reminder.dueDate),
                          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: l10n.reminderDetailTypeLabel, value: reminder.title),
                    const SizedBox(height: 12),
                    _InfoRow(label: l10n.addEditDebtDueDateHeading, value: formatFriendlyDateTimeFromIso(reminder.dueDate)),
                    if (_amountDueTypes.contains(reminder.type) && reminder.amountDue != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(label: l10n.reminderDetailAmountDueLabel, value: formatFriendlyAmount(reminder.amountDue!)),
                    ],
                    if (reminder.relatedCaseId != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: l10n.reminderDetailRelatedCaseLabel,
                        value: l10n.reminderDetailViewCaseLabel,
                        onTap: () => context.push('/cases/${reminder.relatedCaseId}'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: l10n.reminderDetailCreatedByLabel,
                      value: l10n.reminderDetailCreatedByValue(reminder.createdByUserId),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: l10n.reminderDetailCreatedOnLabel, value: formatFriendlyDateTimeFromIso(reminder.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.addEditDebtNotesHeading, style: AppTypography.heading.copyWith(color: context.colors.textPrimary)),
              const SizedBox(height: 12),
              AppCard(
                child: Text(
                  (reminder.notes?.trim().isNotEmpty ?? false) ? reminder.notes! : l10n.reminderDetailNoNotesMessage,
                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
              ),
              const SizedBox(height: 24),
              if (isClientVisit) ...[
                OutlinedButton.icon(
                  onPressed: () => _navigate(context, relatedAsync.valueOrNull?.name, relatedAsync.valueOrNull?.address),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(l10n.reminderDetailNavigateButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: reminder.checkedInAt != null ? null : () => _checkIn(context, ref),
                  icon: Icon(reminder.checkedInAt != null ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(reminder.checkedInAt != null ? l10n.reminderDetailCheckedInLabel : l10n.reminderDetailCheckInButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _logVisitOutcome(context, reminder.notes),
                  icon: const Icon(Icons.notes_outlined),
                  label: Text(l10n.reminderDetailLogVisitOutcomeLabel),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isCompleted ? null : () => _snooze(context),
                  icon: const Icon(Icons.snooze_outlined),
                  label: Text(l10n.reminderDetailSnoozeButton),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isCompleted ? null : () => _complete(context, ref),
                  child: Text(l10n.reminderDetailMarkCompletedButton),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _CommunicationActionButton(
                        icon: Icons.call_outlined,
                        label: l10n.logReminderCallLabel,
                        onPressed: () => _placeCall(
                          context,
                          reminder.relatedEntityType,
                          reminder.relatedEntityId,
                          relatedAsync.valueOrNull?.phone,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CommunicationActionButton(
                        icon: Icons.chat_outlined,
                        label: l10n.reminderDetailWhatsAppButton,
                        onPressed: () => context.push('/reminders/${widget.reminderId}/send?channel=whatsapp'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CommunicationActionButton(
                        icon: Icons.sms_outlined,
                        label: l10n.reminderDetailSmsButton,
                        onPressed: () => context.push('/reminders/${widget.reminderId}/send?channel=sms'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isCompleted ? null : () => _complete(context, ref),
                  child: Text(l10n.reminderDetailMarkCompletedButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isCompleted ? null : () => _snooze(context),
                  icon: const Icon(Icons.snooze_outlined),
                  label: Text(l10n.reminderDetailSnoozeButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                  onPressed: () => context.push('/reminders/${widget.reminderId}/edit'),
                  child: Text(l10n.reminderDetailRescheduleButton),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Compact icon+label button for the Follow-up Call/WhatsApp/SMS row.
/// Tighter padding and a fixed single-line label than the default
/// `OutlinedButton.icon` fixes "WhatsApp" wrapping to two lines at this
/// button's width (final polish pass).
class _CommunicationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CommunicationActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12)),
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// Log Visit Outcome (Client Visit workflow). Reuses the existing, real
/// `notes` field via the already-real `PUT /reminders/{id}` endpoint (the
/// same partial-update call Reschedule already makes for other fields) —
/// no new backend API, no schema change. Pre-filled with any existing
/// notes so Save doesn't silently overwrite them.
class _LogVisitOutcomeSheet extends ConsumerStatefulWidget {
  final String reminderId;
  final String? initialNotes;

  const _LogVisitOutcomeSheet({required this.reminderId, this.initialNotes});

  @override
  ConsumerState<_LogVisitOutcomeSheet> createState() => _LogVisitOutcomeSheetState();
}

class _LogVisitOutcomeSheetState extends ConsumerState<_LogVisitOutcomeSheet> {
  late final _outcomeController = TextEditingController(text: widget.initialNotes ?? '');
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _outcomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(reminderActionsProvider).update(id: widget.reminderId, notes: _outcomeController.text.trim());
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDetailVisitOutcomeSavedMessage)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          Text(l10n.reminderDetailLogVisitOutcomeLabel, style: AppTypography.heading.copyWith(color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: _outcomeController,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.reminderDetailLogVisitOutcomeHint),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

/// Snooze (P2.3). Quick presets compute a new due date relative to *now*
/// (the conventional meaning of "snooze"), plus a custom date/time picker
/// for anything else. Persists via the same real, generic `PUT
/// /reminders/{id}` endpoint Reschedule uses, sending only `due_date` —
/// every other field (type, amount, timing rule, delivery methods, notes)
/// is left untouched server-side since `UpdateReminderRequest`'s fields
/// are all `sometimes`.
class _SnoozeReminderSheet extends ConsumerStatefulWidget {
  final String reminderId;

  const _SnoozeReminderSheet({required this.reminderId});

  @override
  ConsumerState<_SnoozeReminderSheet> createState() => _SnoozeReminderSheetState();
}

class _SnoozeReminderSheetState extends ConsumerState<_SnoozeReminderSheet> {
  bool _isSaving = false;
  String? _error;

  Future<void> _snoozeUntil(DateTime dueDate) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(reminderActionsProvider).update(id: widget.reminderId, dueDate: dueDate.toIso8601String());
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderSnoozedUntilMessage(formatFriendlyDateTime(dueDate)))));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 5));
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;

    await _snoozeUntil(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

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
          Text(l10n.reminderSnoozeSheetTitle, style: AppTypography.heading.copyWith(color: context.colors.textPrimary)),
          const SizedBox(height: 16),
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else ...[
            OutlinedButton(
              onPressed: () => _snoozeUntil(now.add(const Duration(hours: 1))),
              child: Text(l10n.reminderSnoozeOneHour),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _snoozeUntil(DateTime(now.year, now.month, now.day + 1, 9, 0)),
              child: Text(l10n.reminderSnoozeTomorrow),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _snoozeUntil(now.add(const Duration(days: 7))),
              child: Text(l10n.reminderSnoozeNextWeek),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _pickCustom,
              child: Text(l10n.reminderSnoozePickDateTime),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: onTap != null ? AppColors.primary : context.colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
