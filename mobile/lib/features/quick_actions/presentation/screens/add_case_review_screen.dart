import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/presentation/providers/customer_actions.dart';
import '../../../debts/domain/debt.dart';
import '../../../debts/presentation/providers/debt_actions.dart';
import '../../domain/add_case_review_input.dart';

/// Add Case wizard's final step. Reviews everything collected, then on
/// confirm chains the real mutations as one business workflow:
/// (`POST /customers` if New Customer) -> `POST /customers/{id}/debts` ->
/// `POST /debts/{id}/collection-cases`.
///
/// No rollback is attempted on a mid-chain failure — confirmed with the
/// Product Owner that neither `archive()` endpoint reverses a created
/// record's financial impact (it's a pure soft-delete flag; the customer's
/// `outstanding_balance` recalculation explicitly still counts archived
/// debts). A failure after a real record was created surfaces the exact
/// error plus a direct link to that record instead of hiding it.
class AddCaseReviewScreen extends ConsumerStatefulWidget {
  final AddCaseReviewInput input;

  const AddCaseReviewScreen({super.key, required this.input});

  @override
  ConsumerState<AddCaseReviewScreen> createState() => _AddCaseReviewScreenState();
}

sealed class _ReviewState {
  const _ReviewState();
}

class _Idle extends _ReviewState {
  const _Idle();
}

class _Running extends _ReviewState {
  const _Running();
}

/// Nothing was created yet (Customer creation failed, or — Existing
/// Customer path — Debt creation failed with no prior step to have
/// created anything). Safe to just show the error and let the user retry.
class _FailedNothingCreated extends _ReviewState {
  final String message;
  const _FailedNothingCreated(this.message);
}

/// The Customer was created successfully but Debt creation failed.
class _FailedAfterCustomer extends _ReviewState {
  final String message;
  final Customer customer;
  const _FailedAfterCustomer(this.message, this.customer);
}

/// The Debt was created successfully (Customer too, if New Customer path)
/// but Collection Case creation failed.
class _FailedAfterDebt extends _ReviewState {
  final String message;
  final Debt debt;
  const _FailedAfterDebt(this.message, this.debt);
}

class _AddCaseReviewScreenState extends ConsumerState<AddCaseReviewScreen> {
  _ReviewState _state = const _Idle();

  bool get _isNewCustomer => widget.input.customerDraft != null;

  Future<void> _confirm() async {
    setState(() => _state = const _Running());

    final debtDraft = widget.input.debtDraft;
    Customer customer;

    if (_isNewCustomer) {
      final draft = widget.input.customerDraft!;
      try {
        final result = await ref.read(customerActionsProvider).create(
              name: draft.name,
              phone: draft.phone,
              creditLimit: draft.creditLimit,
            );
        customer = result.customer;
      } on ApiException catch (e) {
        if (mounted) setState(() => _state = _FailedNothingCreated(e.message));
        return;
      }
    } else {
      customer = widget.input.existingCustomer!;
    }

    Debt debt;
    try {
      final result = await ref.read(debtActionsProvider).create(
            customerId: customer.id,
            amount: debtDraft.amount,
            dueDate: debtDraft.dueDate,
            notes: debtDraft.notes,
          );
      debt = result.debt;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _state = _isNewCustomer ? _FailedAfterCustomer(e.message, customer) : _FailedNothingCreated(e.message);
        });
      }
      return;
    }

    try {
      final collectionCase = await ref.read(debtActionsProvider).openCase(debt.id);
      if (!mounted) return;
      // `go()`, not `push()`/`pushReplacement()` — clears the whole wizard
      // stack (entry sheet's pushed steps) now that the flow is complete,
      // rather than leaving stale draft-collection screens behind Case
      // Detail's back button.
      GoRouter.of(context).go('/cases/${collectionCase.id}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _state = _FailedAfterDebt(e.message, debt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final debtDraft = input.debtDraft;

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Customer', style: AppTypography.heading),
            const SizedBox(height: 12),
            if (input.existingCustomer case final customer?) ...[
              Text(customer.name, style: AppTypography.body),
              Text(customer.phone, style: AppTypography.caption),
            ] else if (input.customerDraft case final draft?) ...[
              Text(draft.name, style: AppTypography.body),
              Text(draft.phone, style: AppTypography.caption),
              Text('Credit Limit: ${draft.creditLimit}', style: AppTypography.caption),
            ],
            const SizedBox(height: 24),
            const Text('Debt', style: AppTypography.heading),
            const SizedBox(height: 12),
            Text('Amount: ${debtDraft.amount}', style: AppTypography.body),
            Text('Due Date: ${debtDraft.dueDate}', style: AppTypography.body),
            if (debtDraft.notes != null) Text('Notes: ${debtDraft.notes}', style: AppTypography.caption),
            const SizedBox(height: 32),
            _buildStateSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSection(BuildContext context) {
    final label = _isNewCustomer ? 'Create Customer & Debt' : 'Create Debt';
    final state = _state;
    return switch (state) {
      _Idle() => PrimaryButton(label: label, onPressed: _confirm),
      _Running() => PrimaryButton(label: label, isLoading: true, onPressed: null),
      _FailedNothingCreated(:final message) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Try Again', onPressed: _confirm),
          ],
        ),
      _FailedAfterCustomer(:final message, :final customer) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The customer "${customer.name}" was created successfully. Creating the debt failed: $message',
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).push('/customers/${customer.id}'),
              child: const Text('Open Customer'),
            ),
          ],
        ),
      _FailedAfterDebt(:final message, :final debt) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debt ${debt.referenceNumber} was created successfully. Creating the Collection Case failed: $message',
              style: AppTypography.body,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can open a Collection Case for this debt later from its Debt Details screen.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => GoRouter.of(context).push('/debts/${debt.id}'),
              child: const Text('Open Debt'),
            ),
          ],
        ),
    };
  }
}
