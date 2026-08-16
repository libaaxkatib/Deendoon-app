import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';

/// Immutable snapshot of the tenant-wide, paginated, tab-filtered
/// Reminder List — real backend pagination/filtering only, no local
/// filtering of what's *fetched*. `tab` is the ONLY real filter
/// `GET /reminders` supports (one of: all/today/upcoming/overdue/
/// completed) — there is no `customer_id`/`debt_id`/`case_id`/
/// `reminder_type`/`delivery_channel`/date-range/`search` parameter (see
/// the Sprint 14 summary's "Missing Backend Support Required").
///
/// `typeFilter` is a client-side-only display filter (one of the five
/// real `Reminder.type` values already present on every fetched resource)
/// layered on top of the real `tab=null` ("All") fetch — it narrows which
/// already-fetched reminders are *shown*, it never changes what's
/// requested from the server. `tab` and `typeFilter` are mutually
/// exclusive in the UI (selecting one clears the other).
class ReminderListState {
  final List<Reminder> reminders;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? tab;
  final String? typeFilter;
  final bool isLoadingMore;
  final bool loadMoreError;

  const ReminderListState({
    required this.reminders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.tab,
    this.typeFilter,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReminderListState copyWith({
    List<Reminder>? reminders,
    int? currentPage,
    int? lastPage,
    int? total,
    String? tab,
    String? typeFilter,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return ReminderListState(
      reminders: reminders ?? this.reminders,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      tab: tab ?? this.tab,
      typeFilter: typeFilter ?? this.typeFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final reminderListProvider =
    AsyncNotifierProvider<ReminderListNotifier, ReminderListState>(
      ReminderListNotifier.new,
    );

class ReminderListNotifier extends AsyncNotifier<ReminderListState> {
  @override
  Future<ReminderListState> build() => _fetchFirstPage(tab: null);

  ReminderRepository get _repository => ref.read(reminderRepositoryProvider);

  /// `tab` is one of the five real, approved values (or null for "All") —
  /// always a real API call, never a client-side filter. Selecting a tab
  /// clears any active `typeFilter`, since the two are mutually exclusive
  /// in the UI.
  Future<void> filterByTab(String? tab) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(tab: tab));
  }

  /// Selects one of the five real `Reminder.type` values as a client-side
  /// display filter. Always fetches under `tab=null` ("All") — the
  /// backend has no `reminder_type` query parameter — and narrows what's
  /// shown to reminders whose real `type` field matches, in
  /// `ReminderListScreen`'s own build method.
  Future<void> filterByType(String type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(tab: null, typeFilter: type),
    );
  }

  Future<void> refresh() async {
    final tab = state.valueOrNull?.tab;
    final typeFilter = state.valueOrNull?.typeFilter;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(tab: tab, typeFilter: typeFilter),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchReminders(
        page: current.currentPage + 1,
        tab: current.tab,
      );
      state = AsyncData(
        current.copyWith(
          reminders: [...current.reminders, ...next.reminders],
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

  /// Optimistically replaces one reminder in-place after Complete —
  /// avoids re-fetching the whole page just to reflect one status change,
  /// while still relying entirely on the server's own returned resource
  /// (not a client-computed value) for the replacement.
  void replaceReminder(Reminder updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        reminders: [
          for (final r in current.reminders)
            if (r.id == updated.id) updated else r,
        ],
      ),
    );
  }

  /// Removes a deleted reminder from the currently visible page.
  void removeReminder(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        reminders: current.reminders.where((r) => r.id != id).toList(),
        total: current.total - 1,
      ),
    );
  }

  Future<ReminderListState> _fetchFirstPage({
    required String? tab,
    String? typeFilter,
  }) async {
    final page = await _repository.fetchReminders(page: 1, tab: tab);
    return ReminderListState(
      reminders: page.reminders,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      tab: tab,
      typeFilter: typeFilter,
    );
  }
}
