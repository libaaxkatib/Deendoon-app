import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/domain/storage_addon.dart';
import 'package:mobile/features/subscription/domain/subscription.dart';
import 'package:mobile/features/subscription/domain/subscription_plan.dart';
import 'package:mobile/features/subscription/domain/subscription_storage.dart';
import 'package:mobile/features/subscription/presentation/screens/storage_screen.dart';
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

final _subscription = Subscription(
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

final _activeAddon = StorageAddon(
  id: 'addon-1',
  tenantId: 'tenant-1',
  tenantName: null,
  storagePackage: '25gb',
  storageSize: 25,
  monthlyPrice: '4.00',
  paymentReference: 'PAY-A1',
  status: 'active',
  startedAt: DateTime.utc(2026, 7, 1),
  expiresAt: DateTime.utc(2026, 8, 1),
  approvedBy: 'user-2',
  approvedAt: DateTime.utc(2026, 7, 1),
  rejectionReason: null,
  rejectionReasons: null,
);

final _pendingAddonResponse = StorageAddon(
  id: 'addon-2',
  tenantId: 'tenant-1',
  tenantName: null,
  storagePackage: '10gb',
  storageSize: 10,
  monthlyPrice: '2.00',
  paymentReference: 'PAY-REF-001',
  status: 'pending',
  startedAt: null,
  expiresAt: null,
  approvedBy: null,
  approvedAt: null,
  rejectionReason: null,
  rejectionReasons: null,
);

final _cancelledAddonResponse = StorageAddon(
  id: 'addon-2',
  tenantId: 'tenant-1',
  tenantName: null,
  storagePackage: '10gb',
  storageSize: 10,
  monthlyPrice: '2.00',
  paymentReference: 'PAY-REF-001',
  status: 'cancelled',
  startedAt: null,
  expiresAt: null,
  approvedBy: null,
  approvedAt: null,
  rejectionReason: null,
  rejectionReasons: null,
);

final _approvedFromPending = StorageAddon(
  id: 'addon-2',
  tenantId: 'tenant-1',
  tenantName: null,
  storagePackage: '10gb',
  storageSize: 10,
  monthlyPrice: '2.00',
  paymentReference: 'PAY-REF-001',
  status: 'active',
  startedAt: DateTime.utc(2026, 8, 3),
  expiresAt: DateTime.utc(2026, 9, 3),
  approvedBy: 'user-2',
  approvedAt: DateTime.utc(2026, 8, 3),
  rejectionReason: null,
  rejectionReasons: null,
);

final _storageWithActiveAddon = SubscriptionStorage(
  storageUsageBytes: 2 * 1024 * 1024 * 1024,
  storageUsageGb: 2.0,
  storageLimitGb: 26,
  purchasedAddons: [_activeAddon],
  remainingStorageGb: 24.0,
);

final _storageEmpty = SubscriptionStorage(
  storageUsageBytes: 1024,
  storageUsageGb: 0.0,
  storageLimitGb: 1,
  purchasedAddons: const [],
  remainingStorageGb: 1.0,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockSubscriptionRepository repository,
  Subscription? subscription,
  SubscriptionStorage? storage,
}) async {
  tester.view.physicalSize = const Size(400, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  when(() => repository.fetchSubscription()).thenAnswer((_) async => subscription ?? _subscription);
  if (storage != null) {
    when(() => repository.fetchStorage()).thenAnswer((_) async => storage);
  }

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
        home: const StorageScreen(),
      ),
    ),
  );
}

