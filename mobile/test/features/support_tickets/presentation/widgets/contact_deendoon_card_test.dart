import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/support_tickets/presentation/widgets/contact_deendoon_card.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Mobile Fix #8 (Support Contact Information — audit approved, values
/// unchanged): the official Deendoon phone (`615178666`), WhatsApp
/// (`615514692`, dialed as `+252615514692`), and email
/// (`deendoonapp@gmail.com`) are intentionally two separate numbers, not a
/// typo — see `contact_deendoon_card.dart`. These tests exist to catch a
/// future *accidental* change to any of the three URIs, using the official
/// `UrlLauncherPlatform` test-substitution point (no production code
/// touched, no new package — `url_launcher_platform_interface` is already
/// a transitive dependency of `url_launcher`).
class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool nextResult = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return nextResult;
  }
}

Future<void> _pumpCard(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SomaliMaterialLocalizationsDelegate(),
        SomaliCupertinoLocalizationsDelegate(),
      ],
      home: const Scaffold(body: ContactDeendoonCard()),
    ),
  );
}

void main() {
  late _FakeUrlLauncher fakeLauncher;
  late UrlLauncherPlatform originalPlatform;

  setUp(() {
    originalPlatform = UrlLauncherPlatform.instance;
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  testWidgets('Phone launches tel:615178666', (tester) async {
    await _pumpCard(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Phone'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls, ['tel:615178666']);
  });

  testWidgets('Email launches mailto:deendoonapp@gmail.com', (tester) async {
    await _pumpCard(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Email'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls, ['mailto:deendoonapp@gmail.com']);
  });

  testWidgets(
    'WhatsApp launches the native intent with +252615514692 when the app is installed',
    (tester) async {
      await _pumpCard(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'WhatsApp'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['whatsapp://send?phone=252615514692']);
    },
  );

  testWidgets(
    'WhatsApp falls back to wa.me/252615514692 when the native app is not available',
    (tester) async {
      fakeLauncher.nextResult = false;
      await _pumpCard(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'WhatsApp'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, [
        'whatsapp://send?phone=252615514692',
        'https://wa.me/252615514692',
      ]);
    },
  );
}
