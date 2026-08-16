import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../customers/domain/customer.dart';
import '../../domain/reminder_entity_preset.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_detail_providers.dart';
import '../widgets/customer_picker_sheet.dart';

const _reminderTypeKeys = <String>[
  'client_visit',
  'follow_up_call',
  'payment_due',
  'contract_renewal',
  'promise_to_pay',
];

String _reminderTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'client_visit' => l10n.reminderTypeClientVisit,
  'follow_up_call' => l10n.reminderTypeFollowUpCall,
  'payment_due' => l10n.reminderTypePaymentDue,
  'contract_renewal' => l10n.reminderTypeContractRenewal,
  'promise_to_pay' => l10n.promiseToPayTitle,
  _ => type,
};

const _amountDueTypes = {'payment_due', 'promise_to_pay'};

const _timingRuleKeys = <String>[
  'one_day_before',
  'same_day',
  'one_hour_before',
  'custom',
];

String _timingRuleLabel(AppLocalizations l10n, String rule) => switch (rule) {
  'one_day_before' => l10n.reminderTimingOneDayBefore,
  'same_day' => l10n.reminderTimingSameDay,
  'one_hour_before' => l10n.reminderTimingOneHourBefore,
  'custom' => l10n.reminderTimingCustomTime,
  _ => rule,
};

const _deliveryMethodKeys = <String>['in_app', 'push', 'whatsapp', 'sms'];

String _deliveryMethodLabel(AppLocalizations l10n, String method) =>
    switch (method) {
      'in_app' => l10n.reminderDeliveryInApp,
      'push' => l10n.reminderDeliveryPush,
      'whatsapp' => l10n.reminderDeliveryWhatsApp,
      'sms' => l10n.reminderDeliverySms,
      _ => method,
    };

/// Reminder Scheduling (§7.5) — one screen, two entry points: bare
/// creation (from the "+" icon on the Reminders tab; `reminderId` null)
/// and Edit/Reschedule (from Reminder Details' edit icon or Reschedule
/// button; `reminderId` set). The frozen spec's §7.5 layout only
/// describes the timing/delivery portion (the novel part of this
/// screen) — Type, Related To, Due Date, Amount Due, and Notes are real
/// fields on the same backend `Reminder` (§7.2/§7.4 already name them as
/// real, approved concepts), included here since a create/edit form
/// cannot omit backend-required fields. Per §7.9's business rule ("a
/// rescheduled reminder retains its original creation record... while
/// adopting a new due date and timing rule"), Type and Related To are
/// fixed/read-only once a reminder exists — only Due Date, Amount Due,
/// Timing Rule, Custom Fire At, Delivery Methods, and Notes are editable
/// on Reschedule.
class ReminderScheduleScreen extends ConsumerStatefulWidget {
  final String? reminderId;

  /// Entity-Aware Reminder Creation (P2.4): when set (only meaningful for
  /// bare creation, `reminderId == null`), "Related To" is pre-filled and
  /// locked to this entity instead of showing the generic customer-picker.
  final ReminderEntityPreset? entityPreset;

  const ReminderScheduleScreen({super.key, this.reminderId, this.entityPreset});

