import 'professional_collection_request.dart';

/// One page of `GET /professional-requests`, mirroring the controller's
/// pagination envelope exactly (`current_page`, `per_page`, `total`,
/// `last_page`) — same shape convention as `CustomerPage`/`DebtPage`.
class ProfessionalCollectionRequestPage {
  final List<ProfessionalCollectionRequest> requests;
  final int currentPage;
  final int lastPage;
  final int total;

  const ProfessionalCollectionRequestPage({
    required this.requests,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ProfessionalCollectionRequestPage.fromJson(
    Map<String, dynamic> json,
  ) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['professional_requests'] as List<dynamic>;
    return ProfessionalCollectionRequestPage(
      requests: items
          .map(
            (e) => ProfessionalCollectionRequest.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
