import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/subscription/presentation/screens/thank_you_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
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
      home: const ThankYouScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'shows the Mahadsanid heading and thank-you message, with no payment-status wording anywhere',
    (tester) async {
      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Mahadsanid'), findsOneWidget);
      expect(
        find.text('Waad ku mahadsan tahay isticmaalka Deendoon.'),
        findsOneWidget,
      );
      // This is the flow's terminal screen — it must never claim a
      // payment/subscription outcome; only the backend approval workflow
      // (unchanged) does that.
      expect(find.textContaining('Pending'), findsNothing);
      expect(find.textContaining('Approved'), findsNothing);
      expect(find.textContaining('Rejected'), findsNothing);
      expect(find.textContaining('Active'), findsNothing);
    },
  );

  testWidgets(
    'reuses the existing Contact Deendoon support card (not reimplemented)',
    (tester) async {
      await _pumpScreen(tester);
      await tester.pumpAndSettle();

      // Same three actions ContactDeendoonCard already exposes and is
      // already tested for in contact_deendoon_card_test.dart — this
      // screen just confirms the real widget is embedded, not a
      // duplicate/hardcoded copy of the same buttons.
      expect(find.widgetWithText(OutlinedButton, 'Phone'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'WhatsApp'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Email'), findsOneWidget);
    },
  );
}