  @override
  ConsumerState<ReminderScheduleScreen> createState() =>
      _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState
    extends ConsumerState<ReminderScheduleScreen> {
  bool get _isEdit => widget.reminderId != null;
  bool get _hasEntityPreset => widget.entityPreset != null;

  bool _prefilled = false;
  String? _type;
  Customer? _selectedCustomer;
  String? _relatedEntityLabel;
  DateTime? _dueDate;
  final _amountController = TextEditingController();
  String _timingRule = 'one_day_before';
  DateTime? _customFireAt;
  final Set<String> _deliveryMethods = {};
  final _notesController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillFromExisting(dynamic reminder) {
    if (_prefilled) return;
    _prefilled = true;
    _type = reminder.type as String;
    _relatedEntityLabel =
        '${reminder.relatedEntityType} (${reminder.relatedEntityId})';
    _dueDate = DateTime.tryParse(reminder.dueDate as String);
    _amountController.text = (reminder.amountDue as String?) ?? '';
    _timingRule = reminder.timingRule as String;
    final customFireAt = reminder.customFireAt as String?;
    _customFireAt = customFireAt != null
        ? DateTime.tryParse(customFireAt)
        : null;
    _deliveryMethods.addAll((reminder.deliveryMethods as List<String>));
    _notesController.text = (reminder.notes as String?) ?? '';
  }

  Future<void> _pickCustomer() async {
    final customer = await showCustomerPickerSheet(context);
    if (customer != null) setState(() => _selectedCustomer = customer);
  }

  Future<void> _pickDateTime({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay.fromDateTime(initial)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _isoOf(DateTime dt) => dt.toIso8601String();

  Future<void> _save() async {
    setState(() => _error = null);
    final l10n = AppLocalizations.of(context);

    if (!_isEdit && _type == null) {
      setState(() => _error = l10n.reminderScheduleTypeRequiredValidator);
      return;
    }
    if (!_isEdit && !_hasEntityPreset && _selectedCustomer == null) {
      setState(() => _error = l10n.reminderScheduleCustomerRequiredValidator);
      return;
    }
    if (_dueDate == null) {
      setState(() => _error = l10n.addEditDebtDueDateRequiredError);
      return;
    }
    if (_timingRule == 'custom' && _customFireAt == null) {
      setState(() => _error = l10n.reminderScheduleCustomFireRequiredValidator);
      return;
    }
    if (_timingRule == 'custom' &&
        _customFireAt != null &&
        _customFireAt!.isAfter(_dueDate!)) {
      setState(
        () => _error = l10n.reminderScheduleCustomFireBeforeDueValidator,
      );
      return;
    }
    if (_deliveryMethods.isEmpty) {
      setState(
        () => _error = l10n.reminderScheduleDeliveryMethodRequiredValidator,
      );
      return;
    }

    setState(() => _isSaving = true);
    final router = GoRouter.of(context);
    try {
      final amount = _amountController.text.trim();
      final carriesAmount = _type != null && _amountDueTypes.contains(_type);

      if (_isEdit) {
        await ref
            .read(reminderActionsProvider)
            .update(
              id: widget.reminderId!,
              dueDate: _isoOf(_dueDate!),
              amountDue: carriesAmount && amount.isNotEmpty ? amount : null,
              timingRule: _timingRule,
              customFireAt: _timingRule == 'custom'
                  ? _isoOf(_customFireAt!)
                  : null,
              deliveryMethods: _deliveryMethods.toList(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      } else {
        await ref
            .read(reminderActionsProvider)
            .create(
              type: _type!,
              relatedEntityType: _hasEntityPreset
                  ? widget.entityPreset!.type
                  : 'customer',
              relatedEntityId: _hasEntityPreset
                  ? widget.entityPreset!.id
                  : _selectedCustomer!.id,
              dueDate: _isoOf(_dueDate!),
              amountDue: carriesAmount && amount.isNotEmpty ? amount : null,
              timingRule: _timingRule,
              customFireAt: _timingRule == 'custom'
                  ? _isoOf(_customFireAt!)
                  : null,
              deliveryMethods: _deliveryMethods.toList(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      }
      if (mounted) router.pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isEdit) {
      final reminderAsync = ref.watch(
        reminderDetailProvider(widget.reminderId!),
      );
      return reminderAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            title: Text(l10n.reminderScheduleRescheduleLoadingTitle),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.reminderScheduleRescheduleLoadingTitle),
          ),
          body: Center(
            child: Text(
              l10n.reminderDetailLoadError,
              style: AppTypography.body,
            ),
          ),
        ),
        data: (reminder) {
          _prefillFromExisting(reminder);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final carriesAmount = _type != null && _amountDueTypes.contains(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? l10n.reminderScheduleRescheduleTitle
              : l10n.reminderScheduleTitle,
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
              Text(
                l10n.reminderScheduleTypeHeading,
                style: AppTypography.heading,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final typeKey in _reminderTypeKeys)
                    ChoiceChip(
                      label: Text(_reminderTypeLabel(l10n, typeKey)),
                      selected: _type == typeKey,
                      onSelected: (_) => setState(() => _type = typeKey),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reminderScheduleRelatedToHeading,
                style: AppTypography.heading,
              ),
              const SizedBox(height: 12),
              if (_hasEntityPreset)
                Text(widget.entityPreset!.label, style: AppTypography.body)
              else
                OutlinedButton(
                  onPressed: _pickCustomer,
                  child: Text(
                    _selectedCustomer?.name ?? l10n.customerListSelectTitle,
                  ),
                ),
            ] else ...[
              Text(l10n.reminderDetailTypeLabel, style: AppTypography.heading),
              const SizedBox(height: 8),
              Text(
                _type != null ? _reminderTypeLabel(l10n, _type!) : '',
                style: AppTypography.body,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.reminderScheduleRelatedToHeading,
                style: AppTypography.caption,
              ),
              const SizedBox(height: 4),
              Text(_relatedEntityLabel ?? '', style: AppTypography.body),
            ],
            const SizedBox(height: 20),
            Text(l10n.addEditDebtDueDateHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _pickDateTime(
                initial: _dueDate,
                onPicked: (dt) => setState(() => _dueDate = dt),
              ),
              child: Text(
                _dueDate == null
                    ? l10n.addEditDebtSelectDueDateButton
                    : formatFriendlyDateTime(_dueDate!),
              ),
            ),
            if (carriesAmount) ...[
              const SizedBox(height: 20),
              Text(
                l10n.reminderDetailAmountDueLabel,
                style: AppTypography.heading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(hintText: l10n.creditLimitHint),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.reminderScheduleTimingHeading,
              style: AppTypography.heading,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ruleKey in _timingRuleKeys)
                  ChoiceChip(
                    label: Text(_timingRuleLabel(l10n, ruleKey)),
                    selected: _timingRule == ruleKey,
                    onSelected: (_) => setState(() => _timingRule = ruleKey),
                  ),
              ],
            ),
            if (_timingRule == 'custom') ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _pickDateTime(
                  initial: _customFireAt,
                  onPicked: (dt) => setState(() => _customFireAt = dt),
                ),
                child: Text(
                  _customFireAt == null
                      ? l10n.reminderScheduleSelectCustomFireTimeButton
                      : formatFriendlyDateTime(_customFireAt!),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.reminderScheduleDeliveryMethodsHeading,
              style: AppTypography.heading,
            ),
            const SizedBox(height: 12),
            for (final methodKey in _deliveryMethodKeys)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_deliveryMethodLabel(l10n, methodKey)),
                value: _deliveryMethods.contains(methodKey),
                onChanged: (checked) => setState(() {
                  if (checked ?? false) {
                    _deliveryMethods.add(methodKey);
                  } else {
                    _deliveryMethods.remove(methodKey);
                  }
                }),
              ),
            const SizedBox(height: 20),
            Text(l10n.addEditDebtNotesHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.addEditDebtNotesHint),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.commonSave,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
