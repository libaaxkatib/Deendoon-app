/// Mirrors `ReminderService::summary()` exactly — the same computation
/// backing both `GET /reminders/summary` (Reminder Center §7.1) and
/// `GET /dashboard/todays-overview` (Home Dashboard §4.3). Deliberately
/// NOT reusing the Home Dashboard's own `TodaysOverview` model here:
/// that model only parses 3 of the 5 `per_type` keys and omits
/// `overdue_count` entirely (fields the Home Dashboard's §4.3 rows never
/// needed), and per this project's "never perform cosmetic refactoring
/// unless requested" rule, the already-shipped, already-tested Dashboard
/// feature is left untouched rather than refactored to share this model.
class ReminderSummary {
  final int totalDueToday;
  final int overdueCount;
  final int clientVisits;
  final int followUpCalls;
  final int paymentsDue;
  final int contractRenewals;
  final int promisesToPay;

  const ReminderSummary({
    required this.totalDueToday,
    required this.overdueCount,
    required this.clientVisits,
    required this.followUpCalls,
    required this.paymentsDue,
    required this.contractRenewals,
    required this.promisesToPay,
  });

  factory ReminderSummary.fromJson(Map<String, dynamic> json) {
    final perType = json['per_type'] as Map<String, dynamic>;
    return ReminderSummary(
      totalDueToday: json['total_due_today'] as int,
      overdueCount: json['overdue_count'] as int,
      clientVisits: (perType['client_visit'] as int?) ?? 0,
      followUpCalls: (perType['follow_up_call'] as int?) ?? 0,
      paymentsDue: (perType['payment_due'] as int?) ?? 0,
      contractRenewals: (perType['contract_renewal'] as int?) ?? 0,
      promisesToPay: (perType['promise_to_pay'] as int?) ?? 0,
    );
  }
}
