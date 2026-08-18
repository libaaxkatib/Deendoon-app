import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../quick_actions/domain/customer_draft.dart';
import '../../domain/customer_phone_number.dart';
import '../../domain/duplicate_warning.dart';
import '../providers/customer_actions.dart';
import '../providers/customer_detail_providers.dart';

/// Add/Edit Customer — one screen, two entry points (`customerId` null vs
/// set), same pattern as `ReminderScheduleScreen`. No screen for this
/// exists in `Mobile_UI_V1_Frozen.md` (Customers isn't one of its 5
/// documented screens, same gap already noted by `customer_list_screen.dart`)
/// — built with the established Deendoon Design System components
/// (`PrimaryButton`, `AppTypography`) rather than a new mockup.
///
/// Fields mirror `StoreCustomerRequest`/`UpdateCustomerRequest` exactly:
/// `name` (required, max 255), `phone` (required, max 30), `address`
/// (optional, max 500 — feeds the Client Visit reminder's real "Navigate"
/// action), `credit_limit` (required, numeric, min 0). Both endpoints also
/// return an optional possible-duplicate `warning` (BRL-013) alongside the
/// saved customer — surfaced here as a post-save dialog, never blocking
/// the save itself.
///
/// Fix #23 — Multiple Customer Phone Numbers: the phone field is a
/// repeatable 1-3 entry editor (add/remove/set-primary) shared by both
/// entry points into this screen — a real create/edit, and the Add Case
/// wizard's `deferSubmit` step (Product Owner decision: the wizard's
/// Customer Details step must offer the exact same multi-phone capability
/// as the normal Add/Edit Customer flow). `CustomerDraft` mirrors
/// `StoreCustomerRequest`'s shape, including `phone_numbers`.
class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;

  /// When true (Add Case wizard's "New Customer" step, `customerId` always
  /// null in this mode), the form validates and pops the route with a
  /// [CustomerDraft] instead of calling `POST /customers` — actual
  /// creation is deferred to the wizard's Review step, which chains
  /// Customer -> Debt -> Collection Case as one flow. Reuses this exact
  /// screen/fields/validation rather than a duplicate form.
  final bool deferSubmit;

  const AddEditCustomerScreen({
    super.key,
    this.customerId,
    this.deferSubmit = false,
  });

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

/// A single row in the multi-phone editor. [id] is null for a phone the
/// user has just added locally and not yet saved.
class _PhoneEntry {
  final String? id;
  final TextEditingController controller;
  bool isPrimary;

  _PhoneEntry({this.id, required String phone, required this.isPrimary})
    : controller = TextEditingController(text: phone);
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  bool get _isEdit => widget.customerId != null;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();

  List<_PhoneEntry> _phoneEntries = [_PhoneEntry(phone: '', isPrimary: true)];

  bool _prefilled = false;
  bool _isSaving = false;
  String? _error;

  Timer? _duplicateDebounce;
  DuplicateWarning? _liveDuplicateWarning;

  @override
  void dispose() {
    _duplicateDebounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    for (final entry in _phoneEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _prefillFromExisting(dynamic customer) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = customer.name as String;
    _addressController.text = (customer.address as String?) ?? '';
    _creditLimitController.text = customer.creditLimit as String;

    // Falls back to the legacy `phone` string when `phoneNumbers` is empty
    // — every real API response already guarantees at least one entry
    // (see `Customer.fromJson`), but this keeps the form correct even for
    // a `Customer` built directly (e.g. a test fixture) without going
    // through that parsing path.
    final existingPhoneNumbers =
        customer.phoneNumbers as List<CustomerPhoneNumber>;
    final normalized = existingPhoneNumbers.isNotEmpty
        ? existingPhoneNumbers
        : [
            CustomerPhoneNumber(
              phone: customer.phone as String,
              isPrimary: true,
            ),
          ];
    for (final entry in _phoneEntries) {
      entry.controller.dispose();
    }
    _phoneEntries = normalized
        .map(
          (p) => _PhoneEntry(id: p.id, phone: p.phone, isPrimary: p.isPrimary),
        )
        .toList();
  }

  String get _primaryPhoneText {
    final primary = _phoneEntries.firstWhere(
      (e) => e.isPrimary,
      orElse: () => _phoneEntries.first,
    );
    return primary.controller.text;
  }

  void _setPrimary(_PhoneEntry entry) {
    setState(() {
      for (final e in _phoneEntries) {
        e.isPrimary = identical(e, entry);
      }
    });
  }

  void _removePhoneEntry(_PhoneEntry entry) {
    if (_phoneEntries.length <= 1) return;
    setState(() {
      final wasPrimary = entry.isPrimary;
      _phoneEntries.remove(entry);
      entry.controller.dispose();
      if (wasPrimary && _phoneEntries.isNotEmpty) {
        _phoneEntries.first.isPrimary = true;
      }
    });
  }

  void _addPhoneEntry() {
    if (_phoneEntries.length >= 3) return;
    setState(() {
      _phoneEntries.add(_PhoneEntry(phone: '', isPrimary: false));
    });
  }

  /// Add-only: `POST /customers/check-duplicate` has no `excludeCustomerId`
  /// param, so calling it from Edit with unchanged fields would flag the
  /// customer's own record as a duplicate of itself — see `customer_api.dart`.
  void _onIdentifyingFieldChanged() {
    if (_isEdit) return;

    _duplicateDebounce?.cancel();
    final name = _nameController.text.trim();
    final phone = _primaryPhoneText.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _liveDuplicateWarning = null);
      return;
    }

