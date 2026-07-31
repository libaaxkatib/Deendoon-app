/// Mirrors `ReportingService::collectionAnalytics()` exactly (§5.4). No
/// "vs previous period" delta exists anywhere in this payload — the
/// backend does not compute one (confirmed by reading the full service),
/// so none is displayed, per explicit product decision for this sprint.
class CollectionAnalytics {
  final double collectionRate;
  final String totalCollected;
  final double? averageDays;

  const CollectionAnalytics({
    required this.collectionRate,
    required this.totalCollected,
    required this.averageDays,
  });

  factory CollectionAnalytics.fromJson(Map<String, dynamic> json) => CollectionAnalytics(
        collectionRate: (json['collection_rate'] as num).toDouble(),
        totalCollected: json['total_collected'] as String,
        averageDays: (json['average_days'] as num?)?.toDouble(),
      );
}
