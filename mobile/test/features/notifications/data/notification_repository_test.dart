import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/notifications/data/notification_api.dart';
import 'package:mobile/features/notifications/data/notification_repository.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mobile/features/notifications/domain/notification_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationApi extends Mock implements NotificationApi {}

final _notification = AppNotification(
  id: '1',
  type: 'payment_received',
  relatedEntityType: 'payment',
  relatedEntityId: '01PAYMENT',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

void main() {
  late _MockNotificationApi mockApi;
  late NotificationRepository repository;

  setUp(() {
    mockApi = _MockNotificationApi();
    repository = NotificationRepository(mockApi);
  });

  test('fetchNotifications passes type through and returns the page', () async {
    final page = NotificationPage(notifications: [_notification], currentPage: 1, lastPage: 2, total: 21);
    when(() => mockApi.list(page: 1, type: 'payment_received')).thenAnswer((_) async => page);

    final result = await repository.fetchNotifications(page: 1, type: 'payment_received');

    expect(result.notifications, [_notification]);
  });

  test('fetchNotifications throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, type: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/notifications'),
        response: Response(
          requestOptions: RequestOptions(path: '/notifications'),
          statusCode: 401,
          data: {'success': false, 'message': 'Unauthenticated.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchNotifications(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('fetchHistory delegates to the api', () async {
    final page = NotificationPage(notifications: [_notification], currentPage: 1, lastPage: 1, total: 1);
    when(() => mockApi.history(page: 1)).thenAnswer((_) async => page);

    final result = await repository.fetchHistory(page: 1);

    expect(result.notifications, [_notification]);
  });

  test('markRead delegates to the api', () async {
    when(() => mockApi.markRead('1')).thenAnswer((_) async {});

    await repository.markRead('1');

    verify(() => mockApi.markRead('1')).called(1);
  });

  test('markAllRead delegates to the api', () async {
    when(() => mockApi.markAllRead()).thenAnswer((_) async {});

    await repository.markAllRead();

    verify(() => mockApi.markAllRead()).called(1);
  });
}
