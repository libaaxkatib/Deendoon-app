import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/kpi_period_provider.dart';

/// Resolves a backend `period` key (`kpiPeriodKeys`) to its localized
/// display label. Returns `null` for `'custom'` or any other key this
/// selector doesn't recognize — callers fall back to the selection's own
/// `label` (the formatted date range, for Custom Date Range, which isn't
/// translatable text).
String? kpiPeriodKeyLabel(AppLocalizations l10n, String key) => switch (key) {
  'today' => l10n.kpiPeriodToday,
  'yesterday' => l10n.kpiPeriodYesterday,
  'this_week' => l10n.kpiPeriodThisWeek,
  'last_week' => l10n.kpiPeriodLastWeek,
  'this_month' => l10n.kpiPeriodThisMonth,
  'last_month' => l10n.kpiPeriodLastMonth,
  'this_quarter' => l10n.kpiPeriodThisQuarter,
  'last_quarter' => l10n.kpiPeriodLastQuarter,
  'this_year' => l10n.kpiPeriodThisYear,
  'last_year' => l10n.kpiPeriodLastYear,
  _ => null,
};

/// Resolves a [KpiPeriodSelection]'s display label — a standard period's
/// backend `key` maps to a localized string via [kpiPeriodKeyLabel]; the
/// Custom Date Range selection's `label` is already a formatted date
/// string (not translatable) and is used as-is.
String kpiPeriodDisplayLabel(AppLocalizations l10n, KpiPeriodSelection selection) =>
    kpiPeriodKeyLabel(l10n, selection.key) ?? selection.label;

/// A real, interactive period selector next to "KPI Overview" — opens a
/// bottom sheet listing every period the reference design calls for.
/// Selecting one updates `kpiPeriodProvider`, which `dashboardKpisProvider`
/// watches directly — every pick here triggers a real
/// `GET /dashboard/kpis?period=...` refetch, never a client-side-only
/// label change. "Custom Date Range" opens the platform date-range picker
/// instead of resolving straight to a fixed key.
class KpiPeriodSelector extends ConsumerWidget {
  const KpiPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(kpiPeriodProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openPicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kpiPeriodDisplayLabel(l10n, selected),
              style: AppTypography.caption.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final selectedKey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(kpiPeriodProvider);
          final l10n = AppLocalizations.of(context);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.kpiSelectPeriodTitle,
                        style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      children: [
                        for (final key in kpiPeriodKeys)
                          _PeriodRow(periodKey: key, label: kpiPeriodKeyLabel(l10n, key)!, selected: key == current.key),
                        _PeriodRow(
                          periodKey: 'custom',
                          label: l10n.kpiPeriodCustomLabel,
                          selected: current.key == 'custom',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (selectedKey == null || !context.mounted) return;

    if (selectedKey == 'custom') {
      await _pickCustomRange(context, ref);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final label = kpiPeriodKeyLabel(l10n, selectedKey);
    if (label != null) {
      ref.read(kpiPeriodProvider.notifier).state = KpiPeriodSelection(key: selectedKey, label: label);
    }
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (range == null) return;

    String dateOnly(DateTime dt) =>
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    ref.read(kpiPeriodProvider.notifier).state = KpiPeriodSelection(
      key: 'custom',
      label: '${dateOnly(range.start)} – ${dateOnly(range.end)}',
      dateFrom: dateOnly(range.start),
      dateTo: dateOnly(range.end),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final String periodKey;
  final String label;
  final bool selected;

  const _PeriodRow({required this.periodKey, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pop(periodKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? AppTypography.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
                      : AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
              ),
              if (selected) const Icon(Icons.check, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
