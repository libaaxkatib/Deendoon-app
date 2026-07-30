import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/document_list_provider.dart';
import '../widgets/document_card.dart';

const _tabTitles = <String?, String>{
  null: 'All Documents',
  'invoices': 'Invoices',
  'receipts': 'Receipts',
  'letters': 'Letters',
  'other': 'Other',
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(documentListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_tabTitles[documentsAsync.valueOrNull?.type] ?? 'Documents')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: RetrySection(
            message: 'Could not load documents.',
            onRetry: () => ref.invalidate(documentListProvider),
          ),
        ),
        data: (state) {
          if (state.documents.isEmpty) {
            return const Center(child: Text('No documents yet', style: AppTypography.body));
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
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final document = state.documents[index];
                return DocumentCard(document: document, onTap: () => context.push('/documents/${document.id}'));
              },
            ),
          );
        },
      ),
    );
  }
}
