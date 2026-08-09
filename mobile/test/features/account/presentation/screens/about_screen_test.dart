import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/account/domain/legal_content.dart';
import 'package:mobile/features/account/presentation/screens/about_screen.dart';
import 'package:mobile/features/account/presentation/screens/legal_content_screen.dart';

void main() {
  /// The About screen's content (branding + 4 cards + Other menu) is
  /// taller than the default 800x600 test viewport, so the "KUWA KALE"
  /// rows never materialize in the widget tree without this — same fix
  /// documented for every other tall-screen test in this codebase.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows Deendoon branding, description, and legal/support rows', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pump();

    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'assets/deendoon_logo.png');
    expect(find.text('Kaaliyaha Casriga ah ee\nSoo Celinta Deymaha'), findsOneWidget);
    expect(find.text('Hordhac DEENDOON'), findsOneWidget);
    expect(find.text('DEENDOON wuxuu kaa caawinayaa inaad:'), findsOneWidget);
    expect(find.text('Gunaanad'), findsOneWidget);
    expect(find.text('Macluumaad'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);
    expect(find.text('Rate the App'), findsOneWidget);
    expect(find.text('Website'), findsNothing);
  });

  testWidgets('Contact Support still shows the coming-soon acknowledgement (no real contact channel exists)',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pump();

    await tester.tap(find.text('Contact Support'));
    await tester.pump();

    expect(find.text('Contact Support — coming soon'), findsOneWidget);
  });

  group('legal content navigation (with a real router)', () {
    Future<void> pumpWithRouter(WidgetTester tester, GoRouter router) async {
      useTallViewport(tester);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets('Privacy Policy opens the real Privacy Policy content screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AboutScreen()),
          GoRoute(
            path: '/account/privacy-policy',
            builder: (_, _) => const LegalContentScreen(title: 'Privacy Policy', content: kPrivacyPolicyContent),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Deendoon stores the business data you enter directly'), findsOneWidget);
    });

    testWidgets('Terms & Conditions opens the real Terms & Conditions content screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AboutScreen()),
          GoRoute(
            path: '/account/terms-conditions',
            builder: (_, _) =>
                const LegalContentScreen(title: 'Terms & Conditions', content: kTermsAndConditionsContent),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Terms & Conditions'), findsOneWidget);
      expect(find.textContaining('Each business account (tenant) is'), findsOneWidget);
    });
  });
}
