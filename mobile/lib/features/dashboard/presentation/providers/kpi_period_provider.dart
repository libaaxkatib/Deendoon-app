import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A selected KPI period: `key` is the real `GET /dashboard/kpis?period=`
/// value (`DashboardController::kpis()`/`ReportingService::periodBounds()`),
/// `label` is what the selector button/sheet displays. `dateFrom`/`dateTo`
/// (`YYYY-MM-DD`) are only set for `key == 'custom'`.
class KpiPeriodSelection {
  final String key;
  final String label;
  final String? dateFrom;
  final String? dateTo;

  const KpiPeriodSelection({
    required this.key,
    required this.label,
    this.dateFrom,
    this.dateTo,
  });

  static const thisMonth = KpiPeriodSelection(
    key: 'this_month',
    label: 'This Month',
  );
}

/// Selecting a period here actually changes the KPI figures —
/// `dashboardKpisProvider` watches this and refetches
/// `GET /dashboard/kpis` with the real `period` (and, for Custom Date
/// Range, `date_from`/`date_to`) query parameters.
final kpiPeriodProvider = StateProvider<KpiPeriodSelection>(
  (ref) => KpiPeriodSelection.thisMonth,
);

/// Real backend `period` values, in the order the picker sheet shows them.
/// Display labels are resolved from these keys at render time in
/// `kpi_period_selector.dart` (which has a `BuildContext` for
/// localization) — this file only owns state/data, not presentation text.
/// "Custom Date Range" isn't here — picking it opens a date range picker
/// instead of resolving straight to a fixed key (see `KpiPeriodSelector`).
const kpiPeriodKeys = <String>[
  'today',
  'yesterday',
  'this_week',
  'last_week',
  'this_month',
  'last_month',
  'this_quarter',
  'last_quarter',
  'this_year',
  'last_year',
];