    _duplicateDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final warning = await ref
            .read(customerActionsProvider)
            .checkDuplicate(name: name, phone: phone);
        if (mounted) setState(() => _liveDuplicateWarning = warning);
      } catch (_) {
        // Best-effort pre-check only — a failure here must never block typing
        // or submission; the authoritative check still runs server-side on save.
      }
    });
  }

  /// Returns `true` if it already navigated away (to the matched existing
  /// customer) so `_save()` knows not to also pop back afterward.
  Future<bool> _showDuplicateDialog(DuplicateWarning warning) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final viewExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addEditCustomerDuplicateTitle),
        content: Text(warning.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonOk),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addEditCustomerViewExistingButton),
          ),
        ],
      ),
    );
    if (viewExisting == true) {
      router.pushReplacement('/customers/${warning.matchedCustomerId}');
      return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final creditLimit = _creditLimitController.text.trim();

    final phoneNumbers = _phoneEntries
        .map(
          (e) => CustomerPhoneNumber(
            id: e.id,
            phone: e.controller.text.trim(),
            isPrimary: e.isPrimary,
          ),
        )
        .toList();
    final phone = phoneNumbers.firstWhere((p) => p.isPrimary).phone;

    if (widget.deferSubmit) {
      GoRouter.of(context).pop(
        CustomerDraft(
          name: name,
          phone: phone,
          address: address.isEmpty ? null : address,
          creditLimit: creditLimit,
          phoneNumbers: phoneNumbers,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      final result = _isEdit
          ? await ref
                .read(customerActionsProvider)
                .update(
                  id: widget.customerId!,
                  name: name,
                  phone: phone,
                  address: address.isEmpty ? null : address,
                  creditLimit: creditLimit,
                  phoneNumbers: phoneNumbers,
                )
          : await ref
                .read(customerActionsProvider)
                .create(
                  name: name,
                  phone: phone,
                  address: address.isEmpty ? null : address,
                  creditLimit: creditLimit,
                  phoneNumbers: phoneNumbers,
                );

      if (!mounted) return;
      // Clear the saving spinner before the (possibly modal) duplicate
      // dialog — the save itself already succeeded, and a still-spinning
      // button underneath an open dialog never lets a widget test's
      // `pumpAndSettle()` return (an indeterminate `CircularProgressIndicator`
      // animates forever).
      setState(() => _isSaving = false);

      var navigatedToExisting = false;
      if (result.warning != null) {
        navigatedToExisting = await _showDuplicateDialog(result.warning!);
      }
      if (mounted && !navigatedToExisting) router.pop();
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
      final customerAsync = ref.watch(
        customerDetailProvider(widget.customerId!),
      );
      return customerAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.customerEditTitle)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.customerEditTitle)),
          body: Center(
            child: Text(
              l10n.customerDetailLoadError,
              style: AppTypography.body,
            ),
          ),
        ),
        data: (customer) {
          _prefillFromExisting(customer);
          return _buildForm(context, l10n);
        },
      );
    }
    return _buildForm(context, l10n);
  }

  Widget _buildPhoneNumbersEditor(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addEditCustomerPhoneNumbersLabel, style: AppTypography.body),
        const SizedBox(height: 8),
        for (final entry in _phoneEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.controller,
                    maxLength: 30,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.addEditCustomerPhoneLabel,
                    ),
                    onChanged: (_) => _onIdentifyingFieldChanged(),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l10n.addEditCustomerPhoneRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                if (entry.isPrimary)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Chip(
                      label: Text(l10n.addEditCustomerPhonePrimaryBadge),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () => _setPrimary(entry),
                      child: Text(l10n.addEditCustomerSetPrimaryButton),
                    ),
                  ),
                if (_phoneEntries.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.addEditCustomerRemovePhoneButton,
                      onPressed: () => _removePhoneEntry(entry),
                    ),
                  ),
              ],
            ),
          ),
        if (_phoneEntries.length < 3)
          TextButton.icon(
            onPressed: _addPhoneEntry,
            icon: const Icon(Icons.add),
            label: Text(l10n.addEditCustomerAddPhoneButton),
          )
        else
          Text(
            l10n.addEditCustomerMaxPhoneNumbersMessage,
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final title = _isEdit
        ? l10n.customerEditTitle
        : (widget.deferSubmit
              ? l10n.customerDetailsTitle
              : l10n.customerAddTitle);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: l10n.addEditCustomerNameLabel,
                ),
                onChanged: (_) => _onIdentifyingFieldChanged(),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.addEditCustomerNameRequired
                    : null,
              ),
              _buildPhoneNumbersEditor(context, l10n),
              if (_liveDuplicateWarning != null) ...[
                const SizedBox(height: 8),
                Text(
                  _liveDuplicateWarning!.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.addEditCustomerAddressLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditLimitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.creditLimitLabel,
                  hintText: l10n.creditLimitHint,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return l10n.creditLimitRequiredValidator;
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null || parsed < 0) {
                    return l10n.creditLimitInvalidValidator;
                  }
                  return null;
                },
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
                label: _isEdit
                    ? l10n.saveChanges
                    : (widget.deferSubmit
                          ? l10n.addEditCustomerContinueButton
                          : l10n.customerAddTitle),
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
