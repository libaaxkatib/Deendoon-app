import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/storage_addon.dart';
import '../domain/subscription.dart';
import '../domain/subscription_change_request.dart';
import '../domain/subscription_change_request_page.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_storage.dart';

final subscriptionApiProvider = Provider<SubscriptionApi>((ref) => SubscriptionApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/POST /subscription*` — mirrors
/// `App\Http\Controllers\SubscriptionController` exactly, Business Owner
/// scope only (every method there is gated by the `admin-only` Gate, which
/// the Business Owner's account satisfies under the current one-account-
/// per-tenant model). The Platform Admin Approval Center endpoints
/// (`admin/subscription/*`, `admin/storage-addons/*`) are deliberately not
/// wrapped here — out of Flutter's scope.
class SubscriptionApi {
  final Dio _dio;

  const SubscriptionApi(this._dio);

  Future<Subscription> fetch() async {
    final response = await _dio.get('subscription');
    return Subscription.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<SubscriptionPlan>> fetchPlans() async {
    final response = await _dio.get('subscription/plans');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `SubscriptionController::changeRequests()` — always the authenticated
  /// tenant's own requests, no `status` filter (unlike the Platform Admin
  /// Approval Center's equivalent).
  Future<SubscriptionChangeRequestPage> fetchChangeRequests({required int page}) async {
    final response = await _dio.get('subscription/change-requests', queryParameters: {'page': page});
    return SubscriptionChangeRequestPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `SubscriptionUpgradeRequestRequest`: both fields required. 409s if a
  /// pending Subscription Change Request already exists for this tenant —
  /// surfaced as an `ApiException` by the repository layer, not handled
  /// here.
  Future<SubscriptionChangeRequest> requestUpgrade({
    required String requestedPlanId,
    required String paymentReference,
  }) async {
    final response = await _dio.post('subscription/upgrade-request', data: {
      'requested_plan_id': requestedPlanId,
      'payment_reference': paymentReference,
    });
    return SubscriptionChangeRequest.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<SubscriptionChangeRequest> cancelChangeRequest(String id) async {
    final response = await _dio.post('subscription/change-requests/$id/cancel');
    return SubscriptionChangeRequest.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<SubscriptionStorage> fetchStorage() async {
    final response = await _dio.get('subscription/storage');
    return SubscriptionStorage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `StorageAddonRequestRequest`: `storagePackage` must be one of
  /// `10gb`/`25gb`/`50gb`/`100gb` — `storage_size`/`monthly_price` are
  /// always derived server-side, never sent by the client. 409s if a
  /// pending Storage Add-on request already exists for this tenant.
  Future<StorageAddon> requestStorageAddon({
    required String storagePackage,
    required String paymentReference,
  }) async {
    final response = await _dio.post('subscription/storage-addon-request', data: {
      'storage_package': storagePackage,
      'payment_reference': paymentReference,
    });
    return StorageAddon.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StorageAddon> cancelStorageAddon(String id) async {
    final response = await _dio.post('subscription/storage-addon-requests/$id/cancel');
    return StorageAddon.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
