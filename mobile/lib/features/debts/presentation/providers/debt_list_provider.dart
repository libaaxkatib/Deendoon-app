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
  final bool isLoadingMore;

  const DebtListState({
    required this.debts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  DebtListState copyWith({
    List<Debt>? debts,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? isLoadingMore,
    bool clearStatus = false,
  }) {
    return DebtListState(
      debts: debts ?? this.debts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: clearStatus ? null : (status ?? this.status),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Keyed by customer id — Debts are always viewed within a customer's
/// context (`Dashboard → Customers → Customer Details → Debt Details`),
/// matching `GET /debts?customer_id=...`, the only backend-supported way
/// to scope a debt list to one customer.
final debtListProvider =
    AsyncNotifierProvider.family<DebtListNotifier, DebtListState, String>(DebtListNotifier.new);

class DebtListNotifier extends FamilyAsyncNotifier<DebtListState, String> {
  late final String customerId;

  @override
  Future<DebtListState> build(String arg) {
    customerId = arg;
    return _fetchFirstPage(status: null);
  }

  DebtRepository get _repository => ref.read(debtRepositoryProvider);

  /// `status` is one of the real `debt_status` values (draft, pending,
  /// overdue, partial_paid, paid, cancelled, written_off) or null for all —
  /// always a real API call, never a client-side filter.
  Future<void> filterByStatus(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(status: status));
  }

  Future<void> refresh() async {
    final status = state.valueOrNull?.status;
    state = await AsyncValue.guard(() => _fetchFirstPage(status: status));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchDebts(
        page: current.currentPage + 1,
        customerId: customerId,
        status: current.status,
      );
      state = AsyncData(current.copyWith(
        debts: [...current.debts, ...next.debts],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<DebtListState> _fetchFirstPage({required String? status}) async {
    final page = await _repository.fetchDebts(page: 1, customerId: customerId, status: status);
    return DebtListState(
      debts: page.debts,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
    );
  }
}
