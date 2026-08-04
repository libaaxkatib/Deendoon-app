import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/presentation/screens/about_screen.dart';

void main() {
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
}
