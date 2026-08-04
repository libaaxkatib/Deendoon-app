import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/account/data/business_profile_repository.dart';
import 'package:mobile/features/account/domain/business_profile.dart';
import 'package:mobile/features/account/presentation/screens/business_profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockBusinessProfileRepository extends Mock implements BusinessProfileRepository {}

const _profile = BusinessProfile(
  id: '1',
  businessName: 'Somali Builders',
  logoPath: null,
  address: '123 Main St',
  contactEmail: 'owner@example.com',
  contactPhone: '+252612345678',
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockBusinessProfileRepository repository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [businessProfileRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: BusinessProfileScreen()),
    ),
  );
}

void main() {
  late _MockBusinessProfileRepository mockRepository;

  setUp(() {
    mockRepository = _MockBusinessProfileRepository();
  });

  testWidgets('shows a retry affordance when the profile fails to load', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load your business profile.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('prefills the form with the real business profile', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('123 Main St'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('+252612345678'), findsOneWidget);
  });

  testWidgets('shows the honest "no logo" affordance when none is on file', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Tap to add a logo'), findsOneWidget);
  });

  testWidgets('shows "Logo on file" instead of a fabricated image when a logo path exists', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer(
      (_) async => const BusinessProfile(
        id: '1',
        businessName: 'Somali Builders',
        logoPath: 'branding/1/logo.png',
        address: null,
        contactEmail: null,
        contactPhone: null,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Logo on file — tap to replace'), findsOneWidget);
  });

  testWidgets('shows a validation error instead of saving an empty company name', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Company Name'), '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Company name is required'), findsOneWidget);
    verifyNever(() => mockRepository.updateBusinessProfile(
          businessName: any(named: 'businessName'),
          address: any(named: 'address'),
          contactEmail: any(named: 'contactEmail'),
          contactPhone: any(named: 'contactPhone'),
        ));
  });

  testWidgets('shows a validation error instead of saving an invalid email', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Email'), 'not-an-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('saves the entered fields and shows a success message', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);
    when(() => mockRepository.updateBusinessProfile(
          businessName: 'Somali Builders Ltd',
          address: '123 Main St',
          contactEmail: 'owner@example.com',
          contactPhone: '+252612345678',
        )).thenAnswer((_) async => _profile);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Company Name'), 'Somali Builders Ltd');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Business Profile updated successfully'), findsOneWidget);
    verify(() => mockRepository.updateBusinessProfile(
          businessName: 'Somali Builders Ltd',
          address: '123 Main St',
          contactEmail: 'owner@example.com',
          contactPhone: '+252612345678',
        )).called(1);
  });

  testWidgets('shows the real server error message when saving fails', (tester) async {
    when(() => mockRepository.fetchBusinessProfile()).thenAnswer((_) async => _profile);
    when(() => mockRepository.updateBusinessProfile(
          businessName: any(named: 'businessName'),
          address: any(named: 'address'),
          contactEmail: any(named: 'contactEmail'),
          contactPhone: any(named: 'contactPhone'),
        )).thenThrow(const ApiException(message: 'Something went wrong. Please try again.'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('Business Profile updated successfully'), findsNothing);
  });
}
