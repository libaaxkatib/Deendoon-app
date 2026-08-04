import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/business_profile.dart';
import 'business_profile_api.dart';

final businessProfileRepositoryProvider =
    Provider<BusinessProfileRepository>((ref) => BusinessProfileRepository(ref.read(businessProfileApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as
/// `CustomerRepository`/`DebtRepository`. No caching, no calculation: each
/// method is a direct pass-through to the matching `BusinessProfileApi` call.
class BusinessProfileRepository {
  final BusinessProfileApi _api;

  const BusinessProfileRepository(this._api);

  Future<BusinessProfile> fetchBusinessProfile() => _guard(() => _api.fetch());

  Future<BusinessProfile> updateBusinessProfile({
    required String businessName,
    String? address,
    String? contactEmail,
    String? contactPhone,
    MultipartFile? logo,
  }) =>
      _guard(() => _api.update(
            businessName: businessName,
            address: address,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            logo: logo,
          ));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
