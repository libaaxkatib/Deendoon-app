import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/storage_addon.dart';
import '../domain/subscription.dart';
import '../domain/subscription_change_request.dart';
import '../domain/subscription_change_request_page.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_storage.dart';
import 'subscription_api.dart';

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) => SubscriptionRepository(ref.read(subscriptionApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no calculation: each method is
/// a direct pass-through to the matching `SubscriptionApi` call.
class SubscriptionRepository {
  final SubscriptionApi _api;

  const SubscriptionRepository(this._api);

  Future<Subscription> fetchSubscription() => _guard(() => _api.fetch());

  Future<List<SubscriptionPlan>> fetchPlans() => _guard(() => _api.fetchPlans());

  Future<SubscriptionChangeRequestPage> fetchChangeRequests({required int page}) =>
      _guard(() => _api.fetchChangeRequests(page: page));

  Future<SubscriptionChangeRequest> requestUpgrade({
    required String requestedPlanId,
    required String paymentReference,
  }) =>
      _guard(() => _api.requestUpgrade(requestedPlanId: requestedPlanId, paymentReference: paymentReference));

  Future<SubscriptionChangeRequest> cancelChangeRequest(String id) => _guard(() => _api.cancelChangeRequest(id));

  Future<SubscriptionStorage> fetchStorage() => _guard(() => _api.fetchStorage());

  Future<StorageAddon> requestStorageAddon({
    required String storagePackage,
    required String paymentReference,
  }) =>
      _guard(() => _api.requestStorageAddon(storagePackage: storagePackage, paymentReference: paymentReference));

  Future<StorageAddon> cancelStorageAddon(String id) => _guard(() => _api.cancelStorageAddon(id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
