/// Mirrors `App\Http\Resources\StorageAddonResource` exactly — returned by
/// `GET /subscription/storage` (`purchased_addons`), `POST /subscription/
/// storage-addon-request`, and `POST /subscription/storage-addon-requests/
/// {id}/cancel`.
///
/// `monthlyPrice` stays a `String` because `StorageAddon::monthly_price` is
/// cast `decimal:2` server-side (Eloquent serializes decimals as strings).
/// `tenantName` is null for every Business Owner-scoped call (this
/// feature's only scope) — only the Platform Admin Approval Center loads
/// `tenant`.
class StorageAddon {
  final String id;
  final String tenantId;
  final String? tenantName;
  final String storagePackage;
  final int storageSize;
  final String monthlyPrice;
  final String paymentReference;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final List<String>? rejectionReasons;

  const StorageAddon({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.storagePackage,
    required this.storageSize,
    required this.monthlyPrice,
    required this.paymentReference,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.approvedBy,
    required this.approvedAt,
    required this.rejectionReason,
    required this.rejectionReasons,
  });

  factory StorageAddon.fromJson(Map<String, dynamic> json) => StorageAddon(
        id: json['id'].toString(),
        tenantId: json['tenant_id'].toString(),
        tenantName: json['tenant_name'] as String?,
        storagePackage: json['storage_package'] as String,
        storageSize: json['storage_size'] as int,
        monthlyPrice: json['monthly_price'] as String,
        paymentReference: json['payment_reference'] as String,
        status: json['status'] as String,
        startedAt: json['started_at'] == null ? null : DateTime.parse(json['started_at'] as String),
        expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
        approvedBy: json['approved_by']?.toString(),
        approvedAt: json['approved_at'] == null ? null : DateTime.parse(json['approved_at'] as String),
        rejectionReason: json['rejection_reason'] as String?,
        rejectionReasons: (json['rejection_reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
}
