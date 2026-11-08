import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/shell/presentation/app_shell_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

/// A minimal 5-branch shell mirroring app_router.dart's real
/// StatefulShellRoute structure, with trivial placeholder branch screens
/// (no feature-screen dependencies to mock) — isolates AppShellScreen's
/// own bottom-nav-label localization from the rest of the route tree.
Future<void> _pumpShell(
  WidgetTester tester, {
  required Locale locale,
  Future<void> Function()? onExit,
  DateTime Function()? now,
  String initialLocation = '/home',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AppShellScreen(navigationShell: shell, onExit: onExit, now: now),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const Text('Home Branch'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (_, _) => const Text('Analytics Branch'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cases',
                builder: (_, _) => const Text('Cases Branch'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (_, _) => const Text('Reminders Branch'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (_, _) => const Text('Documents Branch'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('English locale shows the English bottom-nav labels', (
    tester,
  ) async {
    await _pumpShell(tester, locale: const Locale('en'));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Cases'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets(
    'Somali locale switches the bottom navigation labels, not just Settings',
    (tester) async {
      await _pumpShell(tester, locale: const Locale('so'));

      expect(find.text('Guriga'), findsOneWidget); // Home
      expect(find.text('Falanqaynta'), findsOneWidget); // Analytics
      expect(find.text('Kiisaska'), findsOneWidget); // Cases
      expect(find.text('Xasuusinta'), findsOneWidget); // Reminders
      expect(find.text('Dukumentiyada'), findsOneWidget); // Documents

      // No English bottom-nav label leaked through under Somali.
      expect(find.text('Home'), findsNothing);
      expect(find.text('Analytics'), findsNothing);
      expect(find.text('Cases'), findsNothing);
      expect(find.text('Reminders'), findsNothing);
      expect(find.text('Documents'), findsNothing);
    },
  );

  group('Mobile QA Fix — Back Button', () {
    testWidgets(
      'Back on a non-Home branch root switches to Home instead of exiting',
      (tester) async {
        var exitCalls = 0;
        await _pumpShell(
          tester,
          locale: const Locale('en'),
          initialLocation: '/cases',
          onExit: () async => exitCalls++,
        );
        expect(find.text('Cases Branch'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Home Branch'), findsOneWidget);
        expect(exitCalls, 0);
      },
    );

    testWidgets(
      'First Back on Home root shows the exit-confirmation snackbar without exiting',
      (tester) async {
        var exitCalls = 0;
        await _pumpShell(
          tester,
          locale: const Locale('en'),
          onExit: () async => exitCalls++,
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Press back again to exit'), findsOneWidget);
        expect(exitCalls, 0);
      },
    );

    testWidgets(
      'Second Back on Home root within the exit window calls onExit',
      (tester) async {
        var exitCalls = 0;
        await _pumpShell(
          tester,
          locale: const Locale('en'),
          onExit: () async => exitCalls++,
        );

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(exitCalls, 1);
      },
    );

    testWidgets(
      'A second Back after the exit window has elapsed shows the snackbar again instead of exiting',
      (tester) async {
        var exitCalls = 0;
        // DateTime.now() isn't affected by tester.pump's fake clock, so a
        // fake `now` is injected to simulate real time passing between
        // the two back-presses.
        var fakeNow = DateTime(2026);
        await _pumpShell(
          tester,
          locale: const Locale('en'),
          onExit: () async => exitCalls++,
          now: () => fakeNow,
        );

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Move the fake clock past the 2-second exit window.
        fakeNow = fakeNow.add(const Duration(seconds: 3));

        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(exitCalls, 0);
        expect(find.text('Press back again to exit'), findsOneWidget);
      },
    );
  });
}
