import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_repository.dart';
import '../../domain/storage_addon.dart';
import '../../domain/subscription_change_request.dart';
import 'subscription_change_request_list_provider.dart';
import 'subscription_providers.dart';

final subscriptionActionsProvider = Provider<SubscriptionActions>(
  (ref) => SubscriptionActions(ref),
);

/// The real, backend-supported Business Owner actions on Subscriptions and
/// Storage Add-ons: request an upgrade/downgrade, cancel a still-pending
/// Subscription Change Request, request a Storage Add-on, cancel a
/// still-pending Storage Add-on request. Approve/reject are Deendoon
/// Platform Administrator-only and are deliberately not exposed here — the
/// Platform Admin Approval Center is out of Flutter's scope entirely.
class SubscriptionActions {
  final Ref _ref;

  const SubscriptionActions(this._ref);

  SubscriptionRepository get _repository =>
      _ref.read(subscriptionRepositoryProvider);

  /// Creates a pending Subscription Change Request. Doesn't change the
  /// tenant's current active plan — that only happens once a Platform
  /// Administrator approves it — so only the change-request history list
  /// is invalidated, not `subscriptionProvider`.
  Future<SubscriptionChangeRequest> requestUpgrade({
    required String requestedPlanId,
    required String paymentReference,
  }) async {
    final changeRequest = await _repository.requestUpgrade(
      requestedPlanId: requestedPlanId,
      paymentReference: paymentReference,
    );
    _ref.invalidate(subscriptionChangeRequestListProvider);
    return changeRequest;
  }

  Future<SubscriptionChangeRequest> cancelChangeRequest(String id) async {
    final changeRequest = await _repository.cancelChangeRequest(id);
    _ref.invalidate(subscriptionChangeRequestListProvider);
    return changeRequest;
  }

  /// Creates a pending Storage Add-on request. `subscriptionStorageProvider`
  /// is invalidated defensively, but note `purchased_addons`/the storage
  /// limit only ever reflect *active* add-ons server-side
  /// (`StorageAddonService::activeAddons()`) — a newly created pending
  /// request won't actually appear there until a Platform Administrator
  /// approves it. There is no Business-Owner-facing endpoint that lists
  /// pending Storage Add-on requests; tracking/cancelling one relies on the
  /// id returned here, not on re-fetching a list.
  Future<StorageAddon> requestStorageAddon({
    required String storagePackage,
    required String paymentReference,
  }) async {
    final addon = await _repository.requestStorageAddon(
      storagePackage: storagePackage,
      paymentReference: paymentReference,
    );
    _ref.invalidate(subscriptionStorageProvider);
    return addon;
  }

  Future<StorageAddon> cancelStorageAddon(String id) async {
    final addon = await _repository.cancelStorageAddon(id);
    _ref.invalidate(subscriptionStorageProvider);
    return addon;
  }
}
