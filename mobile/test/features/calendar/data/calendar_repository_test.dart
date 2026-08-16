import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/calendar/data/calendar_api.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_data.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarApi extends Mock implements CalendarApi {}

void main() {
  late _MockCalendarApi mockApi;
  late CalendarRepository repository;

  setUp(() {
    mockApi = _MockCalendarApi();
    repository = CalendarRepository(mockApi);
  });

  test(
    'fetchEntries passes from/to through and returns the parsed data',
    () async {
      const data = CalendarData(
        from: '2026-08-01',
        to: '2026-08-31',
        entries: [],
      );
      when(
        () => mockApi.fetch(from: '2026-08-01', to: '2026-08-31'),
      ).thenAnswer((_) async => data);

      final result = await repository.fetchEntries(
        from: '2026-08-01',
        to: '2026-08-31',
      );

      expect(result.from, '2026-08-01');
      expect(result.to, '2026-08-31');
    },
  );

  test('fetchEntries throws ApiException on failure', () async {
    when(
      () => mockApi.fetch(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/calendar'),
        response: Response(
          requestOptions: RequestOptions(path: '/calendar'),
          statusCode: 403,
          data: {
            'success': false,
            'message': 'This action is unauthorized.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchEntries(from: '2026-08-01', to: '2026-08-31'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });
}
