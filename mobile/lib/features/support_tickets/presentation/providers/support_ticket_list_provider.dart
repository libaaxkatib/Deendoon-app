import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/support_ticket_repository.dart';
import '../../domain/support_ticket.dart';

/// Paginated, status-filtered My Tickets list — real backend pagination/
/// filtering only, mirroring ReminderListState's shape.
class SupportTicketListState {
  final List<SupportTicket> tickets;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? status;
  final bool isLoadingMore;
  final bool loadMoreError;

  const SupportTicketListState({
    required this.tickets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.status,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  SupportTicketListState copyWith({
    List<SupportTicket>? tickets,
    int? currentPage,
    int? lastPage,
    int? total,
    String? status,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return SupportTicketListState(
      tickets: tickets ?? this.tickets,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final supportTicketListProvider =
    AsyncNotifierProvider<SupportTicketListNotifier, SupportTicketListState>(
      SupportTicketListNotifier.new,
    );

class SupportTicketListNotifier extends AsyncNotifier<SupportTicketListState> {
  @override
  Future<SupportTicketListState> build() => _fetchFirstPage(status: null);

  SupportTicketRepository get _repository =>
      ref.read(supportTicketRepositoryProvider);

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

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchTickets(
        page: current.currentPage + 1,
        status: current.status,
      );
      state = AsyncData(
        current.copyWith(
          tickets: [...current.tickets, ...next.tickets],
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

  Future<SupportTicketListState> _fetchFirstPage({
    required String? status,
  }) async {
    final page = await _repository.fetchTickets(page: 1, status: status);
    return SupportTicketListState(
      tickets: page.tickets,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      status: status,
    );
  }
}
