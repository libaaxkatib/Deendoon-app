import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/report_payments_provider.dart';
import '../widgets/date_range_field.dart';
import '../widgets/export_action.dart';
import '../widgets/payment_report_card.dart';

/// §5.2 Reports — Payments category. Real filter: `dateFrom`/`dateTo` on
/// `payment_date`. Reached either plainly (no filter, "All payments") or
/// pre-filtered from the Overview's Total Collected KPI card (§5.4), which
/// passes the same date range already applied there.
class ReportPaymentsScreen extends ConsumerStatefulWidget {
  final String? initialDateFrom;
  final String? initialDateTo;

  const ReportPaymentsScreen({super.key, this.initialDateFrom, this.initialDateTo});

  @override
  ConsumerState<ReportPaymentsScreen> createState() => _ReportPaymentsScreenState();
}

class _ReportPaymentsScreenState extends ConsumerState<ReportPaymentsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final from = DateTime.tryParse(widget.initialDateFrom ?? '');
    final to = DateTime.tryParse(widget.initialDateTo ?? '');
    if (from != null && to != null) {
      Future.microtask(
        () => ref.read(reportPaymentsProvider.notifier).filterByDateRange(DateTimeRange(start: from, end: to)),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(reportPaymentsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentsAsync = ref.watch(reportPaymentsProvider);
    final currentRange = paymentsAsync.valueOrNull?.dateRange;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportPaymentsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.reportExportTooltip,
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'payments',
              filters: {
                if (currentRange != null) 'dateFrom': currentRange.start.toIso8601String().split('T').first,
                if (currentRange != null) 'dateTo': currentRange.end.toIso8601String().split('T').first,
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DateRangeField(
                    value: currentRange ??
                        DateTimeRange(start: DateTime.now().subtract(const Duration(days: 29)), end: DateTime.now()),
                    onChanged: (range) => ref.read(reportPaymentsProvider.notifier).filterByDateRange(range),
                  ),
                ),
                if (currentRange != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.reportPaymentsClearDateFilterTooltip,
                    onPressed: () => ref.read(reportPaymentsProvider.notifier).filterByDateRange(null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.reportPaymentsLoadError,
                    onRetry: () => ref.invalidate(reportPaymentsProvider),
                  ),
                ),
                data: (state) {
                  if (state.payments.isEmpty) {
                    return Center(child: Text(l10n.reportPaymentsEmptyState, style: AppTypography.body));
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reportPaymentsProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.payments.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.payments.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return PaymentReportCard(payment: state.payments[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
