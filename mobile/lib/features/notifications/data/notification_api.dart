import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/notification_page.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) => NotificationApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/PATCH /notifications*`, mirroring
/// `NotificationController` exactly. There is no `POST /notifications` —
/// every row is created internally by its owning module's service, never
/// via a client request (07_API_Design.md §11) — and no single-item
/// `GET /notifications/{id}` either, so Notification Detail is only
/// reachable from an already-loaded list item, never deep-linked.
class NotificationApi {
  final Dio _dio;

  const NotificationApi(this._dio);

  Future<NotificationPage> list({required int page, String? type}) async {
    final response = await _dio.get('notifications', queryParameters: {
      'page': page,
      'type': ?type,
    });
    return NotificationPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NotificationPage> history({required int page}) async {
    final response = await _dio.get('notifications/history', queryParameters: {'page': page});
    return NotificationPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> markRead(String id) async {
    await _dio.patch('notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('notifications/mark-all-read');
  }
}
