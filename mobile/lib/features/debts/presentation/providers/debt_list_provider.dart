import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/debt_repository.dart';
import '../../domain/debt.dart';

/// Immutable snapshot of one customer's paginated, filterable Debt List —
/// real backend pagination/filtering only, no local filtering.
class DebtListState {
  final List<Debt> debts;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? status;
  final bool includeArchived;
  final bool isLoadingMore;
  final bool loadMoreError;

  const DebtListState({
    required this.debts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    required this.includeArchived,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  DebtListState copyWith({
    List<Debt>? debts,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? includeArchived,
    bool? isLoadingMore,
    bool? loadMoreError,
    bool clearStatus = false,
  }) {
    return DebtListState(
      debts: debts ?? this.debts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: clearStatus ? null : (status ?? this.status),
      includeArchived: includeArchived ?? this.includeArchived,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

/// Keyed by customer id — Debts are always viewed within a customer's
/// context (`Dashboard → Customers → Customer Details → Debt Details`),
/// matching `GET /debts?customer_id=...`, the only backend-supported way
/// to scope a debt list to one customer.
final debtListProvider =
    AsyncNotifierProvider.family<DebtListNotifier, DebtListState, String>(
      DebtListNotifier.new,
    );

class DebtListNotifier extends FamilyAsyncNotifier<DebtListState, String> {
  @override
  Future<DebtListState> build(String arg) {
    return _fetchFirstPage(status: null, includeArchived: false);
  }

  DebtRepository get _repository => ref.read(debtRepositoryProvider);

  /// `status` is one of the real `debt_status` values (draft, pending,
  /// overdue, partial_paid, paid, cancelled, written_off) or null for all —
  /// always a real API call, never a client-side filter.
  Future<void> filterByStatus(String? status) async {
    final includeArchived = state.valueOrNull?.includeArchived ?? false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(status: status, includeArchived: includeArchived),
    );
  }

  /// "Show Archived" filter chip — a real `includeArchived` query param on
  /// `GET /debts` (`DebtController::index()`), not a client-side filter.
  Future<void> toggleIncludeArchived() async {
    final status = state.valueOrNull?.status;
    final includeArchived = !(state.valueOrNull?.includeArchived ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(status: status, includeArchived: includeArchived),
    );
  }

  Future<void> refresh() async {
    final status = state.valueOrNull?.status;
    final includeArchived = state.valueOrNull?.includeArchived ?? false;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(status: status, includeArchived: includeArchived),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchDebts(
        page: current.currentPage + 1,
        customerId: arg,
        status: current.status,
        includeArchived: current.includeArchived,
      );
      state = AsyncData(
        current.copyWith(
          debts: [...current.debts, ...next.debts],
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

  Future<DebtListState> _fetchFirstPage({
    required String? status,
    required bool includeArchived,
  }) async {
    final page = await _repository.fetchDebts(
      page: 1,
      customerId: arg,
      status: status,
      includeArchived: includeArchived,
    );
    return DebtListState(
      debts: page.debts,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
      includeArchived: includeArchived,
    );
  }
}
