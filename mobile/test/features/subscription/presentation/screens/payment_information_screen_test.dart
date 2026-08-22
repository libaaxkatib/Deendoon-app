import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/account/data/business_profile_repository.dart';
import 'package:mobile/features/account/domain/business_profile.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/domain/subscription_change_request.dart';
import 'package:mobile/features/subscription/domain/subscription_plan.dart';
import 'package:mobile/features/subscription/presentation/screens/payment_information_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class _MockBusinessProfileRepository extends Mock
    implements BusinessProfileRepository {}

const _plan = SubscriptionPlan(
  id: 'plan-small',
  name: 'Small Business',
  monthlyPrice: '5.00',
  customerLimit: 110,
  storageLimit: 25,
  analyticsEnabled: true,
  trialEligible: false,
  features: [],
);

const _businessProfile = BusinessProfile(
  id: 'tenant-1',
  businessName: 'Acme Co',
  logoPath: null,
  address: null,
  contactEmail: null,
  contactPhone: null,
);

final _pendingChangeRequest = SubscriptionChangeRequest(
  id: 'req-1',
  tenantId: 'tenant-1',
  tenantName: null,
  requestedPlan: _plan,
  currentPlan: null,
  paymentPhone: '+252611234567',
  paymentReference: null,
  status: 'pending',
  requestedAt: DateTime.utc(2026, 8, 1),
  reviewedBy: null,
  reviewedAt: null,
  rejectionReason: null,
  rejectionReasons: null,
);

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required _MockSubscriptionRepository subscriptionRepository,
  required _MockBusinessProfileRepository businessProfileRepository,
}) async {
  when(
    () => businessProfileRepository.fetchBusinessProfile(),
  ).thenAnswer((_) async => _businessProfile);

  final router = GoRouter(
    initialLocation: '/account/subscription/payment-information',
    routes: [
      GoRoute(
        path: '/account/subscription/payment-information',
        builder: (_, _) => const PaymentInformationScreen(plan: _plan),
      ),
      GoRoute(
        path: '/account/subscription/payment-saved',
        builder: (_, _) => const Scaffold(body: Text('Payment Saved Screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepository,
        ),
        businessProfileRepositoryProvider.overrideWithValue(
          businessProfileRepository,
        ),
      ],
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

  return router;
}

void main() {
  late _MockSubscriptionRepository mockSubscriptionRepository;
  late _MockBusinessProfileRepository mockBusinessProfileRepository;

  setUp(() {
    mockSubscriptionRepository = _MockSubscriptionRepository();
    mockBusinessProfileRepository = _MockBusinessProfileRepository();
  });

  testWidgets(
    'renders the business name, plan, and amount read-only, auto-populated from the selected plan',
    (tester) async {
      await _pumpScreen(
        tester,
        subscriptionRepository: mockSubscriptionRepository,
        businessProfileRepository: mockBusinessProfileRepository,
      );
      await tester.pumpAndSettle();

      expect(find.text('Acme Co'), findsOneWidget);
      expect(find.text('Small Business'), findsOneWidget);
      expect(find.text('5.00'), findsOneWidget);
      // Neither is an editable field — no TextFormField carries the plan
      // name or amount as its current text.
      expect(find.widgetWithText(TextFormField, 'Small Business'), findsNothing);
    },
  );

  testWidgets(
    'leaving the payment phone empty shows a validation error and never calls the repository',
    (tester) async {
      await _pumpScreen(
        tester,
        subscriptionRepository: mockSubscriptionRepository,
        businessProfileRepository: mockBusinessProfileRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Payment phone number is required'), findsOneWidget);
      verifyNever(
        () => mockSubscriptionRepository.requestUpgrade(
          requestedPlanId: any(named: 'requestedPlanId'),
          paymentPhone: any(named: 'paymentPhone'),
          paymentReference: any(named: 'paymentReference'),
        ),
      );
    },
  );

  testWidgets(
    'a valid submission with only a phone number sends a null payment reference and navigates to Payment Saved',
    (tester) async {
      when(
        () => mockSubscriptionRepository.requestUpgrade(
          requestedPlanId: 'plan-small',
          paymentPhone: '+252611234567',
          paymentReference: null,
        ),
      ).thenAnswer((_) async => _pendingChangeRequest);

      await _pumpScreen(
        tester,
        subscriptionRepository: mockSubscriptionRepository,
        businessProfileRepository: mockBusinessProfileRepository,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Payment Phone Number'),
        '+252611234567',
      );
      await tester.tap(find.text('Continue Payment'));
      await tester.pumpAndSettle();

      verify(
        () => mockSubscriptionRepository.requestUpgrade(
          requestedPlanId: 'plan-small',
          paymentPhone: '+252611234567',
          paymentReference: null,
        ),
      ).called(1);
      expect(find.text('Payment Saved Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'the Transaction Reference field no longer exists on this screen',
    (tester) async {
      await _pumpScreen(
        tester,
        subscriptionRepository: mockSubscriptionRepository,
        businessProfileRepository: mockBusinessProfileRepository,
      );
      await tester.pumpAndSettle();

      // Only one TextFormField remains: Payment Phone Number.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Payment Phone Number'),
        findsOneWidget,
      );
      expect(find.textContaining('Transaction Reference'), findsNothing);
    },
  );

  testWidgets(
    '409 conflict from the backend shows the exact message and stays on the form',
    (tester) async {
      when(
        () => mockSubscriptionRepository.requestUpgrade(
          requestedPlanId: any(named: 'requestedPlanId'),
          paymentPhone: any(named: 'paymentPhone'),
          paymentReference: any(named: 'paymentReference'),
        ),
      ).thenThrow(
        const ApiException(
          message:
              'A pending Subscription Change Request already exists for this tenant.',
          statusCode: 409,
        ),
      );

      await _pumpScreen(
        tester,
        subscriptionRepository: mockSubscriptionRepository,
        businessProfileRepository: mockBusinessProfileRepository,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Payment Phone Number'),
        '+252611234567',
      );
      await tester.tap(find.text('Continue Payment'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'A pending Subscription Change Request already exists for this tenant.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue Payment'), findsOneWidget);
    },
  );
}
