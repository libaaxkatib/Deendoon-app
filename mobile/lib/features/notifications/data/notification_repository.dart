import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/notification_page.dart';
import 'notification_api.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.read(notificationApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app.
class NotificationRepository {
  final NotificationApi _api;

  const NotificationRepository(this._api);

  Future<NotificationPage> fetchNotifications({
    required int page,
    String? type,
  }) => _guard(() => _api.list(page: page, type: type));

  Future<NotificationPage> fetchHistory({required int page}) =>
      _guard(() => _api.history(page: page));

  Future<void> markRead(String id) => _guard(() => _api.markRead(id));

  Future<void> markAllRead() => _guard(() => _api.markAllRead());

  Future<void> deleteNotification(String id) => _guard(() => _api.delete(id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
