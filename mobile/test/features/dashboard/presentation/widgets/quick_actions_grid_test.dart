import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/dashboard/presentation/widgets/quick_actions_grid.dart';

Future<void> _pumpGrid(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: QuickActionsGrid())),
      GoRoute(path: '/reminders/new', builder: (_, _) => const Text('Reminder Schedule Screen')),
      GoRoute(path: '/search', builder: (_, _) => const Text('Global Search Screen')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all 4 real Quick Actions', (tester) async {
    await _pumpGrid(tester);

    expect(find.text('Add Case'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Add Reminder'), findsOneWidget);
    expect(find.text('Global Search'), findsOneWidget);
  });

  testWidgets('tapping Add Reminder navigates directly to Reminder Scheduling', (tester) async {
    await _pumpGrid(tester);

    await tester.tap(find.text('Add Reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Schedule Screen'), findsOneWidget);
  });

  testWidgets('tapping Global Search navigates to the real Global Search screen', (tester) async {
    await _pumpGrid(tester);

    await tester.tap(find.text('Global Search'));
    await tester.pumpAndSettle();

    expect(find.text('Global Search Screen'), findsOneWidget);
  });

  testWidgets('tapping Add Case opens the entry sheet with both starting points', (tester) async {
    await _pumpGrid(tester);

    await tester.tap(find.text('Add Case'));
    await tester.pumpAndSettle();

    expect(find.text('Existing Customer'), findsOneWidget);
    expect(find.text('New Customer'), findsOneWidget);
  });
}
