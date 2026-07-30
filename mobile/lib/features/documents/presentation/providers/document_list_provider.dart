import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../data/document_repository.dart';

/// Immutable snapshot of the tenant-wide, paginated, type-filterable,
/// searchable Document List — real backend pagination/filtering only, no
/// local filtering. `type` maps 1:1 onto the five approved tabs (All,
/// Invoices, Receipts, Letters, Other — null = All). `search` matches
/// only `reference_number` server-side (see `document_api.dart`).
class DocumentListState {
  final List<DocumentSummary> documents;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? type;
  final String search;
  final bool isLoadingMore;

  const DocumentListState({
    required this.documents,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.type,
    required this.search,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  DocumentListState copyWith({
    List<DocumentSummary>? documents,
    int? currentPage,
    int? lastPage,
    int? total,
    String? type,
    String? search,
    bool? isLoadingMore,
  }) {
    return DocumentListState(
      documents: documents ?? this.documents,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      type: type ?? this.type,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final documentListProvider =
    AsyncNotifierProvider<DocumentListNotifier, DocumentListState>(DocumentListNotifier.new);

class DocumentListNotifier extends AsyncNotifier<DocumentListState> {
  @override
  Future<DocumentListState> build() => _fetchFirstPage(type: null, search: '');

  DocumentRepository get _repository => ref.read(documentRepositoryProvider);

  /// `type` is one of the five real, approved tab values (or null for
  /// "All") — always a real API call, never a client-side filter.
  Future<void> filterByType(String? type) async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(type: type, search: search));
  }

  Future<void> search(String query) async {
    final type = state.valueOrNull?.type;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(type: type, search: query));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(() => _fetchFirstPage(type: current?.type, search: current?.search ?? ''));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchDocuments(
        page: current.currentPage + 1,
        type: current.type,
        search: current.search,
      );
      state = AsyncData(current.copyWith(
        documents: [...current.documents, ...next.documents],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<DocumentListState> _fetchFirstPage({required String? type, required String search}) async {
    final page = await _repository.fetchDocuments(page: 1, type: type, search: search);
    return DocumentListState(
      documents: page.documents,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      type: type,
      search: search,
    );
  }
}
