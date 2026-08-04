import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/recent_searches_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('readAll returns an empty list when nothing has been searched yet', () async {
    final result = await const RecentSearchesStorage().readAll();
    expect(result, isEmpty);
  });

  test('add puts the newest query first', () async {
    const storage = RecentSearchesStorage();
    await storage.add('asad');
    final result = await storage.add('hassan');

    expect(result, ['hassan', 'asad']);
  });

  test('add deduplicates case-insensitively and moves the repeat to the front', () async {
    const storage = RecentSearchesStorage();
    await storage.add('asad');
    await storage.add('hassan');
    final result = await storage.add('ASAD');

    expect(result, ['ASAD', 'hassan']);
  });

  test('add caps the list at 10 entries', () async {
    const storage = RecentSearchesStorage();
    for (var i = 0; i < 12; i++) {
      await storage.add('query-$i');
    }
    final result = await storage.readAll();

    expect(result, hasLength(10));
    expect(result.first, 'query-11');
  });

  test('add ignores a blank query', () async {
    const storage = RecentSearchesStorage();
    await storage.add('asad');
    final result = await storage.add('   ');

    expect(result, ['asad']);
  });

  test('clear removes every stored query', () async {
    const storage = RecentSearchesStorage();
    await storage.add('asad');
    await storage.clear();

    expect(await storage.readAll(), isEmpty);
  });
}
