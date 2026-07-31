import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../domain/risk_distribution.dart';

/// §5.6 — a live snapshot of the full active customer base, not scoped to
/// any date range (the backend endpoint takes no date parameters at all).
final riskDistributionProvider = FutureProvider<RiskDistribution>((ref) {
  return ref.read(analyticsRepositoryProvider).fetchRiskDistribution();
});
