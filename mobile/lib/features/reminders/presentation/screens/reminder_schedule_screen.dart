import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../customers/domain/customer.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_detail_providers.dart';
import '../widgets/customer_picker_sheet.dart';

const _reminderTypes = <String, String>{
  'client_visit': 'Client Visit',
  'follow_up_call': 'Follow-up Call',
  'payment_due': 'Payment Due',
  'contract_renewal': 'Contract Renewal',
  'promise_to_pay': 'Promise to Pay',
};

const _amountDueTypes = {'payment_due', 'promise_to_pay'};

const _timingRules = <String, String>{
  'one_day_before': '1 day before',
  'same_day': 'Same day',
  'one_hour_before': '1 hour before',
  'custom': 'Custom time',
};

const _deliveryMethodLabels = <String, String>{
  'in_app': 'In-App Notification',
  'push': 'Push Notification',
  'whatsapp': 'WhatsApp Message',
  'sms': 'SMS Message',
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

  const ReminderScheduleScreen({super.key, this.reminderId});

  @override
  ConsumerState<ReminderScheduleScreen> createState() => _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState extends ConsumerState<ReminderScheduleScreen> {
  bool get _isEdit => widget.reminderId != null;

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
    _relatedEntityLabel = '${reminder.relatedEntityType} (${reminder.relatedEntityId})';
    _dueDate = DateTime.tryParse(reminder.dueDate as String);
    _amountController.text = (reminder.amountDue as String?) ?? '';
    _timingRule = reminder.timingRule as String;
    final customFireAt = reminder.customFireAt as String?;
    _customFireAt = customFireAt != null ? DateTime.tryParse(customFireAt) : null;
    _deliveryMethods.addAll((reminder.deliveryMethods as List<String>));
    _notesController.text = (reminder.notes as String?) ?? '';
  }

  Future<void> _pickCustomer() async {
    final customer = await showCustomerPickerSheet(context);
    if (customer != null) setState(() => _selectedCustomer = customer);
  }

  Future<void> _pickDateTime({required DateTime? initial, required ValueChanged<DateTime> onPicked}) async {
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
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
    );
    if (time == null) return;

    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _isoOf(DateTime dt) => dt.toIso8601String();

  Future<void> _save() async {
    setState(() => _error = null);

    if (!_isEdit && _type == null) {
      setState(() => _error = 'Select a reminder type.');
      return;
    }
    if (!_isEdit && _selectedCustomer == null) {
      setState(() => _error = 'Select a customer.');
      return;
    }
    if (_dueDate == null) {
      setState(() => _error = 'Select a due date.');
      return;
    }
    if (_timingRule == 'custom' && _customFireAt == null) {
      setState(() => _error = 'Select a custom fire date/time.');
      return;
    }
    if (_timingRule == 'custom' && _customFireAt != null && _customFireAt!.isAfter(_dueDate!)) {
      setState(() => _error = 'Custom fire time must be on or before the due date.');
      return;
    }
    if (_deliveryMethods.isEmpty) {
      setState(() => _error = 'Select at least one delivery method.');
      return;
    }

    setState(() => _isSaving = true);
    final router = GoRouter.of(context);
    try {
      final amount = _amountController.text.trim();
      final carriesAmount = _type != null && _amountDueTypes.contains(_type);

      if (_isEdit) {
        await ref.read(reminderActionsProvider).update(
              id: widget.reminderId!,
              dueDate: _isoOf(_dueDate!),
              amountDue: carriesAmount && amount.isNotEmpty ? amount : null,
              timingRule: _timingRule,
              customFireAt: _timingRule == 'custom' ? _isoOf(_customFireAt!) : null,
              deliveryMethods: _deliveryMethods.toList(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
      } else {
        await ref.read(reminderActionsProvider).create(
              type: _type!,
              relatedEntityType: 'customer',
              relatedEntityId: _selectedCustomer!.id,
              dueDate: _isoOf(_dueDate!),
              amountDue: carriesAmount && amount.isNotEmpty ? amount : null,
              timingRule: _timingRule,
              customFireAt: _timingRule == 'custom' ? _isoOf(_customFireAt!) : null,
              deliveryMethods: _deliveryMethods.toList(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
    if (_isEdit) {
      final reminderAsync = ref.watch(reminderDetailProvider(widget.reminderId!));
      return reminderAsync.when(
        loading: () => Scaffold(appBar: AppBar(title: const Text('Reschedule')), body: const Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Reschedule')),
          body: const Center(child: Text('Could not load this reminder.', style: AppTypography.body)),
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
    final carriesAmount = _type != null && _amountDueTypes.contains(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Reschedule Reminder' : 'Schedule Reminder'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isEdit) ...[
            const Text('Reminder Type', style: AppTypography.heading),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _reminderTypes.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _type == entry.key,
                    onSelected: (_) => setState(() => _type = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Related To', style: AppTypography.heading),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pickCustomer,
              child: Text(_selectedCustomer?.name ?? 'Select Customer'),
            ),
          ] else ...[
            const Text('Type', style: AppTypography.heading),
            const SizedBox(height: 8),
            Text(_reminderTypes[_type] ?? _type ?? '', style: AppTypography.body),
            const SizedBox(height: 12),
            const Text('Related To', style: AppTypography.caption),
            const SizedBox(height: 4),
            Text(_relatedEntityLabel ?? '', style: AppTypography.body),
          ],
          const SizedBox(height: 20),
          const Text('Due Date', style: AppTypography.heading),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _pickDateTime(initial: _dueDate, onPicked: (dt) => setState(() => _dueDate = dt)),
            child: Text(_dueDate == null ? 'Select Due Date' : _dueDate!.toIso8601String()),
          ),
          if (carriesAmount) ...[
            const SizedBox(height: 20),
            const Text('Amount Due', style: AppTypography.heading),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
          ],
          const SizedBox(height: 20),
          const Text('When should this reminder be sent?', style: AppTypography.heading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _timingRules.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _timingRule == entry.key,
                  onSelected: (_) => setState(() => _timingRule = entry.key),
                ),
            ],
          ),
          if (_timingRule == 'custom') ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _pickDateTime(initial: _customFireAt, onPicked: (dt) => setState(() => _customFireAt = dt)),
              child: Text(_customFireAt == null ? 'Select Custom Fire Time' : _customFireAt!.toIso8601String()),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Delivery Methods', style: AppTypography.heading),
          const SizedBox(height: 12),
          for (final entry in _deliveryMethodLabels.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value),
              value: _deliveryMethods.contains(entry.key),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _deliveryMethods.add(entry.key);
                } else {
                  _deliveryMethods.remove(entry.key);
                }
              }),
            ),
          const SizedBox(height: 20),
          const Text('Notes', style: AppTypography.heading),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Optional notes'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save', isLoading: _isSaving, onPressed: _save),
        ],
      ),
    );
  }
}
