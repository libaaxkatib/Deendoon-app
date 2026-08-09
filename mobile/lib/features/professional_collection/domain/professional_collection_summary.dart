import 'professional_collection_request.dart';
import 'professional_collection_timeline_event.dart';

/// Mirrors `ProfessionalCollectionRequestController::summary()` exactly —
/// `GET /professional-requests/summary` (Business Owner only, same
/// `admin-only` gate as Business Health; no cross-tenant summary for the
/// Deendoon Platform Administrator). `countsByStatus` always has all 8
/// real status keys present (0 where none exist) — never a sparse map.
class ProfessionalCollectionSummary {
  final Map<String, int> countsByStatus;
  final int totalActive;
  final int totalRecovered;
  final ProfessionalCollectionRequest? latestRequest;
  final ProfessionalCollectionTimelineEvent? latestTimelineEvent;

  const ProfessionalCollectionSummary({
    required this.countsByStatus,
    required this.totalActive,
    required this.totalRecovered,
    required this.latestRequest,
    required this.latestTimelineEvent,
  });

  bool get isEmpty => totalActive == 0 && totalRecovered == 0 && latestRequest == null;

  factory ProfessionalCollectionSummary.fromJson(Map<String, dynamic> json) => ProfessionalCollectionSummary(
        countsByStatus: (json['counts_by_status'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
        totalActive: json['total_active'] as int,
        totalRecovered: json['total_recovered'] as int,
        latestRequest: json['latest_request'] == null
            ? null
            : ProfessionalCollectionRequest.fromJson(json['latest_request'] as Map<String, dynamic>),
        latestTimelineEvent: json['latest_timeline_event'] == null
            ? null
            : ProfessionalCollectionTimelineEvent.fromJson(json['latest_timeline_event'] as Map<String, dynamic>),
      );
}
