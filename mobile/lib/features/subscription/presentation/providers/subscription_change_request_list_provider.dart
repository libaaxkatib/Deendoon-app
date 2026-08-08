import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_repository.dart';
import '../../domain/subscription_change_request.dart';

/// Immutable snapshot of the tenant's own paginated Subscription Change
/// Request history — real backend pagination only, no local filtering.
/// Unlike `ProfessionalCollectionListState`, there is no `status` filter:
/// `SubscriptionController::changeRequests()` doesn't accept one (that's
/// only the Platform Admin Approval Center's equivalent, out of scope
/// here).
class SubscriptionChangeRequestListState {
  final List<SubscriptionChangeRequest> changeRequests;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;

  const SubscriptionChangeRequestListState({
    required this.changeRequests,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  SubscriptionChangeRequestListState copyWith({
    List<SubscriptionChangeRequest>? changeRequests,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
  }) {
    return SubscriptionChangeRequestListState(
      changeRequests: changeRequests ?? this.changeRequests,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final subscriptionChangeRequestListProvider =
    AsyncNotifierProvider<SubscriptionChangeRequestListNotifier, SubscriptionChangeRequestListState>(
  SubscriptionChangeRequestListNotifier.new,
);

class SubscriptionChangeRequestListNotifier extends AsyncNotifier<SubscriptionChangeRequestListState> {
  @override
  Future<SubscriptionChangeRequestListState> build() => _fetchFirstPage();

  SubscriptionRepository get _repository => ref.read(subscriptionRepositoryProvider);

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchChangeRequests(page: current.currentPage + 1);
      state = AsyncData(current.copyWith(
        changeRequests: [...current.changeRequests, ...next.changeRequests],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<SubscriptionChangeRequestListState> _fetchFirstPage() async {
    final page = await _repository.fetchChangeRequests(page: 1);
    return SubscriptionChangeRequestListState(
      changeRequests: page.changeRequests,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
    );
  }
}