/// Selects [packageLabel] (e.g. "10GB") then taps the resulting
/// "Request Storage Add-on (X)" button.
Future<void> _openRequestSheet(WidgetTester tester, String packageLabel) async {
  await tester.tap(find.text(packageLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Request Storage Add-on ($packageLabel)'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockSubscriptionRepository mockRepository;

  setUp(() {
    mockRepository = _MockSubscriptionRepository();
  });

  testWidgets('shows a retry affordance when storage fails to load', (tester) async {
    when(() => mockRepository.fetchStorage()).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load your storage usage.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders the real storage overview fields', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageWithActiveAddon);
    await tester.pumpAndSettle();

    expect(find.text('2.0 GB'), findsOneWidget); // storage used
    expect(find.text('1 GB'), findsOneWidget); // base storage allowance (plan-only)
    expect(find.text('26 GB'), findsOneWidget); // effective storage allowance (plan + addon)
    expect(find.text('24.00 GB'), findsOneWidget); // remaining storage
  });

  testWidgets('renders active storage add-ons with their real fields', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageWithActiveAddon);
    await tester.pumpAndSettle();

    // "25GB" appears twice by coincidence: the add-on card's title AND the
    // "25gb" package's ChoiceChip label in Available Storage Packages below.
    expect(find.text('25GB'), findsNWidgets(2));
    expect(find.text('4.00'), findsOneWidget); // monthly price
    expect(find.text('PAY-A1'), findsNothing); // payment reference isn't shown on active add-ons, only pending ones
  });

  testWidgets('shows an honest empty state when there are no active storage add-ons', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    expect(find.text('No active storage add-ons.'), findsOneWidget);
  });

  testWidgets('no Cancel action is offered when nothing was requested in this session', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageWithActiveAddon);
    await tester.pumpAndSettle();

    // An active add-on exists, but "active" is never "pending" — no
    // fabricated Cancel action anywhere on first load.
    expect(find.text('Cancel Request'), findsNothing);
  });

  testWidgets('selecting a package reveals the Request Storage Add-on button', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    expect(find.text('Request Storage Add-on (10GB)'), findsNothing);

    await tester.tap(find.text('10GB'));
    await tester.pumpAndSettle();

    expect(find.text('Request Storage Add-on (10GB)'), findsOneWidget);
  });

  testWidgets('a valid submission calls requestStorageAddon with the exact payload and never claims storage increased',
      (tester) async {
    when(() => mockRepository.requestStorageAddon(
          storagePackage: '10gb',
          paymentReference: 'PAY-REF-001',
        )).thenAnswer((_) async => _pendingAddonResponse);

    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    expect(find.text('Request Storage Add-on'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.requestStorageAddon(storagePackage: '10gb', paymentReference: 'PAY-REF-001')).called(1);
    expect(
      find.text('Storage Add-on request for 10GB submitted — pending Platform Administrator approval.'),
      findsOneWidget,
    );
    // The overview's Effective/Remaining figures are unchanged — still exactly what
    // `_storageEmpty` (unaffected by the still-pending request) reports.
    expect(find.text('1 GB'), findsWidgets); // base + effective both 1 GB in this fixture
    expect(find.textContaining('now available'), findsNothing);
    expect(find.textContaining('increased'), findsNothing);
  });

  testWidgets('leaving payment reference empty shows a client-side validation error and never calls the repository',
      (tester) async {
    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Payment reference is required'), findsOneWidget);
    verifyNever(() => mockRepository.requestStorageAddon(
          storagePackage: any(named: 'storagePackage'),
          paymentReference: any(named: 'paymentReference'),
        ));
  });

  testWidgets('409 conflict from a pending request already existing shows the exact backend message', (tester) async {
    when(() => mockRepository.requestStorageAddon(
          storagePackage: any(named: 'storagePackage'),
          paymentReference: any(named: 'paymentReference'),
        )).thenThrow(const ApiException(
      message: 'A pending Storage Add-on Request already exists for this tenant.',
      statusCode: 409,
    ));

    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('A pending Storage Add-on Request already exists for this tenant.'), findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget); // sheet stays open
  });

  testWidgets('422 validation failure from the backend shows the exact backend message', (tester) async {
    when(() => mockRepository.requestStorageAddon(
          storagePackage: any(named: 'storagePackage'),
          paymentReference: any(named: 'paymentReference'),
        )).thenThrow(const ApiException(
      message: 'The given data was invalid.',
      statusCode: 422,
      fieldErrors: {
        'payment_reference': ['The payment reference field must not be greater than 100 characters.'],
      },
    ));

    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('The given data was invalid.'), findsOneWidget);
  });

  testWidgets('cancelling the just-created pending request calls the real endpoint with the real id', (tester) async {
    when(() => mockRepository.requestStorageAddon(
          storagePackage: '10gb',
          paymentReference: 'PAY-REF-001',
        )).thenAnswer((_) async => _pendingAddonResponse);
    when(() => mockRepository.cancelStorageAddon('addon-2')).thenAnswer((_) async => _cancelledAddonResponse);

    await _pumpScreen(tester, repository: mockRepository, storage: _storageEmpty);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Request'), findsOneWidget);

    // The submission SnackBar is still technically "showing" (pumpAndSettle
    // stops once nothing is actively animating, not once its dismiss Timer
    // has fired) — without advancing past its display duration, the
    // cancellation SnackBar below would just queue behind it and never
    // render within this test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.cancelStorageAddon('addon-2')).called(1);
    expect(find.text('Storage Add-on request cancelled.'), findsOneWidget);
    expect(find.text('Cancel Request'), findsNothing);
  });

  testWidgets('reconciliation is scoped by id: refreshing to a DIFFERENT active add-on does not clear the pending card',
      (tester) async {
    var fetchCount = 0;
    when(() => mockRepository.fetchStorage()).thenAnswer((_) async {
      fetchCount++;
      // `_storageWithActiveAddon` carries `_activeAddon` (id 'addon-1'),
      // never the id 'addon-2' that `_pendingAddonResponse` returns below —
      // proves reconciliation only fires for a real id match, not any
      // refresh that happens to show something active.
      return fetchCount == 1 ? _storageEmpty : _storageWithActiveAddon;
    });
    when(() => mockRepository.requestStorageAddon(
          storagePackage: '10gb',
          paymentReference: 'PAY-REF-001',
        )).thenAnswer((_) async => _pendingAddonResponse);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Request'), findsOneWidget);

    final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(find.text('Cancel Request'), findsOneWidget);
  });

  testWidgets('reconciliation clears the pending card once the same id appears in the active add-ons list',
      (tester) async {
    var fetchCount = 0;
    when(() => mockRepository.fetchStorage()).thenAnswer((_) async {
      fetchCount++;
      // Call 1: initial load. Call 2: `SubscriptionActions.
      // requestStorageAddon`'s own defensive `subscriptionStorageProvider`
      // invalidation right after submission — still not yet active this
      // soon (approval is a separate, later, human action), so both
      // return `_storageEmpty`. Only call 3 (this test's own explicit
      // manual refresh, standing in for the user checking back later)
      // reflects the add-on having since been approved.
      if (fetchCount <= 2) return _storageEmpty;
      return SubscriptionStorage(
        storageUsageBytes: _storageEmpty.storageUsageBytes,
        storageUsageGb: _storageEmpty.storageUsageGb,
        storageLimitGb: 11,
        purchasedAddons: [_approvedFromPending],
        remainingStorageGb: 11.0,
      );
    });
    when(() => mockRepository.requestStorageAddon(
          storagePackage: '10gb',
          paymentReference: 'PAY-REF-001',
        )).thenAnswer((_) async => _pendingAddonResponse);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await _openRequestSheet(tester, '10GB');
    await tester.enterText(find.byType(TextFormField), 'PAY-REF-001');
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel Request'), findsOneWidget);

    final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    // Now shown once, as Active — the stale Pending shadow is gone.
    expect(find.text('Cancel Request'), findsNothing);
  });
}
