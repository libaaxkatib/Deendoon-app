import 'subscription_change_request.dart';

/// One page of `GET /subscription/change-requests`, mirroring
/// `SubscriptionController::changeRequests()`'s pagination envelope exactly
/// (`current_page`, `per_page`, `total`, `last_page`) — same shape
/// convention as `ProfessionalCollectionRequestPage`.
class SubscriptionChangeRequestPage {
  final List<SubscriptionChangeRequest> changeRequests;
  final int currentPage;
  final int lastPage;
  final int total;

  const SubscriptionChangeRequestPage({
    required this.changeRequests,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory SubscriptionChangeRequestPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['change_requests'] as List<dynamic>;
    return SubscriptionChangeRequestPage(
      changeRequests: items.map((e) => SubscriptionChangeRequest.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
