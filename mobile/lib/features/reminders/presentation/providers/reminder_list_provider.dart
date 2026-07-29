import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';

/// Immutable snapshot of the tenant-wide, paginated, tab-filtered
/// Reminder List — real backend pagination/filtering only, no local
/// filtering. `tab` is the ONLY real filter `GET /reminders` supports
/// (one of: all/today/upcoming/overdue/completed) — there is no
/// `customer_id`/`debt_id`/`case_id`/`reminder_type`/`delivery_channel`/
/// date-range/`search` parameter (see the Sprint 14 summary's "Missing
/// Backend Support Required").
class ReminderListState {
  final List<Reminder> reminders;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? tab;
  final bool isLoadingMore;

  const ReminderListState({
    required this.reminders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.tab,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReminderListState copyWith({
    List<Reminder>? reminders,
    int? currentPage,
    int? lastPage,
    int? total,
    String? tab,
    bool? isLoadingMore,
  }) {
    return ReminderListState(
      reminders: reminders ?? this.reminders,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      tab: tab ?? this.tab,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final reminderListProvider = AsyncNotifierProvider<ReminderListNotifier, ReminderListState>(ReminderListNotifier.new);

class ReminderListNotifier extends AsyncNotifier<ReminderListState> {
  @override
  Future<ReminderListState> build() => _fetchFirstPage(tab: null);

  ReminderRepository get _repository => ref.read(reminderRepositoryProvider);

  /// `tab` is one of the five real, approved values (or null for "All") —
  /// always a real API call, never a client-side filter.
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

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchReminders(page: current.currentPage + 1, tab: current.tab);
      state = AsyncData(current.copyWith(
        reminders: [...current.reminders, ...next.reminders],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Optimistically replaces one reminder in-place after Complete —
  /// avoids re-fetching the whole page just to reflect one status change,
  /// while still relying entirely on the server's own returned resource
  /// (not a client-computed value) for the replacement.
  void replaceReminder(Reminder updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      reminders: [for (final r in current.reminders) if (r.id == updated.id) updated else r],
    ));
  }

  /// Removes a deleted reminder from the currently visible page.
  void removeReminder(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      reminders: current.reminders.where((r) => r.id != id).toList(),
      total: current.total - 1,
    ));
  }

  Future<ReminderListState> _fetchFirstPage({required String? tab}) async {
    final page = await _repository.fetchReminders(page: 1, tab: tab);
    return ReminderListState(
      reminders: page.reminders,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      tab: tab,
    );
  }
}
