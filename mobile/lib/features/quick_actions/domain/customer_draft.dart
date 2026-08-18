import '../../customers/domain/customer_phone_number.dart';

/// Locally-held, not-yet-created Customer fields collected by the Add Case
/// wizard's "New Customer" step. Mirrors `StoreCustomerRequest` exactly
/// (`name`, `phone`, `address`, `credit_limit`, `phone_numbers`) — turned
/// into a real Customer only when the wizard's Review step calls
/// `POST /customers`.
///
/// Fix #23 extension (Product Owner decision): the Customer Details step
/// now uses the exact same multi-phone editor as the normal Add/Edit
/// Customer screen. [phone] stays the primary entry's number (kept for the
/// Review screen's existing summary display and because
/// `CustomerActions.create()`'s `phone` param is still required —
/// `AddEditCustomerScreen._save()` derives it from [phoneNumbers] the same
/// way for both the real and deferred paths), while [phoneNumbers] carries
/// every entered number (1-3, exactly one primary) through to the deferred
/// `POST /customers` call.
class CustomerDraft {
  final String name;
  final String phone;
  final String? address;
  final String creditLimit;
  final List<CustomerPhoneNumber> phoneNumbers;

  const CustomerDraft({
    required this.name,
    required this.phone,
    this.address,
    required this.creditLimit,
    required this.phoneNumbers,
  });
}
