import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../customers/domain/customer.dart';
import '../domain/add_case_review_input.dart';
import '../domain/customer_draft.dart';
import '../domain/debt_draft.dart';
import 'widgets/add_case_entry_sheet.dart';

/// Orchestrates the Add Case Quick Action end to end: the entry-choice
/// sheet, then either the real Customer List in selection mode or the
/// Customer Details draft form, then the Debt Details draft form, then
/// Review (which performs the actual chained creation). Nothing is
/// created until Review's confirm — every step up to here is purely
/// local/collected data.
///
/// The invoice scan/upload step from the approved workflow is
/// intentionally not present here — no backend support exists yet (no
/// OCR, no debt-attachment upload endpoint). Per Product Owner decision,
/// it stays hidden rather than shown as disabled/"coming soon"; re-enable
/// it as its own step between Debt Details and Review once the backend
/// supports it, without changing the rest of this flow.
Future<void> startAddCaseFlow(BuildContext context) async {
  final mode = await showAddCaseEntrySheet(context);
  if (mode == null || !context.mounted) return;

  Customer? existingCustomer;
  CustomerDraft? customerDraft;

  if (mode == 'existing') {
    existingCustomer = await context.push<Customer>('/customers?select=true');
    if (existingCustomer == null || !context.mounted) return;
  } else {
    customerDraft = await context.push<CustomerDraft>('/customers/draft');
    if (customerDraft == null || !context.mounted) return;
  }

  final debtDraft = await context.push<DebtDraft>('/debts/draft');
  if (debtDraft == null || !context.mounted) return;

  await context.push(
    '/add-case/review',
    extra: AddCaseReviewInput(existingCustomer: existingCustomer, customerDraft: customerDraft, debtDraft: debtDraft),
  );
}
