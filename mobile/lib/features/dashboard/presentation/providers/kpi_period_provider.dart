import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TODO(Backend Required): `Dashboard KPI Summary retrieval API` has no
/// period parameter — selecting a period here only updates this local UI
/// state, matching the current "This Month" figures the API already
/// returns. No refetch, no client-side recomputation, no fabricated
/// values for any other period. Once the backend accepts a period
/// parameter, wire it into `dashboardKpisProvider`'s query here.
final kpiPeriodProvider = StateProvider<String>((ref) => 'This Month');

const kpiPeriodOptions = <String>[
  'Today',
  'Yesterday',
  'This Week',
  'Last Week',
  'This Month',
  'Last Month',
  'This Quarter',
  'Last Quarter',
  'This Year',
  'Last Year',
  'Custom Date Range',
];
