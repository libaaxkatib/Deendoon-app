import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final recentSearchesStorageProvider = Provider<RecentSearchesStorage>(
  (ref) => const RecentSearchesStorage(),
);

/// Global Search's "Recent Searches" — device-local only, never sent to
/// the backend (no such endpoint exists, and none was requested). Newest
/// first, deduplicated case-insensitively, capped at 10.
class RecentSearchesStorage {
  static const _key = 'global_search_recent_searches';
  static const maxEntries = 10;

  const RecentSearchesStorage();

  Future<List<String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<List<String>> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return readAll();

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    final updated = [
      trimmed,
      ...current.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(maxEntries).toList();

    await prefs.setStringList(_key, updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
