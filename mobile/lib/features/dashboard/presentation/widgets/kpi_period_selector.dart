import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../providers/kpi_period_provider.dart';

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
    final selected = ref.watch(kpiPeriodProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openPicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.label, style: AppTypography.caption.copyWith(color: AppColors.primary)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(kpiPeriodProvider);
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
                        'Select Period',
                        style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      children: [
                        for (final label in kpiPeriodOptions.keys)
                          _PeriodRow(period: label, selected: label == current.label),
                        _PeriodRow(period: kpiPeriodCustomLabel, selected: current.key == 'custom'),
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

    if (selected == null || !context.mounted) return;

    if (selected == kpiPeriodCustomLabel) {
      await _pickCustomRange(context, ref);
      return;
    }

    final key = kpiPeriodOptions[selected];
    if (key != null) {
      ref.read(kpiPeriodProvider.notifier).state = KpiPeriodSelection(key: key, label: selected);
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
  final String period;
  final bool selected;

  const _PeriodRow({required this.period, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pop(period),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  period,
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
