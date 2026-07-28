/// Mirrors `App\Http\Resources\PromiseToPayResource` exactly. `status` is
/// `open` at creation; the backend also resolves it to a closed status
/// elsewhere, but there is no endpoint to list past promises for a debt —
/// only `POST /debts/{id}/promise-to-pay` to create one (see the Sprint 12
/// summary's "Missing Backend Support Required").
class PromiseToPay {
  final String id;
  final String debtId;
  final String promisedDate;
  final String status;

  const PromiseToPay({
    required this.id,
    required this.debtId,
    required this.promisedDate,
    required this.status,
  });

  factory PromiseToPay.fromJson(Map<String, dynamic> json) => PromiseToPay(
        id: json['id'].toString(),
        debtId: json['debt_id'].toString(),
        promisedDate: json['promised_date'] as String,
        status: json['status'] as String,
      );
}
