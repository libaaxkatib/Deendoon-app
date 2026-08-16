import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_case_repository.dart';
import '../../domain/collection_case.dart';

/// Immutable snapshot of the tenant-wide, paginated, filterable Case
/// List — real backend pagination/filtering only, no local filtering.
/// Not scoped to a customer or debt: `GET /collection-cases` has no
/// `customer_id`/`debt_id` filter, only `tab` (all/high_risk/follow_up/
/// promise_due).
class CaseListState {
  final List<CollectionCase> cases;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? tab;
  final bool isLoadingMore;
  final bool loadMoreError;

  const CaseListState({
    required this.cases,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.tab,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  CaseListState copyWith({
    List<CollectionCase>? cases,
    int? currentPage,
    int? lastPage,
    int? total,
    String? tab,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return CaseListState(
      cases: cases ?? this.cases,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      tab: tab ?? this.tab,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final caseListProvider = AsyncNotifierProvider<CaseListNotifier, CaseListState>(
  CaseListNotifier.new,
);

class CaseListNotifier extends AsyncNotifier<CaseListState> {
  @override
  Future<CaseListState> build() => _fetchFirstPage(tab: null);

  CollectionCaseRepository get _repository =>
      ref.read(collectionCaseRepositoryProvider);

  /// `tab` is one of the four real, approved filter values (or null for
  /// "All") — always a real API call, never a client-side filter.
  Future<void> filterByTab(String? tab) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(tab: tab));
  }

  Future<void> refresh() async {
    final tab = state.valueOrNull?.tab;
    state = await AsyncValue.guard(() => _fetchFirstPage(tab: tab));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchCases(
        page: current.currentPage + 1,
        tab: current.tab,
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

  Future<CaseListState> _fetchFirstPage({required String? tab}) async {
    final page = await _repository.fetchCases(page: 1, tab: tab);
    return CaseListState(
      cases: page.cases,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      tab: tab,
    );
  }
}
