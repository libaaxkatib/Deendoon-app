import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/customer_import/data/customer_import_repository.dart';
import 'package:mobile/features/customer_import/domain/import_commit_result.dart';
import 'package:mobile/features/customer_import/domain/import_preview.dart';
import 'package:mobile/features/customer_import/domain/import_preview_row.dart';
import 'package:mobile/features/customer_import/presentation/providers/import_file_picker_provider.dart';
import 'package:mobile/features/customer_import/presentation/screens/bulk_import_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerImportRepository extends Mock
    implements CustomerImportRepository {}

Future<PickedImportFile?> _fakePickerReturning(PickedImportFile? file) =>
    Future.value(file);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCustomerImportRepository repository,
  required Future<PickedImportFile?> Function() picker,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerImportRepositoryProvider.overrideWithValue(repository),
        importFilePickerProvider.overrideWithValue(picker),
      ],
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
        home: const BulkImportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockCustomerImportRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerImportRepository();
  });

  testWidgets(
    'shows the upload prompt and the real Download Sample Template button',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        picker: () => _fakePickerReturning(null),
      );

      expect(find.text('Select Excel file'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Download Sample Template'),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping Download Sample Template calls the real endpoint', (
    tester,
  ) async {
    when(
      () => mockRepository.downloadTemplate(),
    ).thenAnswer((_) async => [1, 2, 3, 4]);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      picker: () => _fakePickerReturning(null),
    );

    // A bounded pump rather than pumpAndSettle: the actual on-device file
    // write this action performs afterward (via `path_provider`) isn't
    // reliably completable in the widget-test sandbox — same untested
    // territory as `DocumentActions.saveToDevice`, which has no widget
    // test anywhere in this codebase for the identical reason. What's
    // verifiable and meaningful here is that the real network call
    // happens; the on-device save itself is exercised for real on a
    // device/emulator, not simulated in this environment.
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Download Sample Template'),
    );
    await tester.pump();

    verify(() => mockRepository.downloadTemplate()).called(1);
  });

  testWidgets('shows the real backend error when the template download fails', (
    tester,
  ) async {
    when(() => mockRepository.downloadTemplate()).thenThrow(
      const ApiException(
        message: 'This action is unauthorized.',
        statusCode: 403,
      ),
    );

    await _pumpScreen(
      tester,
      repository: mockRepository,
      picker: () => _fakePickerReturning(null),
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Download Sample Template'),
    );
    await tester.pumpAndSettle();

    expect(find.text('This action is unauthorized.'), findsOneWidget);
  });

  testWidgets('picking a supported file shows the Selected File Card', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      repository: mockRepository,
      picker: () => _fakePickerReturning((
        path: '/tmp/customers.xlsx',
        name: 'customers.xlsx',
        size: 2048,
      )),
    );

    await tester.tap(find.text('Select Excel file'));
    await tester.pumpAndSettle();

    expect(find.text('customers.xlsx'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
  });

  testWidgets(
    'picking an unsupported file type shows a real client-side rejection',
    (tester) async {
      await _pumpScreen(
        tester,
        repository: mockRepository,
        picker: () => _fakePickerReturning((
          path: '/tmp/customers.csv',
          name: 'customers.csv',
          size: 100,
        )),
      );

      await tester.tap(find.text('Select Excel file'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Unsupported file type. Only .xlsx and .xls files are supported.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping Import runs the real preview+commit flow and shows the aggregated summary',
    (tester) async {
      final preview = ImportPreview(
        batchId: '01BATCH',
        status: 'preview',
        rows: [
          {
            'row_number': 1,
            'data': {
              'name': 'Jane Trader',
              'phone': '254711111111',
              'credit_limit': 1000,
            },
            'validation_status': 'valid',
            'validation_errors': null,
            'duplicate_match': null,
          },
          {
            'row_number': 2,
            'data': {
              'name': 'John Vendor',
              'phone': '254722222222',
              'credit_limit': 2000,
            },
            'validation_status': 'valid',
            'validation_errors': null,
            'duplicate_match': null,
          },
          {
            'row_number': 3,
            'data': {
              'name': 'Existing Person',
              'phone': '254733333333',
              'credit_limit': 900,
            },
            'validation_status': 'valid',
            'validation_errors': null,
            'duplicate_match': {
              'customer_id': '01EXISTING',
              'name': 'Existing Person',
            },
          },
          {
            'row_number': 4,
            'data': {'name': '', 'phone': '254744444444', 'credit_limit': null},
            'validation_status': 'invalid',
            'validation_errors': [
              'name is required',
              'credit_limit is required and must be a non-negative number',
            ],
            'duplicate_match': null,
          },
        ].map((json) => ImportPreviewRow.fromJson(json)).toList(),
      );
      final commitResult = ImportCommitResult(
        batchId: '01BATCH',
        status: 'committed',
        results: [
          {'row_number': 1, 'outcome': 'created', 'customer_id': '01A'},
          {'row_number': 2, 'outcome': 'created', 'customer_id': '01B'},
          {'row_number': 3, 'outcome': 'skipped', 'customer_id': null},
          {'row_number': 4, 'outcome': 'skipped_invalid', 'customer_id': null},
        ].map(_toResultRow).toList(),
        message: 'Import committed successfully',
      );
      when(
        () => mockRepository.previewImport(
          filePath: '/tmp/customers.xlsx',
          fileName: 'customers.xlsx',
        ),
      ).thenAnswer((_) async => preview);
      when(
        () => mockRepository.commitImport(batchId: '01BATCH'),
      ).thenAnswer((_) async => commitResult);

      await _pumpScreen(
        tester,
        repository: mockRepository,
        picker: () => _fakePickerReturning((
          path: '/tmp/customers.xlsx',
          name: 'customers.xlsx',
          size: 2048,
        )),
      );
      await tester.tap(find.text('Select Excel file'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(find.text('Imported Successfully'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Skipped (Duplicate)'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Import committed successfully'), findsOneWidget);
    },
  );

  testWidgets('shows the empty state when the uploaded file has no rows', (
    tester,
  ) async {
    const preview = ImportPreview(
      batchId: '01BATCH',
      status: 'preview',
      rows: [],
    );
    const commitResult = ImportCommitResult(
      batchId: '01BATCH',
      status: 'committed',
      results: [],
      message: '',
    );
    when(
      () => mockRepository.previewImport(
        filePath: '/tmp/empty.xlsx',
        fileName: 'empty.xlsx',
      ),
    ).thenAnswer((_) async => preview);
    when(
      () => mockRepository.commitImport(batchId: '01BATCH'),
    ).thenAnswer((_) async => commitResult);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      picker: () => _fakePickerReturning((
        path: '/tmp/empty.xlsx',
        name: 'empty.xlsx',
        size: 512,
      )),
    );
    await tester.tap(find.text('Select Excel file'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.text('No rows found in the uploaded file.'), findsOneWidget);
  });

  testWidgets('shows the real backend error message when the import fails', (
    tester,
  ) async {
    when(
      () => mockRepository.previewImport(
        filePath: '/tmp/bad.xlsx',
        fileName: 'bad.xlsx',
      ),
    ).thenThrow(
      const ApiException(
        message:
            'The uploaded file could not be read. It may be corrupted or in an unsupported format.',
        statusCode: 422,
      ),
    );

    await _pumpScreen(
      tester,
      repository: mockRepository,
      picker: () => _fakePickerReturning((
        path: '/tmp/bad.xlsx',
        name: 'bad.xlsx',
        size: 512,
      )),
    );
    await tester.tap(find.text('Select Excel file'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The uploaded file could not be read.'),
      findsOneWidget,
    );
  });
}

ImportResultRow _toResultRow(Map<String, dynamic> json) =>
    ImportResultRow.fromJson(json);
