import 'credit_limit_warning.dart';
import 'debt.dart';

/// `store` returns the created debt plus an optional credit-limit-exceeded
/// warning (BRL-023) — pairs them so callers can't accidentally drop it.
/// `update` never returns a warning (only `due_date`/`notes` are editable,
/// neither affects the credit-limit check), so it just returns a `Debt`.
typedef DebtSaveResult = ({Debt debt, CreditLimitWarning? warning});
