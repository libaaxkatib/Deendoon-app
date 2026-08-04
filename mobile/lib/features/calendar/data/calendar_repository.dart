import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/calendar_data.dart';
import 'calendar_api.dart';

final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository(ref.read(calendarApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no business logic.
class CalendarRepository {
  final CalendarApi _api;

  const CalendarRepository(this._api);

  Future<CalendarData> fetchEntries({String? from, String? to}) => _guard(() => _api.fetch(from: from, to: to));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
