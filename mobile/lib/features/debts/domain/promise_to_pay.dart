/// Mirrors `App\Http\Resources\PromiseToPayResource` exactly. `status` is
/// `open` at creation; the backend also resolves it to `fulfilled`/
/// `broken` elsewhere. `GET /debts/{id}/promise-to-pay`
/// (`PromiseToPayController::index`) lists every promise for a debt,
/// newest first.
class PromiseToPay {
  final String id;
  final String debtId;
  final String promisedDate;
  final String status;
  final String createdAt;

  const PromiseToPay({
    required this.id,
    required this.debtId,
    required this.promisedDate,
    required this.status,
    required this.createdAt,
  });

  factory PromiseToPay.fromJson(Map<String, dynamic> json) => PromiseToPay(
    id: json['id'].toString(),
    debtId: json['debt_id'].toString(),
    promisedDate: json['promised_date'] as String,
    status: json['status'] as String,
    createdAt: json['created_at'] as String,
  );
}
