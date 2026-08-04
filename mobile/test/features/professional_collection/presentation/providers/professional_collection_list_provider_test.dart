import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/presentation/providers/professional_collection_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

const _pageOneRequest = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'submitted',
  submittedByUserId: '01USER',
  actionedByUserId: null,
  createdAt: '2026-08-01T00:00:00.000000Z',
  closedAt: null,
);

const _pageTwoRequest = ProfessionalCollectionRequest(
  id: '2',
  collectionCaseId: '02CASE',
  referenceNumber: 'PCR-0002',
  status: 'under_review',
  submittedByUserId: '01USER',
  actionedByUserId: '02USER',
  createdAt: '2026-08-02T00:00:00.000000Z',
  closedAt: null,
);

void main() {
  late _MockProfessionalCollectionRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
    container = ProviderContainer(
      overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no status filter', () async {
    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageOneRequest], currentPage: 1, lastPage: 2, total: 30),
    );

    final state = await container.read(professionalCollectionListProvider.future);

    expect(state.requests, [_pageOneRequest]);
    expect(state.hasMore, isTrue);
  });

  test('filterByStatus() resets to page 1 under the real status value', () async {
    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageOneRequest], currentPage: 1, lastPage: 1, total: 1),
    );
    await container.read(professionalCollectionListProvider.future);

    when(() => mockRepository.fetchRequests(page: 1, status: 'under_review')).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageTwoRequest], currentPage: 1, lastPage: 1, total: 1),
    );

    await container.read(professionalCollectionListProvider.notifier).filterByStatus('under_review');

    final state = container.read(professionalCollectionListProvider).value!;
    expect(state.requests, [_pageTwoRequest]);
    expect(state.status, 'under_review');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageOneRequest], currentPage: 1, lastPage: 2, total: 2),
    );
    await container.read(professionalCollectionListProvider.future);

    when(() => mockRepository.fetchRequests(page: 2, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageTwoRequest], currentPage: 2, lastPage: 2, total: 2),
    );

    await container.read(professionalCollectionListProvider.notifier).loadMore();

    final state = container.read(professionalCollectionListProvider).value!;
    expect(state.requests, [_pageOneRequest, _pageTwoRequest]);
    expect(state.hasMore, isFalse);

    await container.read(professionalCollectionListProvider.notifier).loadMore();
    verifyNever(() => mockRepository.fetchRequests(page: 3, status: any(named: 'status')));
  });

  test('refresh() re-fetches page 1 preserving the current status filter', () async {
    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageOneRequest], currentPage: 1, lastPage: 1, total: 1),
    );
    await container.read(professionalCollectionListProvider.future);

    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenAnswer(
      (_) async => const ProfessionalCollectionRequestPage(requests: [_pageOneRequest, _pageTwoRequest], currentPage: 1, lastPage: 1, total: 2),
    );

    await container.read(professionalCollectionListProvider.notifier).refresh();

    final state = container.read(professionalCollectionListProvider).value!;
    expect(state.requests, [_pageOneRequest, _pageTwoRequest]);
  });
}
