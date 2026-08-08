/// Mirrors `App\Http\Resources\SubscriptionPlanResource` exactly — the
/// shape returned by `GET /subscription/plans`, and embedded in `GET
/// /subscription` (`plan`) and `SubscriptionChangeRequestResource`
/// (`requested_plan`/`current_plan`).
///
/// `monthlyPrice` stays a `String` because `SubscriptionPlan::monthly_price`
/// is cast `decimal:2` server-side, which Eloquent serializes as a string,
/// not a number — same convention as `Debt.outstandingAmount`.
class SubscriptionPlan {
  final String id;
  final String name;
  final String monthlyPrice;
  final int? customerLimit;
  final int? storageLimit;
  final bool analyticsEnabled;
  final bool trialEligible;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.customerLimit,
    required this.storageLimit,
    required this.analyticsEnabled,
    required this.trialEligible,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'].toString(),
        name: json['name'] as String,
        monthlyPrice: json['monthly_price'] as String,
        customerLimit: json['customer_limit'] as int?,
        storageLimit: json['storage_limit'] as int?,
        analyticsEnabled: json['analytics_enabled'] as bool,
        trialEligible: json['trial_eligible'] as bool,
        features: (json['features'] as List<dynamic>).map((e) => e.toString()).toList(),
      );
}
