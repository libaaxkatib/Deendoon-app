import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

/// Immutable snapshot of the tenant-wide, paginated Notification List —
/// real backend pagination only, no local filtering beyond the one real
/// `type` query parameter `GET /notifications` supports.
class NotificationListState {
  final List<AppNotification> notifications;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? type;
  final bool isLoadingMore;

  const NotificationListState({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.type,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;
  bool get hasUnread => notifications.any((n) => !n.isRead);

  NotificationListState copyWith({
    List<AppNotification>? notifications,
    int? currentPage,
    int? lastPage,
    int? total,
    String? type,
    bool? isLoadingMore,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      type: type ?? this.type,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final notificationListProvider =
    AsyncNotifierProvider<NotificationListNotifier, NotificationListState>(NotificationListNotifier.new);

class NotificationListNotifier extends AsyncNotifier<NotificationListState> {
  @override
  Future<NotificationListState> build() => _fetchFirstPage(type: null);

  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  Future<void> filterByType(String? type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(type: type));
  }

  Future<void> refresh() async {
    final type = state.valueOrNull?.type;
    state = await AsyncValue.guard(() => _fetchFirstPage(type: type));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchNotifications(page: current.currentPage + 1, type: current.type);
      state = AsyncData(current.copyWith(
        notifications: [...current.notifications, ...next.notifications],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Marks one notification read against the real endpoint, then updates
  /// it in place — avoids re-fetching the whole page for one field change.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final target = current.notifications.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    await _repository.markRead(id);
    state = AsyncData(current.copyWith(
      notifications: [
        for (final n in current.notifications) if (n.id == id) n.copyWith(readAt: DateTime.now()) else n,
      ],
    ));
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _repository.markAllRead();
    final now = DateTime.now();
    state = AsyncData(current.copyWith(
      notifications: [for (final n in current.notifications) n.isRead ? n : n.copyWith(readAt: now)],
    ));
  }

  Future<NotificationListState> _fetchFirstPage({required String? type}) async {
    final page = await _repository.fetchNotifications(page: 1, type: type);
    return NotificationListState(
      notifications: page.notifications,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      type: type,
    );
  }
}
