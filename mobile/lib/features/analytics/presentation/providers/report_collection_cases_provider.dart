import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cases/domain/collection_case.dart';
import '../../data/analytics_repository.dart';

/// §5.2 Reports — Collection Cases category. Real filter: `status`
/// (`case_status` ∈ open/closed — `ReportController::
/// collectionCasesQuery()`). Distinct from the Cases module's own
/// `GET /collection-cases?tab=` (high_risk/follow_up/promise_due) — a
/// different query param on the same table, not reused here.
class ReportCollectionCasesState {
  final List<CollectionCase> cases;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? status;
  final bool isLoadingMore;
  final bool loadMoreError;

  const ReportCollectionCasesState({
    required this.cases,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReportCollectionCasesState copyWith({
    List<CollectionCase>? cases,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return ReportCollectionCasesState(
      cases: cases ?? this.cases,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final reportCollectionCasesProvider =
    AsyncNotifierProvider<
      ReportCollectionCasesNotifier,
      ReportCollectionCasesState
    >(ReportCollectionCasesNotifier.new);

class ReportCollectionCasesNotifier
    extends AsyncNotifier<ReportCollectionCasesState> {
  @override
  Future<ReportCollectionCasesState> build() => _fetchFirstPage(status: null);

  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  Future<void> filterByStatus(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(status: status));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(status: current?.status),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchReportCollectionCases(
        page: current.currentPage + 1,
        status: current.status,
      );
      state = AsyncData(
        current.copyWith(
          cases: [...current.cases, ...next.cases],
          currentPage: next.currentPage,
          lastPage: next.lastPage,
          total: next.total,
          isLoadingMore: false,
          loadMoreError: false,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: true),
      );
    }
  }

  Future<ReportCollectionCasesState> _fetchFirstPage({
    required String? status,
  }) async {
    final page = await _repository.fetchReportCollectionCases(
      page: 1,
      status: status,
    );
    return ReportCollectionCasesState(
      cases: page.cases,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
    );
  }
}
