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

  const KpiPeriodSelection({required this.key, required this.label, this.dateFrom, this.dateTo});

  static const thisMonth = KpiPeriodSelection(key: 'this_month', label: 'This Month');
}

/// Selecting a period here actually changes the KPI figures —
/// `dashboardKpisProvider` watches this and refetches
/// `GET /dashboard/kpis` with the real `period` (and, for Custom Date
/// Range, `date_from`/`date_to`) query parameters.
final kpiPeriodProvider = StateProvider<KpiPeriodSelection>((ref) => KpiPeriodSelection.thisMonth);

/// Label -> real backend `period` value, in the order the picker sheet
/// shows them. "Custom Date Range" isn't here — picking it opens a date
/// range picker instead of resolving straight to a fixed key (see
/// `KpiPeriodSelector`).
const kpiPeriodOptions = <String, String>{
  'Today': 'today',
  'Yesterday': 'yesterday',
  'This Week': 'this_week',
  'Last Week': 'last_week',
  'This Month': 'this_month',
  'Last Month': 'last_month',
  'This Quarter': 'this_quarter',
  'Last Quarter': 'last_quarter',
  'This Year': 'this_year',
  'Last Year': 'last_year',
};

const kpiPeriodCustomLabel = 'Custom Date Range';
