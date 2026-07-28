/// Mirrors `App\Http\Resources\PaymentResource` exactly, as returned by
/// `GET /customers/{id}/payments` (already ordered most-recent-first by
/// the backend).
class CustomerPayment {
  final String id;
  final String debtId;
  final String amount;
  final String paymentDate;
  final String paymentMethod;

  const CustomerPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
  });

  factory CustomerPayment.fromJson(Map<String, dynamic> json) => CustomerPayment(
        id: json['id'].toString(),
        debtId: json['debt_id'].toString(),
        amount: json['amount'] as String,
        paymentDate: json['payment_date'] as String,
        paymentMethod: json['payment_method'] as String,
      );
}
