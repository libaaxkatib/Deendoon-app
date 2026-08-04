/// Locally-held, not-yet-created Customer fields collected by the Add Case
/// wizard's "New Customer" step. Mirrors `StoreCustomerRequest` exactly
/// (`name`, `phone`, `credit_limit`) — turned into a real Customer only
/// when the wizard's Review step calls `POST /customers`.
class CustomerDraft {
  final String name;
  final String phone;
  final String creditLimit;

  const CustomerDraft({required this.name, required this.phone, required this.creditLimit});
}
