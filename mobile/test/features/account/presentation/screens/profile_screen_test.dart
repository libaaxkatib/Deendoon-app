import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/account/presentation/screens/profile_screen.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const Authenticated(user: User(id: '1', name: 'Test User', email: 'test@example.com'), token: 't');
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_FakeAuthNotifier.new)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the user\'s avatar, name, email, and Change Password', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
  });

  testWidgets('no longer shows any About Deendoon content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Deendoon'), findsNothing);
    expect(find.text('Website'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms & Conditions'), findsNothing);
    expect(find.text('Contact Support'), findsNothing);
    expect(find.text('Rate the App'), findsNothing);
  });
}
