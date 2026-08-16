import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../customers/domain/customer.dart';
import '../../debts/domain/debt.dart';
import '../../debts/presentation/widgets/record_payment_sheet.dart';

/// Orchestrates the Record Payment Quick Action: pick an existing customer
/// via the real Customer List in selection mode, pick one of that
/// customer's debts via the real Debt List in selection mode, then reuse
/// the existing `record_payment_sheet.dart` (the same one Debt Details
/// already uses) — no new payment form.
Future<void> startRecordPaymentFlow(BuildContext context) async {
  final customer = await context.push<Customer>('/customers?select=true');
  if (customer == null || !context.mounted) return;

  final debt = await context.push<Debt>(
    '/customers/${customer.id}/debts?select=true',
  );
  if (debt == null || !context.mounted) return;

  await showRecordPaymentSheet(context, debt.id, customer.id);
}
