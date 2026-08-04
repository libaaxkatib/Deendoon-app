import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/recent_searches_storage.dart';
import '../../data/search_repository.dart';
import '../../domain/search_results.dart';

/// `null` = no search performed yet (distinct from an empty
/// [SearchResults], which means a real search ran and found nothing).
final globalSearchProvider =
    AsyncNotifierProvider<GlobalSearchNotifier, SearchResults?>(GlobalSearchNotifier.new);

class GlobalSearchNotifier extends AsyncNotifier<SearchResults?> {
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  @override
  Future<SearchResults?> build() async => null;

  /// Always a real `GET /search?q=...` call — never a client-side filter
  /// of previous results. An empty/blank query clears back to the
  /// no-search-yet state rather than calling the backend (the endpoint
  /// itself requires a non-empty `q`).
  Future<void> search(String query) async {
    final trimmed = query.trim();
    _lastQuery = trimmed;

    if (trimmed.isEmpty) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(searchRepositoryProvider).search(trimmed));

    if (state.hasValue) {
      await ref.read(recentSearchesProvider.notifier).add(trimmed);
    }
  }

  void clear() {
    _lastQuery = '';
    state = const AsyncData(null);
  }
}

final recentSearchesProvider =
    AsyncNotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => ref.read(recentSearchesStorageProvider).readAll();

  Future<void> add(String query) async {
    final updated = await ref.read(recentSearchesStorageProvider).add(query);
    state = AsyncData(updated);
  }

  Future<void> clearAll() async {
    await ref.read(recentSearchesStorageProvider).clear();
    state = const AsyncData([]);
  }
}
