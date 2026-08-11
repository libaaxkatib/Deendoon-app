import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/domain/subscription.dart';
import 'package:mobile/features/subscription/domain/subscription_change_request.dart';
import 'package:mobile/features/subscription/domain/subscription_change_request_page.dart';
import 'package:mobile/features/subscription/domain/subscription_plan.dart';
import 'package:mobile/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

const _freePlan = SubscriptionPlan(
  id: 'plan-free',
  name: 'Free',
  monthlyPrice: '0.00',
  customerLimit: 2,
  storageLimit: 1,
  analyticsEnabled: false,
  trialEligible: false,
  features: [],
);

const _smallBusinessPlan = SubscriptionPlan(
  id: 'plan-small',
  name: 'Small Business',
  monthlyPrice: '29.99',
  customerLimit: 50,
  storageLimit: 25,
  analyticsEnabled: true,
  trialEligible: true,
  features: [],
);

final _activeSubscription = Subscription(
  plan: _freePlan,
  planName: 'Free',
  planPrice: '0.00',
  onTrial: false,
  trialEndsAt: null,
  startedAt: DateTime.utc(2026, 1, 1),
  expiresAt: null,
  subscriptionStatus: 'active',
  customerUsage: 1,
  customerLimit: 2,
  storageUsageBytes: 1024,
  storageLimit: 1,
  analyticsEnabled: false,
  readOnly: false,
);

final _readOnlySubscription = Subscription(
  plan: _freePlan,
  planName: 'Free',
  planPrice: '0.00',
  onTrial: false,
  trialEndsAt: null,
  startedAt: DateTime.utc(2026, 1, 1),
  expiresAt: null,
  subscriptionStatus: 'active',
  customerUsage: 2,
  customerLimit: 2,
  storageUsageBytes: 1024,
  storageLimit: 1,
  analyticsEnabled: false,
  readOnly: true,
);

/// Current plan is Small Business (the pricier plan) — used to prove
/// selecting the cheaper Free plan (a downgrade) works through the exact
/// same flow as an upgrade, with no price-direction assumption anywhere.
final _smallBusinessSubscription = Subscription(
  plan: _smallBusinessPlan,
  planName: 'Small Business',
  planPrice: '29.99',
  onTrial: false,
  trialEndsAt: null,
  startedAt: DateTime.utc(2026, 1, 1),
  expiresAt: null,
  subscriptionStatus: 'active',
  customerUsage: 5,
  customerLimit: 50,
  storageUsageBytes: 1024,
  storageLimit: 25,
  analyticsEnabled: true,
  readOnly: false,
);

final _pendingChangeRequest = SubscriptionChangeRequest(
  id: 'req-1',
  tenantId: 'tenant-1',
  tenantName: null,
  requestedPlan: _smallBusinessPlan,
  currentPlan: _freePlan,
  paymentReference: 'PAY-REF-001',
  status: 'pending',
  requestedAt: DateTime.utc(2026, 8, 1),
  reviewedBy: null,
  reviewedAt: null,
  rejectionReason: null,
  rejectionReasons: null,
);

final _cancelledChangeRequest = SubscriptionChangeRequest(
  id: 'req-1',
  tenantId: 'tenant-1',
  tenantName: null,
  requestedPlan: _smallBusinessPlan,
  currentPlan: _freePlan,
  paymentReference: 'PAY-REF-001',
  status: 'cancelled',
  requestedAt: DateTime.utc(2026, 8, 1),
  reviewedBy: null,
  reviewedAt: DateTime.utc(2026, 8, 2),
  rejectionReason: null,
  rejectionReasons: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockSubscriptionRepository repository,
  Subscription? subscription,
  List<SubscriptionPlan>? plans,
  List<SubscriptionChangeRequest> changeRequests = const [],
}) async {
  tester.view.physicalSize = const Size(400, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  if (subscription != null) {
    when(() => repository.fetchSubscription()).thenAnswer((_) async => subscription);
  }
  if (plans != null) {
    when(() => repository.fetchPlans()).thenAnswer((_) async => plans);
  }
  when(() => repository.fetchChangeRequests(page: any(named: 'page'))).thenAnswer(
    (_) async => SubscriptionChangeRequestPage(
      changeRequests: changeRequests,
      currentPage: 1,
      lastPage: 1,
      total: changeRequests.length,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
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
        home: const SubscriptionScreen(),
      ),
    ),
  );
}

