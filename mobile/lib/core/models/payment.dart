/// Mirrors `App\Http\Resources\PaymentResource` exactly. Identical shape
/// is returned by `GET /customers/{id}/payments` and
/// `GET /debts/{id}/payments` — one shared model for both, not duplicated
/// per feature.
class Payment {
  final String id;
  final String debtId;
  final String amount;
  final String paymentDate;
  final String? paymentMethod;

  const Payment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'].toString(),
        debtId: json['debt_id'].toString(),
        amount: json['amount'] as String,
        paymentDate: json['payment_date'] as String,
        paymentMethod: json['payment_method'] as String?,
      );
}
