import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/documents/data/document_repository.dart';
import 'package:mobile/features/documents/domain/document_page.dart';
import 'package:mobile/features/documents/presentation/providers/document_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

const _documentOne = DocumentSummary(
  id: '1',
  documentType: 'invoice',
  referenceNumber: 'INV-000123',
  generatedAt: '2026-07-20T10:00:00.000000Z',
  fileSize: 2048,
);

const _documentTwo = DocumentSummary(
  id: '2',
  documentType: 'receipt',
  referenceNumber: 'RCT-000045',
  generatedAt: '2026-07-19T10:00:00.000000Z',
  fileSize: 1024,
);

void main() {
  late _MockDocumentRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockDocumentRepository();
    container = ProviderContainer(
      overrides: [documentRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no type filter and no search', () async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentOne], currentPage: 1, lastPage: 2, total: 30));

    final state = await container.read(documentListProvider.future);

    expect(state.documents, [_documentOne]);
    expect(state.hasMore, isTrue);
  });

  test('filterByType() re-fetches page 1 under the real type value', () async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(documentListProvider.future);

    when(() => mockRepository.fetchDocuments(page: 1, type: 'receipts', search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentTwo], currentPage: 1, lastPage: 1, total: 1));

    await container.read(documentListProvider.notifier).filterByType('receipts');

    final state = container.read(documentListProvider).value!;
    expect(state.documents, [_documentTwo]);
    expect(state.type, 'receipts');
  });

  test('search() re-fetches page 1 under the given query', () async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(documentListProvider.future);

    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: 'INV-000123'))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentOne], currentPage: 1, lastPage: 1, total: 1));

    await container.read(documentListProvider.notifier).search('INV-000123');

    final state = container.read(documentListProvider).value!;
    expect(state.search, 'INV-000123');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentOne], currentPage: 1, lastPage: 2, total: 2));
    await container.read(documentListProvider.future);

    when(() => mockRepository.fetchDocuments(page: 2, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_documentTwo], currentPage: 2, lastPage: 2, total: 2));

    await container.read(documentListProvider.notifier).loadMore();

    final state = container.read(documentListProvider).value!;
    expect(state.documents, [_documentOne, _documentTwo]);
    expect(state.hasMore, isFalse);
  });
}
