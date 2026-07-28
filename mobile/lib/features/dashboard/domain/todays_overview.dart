/// Mirrors `ReminderService::summary()` exactly (reused verbatim by
/// `DashboardController::todaysOverview()` — the same data backing
/// Reminder Center §7.1). `per_type` is keyed by `ReminderType` enum
/// values; only the three types the frozen spec's §4.3 rows name are read
/// here (Payment Due, Client Visit, Follow-up Call).
class TodaysOverview {
  final int totalDueToday;
  final int paymentsDue;
  final int clientVisits;
  final int followUpCalls;

  const TodaysOverview({
    required this.totalDueToday,
    required this.paymentsDue,
    required this.clientVisits,
    required this.followUpCalls,
  });

  factory TodaysOverview.fromJson(Map<String, dynamic> json) {
    final perType = json['per_type'] as Map<String, dynamic>;
    return TodaysOverview(
      totalDueToday: json['total_due_today'] as int,
      paymentsDue: (perType['payment_due'] as int?) ?? 0,
      clientVisits: (perType['client_visit'] as int?) ?? 0,
      followUpCalls: (perType['follow_up_call'] as int?) ?? 0,
    );
  }
}
