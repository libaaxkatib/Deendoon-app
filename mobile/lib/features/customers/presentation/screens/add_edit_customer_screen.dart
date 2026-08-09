import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../quick_actions/domain/customer_draft.dart';
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
class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;

  /// When true (Add Case wizard's "New Customer" step, `customerId` always
  /// null in this mode), the form validates and pops the route with a
  /// [CustomerDraft] instead of calling `POST /customers` — actual
  /// creation is deferred to the wizard's Review step, which chains
  /// Customer -> Debt -> Collection Case as one flow. Reuses this exact
  /// screen/fields/validation rather than a duplicate form.
  final bool deferSubmit;

  const AddEditCustomerScreen({super.key, this.customerId, this.deferSubmit = false});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  bool get _isEdit => widget.customerId != null;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();

  bool _prefilled = false;
  bool _isSaving = false;
  String? _error;

  Timer? _duplicateDebounce;
  DuplicateWarning? _liveDuplicateWarning;

  @override
  void dispose() {
    _duplicateDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _prefillFromExisting(dynamic customer) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = customer.name as String;
    _phoneController.text = customer.phone as String;
    _addressController.text = (customer.address as String?) ?? '';
    _creditLimitController.text = customer.creditLimit as String;
  }

  /// Add-only: `POST /customers/check-duplicate` has no `excludeCustomerId`
  /// param, so calling it from Edit with unchanged fields would flag the
  /// customer's own record as a duplicate of itself — see `customer_api.dart`.
  void _onIdentifyingFieldChanged() {
    if (_isEdit) return;

    _duplicateDebounce?.cancel();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _liveDuplicateWarning = null);
      return;
    }

    _duplicateDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final warning = await ref.read(customerActionsProvider).checkDuplicate(name: name, phone: phone);
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
    final router = GoRouter.of(context);
    final viewExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Possible Duplicate'),
        content: Text(warning.message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('OK')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('View Existing Customer')),
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
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final creditLimit = _creditLimitController.text.trim();

    if (widget.deferSubmit) {
      GoRouter.of(context).pop(CustomerDraft(
        name: name,
        phone: phone,
        address: address.isEmpty ? null : address,
        creditLimit: creditLimit,
      ));
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      final result = _isEdit
          ? await ref.read(customerActionsProvider).update(
                id: widget.customerId!,
                name: name,
                phone: phone,
                address: address.isEmpty ? null : address,
                creditLimit: creditLimit,
              )
          : await ref.read(customerActionsProvider).create(
                name: name,
                phone: phone,
                address: address.isEmpty ? null : address,
                creditLimit: creditLimit,
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
    if (_isEdit) {
      final customerAsync = ref.watch(customerDetailProvider(widget.customerId!));
      return customerAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Customer')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Customer')),
          body: const Center(child: Text('Could not load this customer.', style: AppTypography.body)),
        ),
        data: (customer) {
          _prefillFromExisting(customer);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final title = _isEdit ? 'Edit Customer' : (widget.deferSubmit ? 'Customer Details' : 'Add Customer');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              maxLength: 255,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => _onIdentifyingFieldChanged(),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter the customer\'s name' : null,
            ),
            TextFormField(
              controller: _phoneController,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              onChanged: (_) => _onIdentifyingFieldChanged(),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a phone number' : null,
            ),
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
              decoration: const InputDecoration(labelText: 'Address (Optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Credit Limit', hintText: '0.00'),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Enter a credit limit';
                final parsed = double.tryParse(trimmed);
                if (parsed == null || parsed < 0) return 'Enter a valid credit limit';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isEdit ? 'Save Changes' : (widget.deferSubmit ? 'Continue' : 'Add Customer'),
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
