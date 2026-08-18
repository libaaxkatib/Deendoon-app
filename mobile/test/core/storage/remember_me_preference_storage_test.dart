import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/remember_me_preference_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('readEnabled defaults to false when nothing has been saved', () async {
    const storage = RememberMePreferenceStorage();

    expect(await storage.readEnabled(), isFalse);
  });

  test('saveEnabled(true) persists and readEnabled reflects it', () async {
    const storage = RememberMePreferenceStorage();

    await storage.saveEnabled(true);

    expect(await storage.readEnabled(), isTrue);
  });

  test(
    'saveEnabled persists across separate storage instances (real disk-backed persistence)',
    () async {
      await const RememberMePreferenceStorage().saveEnabled(true);

      expect(await const RememberMePreferenceStorage().readEnabled(), isTrue);
    },
  );

  test(
    'saveEnabled(false) after a prior true correctly turns it back off',
    () async {
      const storage = RememberMePreferenceStorage();

      await storage.saveEnabled(true);
      await storage.saveEnabled(false);

      expect(await storage.readEnabled(), isFalse);
    },
  );
}
