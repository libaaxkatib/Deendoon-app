import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/customer_import/data/customer_import_repository.dart';
import 'package:mobile/features/customer_import/domain/customer_import_state.dart';
import 'package:mobile/features/customer_import/domain/import_commit_result.dart';
import 'package:mobile/features/customer_import/domain/import_preview.dart';
import 'package:mobile/features/customer_import/presentation/providers/customer_import_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerImportRepository extends Mock implements CustomerImportRepository {}

void main() {
  late _MockCustomerImportRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockCustomerImportRepository();
    container = ProviderContainer(
      overrides: [customerImportRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('starts in ImportInitial', () {
    expect(container.read(customerImportProvider), isA<ImportInitial>());
  });

  test('selectFile with a supported extension moves to ImportFileSelected', () {
    container
        .read(customerImportProvider.notifier)
        .selectFile(path: '/tmp/customers.xlsx', name: 'customers.xlsx', size: 2048);

    final state = container.read(customerImportProvider) as ImportFileSelected;
    expect(state.fileName, 'customers.xlsx');
    expect(state.fileSize, 2048);
  });

  test('selectFile with an unsupported extension moves to ImportFailed', () {
    container.read(customerImportProvider.notifier).selectFile(path: '/tmp/customers.csv', name: 'customers.csv', size: 100);

    final state = container.read(customerImportProvider) as ImportFailed;
    expect(state.message, contains('Unsupported file type'));
  });

  test('clear resets to ImportInitial', () {
    final notifier = container.read(customerImportProvider.notifier);
    notifier.selectFile(path: '/tmp/customers.xlsx', name: 'customers.xlsx', size: 2048);
    notifier.clear();

    expect(container.read(customerImportProvider), isA<ImportInitial>());
  });

  test('startImport previews then commits, ending in ImportSucceeded with real aggregated outcomes', () async {
    const preview = ImportPreview(batchId: '01BATCH', status: 'preview', rows: []);
    const commitResult = ImportCommitResult(
      batchId: '01BATCH',
      status: 'committed',
      results: [],
      message: 'Import committed successfully',
    );
    when(() => mockRepository.previewImport(filePath: '/tmp/customers.xlsx', fileName: 'customers.xlsx'))
        .thenAnswer((_) async => preview);
    when(() => mockRepository.commitImport(batchId: '01BATCH')).thenAnswer((_) async => commitResult);

    final notifier = container.read(customerImportProvider.notifier);
    notifier.selectFile(path: '/tmp/customers.xlsx', name: 'customers.xlsx', size: 2048);

    await notifier.startImport();

    final state = container.read(customerImportProvider) as ImportSucceeded;
    expect(state.result.status, 'committed');
    verify(() => mockRepository.previewImport(filePath: '/tmp/customers.xlsx', fileName: 'customers.xlsx')).called(1);
    verify(() => mockRepository.commitImport(batchId: '01BATCH')).called(1);
  });

  test('startImport surfaces a real backend error as ImportFailed', () async {
    when(() => mockRepository.previewImport(filePath: any(named: 'filePath'), fileName: any(named: 'fileName')))
        .thenThrow(const ApiException(message: 'The uploaded file could not be read.', statusCode: 422));

    final notifier = container.read(customerImportProvider.notifier);
    notifier.selectFile(path: '/tmp/customers.xlsx', name: 'customers.xlsx', size: 2048);

    await notifier.startImport();

    final state = container.read(customerImportProvider) as ImportFailed;
    expect(state.message, 'The uploaded file could not be read.');
  });

  test('startImport does nothing when no file has been selected', () async {
    final notifier = container.read(customerImportProvider.notifier);

    await notifier.startImport();

    expect(container.read(customerImportProvider), isA<ImportInitial>());
    verifyNever(() => mockRepository.previewImport(filePath: any(named: 'filePath'), fileName: any(named: 'fileName')));
  });
}
