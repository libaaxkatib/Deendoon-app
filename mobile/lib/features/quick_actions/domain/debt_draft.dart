/// Locally-held, not-yet-created Debt fields collected by the Add Case
/// wizard's Debt Details step. Mirrors `StoreDebtRequest` exactly
/// (`amount`, `due_date`, `notes`) — turned into a real Debt only when the
/// wizard's Review step calls `POST /customers/{id}/debts`.
class DebtDraft {
  final String amount;
  final String dueDate;
  final String? notes;

  const DebtDraft({required this.amount, required this.dueDate, this.notes});
}
