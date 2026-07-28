/// Mirrors `App\Http\Resources\CustomerResource` exactly — used for both
/// the Customer List and Customer Details screens (the backend returns
/// the identical shape from `GET /customers` and `GET /customers/{id}`).
/// There is no "company" field anywhere on the Customer model/resource —
/// customers are represented by name + phone only, so no company field is
/// shown anywhere in this module.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String customerStatus;
  final String creditLimit;
  final String outstandingBalance;
  final String remainingCredit;
  final String? riskLevel;
  final int? creditScore;
  final String? creditScoreBand;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.customerStatus,
    required this.creditLimit,
    required this.outstandingBalance,
    required this.remainingCredit,
    required this.riskLevel,
    required this.creditScore,
    required this.creditScoreBand,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'].toString(),
        name: json['name'] as String,
        phone: json['phone'] as String,
        customerStatus: json['customer_status'] as String,
        creditLimit: json['credit_limit'] as String,
        outstandingBalance: json['outstanding_balance'] as String,
        remainingCredit: json['remaining_credit'] as String,
        riskLevel: json['risk_level'] as String?,
        creditScore: json['credit_score'] as int?,
        creditScoreBand: json['credit_score_band'] as String?,
      );
}