/// Opens the request sheet for [planName] from an already-pumped screen —
/// selects the plan card, then taps the resulting "Request Plan Change to
/// X" button.
Future<void> _openRequestSheet(WidgetTester tester, String planName) async {
  await tester.tap(find.text(planName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Request Plan Change to $planName'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockSubscriptionRepository mockRepository;

  setUp(() {
    mockRepository = _MockSubscriptionRepository();
  });

  testWidgets('shows a retry affordance when the subscription fails to load', (tester) async {
    when(() => mockRepository.fetchSubscription()).thenThrow(Exception('network down'));
    when(() => mockRepository.fetchPlans()).thenAnswer((_) async => [_freePlan, _smallBusinessPlan]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load your subscription.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders the real current subscription fields', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('does not show the read-only banner when the tenant is not read-only', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Limit Reached'), findsNothing);
  });

  testWidgets('shows the read-only explanation and Upgrade Plan CTA when readOnly is true', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _readOnlySubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Limit Reached'), findsOneWidget);
    expect(find.text('Upgrade Plan'), findsOneWidget);
    expect(find.text('Read-only'), findsOneWidget);

    await tester.tap(find.text('Upgrade Plan'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsOneWidget);
  });

  testWidgets('renders the real plan catalog and tags the current plan', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    expect(find.text('Small Business'), findsOneWidget);
    expect(find.text('Current Plan'), findsOneWidget);
  });

  testWidgets('selecting another active plan reveals the Request Plan Change button', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    expect(find.text('Request Plan Change to Small Business'), findsNothing);

    await tester.tap(find.text('Small Business'));
    await tester.pumpAndSettle();

    expect(find.text('Request Plan Change to Small Business'), findsOneWidget);
  });

  testWidgets('the current plan card is not selectable', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    // "Free" is both the AppBar-adjacent current-subscription value and the
    // current plan card's title — tapping the plan card must not reveal a
    // Request Plan Change button for it, since it's the current plan.
    await tester.tap(find.text('Current Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Request Plan Change to Free'), findsNothing);
  });

  testWidgets('a valid submission calls requestUpgrade with the exact payload and shows Pending feedback', (tester) async {
    when(() => mockRepository.requestUpgrade(
          requestedPlanId: 'plan-small',
          paymentReference: 'PAY-REF-001',
        )).thenAnswer((_) async => _pendingChangeRequest);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, 'Small Business');
    expect(find.text('Request Plan Change'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.requestUpgrade(requestedPlanId: 'plan-small', paymentReference: 'PAY-REF-001'))
        .called(1);
    expect(find.text('Plan change request to Small Business submitted — status: Pending.'), findsOneWidget);
    // Never claims activation — the word "active"/"activated" is never shown for the request itself.
    expect(find.textContaining('now active'), findsNothing);
  });

  testWidgets('leaving payment reference empty shows a client-side validation error and never calls the repository',
      (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, 'Small Business');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Payment reference is required'), findsOneWidget);
    verifyNever(() => mockRepository.requestUpgrade(
          requestedPlanId: any(named: 'requestedPlanId'),
          paymentReference: any(named: 'paymentReference'),
        ));
  });

  testWidgets('409 conflict from a pending request already existing shows the exact backend message', (tester) async {
    when(() => mockRepository.requestUpgrade(
          requestedPlanId: any(named: 'requestedPlanId'),
          paymentReference: any(named: 'paymentReference'),
        )).thenThrow(const ApiException(
      message: 'A pending Subscription Change Request already exists for this tenant.',
      statusCode: 409,
    ));

    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, 'Small Business');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('A pending Subscription Change Request already exists for this tenant.'), findsOneWidget);
    // The sheet stays open on failure, not silently dismissed.
    expect(find.text('Submit Request'), findsOneWidget);
  });

  testWidgets('422 validation failure from the backend shows the exact backend message', (tester) async {
    when(() => mockRepository.requestUpgrade(
          requestedPlanId: any(named: 'requestedPlanId'),
          paymentReference: any(named: 'paymentReference'),
        )).thenThrow(const ApiException(
      message: 'The given data was invalid.',
      statusCode: 422,
      fieldErrors: {
        'payment_reference': ['The payment reference field must not be greater than 100 characters.'],
      },
    ));

    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, 'Small Business');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('The given data was invalid.'), findsOneWidget);
  });

  testWidgets('a pending request is shown clearly in history with a Cancel action', (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
      changeRequests: [_pendingChangeRequest],
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('PAY-REF-001'), findsOneWidget);
    expect(find.text('Cancel Request'), findsOneWidget);
  });

  testWidgets('cancelling a pending request calls the real endpoint and confirms it', (tester) async {
    when(() => mockRepository.cancelChangeRequest('req-1')).thenAnswer((_) async => _cancelledChangeRequest);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
      changeRequests: [_pendingChangeRequest],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.cancelChangeRequest('req-1')).called(1);
    expect(find.text('Subscription Change Request cancelled.'), findsOneWidget);
  });

  testWidgets('a cancelled request shows the Cancelled status with no Cancel action, and a new request can still be made',
      (tester) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _activeSubscription,
      plans: [_freePlan, _smallBusinessPlan],
      changeRequests: [_cancelledChangeRequest],
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancel Request'), findsNothing);

    // Nothing about the cancelled history entry blocks starting a new
    // request. "Small Business" now appears twice (the Available Plans
    // card and the history card's requested-plan name) — `.first` targets
    // the plan card, which precedes history in the ListView.
    await tester.tap(find.text('Small Business').first);
    await tester.pumpAndSettle();
    expect(find.text('Request Plan Change to Small Business'), findsOneWidget);
  });

  testWidgets('selecting a cheaper plan (downgrade) works through the exact same flow as an upgrade', (tester) async {
    when(() => mockRepository.requestUpgrade(
          requestedPlanId: 'plan-free',
          paymentReference: 'PAY-REF-002',
        )).thenAnswer((_) async => _pendingChangeRequest);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      subscription: _smallBusinessSubscription,
      plans: [_freePlan, _smallBusinessPlan],
    );
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, 'Free');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-002');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.requestUpgrade(requestedPlanId: 'plan-free', paymentReference: 'PAY-REF-002'))
        .called(1);
  });

  testWidgets('Manage Storage navigates to the real Storage screen (Account → Subscription → Storage)', (tester) async {
    when(() => mockRepository.fetchSubscription()).thenAnswer((_) async => _activeSubscription);
    when(() => mockRepository.fetchPlans()).thenAnswer((_) async => [_freePlan, _smallBusinessPlan]);
    when(() => mockRepository.fetchChangeRequests(page: any(named: 'page'))).thenAnswer(
      (_) async => const SubscriptionChangeRequestPage(changeRequests: [], currentPage: 1, lastPage: 1, total: 0),
    );

    tester.view.physicalSize = const Size(400, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/account/subscription',
      routes: [
        GoRoute(path: '/account/subscription', builder: (_, _) => const SubscriptionScreen()),
        GoRoute(path: '/account/storage', builder: (_, _) => const Scaffold(body: Text('Storage Screen'))),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepository)],
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Storage'));
    await tester.pumpAndSettle();

    expect(find.text('Storage Screen'), findsOneWidget);
  });
}
