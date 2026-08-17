/// Fix #23 — Multiple Customer Phone Numbers. Mirrors the backend's
/// `phone_numbers` array field on `CustomerResource` exactly — up to 3
/// per customer, exactly one `isPrimary`. [id] is null only for an entry
/// the Add/Edit Customer form's local editor has added but not yet
/// saved — every entry the backend has ever returned always has a real
/// [id]. `CustomerPhoneNumberService::reconcile()` on the backend reads
/// this the same way: a present `id` means "update this row," a null
/// `id` means "create a new one."
class CustomerPhoneNumber {
  final String? id;
  final String phone;
  final bool isPrimary;

  const CustomerPhoneNumber({
    this.id,
    required this.phone,
    required this.isPrimary,
  });

  factory CustomerPhoneNumber.fromJson(Map<String, dynamic> json) =>
      CustomerPhoneNumber(
        id: json['id'].toString(),
        phone: json['phone'] as String,
        isPrimary: json['is_primary'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'is_primary': isPrimary,
  };

  CustomerPhoneNumber copyWith({String? phone, bool? isPrimary}) =>
      CustomerPhoneNumber(
        id: id,
        phone: phone ?? this.phone,
        isPrimary: isPrimary ?? this.isPrimary,
      );
}
