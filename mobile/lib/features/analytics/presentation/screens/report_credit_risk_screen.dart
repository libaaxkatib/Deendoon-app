import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../customers/presentation/widgets/customer_card.dart';
import '../providers/report_credit_risk_provider.dart';
import '../widgets/export_action.dart';

const _riskFilters = <String?, String>{null: 'All', 'high': 'High', 'medium': 'Medium', 'low': 'Low'};

/// §5.2 Reports — Credit Risk category. Same `Customer` shape as the
/// Customers report, ordered by `credit_score` desc server-side
/// (`ReportController::creditRisk()`).
class ReportCreditRiskScreen extends ConsumerStatefulWidget {
  const ReportCreditRiskScreen({super.key});

  @override
  ConsumerState<ReportCreditRiskScreen> createState() => _ReportCreditRiskScreenState();
}

class _ReportCreditRiskScreenState extends ConsumerState<ReportCreditRiskScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(reportCreditRiskProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(reportCreditRiskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Risk Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export',
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'credit-risk',
              filters: {if (customersAsync.valueOrNull?.riskLevel != null) 'riskLevel': customersAsync.valueOrNull!.riskLevel},
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
                  for (final entry in _riskFilters.entries) ...[
                    _FilterChip(
                      label: entry.value,
                      selected: customersAsync.valueOrNull?.riskLevel == entry.key,
                      onTap: () => ref.read(reportCreditRiskProvider.notifier).filterByRiskLevel(entry.key),
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
                    message: 'Could not load credit risk report.',
                    onRetry: () => ref.invalidate(reportCreditRiskProvider),
                  ),
                ),
                data: (state) {
                  if (state.customers.isEmpty) {
                    return const Center(child: Text('No customers match this filter', style: AppTypography.body));
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reportCreditRiskProvider.notifier).refresh(),
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
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
    );
  }
}
