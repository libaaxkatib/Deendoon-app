import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/document_type_icon.dart';
import '../widgets/storage_usage_card.dart';

const _tabFilters = <String?, String>{
  null: 'All',
  'invoices': 'Invoices',
  'receipts': 'Receipts',
  'letters': 'Letters',
  'other': 'Other',
};

const _emptyMessages = <String?, String>{
  null: 'No documents yet',
  'invoices': 'No invoices yet',
  'receipts': 'No receipts yet',
  'letters': 'No letters yet',
  'other': 'No statements yet',
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
  ConsumerState<DocumentsHomeScreen> createState() => _DocumentsHomeScreenState();
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
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search documents...'),
                onChanged: (value) => ref.read(documentListProvider.notifier).search(value),
              )
            : const Text('Documents'),
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
                  for (final entry in _tabFilters.entries) ...[
                    _TabFilterChip(
                      label: entry.value,
                      selected: documentsAsync.valueOrNull?.type == entry.key,
                      onTap: () => ref.read(documentListProvider.notifier).filterByType(entry.key),
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
                const Expanded(
                  child: Text('Recent Documents', style: AppTypography.heading, overflow: TextOverflow.ellipsis),
                ),
                TextButton(
                  // The pushed screen watches the same shared
                  // `documentListProvider`, already reflecting whichever
                  // tab/search is active here — no query params needed.
                  onPressed: () => context.push('/documents/list'),
                  child: const Text('View All'),
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
                message: 'Could not load documents.',
                onRetry: () => ref.invalidate(documentListProvider),
              ),
              data: (state) {
                if (state.documents.isEmpty) {
                  return state.type == 'other'
                      ? const _StatementsEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(_emptyMessages[state.type] ?? 'No documents yet', style: AppTypography.body),
                        );
                }

                final recent = state.documents.take(5).toList();
                return Column(
                  children: [
                    for (final document in recent) ...[
                      DocumentCard(document: document, onTap: () => context.push('/documents/${document.id}')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const DocumentTypeIcon(documentType: 'statement', size: 56),
          const SizedBox(height: 16),
          const Text('No statements yet', style: AppTypography.body),
          const SizedBox(height: 4),
          Text(
            'Account statements will appear here once generated.',
            style: AppTypography.caption,
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

  const _TabFilterChip({required this.label, required this.selected, required this.onTap});

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
