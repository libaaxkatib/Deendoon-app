import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../cases/presentation/widgets/case_card.dart';
import '../../../customers/presentation/widgets/customer_card.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../../../documents/presentation/widgets/document_card.dart';
import '../../domain/search_results.dart';
import '../providers/search_providers.dart';
import '../widgets/payment_result_tile.dart';

enum _Category { all, customers, debts, payments, documents, cases }

Map<_Category, String> _categoryLabels(AppLocalizations l10n) => {
  _Category.all: l10n.globalSearchCategoryAll,
  _Category.customers: l10n.globalSearchCategoryCustomers,
  _Category.debts: l10n.globalSearchCategoryDebts,
  _Category.payments: l10n.globalSearchCategoryPayments,
  _Category.documents: l10n.globalSearchCategoryDocuments,
  _Category.cases: l10n.globalSearchCategoryCases,
};

/// Global Search (FR-063) — real `GET /search?q=...`, one unified
/// response per query. The backend has no server-side category-filter
/// parameter, so the chip row below is a client-side view over the
/// single already-fetched response, never a second request per chip —
/// same "debounce only delays when the request fires" principle already
/// established by Customer List's search bar.
///
/// Reminders are not searched by this backend endpoint at all (confirmed
/// in `SearchService`), and there is no "Invoice" entity — Receipts,
/// Demand Letters, and Statements are the real document types instead,
/// shown here combined under "Documents". Both gaps are reported in the
/// Sprint 3 report rather than fabricated.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  _Category _category = _Category.all;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    // globalSearchProvider is app-global, not scoped to this screen, so a
    // previous visit's results would otherwise still be showing (with an
    // empty, freshly-built search box and no way back to Recent Searches)
    // the next time this screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(globalSearchProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(globalSearchProvider.notifier).search(value);
    });
  }

  void _runSearch(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _debounce?.cancel();
    ref.read(globalSearchProvider.notifier).search(query);
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(globalSearchProvider.notifier).clear();
    setState(() => _category = _Category.all);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchAsync = ref.watch(globalSearchProvider);
    final notifier = ref.read(globalSearchProvider.notifier);
    final categoryLabels = _categoryLabels(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.globalSearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: _runSearch,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.globalSearchHint,
                prefixIcon: Icon(
                  Icons.search,
                  color: context.colors.textSecondary,
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.colors.textSecondary,
                        ),
                        onPressed: _clearSearch,
                      ),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (searchAsync.valueOrNull != null || searchAsync.isLoading) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in _Category.values) ...[
                    _CategoryChip(
                      label: categoryLabels[category]!,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              // Centered content is wrapped in a scroll view rather than a
              // bare Center: with the keyboard open, the available height
              // can be smaller than the content's natural height, which
              // would otherwise overflow instead of scrolling.
              error: (error, _) => SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: RetrySection(
                      message: error is ApiException
                          ? error.message
                          : l10n.globalSearchErrorMessage,
                      onRetry: () => notifier.search(notifier.lastQuery),
                    ),
                  ),
                ),
              ),
              data: (results) {
                if (results == null)
                  return _RecentSearchesView(onSearch: _runSearch);
                if (results.totalCount == 0) {
                  return SingleChildScrollView(
                    child: Center(
                      child: PremiumEmptyState(
                        icon: Icons.search_off,
                        title: l10n.globalSearchNoResultsTitle,
                        message: l10n.globalSearchNoResultsMessage(
                          notifier.lastQuery,
                        ),
                      ),
                    ),
                  );
                }
                return _ResultsView(results: results, category: _category);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : context.colors.textSecondary,
      ),
      backgroundColor: context.colors.background,
      side: BorderSide.none,
    );
  }
}

class _RecentSearchesView extends ConsumerWidget {
  final ValueChanged<String> onSearch;

  const _RecentSearchesView({required this.onSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentAsync = ref.watch(recentSearchesProvider);

    // Wrapped in a scroll view, not a bare Center: the search field
    // autofocuses, so this is often the very first thing shown with the
    // keyboard already open and less height available than on a full
    // screen — without scrolling, that overflows instead of adapting.
    final emptyState = SingleChildScrollView(
      child: Center(
        child: PremiumEmptyState(
          icon: Icons.search,
          title: l10n.globalSearchDeendoonTitle,
          message: l10n.globalSearchDeendoonMessage,
        ),
      ),
    );

    return recentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => emptyState,
      data: (recent) {
        if (recent.isEmpty) {
          return emptyState;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.globalSearchRecentSearchesHeading,
                  style: AppTypography.subheading.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(recentSearchesProvider.notifier).clearAll(),
                  child: Text(l10n.globalSearchClearButton),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final query in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.history,
                  color: context.colors.textSecondary,
                ),
                title: Text(
                  query,
                  style: AppTypography.body.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                onTap: () => onSearch(query),
              ),
          ],
        );
      },
    );
  }
}

class _ResultsView extends StatelessWidget {
  final SearchResults results;
  final _Category category;

  const _ResultsView({required this.results, required this.category});

  bool _show(_Category c) => category == _Category.all || category == c;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customers = results.customers ?? [];
    final debts = results.debts ?? [];
    final payments = results.payments ?? [];
    final documents = results.documents;
    final cases = results.collectionCases ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (_show(_Category.customers) && customers.isNotEmpty) ...[
          _SectionHeader(l10n.globalSearchCategoryCustomers),
          for (final customer in customers) ...[
            CustomerCard(
              customer: customer,
              onTap: () => context.push('/customers/${customer.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (_show(_Category.debts) && debts.isNotEmpty) ...[
          _SectionHeader(l10n.globalSearchCategoryDebts),
          for (final debt in debts) ...[
            DebtCard(
              debt: debt,
              riskLevel: null,
              onTap: () => context.push('/debts/${debt.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (_show(_Category.payments) && payments.isNotEmpty) ...[
          _SectionHeader(l10n.globalSearchCategoryPayments),
          for (final payment in payments) ...[
            PaymentResultTile(
              payment: payment,
              onTap: () => context.push('/debts/${payment.debtId}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (_show(_Category.documents) && documents.isNotEmpty) ...[
          _SectionHeader(l10n.globalSearchCategoryDocuments),
          for (final document in documents) ...[
            DocumentCard(
              document: document,
              onTap: () => context.push('/documents/${document.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (_show(_Category.cases) && cases.isNotEmpty) ...[
          _SectionHeader(l10n.globalSearchCategoryCases),
          for (final collectionCase in cases) ...[
            CaseCard(
              collectionCase: collectionCase,
              activeTab: null,
              onTap: () => context.push('/cases/${collectionCase.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: AppTypography.subheading.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
