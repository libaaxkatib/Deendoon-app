import 'storage_addon.dart';

/// Mirrors `SubscriptionController::storage()` exactly — the response
/// shape of `GET /subscription/storage`. `storageLimitGb`/`remainingStorageGb`
/// are null only when the tenant has no resolvable plan at all (see
/// `StorageAddonService::totalStorageAllowance()`'s docblock) — never a
/// stand-in for "unlimited" or "zero".
class SubscriptionStorage {
  final int storageUsageBytes;
  final double storageUsageGb;
  final int? storageLimitGb;
  final List<StorageAddon> purchasedAddons;
  final double? remainingStorageGb;

  const SubscriptionStorage({
    required this.storageUsageBytes,
    required this.storageUsageGb,
    required this.storageLimitGb,
    required this.purchasedAddons,
    required this.remainingStorageGb,
  });

  factory SubscriptionStorage.fromJson(Map<String, dynamic> json) => SubscriptionStorage(
        storageUsageBytes: json['storage_usage_bytes'] as int,
        storageUsageGb: (json['storage_usage_gb'] as num).toDouble(),
        storageLimitGb: json['storage_limit_gb'] as int?,
        purchasedAddons: (json['purchased_addons'] as List<dynamic>)
            .map((e) => StorageAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
        remainingStorageGb: (json['remaining_storage_gb'] as num?)?.toDouble(),
      );
}
