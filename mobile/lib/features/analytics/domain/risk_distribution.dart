/// Mirrors `ReportingService::riskDistribution()` exactly (§5.6). Always
/// exactly 3 segments (high/medium/low) — unclassified customers are
/// excluded from the percentage base by the backend itself, not by this
/// model.
class RiskSegment {
  final String riskLevel;
  final int customerCount;
  final double percentage;

  const RiskSegment({
    required this.riskLevel,
    required this.customerCount,
    required this.percentage,
  });

  factory RiskSegment.fromJson(Map<String, dynamic> json) => RiskSegment(
        riskLevel: json['risk_level'] as String,
        customerCount: json['customer_count'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class RiskDistribution {
  final List<RiskSegment> segments;

  const RiskDistribution({required this.segments});

  factory RiskDistribution.fromJson(Map<String, dynamic> json) {
    final segments = json['segments'] as List<dynamic>;
    return RiskDistribution(
      segments: segments.map((e) => RiskSegment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
