import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/app/router/route_paths.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mobile/features/dashboard/domain/recent_case.dart';
import 'package:mobile/features/dashboard/domain/todays_overview.dart';
import 'package:mobile/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');

const _kpis = DashboardKpis(
  totalOutstandingAmount: '0.00',
  totalCollectedPeriod: '0.00',
  highRiskCustomers: 0,
  overdueCount: 0,
  overdueValue: '0.00',
  customersOverCreditLimit: 0,
  activeCollectionCases: 0,
);

const _overview = TodaysOverview(totalDueToday: 0, paymentsDue: 0, clientVisits: 0, followUpCalls: 0);

void main() {
  late ProviderContainer container;

  setUp(() {
    final mockApi = _MockAuthApi();
    final mockStorage = _MockSecureTokenStorage();
    // Splash fires restoreSession() on first frame; stub it to a quiet
    // "nothing stored" outcome so it never interferes with a state this
    // test sets directly afterwards.
    when(() => mockStorage.readToken()).thenAnswer((_) async => null);
    when(() => mockStorage.readUserJson()).thenAnswer((_) async => null);

    // The real Home Dashboard screen now lives behind /home; stub its data
    // so reaching it in these navigation-guard tests never hits the network.
    final mockDashboardRepository = _MockDashboardRepository();
    when(() => mockDashboardRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    when(() => mockDashboardRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockDashboardRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureTokenStorageProvider.overrideWithValue(mockStorage),
        dashboardRepositoryProvider.overrideWithValue(mockDashboardRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DeendoonApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an unauthenticated user hitting a shell route is redirected to /login', (tester) async {
    await pumpApp(tester);
    container.read(authProvider.notifier).state = const Unauthenticated();
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.byType(HomeDashboardScreen), findsNothing);
  });

  testWidgets('an unauthenticated user can reach /forgot-password without being bounced', (tester) async {
    await pumpApp(tester);
    container.read(authProvider.notifier).state = const Unauthenticated();
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(RoutePaths.forgotPassword);
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
  });

  testWidgets('an authenticated user landing on /login is redirected to /home', (tester) async {
    await pumpApp(tester);
    container.read(authProvider.notifier).state =
        const Authenticated(user: _user, token: 'live-token');
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go(RoutePaths.login);
    await tester.pumpAndSettle();

    expect(find.byType(HomeDashboardScreen), findsOneWidget);
  });
}
