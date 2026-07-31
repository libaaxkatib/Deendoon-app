import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../domain/aging_analysis.dart';

/// §5.5 — deliberately NOT scoped to the Overview's date range. Every
/// bucket is defined purely in terms of "days between due date and today"
/// (`ReportingService::assignBucket()`), a current-state concept that an
/// arbitrary look-back window doesn't change; §5.5 itself has no date
/// range component in its own layout, unlike §5.3/§5.4 which explicitly
/// do. A single live snapshot of every currently-open debt.
final agingAnalysisProvider = FutureProvider<AgingAnalysis>((ref) {
  return ref.read(analyticsRepositoryProvider).fetchAgingAnalysis();
});
