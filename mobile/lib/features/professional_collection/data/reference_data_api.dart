import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/reference_data_item.dart';

final referenceDataApiProvider = Provider<ReferenceDataApi>(
  (ref) => ReferenceDataApi(ref.read(dioProvider)),
);

/// Thin wrapper around `GET admin/reference-data/{category}` — mirrors
/// `App\Http\Controllers\AdminReferenceDataController::show`. Gated by the
/// `admin-only` Gate, which in this codebase's RBAC resolves to the tenant
/// Business Owner (`hasRole('admin')`) — reachable despite the `admin/`
/// URL prefix, not restricted to the Deendoon Platform Administrator.
/// Only `show` is wrapped; `update` is out of this feature's scope.
class ReferenceDataApi {
  final Dio _dio;

  const ReferenceDataApi(this._dio);

  Future<List<ReferenceDataItem>> forCategory(String category) async {
    final response = await _dio.get('admin/reference-data/$category');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => ReferenceDataItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
