import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/professional_collection_repository.dart';
import '../../domain/professional_collection_request.dart';

/// Immutable snapshot of the tenant-wide, paginated, status-filterable
/// Professional Collection Request List — real backend pagination/
/// filtering only, no local filtering.
class ProfessionalCollectionListState {
  final List<ProfessionalCollectionRequest> requests;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? status;
  final bool isLoadingMore;

  const ProfessionalCollectionListState({
    required this.requests,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ProfessionalCollectionListState copyWith({
    List<ProfessionalCollectionRequest>? requests,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? isLoadingMore,
    bool clearStatus = false,
  }) {
    return ProfessionalCollectionListState(
      requests: requests ?? this.requests,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: clearStatus ? null : (status ?? this.status),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final professionalCollectionListProvider =
    AsyncNotifierProvider<ProfessionalCollectionListNotifier, ProfessionalCollectionListState>(
  ProfessionalCollectionListNotifier.new,
);

class ProfessionalCollectionListNotifier extends AsyncNotifier<ProfessionalCollectionListState> {
  @override
  Future<ProfessionalCollectionListState> build() => _fetchFirstPage(status: null);

  ProfessionalCollectionRepository get _repository => ref.read(professionalCollectionRepositoryProvider);

  /// `status` is one of the real 8 status values or null for all — always
  /// a real API call, never a client-side filter.
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
      final next = await _repository.fetchRequests(page: current.currentPage + 1, status: current.status);
      state = AsyncData(current.copyWith(
        requests: [...current.requests, ...next.requests],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<ProfessionalCollectionListState> _fetchFirstPage({required String? status}) async {
    final page = await _repository.fetchRequests(page: 1, status: status);
    return ProfessionalCollectionListState(
      requests: page.requests,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
    );
  }
}
