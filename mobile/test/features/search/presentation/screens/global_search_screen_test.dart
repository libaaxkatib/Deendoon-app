import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/search/data/search_repository.dart';
import 'package:mobile/features/search/domain/search_results.dart';
import 'package:mobile/features/search/presentation/screens/global_search_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSearchRepository extends Mock implements SearchRepository {}

const _customer = {
  'id': '1',
  'name': 'Asad Mohamed',
  'phone': '0612345678',
  'customer_status': 'active',
  'credit_limit': '1000.00',
  'outstanding_balance': '200.00',
  'remaining_credit': '800.00',
  'risk_level': 'low',
  'credit_score': 80,
  'credit_score_band': 'good',
  'archived_at': null,
  'created_at': '2026-01-01T00:00:00.000000Z',
  'updated_at': '2026-01-01T00:00:00.000000Z',
};

final _resultsWithCustomer = SearchResults.fromJson({
  'customers': [_customer],
  'debts': [],
  'payments': null,
  'receipts': [],
  'demand_letters': [],
  'statements': [],
  'collection_cases': [],
});

const _emptyResults = SearchResults(
  customers: [],
  debts: [],
  payments: [],
  receipts: [],
  demandLetters: [],
  statements: [],
  collectionCases: [],
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockSearchRepository repository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: GlobalSearchScreen()),
    ),
  );
}

void main() {
  late _MockSearchRepository mockRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = _MockSearchRepository();
  });

  testWidgets('shows the no-search-yet state when nothing has been searched', (tester) async {
    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Search Deendoon'), findsOneWidget);
  });

  testWidgets('submitting a query calls the real search endpoint and shows results', (tester) async {
    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Asad Mohamed'), findsOneWidget);
    verify(() => mockRepository.search('asad')).called(1);
  });

  testWidgets('typing debounces before firing the real search call', (tester) async {
    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => mockRepository.search(any()));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(() => mockRepository.search('asad')).called(1);
  });

  testWidgets('shows the honest empty state when a real search finds nothing', (tester) async {
    when(() => mockRepository.search('zzz')).thenAnswer((_) async => _emptyResults);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('shows the real server error message and retries on tap', (tester) async {
    when(() => mockRepository.search('asad'))
        .thenThrow(const ApiException(message: 'Something went wrong. Please try again.'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);

    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Asad Mohamed'), findsOneWidget);
  });

  testWidgets('filtering to the Customers chip still shows customer results', (tester) async {
    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Customers'));
    await tester.pumpAndSettle();

    expect(find.text('Asad Mohamed'), findsOneWidget);
  });

  testWidgets('a completed search is saved to Recent Searches and can be re-run', (tester) async {
    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('asad'), findsOneWidget);

    await tester.tap(find.text('asad'));
    await tester.pumpAndSettle();

    expect(find.text('Asad Mohamed'), findsOneWidget);
    verify(() => mockRepository.search('asad')).called(2);
  });

  testWidgets('Clear removes every recent search', (tester) async {
    when(() => mockRepository.search('asad')).thenAnswer((_) async => _resultsWithCustomer);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'asad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Search Deendoon'), findsOneWidget);
  });
}
