import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../customers/presentation/widgets/customer_card.dart';
import '../providers/report_customers_provider.dart';
import '../widgets/export_action.dart';

Map<String?, String> _statusFilters(AppLocalizations l10n) => {
      null: l10n.debtListFilterAll,
      'active': l10n.statusActive,
      'good_standing': l10n.statusGoodStanding,
      'late_payer': l10n.statusLatePayer,
      'high_risk': l10n.statusHighRisk,
      'in_collection': l10n.statusInCollection,
      'recovered': l10n.statusRecovered,
      'blocked': l10n.statusBlocked,
    };

Map<String?, String> _riskFilters(AppLocalizations l10n) => {
      null: l10n.reportRiskFilterAll,
      'high': l10n.riskHigh,
      'medium': l10n.riskMedium,
      'low': l10n.riskLow,
    };

/// §5.2 Reports — Customers category. `initialRiskLevel` pre-applies the
/// risk filter when reached via §5.6's Risk Distribution drill-through
/// (a real, backend-filtered request — `riskLevel` is a genuine
/// `reports/customers` query param, unlike the Aging drill-down which
/// must not issue a new request).
class ReportCustomersScreen extends ConsumerStatefulWidget {
  final String? initialRiskLevel;

  const ReportCustomersScreen({super.key, this.initialRiskLevel});

  @override
  ConsumerState<ReportCustomersScreen> createState() => _ReportCustomersScreenState();
}

class _ReportCustomersScreenState extends ConsumerState<ReportCustomersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialRiskLevel != null) {
      Future.microtask(
        () => ref.read(reportCustomersProvider.notifier).filterByRiskLevel(widget.initialRiskLevel),
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
      ref.read(reportCustomersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(reportCustomersProvider);
    final statusFilters = _statusFilters(l10n);
    final riskFilters = _riskFilters(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCustomersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.reportExportTooltip,
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'customers',
              filters: {
                if (customersAsync.valueOrNull?.customerStatus != null)
                  'customer_status': customersAsync.valueOrNull!.customerStatus,
                if (customersAsync.valueOrNull?.riskLevel != null) 'riskLevel': customersAsync.valueOrNull!.riskLevel,
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
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in statusFilters.entries) ...[
                    _FilterChip(
                      label: entry.value,
                      selected: customersAsync.valueOrNull?.customerStatus == entry.key,
                      onTap: () => ref.read(reportCustomersProvider.notifier).filterByStatus(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in riskFilters.entries) ...[
                    _FilterChip(
                      label: entry.value,
                      selected: customersAsync.valueOrNull?.riskLevel == entry.key,
                      onTap: () => ref.read(reportCustomersProvider.notifier).filterByRiskLevel(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.customerListLoadError,
                    onRetry: () => ref.invalidate(reportCustomersProvider),
                  ),
                ),
                data: (state) {
                  if (state.customers.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.reportCustomersEmptyState,
                        style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reportCustomersProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.customers.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.customers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final customer = state.customers[index];
                        return CustomerCard(customer: customer, onTap: () => context.push('/customers/${customer.id}'));
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? AppColors.primary : context.colors.textSecondary),
      backgroundColor: context.colors.surface,
      side: BorderSide.none,
    );
  }
}
