/// Mirrors `ReportingService::dashboardKpis()` exactly — no delta/
/// "vs last month" fields exist in the real backend response (the frozen
/// spec's §4.2 business rule for month-over-month deltas is not satisfiable
/// today; see the Sprint 10 summary's flagged gap). `recovery_rate` is
/// always null server-side (DD-032, never resolved) and is not surfaced.
class DashboardKpis {
  final String totalOutstandingAmount;
  final String totalCollectedPeriod;
  final int highRiskCustomers;
  final int overdueCount;
  final String overdueValue;
  final int customersOverCreditLimit;
  final int activeCollectionCases;

  const DashboardKpis({
    required this.totalOutstandingAmount,
    required this.totalCollectedPeriod,
    required this.highRiskCustomers,
    required this.overdueCount,
    required this.overdueValue,
    required this.customersOverCreditLimit,
    required this.activeCollectionCases,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    final overdue = json['total_overdue_debts'] as Map<String, dynamic>;
    return DashboardKpis(
      totalOutstandingAmount: json['total_outstanding_amount'] as String,
      totalCollectedPeriod: json['total_collected_period'] as String,
      highRiskCustomers: json['high_risk_customers'] as int,
      overdueCount: overdue['count'] as int,
      overdueValue: overdue['value'] as String,
      customersOverCreditLimit: json['customers_over_credit_limit'] as int,
      activeCollectionCases: json['active_collection_cases'] as int,
    );
  }
}
