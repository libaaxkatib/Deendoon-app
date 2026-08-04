import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/calendar_data.dart';

final calendarApiProvider = Provider<CalendarApi>((ref) => CalendarApi(ref.read(dioProvider)));

/// Thin wrapper around `GET /calendar` — mirrors `CalendarController::index`
/// exactly. `from`/`to` are optional `YYYY-MM-DD` strings; the backend
/// defaults to the current month when omitted.
class CalendarApi {
  final Dio _dio;

  const CalendarApi(this._dio);

  Future<CalendarData> fetch({String? from, String? to}) async {
    final response = await _dio.get('calendar', queryParameters: {
      'from': ?from,
      'to': ?to,
    });
    return CalendarData.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
