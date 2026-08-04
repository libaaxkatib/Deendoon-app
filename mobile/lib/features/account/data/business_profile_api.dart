import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/business_profile.dart';

final businessProfileApiProvider =
    Provider<BusinessProfileApi>((ref) => BusinessProfileApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/PUT /admin/settings/company-profile` — mirrors
/// `App\Http\Controllers\AdminSettingsController` exactly (FR-068). The
/// endpoint is gated by the backend's `admin-only` Gate, which the
/// Business Owner's account satisfies under the current one-account-per-
/// tenant model (Business Owner == role `admin`, per the RBAC Architecture
/// Amendment) — real and reachable, not a stub.
class BusinessProfileApi {
  final Dio _dio;

  const BusinessProfileApi(this._dio);

  Future<BusinessProfile> fetch() async {
    final response = await _dio.get('admin/settings/company-profile');
    return BusinessProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Sent as a real `POST` with a `_method` override field rather than a
  /// genuine HTTP `PUT`, even though the registered route is
  /// `Route::put(...)`. This isn't a workaround for a backend limitation —
  /// it's standard Laravel behavior: PHP only parses a multipart body into
  /// `$_FILES` for an actual `POST` request, so a raw `PUT` carrying the
  /// logo file would leave `$request->file('logo')` empty server-side.
  /// Laravel's router still matches this to the registered `PUT` route via
  /// its own method-override support — no backend change needed.
  ///
  /// `address`/`contactEmail`/`contactPhone` are omitted from the form
  /// entirely (not sent as empty strings) when blank, since the service
  /// unconditionally assigns `$data[field] ?? null` — omitting the key is
  /// what actually clears the field server-side; an empty string would
  /// instead fail `contact_email`'s `email` format rule.
  Future<BusinessProfile> update({
    required String businessName,
    String? address,
    String? contactEmail,
    String? contactPhone,
    MultipartFile? logo,
  }) async {
    final formData = FormData.fromMap({
      '_method': 'PUT',
      'business_name': businessName,
      'address': ?(address != null && address.isNotEmpty ? address : null),
      'contact_email': ?(contactEmail != null && contactEmail.isNotEmpty ? contactEmail : null),
      'contact_phone': ?(contactPhone != null && contactPhone.isNotEmpty ? contactPhone : null),
      'logo': ?logo,
    });
    final response = await _dio.post('admin/settings/company-profile', data: formData);
    return BusinessProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
