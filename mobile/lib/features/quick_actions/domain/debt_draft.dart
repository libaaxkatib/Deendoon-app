import '../../attachments/presentation/providers/attachment_providers.dart';

/// Locally-held, not-yet-created Debt fields collected by the Add Case
/// wizard's Debt Details step. Mirrors `StoreDebtRequest` exactly
/// (`amount`, `due_date`, `notes`) — turned into a real Debt only when the
/// wizard's Review step calls `POST /customers/{id}/debts`.
///
/// `invoiceFile` (P2.6/P2.7 in wizard mode) is captured/picked here but
/// can't be uploaded yet — there is no Debt id until the Review step's
/// `POST /customers/{id}/debts` succeeds. The Review step uploads it as a
/// best-effort step right after that call returns a real Debt id.
class DebtDraft {
  final String amount;
  final String dueDate;
  final String? notes;
  final PickedAttachmentFile? invoiceFile;

  const DebtDraft({
    required this.amount,
    required this.dueDate,
    this.notes,
    this.invoiceFile,
  });
}
