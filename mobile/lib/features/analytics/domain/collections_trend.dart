/// Mirrors `ReportingService::collectionsTrend()` exactly (§5.3). The
/// backend only supports the `collected_amount` metric — `outstanding_amount`
/// and `risk_concentration` are rejected server-side (422) because neither
/// field has point-in-time history retained anywhere in the schema. This
/// model, and every screen using it, is scoped to `collected_amount` only,
/// per explicit product decision for this sprint — no metric switcher.
class TrendPoint {
  final String date;
  final String value;

  const TrendPoint({required this.date, required this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: json['date'] as String,
        value: json['value'] as String,
      );
}

class CollectionsTrend {
  final String metric;
  final List<TrendPoint> series;

  const CollectionsTrend({required this.metric, required this.series});

  factory CollectionsTrend.fromJson(Map<String, dynamic> json) {
    final series = json['series'] as List<dynamic>;
    return CollectionsTrend(
      metric: json['metric'] as String,
      series: series.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
