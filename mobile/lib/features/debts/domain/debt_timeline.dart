/// Mirrors `GET /debts/{id}/timeline` exactly — the real FR-024 follow-up
/// timeline: 8 fixed stages (debt_created, whatsapp_reminder, sms_reminder,
/// phone_call, promise_to_pay, payment, professional_collection,
/// recovered), each genuinely `pending` until its real source event
/// exists (never fabricated — the backend itself only marks a stage
/// `completed` when a real audit/follow-up record backs it).
class DebtTimelineStage {
  final String event;
  final String status;
  final String? occurredAt;

  const DebtTimelineStage({
    required this.event,
    required this.status,
    required this.occurredAt,
  });

  factory DebtTimelineStage.fromJson(Map<String, dynamic> json) => DebtTimelineStage(
        event: json['event'] as String,
        status: json['status'] as String,
        occurredAt: json['occurred_at'] as String?,
      );
}

class DebtTimeline {
  final String debtId;
  final List<DebtTimelineStage> stages;

  const DebtTimeline({required this.debtId, required this.stages});

  factory DebtTimeline.fromJson(Map<String, dynamic> json) => DebtTimeline(
        debtId: json['debt_id'].toString(),
        stages: (json['stages'] as List<dynamic>)
            .map((e) => DebtTimelineStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
