import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/widgets/password_field.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

Future<void> _pumpField(
  WidgetTester tester, {
  required TextEditingController controller,
  String? Function(String?)? validator,
  Iterable<String>? autofillHints,
}) async {
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
      home: Scaffold(
        body: Form(
          child: PasswordField(
            controller: controller,
            labelText: 'Password',
            validator: validator,
            autofillHints: autofillHints,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('is obscured by default', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpField(tester, controller: controller);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('tapping the visibility button reveals the password', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpField(tester, controller: controller);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('tapping again hides the password', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpField(tester, controller: controller);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('the controller value is unchanged by toggling visibility', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'CorrectPassword123!');
    addTearDown(controller.dispose);

    await _pumpField(tester, controller: controller);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(controller.text, 'CorrectPassword123!');
  });

  testWidgets(
    'autofillHints defaults to null when not provided (unaffected callers)',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpField(tester, controller: controller);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, isNull);
    },
  );

  testWidgets(
    'Mobile QA Fix — Remember Me: autofillHints is passed through to the '
    'underlying field when provided',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        autofillHints: const [AutofillHints.password],
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, [AutofillHints.password]);
    },
  );

  testWidgets('the validator is passed through and runs on form validation', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

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
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PasswordField(
              controller: controller,
              labelText: 'Password',
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Password is required'
                  : null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();
    expect(find.text('Password is required'), findsOneWidget);
  });
}
