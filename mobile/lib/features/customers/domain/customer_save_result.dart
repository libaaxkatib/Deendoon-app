import 'customer.dart';
import 'duplicate_warning.dart';

/// `store`/`update` both return the saved customer plus an optional
/// possible-duplicate warning in the same response — this pairs them so
/// callers can't accidentally drop the warning.
typedef CustomerSaveResult = ({Customer customer, DuplicateWarning? warning});
