import 'subscription_plan.dart';

/// Mirrors `SubscriptionController::show()` exactly — the response shape of
/// `GET /subscription`. Every nullable field here is genuinely nullable
/// server-side: `plan`/`planName`/`planPrice` are null only if the Free
/// Plan row itself hasn't been seeded (see `SubscriptionService::
/// currentPlan()`), and `subscriptionStatus`/`startedAt`/`expiresAt` are
/// null for a tenant that has no `tenant_subscriptions` row at all.
class Subscription {
  final SubscriptionPlan? plan;
  final String? planName;
  final String? planPrice;
  final bool onTrial;
  final DateTime? trialEndsAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? subscriptionStatus;
  final int customerUsage;
  final int? customerLimit;
  final int storageUsageBytes;
  final int? storageLimit;
  final bool analyticsEnabled;
  final bool readOnly;

  const Subscription({
    required this.plan,
    required this.planName,
    required this.planPrice,
    required this.onTrial,
    required this.trialEndsAt,
    required this.startedAt,
    required this.expiresAt,
    required this.subscriptionStatus,
    required this.customerUsage,
    required this.customerLimit,
    required this.storageUsageBytes,
    required this.storageLimit,
    required this.analyticsEnabled,
    required this.readOnly,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final trialStatus = json['trial_status'] as Map<String, dynamic>;
    return Subscription(
      plan: json['plan'] == null
          ? null
          : SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      planName: json['plan_name'] as String?,
      planPrice: json['plan_price'] as String?,
      onTrial: trialStatus['on_trial'] as bool,
      trialEndsAt: trialStatus['trial_ends_at'] == null
          ? null
          : DateTime.parse(trialStatus['trial_ends_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      subscriptionStatus: json['subscription_status'] as String?,
      customerUsage: json['customer_usage'] as int,
      customerLimit: json['customer_limit'] as int?,
      storageUsageBytes: json['storage_usage_bytes'] as int,
      storageLimit: json['storage_limit'] as int?,
      analyticsEnabled: json['analytics_enabled'] as bool,
      readOnly: json['read_only'] as bool,
    );
  }
}
