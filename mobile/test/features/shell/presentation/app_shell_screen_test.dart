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
Future<void> _pumpShell(WidgetTester tester, {required Locale locale}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const Text('Home Branch'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (_, _) => const Text('Analytics Branch'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/cases', builder: (_, _) => const Text('Cases Branch'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/reminders', builder: (_, _) => const Text('Reminders Branch'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/documents', builder: (_, _) => const Text('Documents Branch'))]),
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
  testWidgets('English locale shows the English bottom-nav labels', (tester) async {
    await _pumpShell(tester, locale: const Locale('en'));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Cases'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('Somali locale switches the bottom navigation labels, not just Settings', (tester) async {
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
  });
}
