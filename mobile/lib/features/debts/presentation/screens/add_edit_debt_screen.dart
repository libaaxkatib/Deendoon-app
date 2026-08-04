import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../quick_actions/domain/debt_draft.dart';
import '../providers/debt_actions.dart';
import '../providers/debt_detail_providers.dart';

/// Add/Edit Debt — one screen, two entry points (`customerId` set for Add,
/// `debtId` set for Edit), same pattern as `AddEditCustomerScreen`/
/// `ReminderScheduleScreen`. No screen for this exists in
/// `Mobile_UI_V1_Frozen.md` (Debts isn't one of its 5 documented screens,
/// same gap already noted by `debt_list_screen.dart`) — built with the
/// established Deendoon Design System components rather than a new mockup.
///
/// Fields mirror `StoreDebtRequest`/`UpdateDebtRequest` exactly: Add takes
/// `amount` (required, > 0), `due_date` (required), `notes` (optional).
/// FR-020: `amount` is immutable after creation — Edit only exposes
/// `due_date`/`notes`, with amount shown read-only. `store()` may attach a
/// `CREDIT_LIMIT_EXCEEDED` warning (BRL-023) — informational only, shown
/// as a dialog after the debt is already successfully created.
///
/// The "Invoice (Optional)" section (Scan/Upload) between Due Date and
/// Notes is UI-only — no invoice capture/upload endpoint exists yet, so
/// both actions use the app's existing `showComingSoon` convention rather
/// than a fake upload. Purely additive: does not touch `StoreDebtRequest`/
/// `UpdateDebtRequest`, validation, or the submit flow.
class AddEditDebtScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? debtId;

  /// When true (Add Case wizard's Debt Details step), the form validates
  /// and pops the route with a [DebtDraft] instead of calling
  /// `POST /customers/{id}/debts` — `customerId` is irrelevant in this
  /// mode since the customer may not exist yet (New Customer path).
  /// Actual creation is deferred to the wizard's Review step.
  final bool deferSubmit;

  const AddEditDebtScreen({super.key, this.customerId, this.debtId, this.deferSubmit = false});

  @override
  ConsumerState<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends ConsumerState<AddEditDebtScreen> {
  bool get _isEdit => widget.debtId != null;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dueDate;

  bool _prefilled = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillFromExisting(dynamic debt) {
    if (_prefilled) return;
    _prefilled = true;
    _amountController.text = debt.amount as String;
    _dueDate = DateTime.tryParse(debt.dueDate as String);
    _notesController.text = (debt.notes as String?) ?? '';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _showCreditLimitDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credit Limit Exceeded'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_dueDate == null) {
      setState(() => _error = 'Select a due date.');
      return;
    }

    final notes = _notesController.text.trim();

    if (widget.deferSubmit) {
      GoRouter.of(context).pop(DebtDraft(
        amount: _amountController.text.trim(),
        dueDate: _dateOnly(_dueDate!),
        notes: notes.isEmpty ? null : notes,
      ));
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      if (_isEdit) {
        await ref.read(debtActionsProvider).update(
              debtId: widget.debtId!,
              dueDate: _dateOnly(_dueDate!),
              notes: notes.isEmpty ? null : notes,
            );
        if (!mounted) return;
        setState(() => _isSaving = false);
        router.pop();
      } else {
        final result = await ref.read(debtActionsProvider).create(
              customerId: widget.customerId!,
              amount: _amountController.text.trim(),
              dueDate: _dateOnly(_dueDate!),
              notes: notes.isEmpty ? null : notes,
            );
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (result.warning != null) {
          await _showCreditLimitDialog(result.warning!.message);
        }
        if (mounted) router.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final debtAsync = ref.watch(debtDetailProvider(widget.debtId!));
      return debtAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Debt')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Debt')),
          body: const Center(child: Text('Could not load this debt.', style: AppTypography.body)),
        ),
        data: (debt) {
          _prefillFromExisting(debt);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final title = _isEdit ? 'Edit Debt' : (widget.deferSubmit ? 'Debt Details' : 'Add Debt');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit) ...[
              const Text('Amount', style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(_amountController.text, style: AppTypography.body),
              const SizedBox(height: 20),
            ] else
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
            const SizedBox(height: 20),
            const Text('Due Date', style: AppTypography.heading),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pickDueDate,
              child: Text(_dueDate == null ? 'Select Due Date' : _dateOnly(_dueDate!)),
            ),
            const SizedBox(height: 20),
            const Text('Invoice (Optional)', style: AppTypography.heading),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showComingSoon(context, 'Scan Invoice'),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: const Text('Scan Invoice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showComingSoon(context, 'Upload Invoice'),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Upload Invoice'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Notes', style: AppTypography.heading),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional notes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEdit ? 'Save Changes' : (widget.deferSubmit ? 'Continue' : 'Add Debt'),
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
