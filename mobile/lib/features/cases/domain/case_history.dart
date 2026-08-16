/// One entry of `GET /collection-cases/{id}/history` — the backend merges
/// two real sources (`follow_up_history` rows scoped to this case, and
/// `audit_log` rows for this case entity) into one chronological stream,
/// sorted by `occurred_at` ascending. This single real endpoint is what
/// backs both the Case Detail's "Timeline" and "Follow-up History"
/// sections (see the Sprint 13 summary's "Timeline Support").
class CaseHistoryEntry {
  final String source;
  final String action;
  final String? details;
  final String? actorUserId;
  final String occurredAt;

  const CaseHistoryEntry({
    required this.source,
    required this.action,
    required this.details,
    required this.actorUserId,
    required this.occurredAt,
  });

  factory CaseHistoryEntry.fromJson(Map<String, dynamic> json) =>
      CaseHistoryEntry(
        source: json['source'] as String,
        action: json['action'] as String,
        details: json['details'] as String?,
        actorUserId: json['actor_user_id']?.toString(),
        occurredAt: json['occurred_at'] as String,
      );
}

class CaseHistory {
  final String collectionCaseId;
  final List<CaseHistoryEntry> entries;

  const CaseHistory({required this.collectionCaseId, required this.entries});

  factory CaseHistory.fromJson(Map<String, dynamic> json) {
    final items = json['history'] as List<dynamic>;
    return CaseHistory(
      collectionCaseId: json['collection_case_id'].toString(),
      entries: items
          .map((e) => CaseHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
