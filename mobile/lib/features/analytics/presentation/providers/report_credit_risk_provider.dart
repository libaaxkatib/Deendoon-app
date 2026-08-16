import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customers/domain/customer.dart';
import '../../data/analytics_repository.dart';

/// §5.2 Reports — Credit Risk category. Reuses the identical `Customer`
/// model/shape as the Customers report (`ReportController::creditRisk()`
/// calls the same private `customersQuery()`, just ordered by
/// `credit_score` desc) — a separate provider because it's a distinct
/// endpoint/category in the approved UI, not because the data differs.
class ReportCreditRiskState {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? riskLevel;
  final bool isLoadingMore;
  final bool loadMoreError;

  const ReportCreditRiskState({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.riskLevel,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReportCreditRiskState copyWith({
    List<Customer>? customers,
    int? currentPage,
    int? lastPage,
    int? total,
    String? riskLevel,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return ReportCreditRiskState(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      riskLevel: riskLevel ?? this.riskLevel,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final reportCreditRiskProvider =
    AsyncNotifierProvider<ReportCreditRiskNotifier, ReportCreditRiskState>(
      ReportCreditRiskNotifier.new,
    );

class ReportCreditRiskNotifier extends AsyncNotifier<ReportCreditRiskState> {
  @override
  Future<ReportCreditRiskState> build() => _fetchFirstPage(riskLevel: null);

  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  Future<void> filterByRiskLevel(String? riskLevel) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(riskLevel: riskLevel));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(riskLevel: current?.riskLevel),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchReportCreditRisk(
        page: current.currentPage + 1,
        riskLevel: current.riskLevel,
      );
      state = AsyncData(
        current.copyWith(
          customers: [...current.customers, ...next.customers],
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

  Future<ReportCreditRiskState> _fetchFirstPage({
    required String? riskLevel,
  }) async {
    final page = await _repository.fetchReportCreditRisk(
      page: 1,
      riskLevel: riskLevel,
    );
    return ReportCreditRiskState(
      customers: page.customers,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      riskLevel: riskLevel,
    );
  }
}
