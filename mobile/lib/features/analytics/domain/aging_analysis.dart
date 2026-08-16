import '../../../l10n/generated/app_localizations.dart';
import '../../debts/domain/debt.dart';

/// Mirrors `ReportingService::agingBuckets()` — always exactly 5 buckets,
/// matching the real backend terminology verbatim (not merged/renamed):
/// `current`, `1_30`, `31_60`, `61_90`, `over_90`.
class AgingBucket {
  final int count;
  final String totalRemainingBalance;

  const AgingBucket({required this.count, required this.totalRemainingBalance});

  factory AgingBucket.fromJson(Map<String, dynamic> json) => AgingBucket(
    count: json['count'] as int,
    totalRemainingBalance: json['total_remaining_balance'] as String,
  );
}

/// A `DebtResource` row from `GET /reports/aging-analysis`, with the
/// per-row `aging_bucket` field the controller injects on top of the
/// standard resource shape (`ReportController::agingAnalysis()`).
class AgingDebt {
  final Debt debt;
  final String agingBucket;

  const AgingDebt({required this.debt, required this.agingBucket});

  factory AgingDebt.fromJson(Map<String, dynamic> json) => AgingDebt(
    debt: Debt.fromJson(json),
    agingBucket: json['aging_bucket'] as String,
  );
}

/// `buckets` totals are computed over every matching open debt regardless
/// of pagination (confirmed in `ReportController::agingAnalysis()`), but
/// `debts` itself is one paginated page — the aging drill-down therefore
/// only has this one page's debts to filter client-side from (see
/// `AgingBucketDebtsScreen`), per explicit product decision: reuse what
/// this endpoint already returned, never issue a second request for it.
class AgingAnalysis {
  final Map<String, AgingBucket> buckets;
  final List<AgingDebt> debts;
  final int currentPage;
  final int lastPage;
  final int total;

  const AgingAnalysis({
    required this.buckets,
    required this.debts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory AgingAnalysis.fromJson(Map<String, dynamic> json) {
    final buckets = json['buckets'] as Map<String, dynamic>;
    final debts = json['debts'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;
    return AgingAnalysis(
      buckets: buckets.map(
        (key, value) =>
            MapEntry(key, AgingBucket.fromJson(value as Map<String, dynamic>)),
      ),
      debts: debts
          .map((e) => AgingDebt.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}

/// The 5 real bucket keys, in the exact order the approved UI board lists
/// them (§5.5) — used to drive both the donut segments and the legend
/// rows, so the two never drift out of sync.
const agingBucketOrder = <String>[
  'current',
  '1_30',
  '31_60',
  '61_90',
  'over_90',
];

Map<String, String> agingBucketLabels(AppLocalizations l10n) => {
  'current': l10n.agingBucketCurrentLabel,
  '1_30': l10n.agingBucket1To30Label,
  '31_60': l10n.agingBucket31To60Label,
  '61_90': l10n.agingBucket61To90Label,
  'over_90': l10n.agingBucketOver90Label,
};
