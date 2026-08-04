import '../../customers/domain/customer.dart';
import 'customer_draft.dart';
import 'debt_draft.dart';

/// Everything the Add Case wizard has collected by the time it reaches
/// Review. Exactly one of [existingCustomer]/[customerDraft] is set,
/// mirroring the wizard's two entry paths (Existing Customer vs New
/// Customer).
class AddCaseReviewInput {
  final Customer? existingCustomer;
  final CustomerDraft? customerDraft;
  final DebtDraft debtDraft;

  const AddCaseReviewInput({this.existingCustomer, this.customerDraft, required this.debtDraft})
      : assert(
          (existingCustomer == null) != (customerDraft == null),
          'Exactly one of existingCustomer/customerDraft must be set',
        );
}
