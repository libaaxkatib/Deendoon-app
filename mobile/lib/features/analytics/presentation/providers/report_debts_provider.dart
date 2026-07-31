import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../debts/domain/debt.dart';
import '../../data/analytics_repository.dart';

/// §5.2 Reports — Debts category. Real, backend-supported filter only:
/// `status` (`ReportController::debtsQuery()`). This is a distinct,
/// tenant-wide endpoint from the Debts module's own per-customer
/// `GET /debts` — a separate provider, not a reuse of `debtListProvider`.
class ReportDebtsState {
  final List<Debt> debts;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? status;
  final bool isLoadingMore;

  const ReportDebtsState({
    required this.debts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReportDebtsState copyWith({
    List<Debt>? debts,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? isLoadingMore,
  }) {
    return ReportDebtsState(
      debts: debts ?? this.debts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final reportDebtsProvider = AsyncNotifierProvider<ReportDebtsNotifier, ReportDebtsState>(ReportDebtsNotifier.new);

class ReportDebtsNotifier extends AsyncNotifier<ReportDebtsState> {
  @override
  Future<ReportDebtsState> build() => _fetchFirstPage(status: null);

  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  Future<void> filterByStatus(String? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(status: status));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(() => _fetchFirstPage(status: current?.status));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchReportDebts(page: current.currentPage + 1, status: current.status);
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

  Future<ReportDebtsState> _fetchFirstPage({required String? status}) async {
    final page = await _repository.fetchReportDebts(page: 1, status: status);
    return ReportDebtsState(
      debts: page.debts,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
    );
  }
}
