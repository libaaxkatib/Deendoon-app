import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attachments/data/attachment_repository.dart';
import '../../../attachments/presentation/providers/attachment_providers.dart';
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
/// Notes reuses the same real attachment architecture as Debt Detail's own
/// Scan/Upload Invoice buttons (`POST /debts/{id}/attachments`, tagged
/// `description: 'Invoice'`) — V1 scope only: capture/pick a file and
/// attach it, no OCR, no invoice-data extraction, no manual metadata form.
/// A new Debt has no id until it's created, so the file is only picked
/// here and uploaded right after a successful save: immediately for Edit
/// (the id is already known) and Add (the id comes back from `create()`);
/// in wizard `deferSubmit` mode the picked file travels inside
/// [DebtDraft] and is uploaded later, by `AddCaseReviewScreen`, once its
/// own `create()` call returns a real Debt id.
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
  PickedAttachmentFile? _invoiceFile;

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

  Future<void> _pickInvoice(Future<PickedAttachmentFile?> Function() pick) async {
    final file = await pick();
    if (file == null || !mounted) return;
    setState(() => _invoiceFile = file);
  }

  /// Best-effort: the Debt/Case has already been created successfully by
  /// the time this runs, so a failed invoice upload is surfaced as a
  /// snackbar rather than blocking or reverting an otherwise-successful
  /// save — matches `AddCaseReviewScreen`'s "no rollback on a later
  /// failure" convention for this same wizard chain.
  Future<void> _uploadInvoiceIfPicked(String debtId) async {
    final file = _invoiceFile;
    if (file == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(attachmentRepositoryProvider).uploadAttachment(
            entityPathPrefix: 'debts/$debtId',
            filePath: file.path,
            fileName: file.name,
            description: 'Invoice',
          );
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).addEditDebtInvoiceUploadFailedMessage(e.message))),
        );
      }
    }
  }

  Future<void> _showCreditLimitDialog(String message) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addEditDebtCreditLimitExceededTitle),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonOk)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_dueDate == null) {
      setState(() => _error = AppLocalizations.of(context).addEditDebtDueDateRequiredError);
      return;
    }

    final notes = _notesController.text.trim();

    if (widget.deferSubmit) {
      GoRouter.of(context).pop(DebtDraft(
        amount: _amountController.text.trim(),
        dueDate: _dateOnly(_dueDate!),
        notes: notes.isEmpty ? null : notes,
        invoiceFile: _invoiceFile,
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
        await _uploadInvoiceIfPicked(widget.debtId!);
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
        await _uploadInvoiceIfPicked(result.debt.id);
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
    final l10n = AppLocalizations.of(context);
    if (_isEdit) {
      final debtAsync = ref.watch(debtDetailProvider(widget.debtId!));
      return debtAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.addEditDebtEditTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.addEditDebtEditTitle)),
          body: Center(child: Text(l10n.debtDetailLoadError, style: AppTypography.body)),
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
    final l10n = AppLocalizations.of(context);
    final title = _isEdit ? l10n.addEditDebtEditTitle : (widget.deferSubmit ? l10n.debtDetailTitle : l10n.addEditDebtAddTitle);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit) ...[
              Text(l10n.addEditDebtAmountLabel, style: AppTypography.caption),
              const SizedBox(height: 4),
              Text(_amountController.text, style: AppTypography.body),
              const SizedBox(height: 20),
            ] else
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.addEditDebtAmountLabel, hintText: l10n.creditLimitHint),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return l10n.addEditDebtAmountRequiredValidator;
                  }
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null || parsed <= 0) {
                    return l10n.addEditDebtAmountInvalidValidator;
                  }
                  return null;
                },
              ),
            const SizedBox(height: 20),
            Text(l10n.addEditDebtDueDateHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pickDueDate,
              child: Text(_dueDate == null ? l10n.addEditDebtSelectDueDateButton : _dateOnly(_dueDate!)),
            ),
            const SizedBox(height: 20),
            Text(l10n.addEditDebtInvoiceHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickInvoice(ref.read(attachmentCameraProvider)),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(l10n.debtScanInvoiceButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickInvoice(ref.read(attachmentFilePickerProvider)),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(l10n.debtUploadInvoiceButton),
                  ),
                ),
              ],
            ),
            if (_invoiceFile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_invoiceFile!.name, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: l10n.addEditDebtRemoveInvoiceTooltip,
                    onPressed: () => setState(() => _invoiceFile = null),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.addEditDebtNotesHeading, style: AppTypography.heading),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.addEditDebtNotesHint),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEdit ? l10n.saveChanges : (widget.deferSubmit ? l10n.addEditCustomerContinueButton : l10n.addEditDebtAddTitle),
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
