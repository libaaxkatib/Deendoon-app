/// Mirrors `DocumentService::storageUsage()` exactly. Two real, honest
/// caveats confirmed by reading the backend in full:
/// - `used_bytes` sums Receipt + DemandLetter + Statement `file_size`
///   only — Invoice is NOT included in the sum (a backend gap, not a
///   client bug — see the Sprint 15 summary's "Backend Blockers").
/// - `total_bytes` is a single hardcoded env-configurable default
///   (10 GiB), not a real per-tenant quota/plan — there is no tenant-level
///   quota column anywhere in the schema.
class StorageUsage {
  final int usedBytes;
  final int totalBytes;
  final double usedPercentage;

  const StorageUsage({
    required this.usedBytes,
    required this.totalBytes,
    required this.usedPercentage,
  });

  factory StorageUsage.fromJson(Map<String, dynamic> json) => StorageUsage(
    usedBytes: json['used_bytes'] as int,
    totalBytes: json['total_bytes'] as int,
    usedPercentage: (json['used_percentage'] as num).toDouble(),
  );
}
