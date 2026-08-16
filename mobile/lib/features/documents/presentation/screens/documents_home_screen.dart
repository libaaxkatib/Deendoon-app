import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/document_type_icon.dart';
import '../widgets/storage_usage_card.dart';

Map<String?, String> _tabFilters(AppLocalizations l10n) => {
  null: l10n.documentTabAll,
  'invoices': l10n.documentTabInvoices,
  'receipts': l10n.documentTabReceipts,
  'letters': l10n.documentTabLetters,
  'other': l10n.documentTabOther,
};

Map<String?, String> _emptyMessages(AppLocalizations l10n) => {
  null: l10n.customerDocumentsEmptyState,
  'invoices': l10n.documentEmptyInvoices,
  'receipts': l10n.documentEmptyReceipts,
  'letters': l10n.documentEmptyLetters,
  'other': l10n.documentEmptyStatements,
};

/// Documents Center (§8.1 "All Documents") — the real content of the
/// Documents tab. Header search icon toggles a real, debounced search
/// field (matches `reference_number` server-side only — see
/// `document_api.dart`); the approved layout also shows a "filter" icon,
/// but `GET /documents` has no filterable dimension beyond `type` (which
/// the tab row already exposes) and `search` — a separate filter sheet
/// would just re-expose the same five tab values, so it is omitted per
/// this project's "don't show non-functional controls" precedent (see
/// the Sprint 15 summary's "Backend Blockers").
class DocumentsHomeScreen extends ConsumerStatefulWidget {
  const DocumentsHomeScreen({super.key});

  @override
  ConsumerState<DocumentsHomeScreen> createState() =>
      _DocumentsHomeScreenState();
}

class _DocumentsHomeScreenState extends ConsumerState<DocumentsHomeScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.documentSearchHint),
                onChanged: (value) =>
                    ref.read(documentListProvider.notifier).search(value),
              )
            : Text(l10n.navDocuments),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchController.clear();
                ref.read(documentListProvider.notifier).search('');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in _tabFilters(l10n).entries) ...[
                    _TabFilterChip(
                      label: entry.value,
                      selected: documentsAsync.valueOrNull?.type == entry.key,
                      onTap: () => ref
                          .read(documentListProvider.notifier)
                          .filterByType(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.documentRecentDocumentsHeading,
                    style: AppTypography.heading.copyWith(
                      color: context.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  // The pushed screen watches the same shared
                  // `documentListProvider`, already reflecting whichever
                  // tab/search is active here — no query params needed.
                  onPressed: () => context.push('/documents/list'),
                  child: Text(l10n.commonViewAll),
                ),
              ],
            ),
            const SizedBox(height: 12),
            documentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => RetrySection(
                message: l10n.customerDocumentsLoadError,
                onRetry: () => ref.invalidate(documentListProvider),
              ),
              data: (state) {
                if (state.documents.isEmpty) {
                  return state.type == 'other'
                      ? const _StatementsEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _emptyMessages(l10n)[state.type] ??
                                l10n.customerDocumentsEmptyState,
                            style: AppTypography.body.copyWith(
                              color: context.colors.textPrimary,
                            ),
                          ),
                        );
                }

                final recent = state.documents.take(5).toList();
                return Column(
                  children: [
                    for (final document in recent) ...[
                      DocumentCard(
                        document: document,
                        onTap: () => context.push('/documents/${document.id}'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const StorageUsageCard(),
          ],
        ),
      ),
    );
  }
}

/// The "Other" (statement) tab's empty state — an icon + supporting
/// caption, matching how every other document type is already
/// represented (see `DocumentTypeIcon`) rather than a bare line of text.
class _StatementsEmptyState extends StatelessWidget {
  const _StatementsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const DocumentTypeIcon(documentType: 'statement', size: 56),
          const SizedBox(height: 16),
          Text(
            l10n.documentEmptyStatements,
            style: AppTypography.body.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.documentEmptyStatementsCaption,
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TabFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabFilterChip({
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
      backgroundColor: context.colors.surface,
      side: BorderSide.none,
    );
  }
}
