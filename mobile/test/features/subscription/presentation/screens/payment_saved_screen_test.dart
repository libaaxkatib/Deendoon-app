import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/presentation/screens/payment_saved_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

/// Same official `UrlLauncherPlatform` test-substitution point already
/// used by `contact_deendoon_card_test.dart` — no production code
/// touched, no new package.
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

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required _MockSubscriptionRepository repository,
  String? destinationNumber,
}) async {
  when(
    () => repository.fetchPaymentInfo(),
  ).thenAnswer((_) async => destinationNumber);

  final router = GoRouter(
    initialLocation: '/account/subscription/payment-saved',
    routes: [
      GoRoute(
        path: '/account/subscription/payment-saved',
        builder: (_, _) => const PaymentSavedScreen(),
      ),
      GoRoute(
        path: '/account/subscription/thank-you',
        builder: (_, _) => const Scaffold(body: Text('Thank You Screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: router,
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
      ),
    ),
  );

  return router;
}

void main() {
  late _MockSubscriptionRepository mockRepository;
  late _FakeUrlLauncher fakeLauncher;
  late UrlLauncherPlatform originalPlatform;

  setUp(() {
    mockRepository = _MockSubscriptionRepository();
    originalPlatform = UrlLauncherPlatform.instance;
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  testWidgets(
    'shows the success message, instruction line, and the destination number from the backend',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      expect(find.text('Your information has been saved.'), findsOneWidget);
      expect(
        find.text('Please send the money to the Deendoon number below.'),
        findsOneWidget,
      );
      expect(find.text('61XXXXXXX'), findsOneWidget);
      // All three fixed operators are offered.
      expect(find.text('SAALAM BANK'), findsOneWidget);
      expect(find.text('EVC PLUS'), findsOneWidget);
      expect(find.text('E-DAHAB'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the unavailable message when no destination number has been set',
    (tester) async {
      await _pumpScreen(tester, repository: mockRepository, destinationNumber: null);
      await tester.pumpAndSettle();

      expect(find.text('Not set yet — please contact support.'), findsOneWidget);
    },
  );

  testWidgets(
    'SAALAM BANK launches the exact fixed USSD code via a correctly-encoded tel: URI',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAALAM BANK'));
      await tester.pumpAndSettle();

      // '#' must be percent-encoded (%23) or Android/the URI parser would
      // read it as a fragment delimiter and silently drop the trailing
      // digit — this assertion locks in the exact string actually handed
      // to the platform channel, not just "a launch happened."
      expect(fakeLauncher.launchedUrls, ['tel:*799*32666663*5%23']);
    },
  );

  testWidgets(
    'EVC PLUS launches the exact fixed USSD code via a correctly-encoded tel: URI',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('EVC PLUS'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['tel:*712*615514692*5%23']);
    },
  );

  testWidgets(
    'E-DAHAB launches the exact fixed USSD code via a correctly-encoded tel: URI',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('E-DAHAB'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['tel:*712*625514692*5%23']);
    },
  );

  testWidgets(
    'a failed dialer launch shows an error but never claims success and never navigates away',
    (tester) async {
      fakeLauncher.nextResult = false;
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('EVC PLUS'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open the dialer.'), findsOneWidget);
      // Still on the same screen — a failed/successful dialer launch never
      // triggers navigation by itself.
      expect(find.text('SAALAM BANK'), findsOneWidget);
      expect(find.text('E-DAHAB'), findsOneWidget);
      expect(find.text('Thank You Screen'), findsNothing);
    },
  );

  testWidgets(
    'tapping either payment button never navigates away or shows any success/paid state — only Done does',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        destinationNumber: '61XXXXXXX',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAALAM BANK'));
      await tester.pumpAndSettle();

      expect(find.text('Thank You Screen'), findsNothing);
      expect(find.textContaining('successful'), findsNothing);
      expect(find.textContaining('Paid'), findsNothing);
      expect(find.textContaining('Verified'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Thank You Screen'), findsOneWidget);
    },
  );
}
