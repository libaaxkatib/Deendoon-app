import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_card.dart';

Map<String?, String> _tabTitles(AppLocalizations l10n) => {
  null: l10n.documentListTitleAll,
  'invoices': l10n.documentTabInvoices,
  'receipts': l10n.documentTabReceipts,
  'letters': l10n.documentTabLetters,
  'other': l10n.documentTabOther,
};

/// "View All" destination from Documents Home (§8.1) — the full,
/// infinite-scroll Document List for whichever tab/search was active.
/// Deliberately shares `documentListProvider` with the Home screen rather
/// than a second, duplicate fetch: this screen is reached already
/// showing whatever Home had loaded, and `loadMore()` extends the same
/// live list both screens observe.
class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(documentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabTitles(l10n)[documentsAsync.valueOrNull?.type] ??
              l10n.navDocuments,
        ),
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: RetrySection(
            message: l10n.customerDocumentsLoadError,
            onRetry: () => ref.invalidate(documentListProvider),
          ),
        ),
        data: (state) {
          if (state.documents.isEmpty) {
            return Center(
              child: Text(
                l10n.customerDocumentsEmptyState,
                style: AppTypography.body,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.documents.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.documents.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: state.loadMoreError
                          ? RetrySection(
                              message: l10n.paginationLoadMoreError,
                              onRetry: () => ref
                                  .read(documentListProvider.notifier)
                                  .loadMore(),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  );
                }
                final document = state.documents[index];
                return DocumentCard(
                  document: document,
                  onTap: () => context.push('/documents/${document.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
