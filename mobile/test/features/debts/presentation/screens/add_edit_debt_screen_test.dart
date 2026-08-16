import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/attachments/data/attachment_repository.dart';
import 'package:mobile/features/attachments/domain/attachment.dart';
import 'package:mobile/features/attachments/presentation/providers/attachment_providers.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/credit_limit_warning.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/presentation/screens/add_edit_debt_screen.dart';
import 'package:mobile/features/quick_actions/domain/debt_draft.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockAttachmentRepository extends Mock implements AttachmentRepository {}

const _uploadedInvoice = Attachment(
  id: '1',
  entityId: '1',
  uploadedByUserId: '01USER',
  originalFilename: 'invoice.jpg',
  mimeType: 'image/jpeg',
  fileSize: 5000,
  description: 'Invoice',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

const _existingDebt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'pending',
  remainingBalance: '1000.00',
  recoveryStage: 1,
  notes: 'Call before 5pm',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDebtRepository repository,
  String? customerId,
  String? debtId,
  List<Override> extraOverrides = const [],
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('Debt List Screen')),
      GoRoute(
        path: '/form',
        builder: (_, _) =>
            AddEditDebtScreen(customerId: customerId, debtId: debtId),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repository),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
      ),
    ),
  );
  router.push('/form');
  await tester.pumpAndSettle();
}

void main() {
  late _MockDebtRepository mockRepository;

  setUp(() {
    mockRepository = _MockDebtRepository();
  });

  group('Add Debt', () {
    testWidgets(
      'shows a validation error instead of submitting an empty amount',
      (tester) async {
        await _pumpScreen(
          tester,
          repository: mockRepository,
          customerId: '01CUST',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
        await tester.pumpAndSettle();

        expect(find.text('Enter an amount'), findsOneWidget);
        verifyNever(
          () => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ),
        );
      },
    );

    testWidgets(
      'selecting Somali localizes the Add Debt screen title, button, and validation error',
      (tester) async {
        await _pumpScreen(
          tester,
          repository: mockRepository,
          customerId: '01CUST',
          locale: const Locale('so'),
        );

        // Screen title and submit button render in Somali outside Settings,
        // on a debt-specific screen.
        expect(
          find.text('Ku Dar Dayn'),
          findsWidgets,
        ); // AppBar title + submit button both use this key
        expect(find.text('Qadarka'), findsOneWidget); // "Amount" field label

        // Submitting with no amount surfaces the Somali validation message.
        await tester.tap(find.widgetWithText(ElevatedButton, 'Ku Dar Dayn'));
        await tester.pumpAndSettle();

        expect(find.text('Geli qadar'), findsOneWidget); // "Enter an amount"
        expect(find.text('Enter an amount'), findsNothing);
        verifyNever(
          () => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ),
        );
      },
    );

    testWidgets(
      'shows a validation error when the amount is valid but no due date was picked',
      (tester) async {
        await _pumpScreen(
          tester,
          repository: mockRepository,
          customerId: '01CUST',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '500.00',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
        await tester.pumpAndSettle();

        expect(find.text('Select a due date.'), findsOneWidget);
        verifyNever(
          () => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ),
        );
      },
    );

    testWidgets('submits the entered fields and pops on success', (
      tester,
    ) async {
      when(
        () => mockRepository.createDebt(
          customerId: '01CUST',
          amount: '500.00',
          dueDate: '2026-08-15',
          notes: null,
        ),
      ).thenAnswer((_) async => (debt: _existingDebt, warning: null));

      await _pumpScreen(
        tester,
        repository: mockRepository,
        customerId: '01CUST',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '500.00',
      );
      // Date picking is exercised via the picker; here we set it directly
      // through the OutlinedButton's onPressed by opening and confirming
      // the date picker dialog.
      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15')); // any visible day in the default month
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.createDebt(
          customerId: '01CUST',
          amount: '500.00',
          dueDate: any(named: 'dueDate'),
          notes: null,
        ),
      ).called(1);
      expect(find.byType(AddEditDebtScreen), findsNothing);
    });

    testWidgets(
      'shows a Credit Limit Exceeded dialog when the save returns a warning',
      (tester) async {
        const warning = CreditLimitWarning(
          type: 'CREDIT_LIMIT_EXCEEDED',
          message: 'This customer has exceeded the approved credit limit.',
          creditLimit: '5000.00',
          projectedOutstanding: '5500.00',
        );
        when(
          () => mockRepository.createDebt(
            customerId: '01CUST',
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => (debt: _existingDebt, warning: warning));

        await _pumpScreen(
          tester,
          repository: mockRepository,
          customerId: '01CUST',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '5500.00',
        );
        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
        await tester.pumpAndSettle();

        expect(find.text('Credit Limit Exceeded'), findsOneWidget);
        expect(
          find.text('This customer has exceeded the approved credit limit.'),
          findsOneWidget,
        );

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(AddEditDebtScreen), findsNothing);
      },
    );
  });

  group('Edit Debt', () {
    testWidgets('prefills fields and shows the amount read-only', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchDebt('1'),
      ).thenAnswer((_) async => _existingDebt);

      await _pumpScreen(tester, repository: mockRepository, debtId: '1');

      expect(find.text('1000.00'), findsOneWidget);
      expect(find.text('Call before 5pm'), findsOneWidget);
      // Amount is not an editable field in Edit mode.
      expect(find.widgetWithText(TextFormField, 'Amount'), findsNothing);
    });

    testWidgets('submits due date and notes without touching amount', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchDebt('1'),
      ).thenAnswer((_) async => _existingDebt);
      when(
        () => mockRepository.updateDebt(
          debtId: '1',
          dueDate: any(named: 'dueDate'),
          notes: 'Updated notes',
        ),
      ).thenAnswer((_) async => _existingDebt);

      await _pumpScreen(tester, repository: mockRepository, debtId: '1');

      // Notes is the only TextFormField in Edit mode — Amount renders as
      // read-only Text and Due Date as an OutlinedButton, not form fields.
      await tester.enterText(find.byType(TextFormField), 'Updated notes');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.updateDebt(
          debtId: '1',
          dueDate: any(named: 'dueDate'),
          notes: 'Updated notes',
        ),
      ).called(1);
    });
  });

  group('Draft mode (deferSubmit — Add Case wizard\'s Debt Details step)', () {
    Future<void> pumpDraftScreen(
      WidgetTester tester, {
      required _MockDebtRepository repository,
    }) async {
      DebtDraft? popped;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await context.push<DebtDraft>('/draft');
                },
                child: Text(
                  popped == null
                      ? 'Open Draft Form'
                      : 'Draft: ${popped!.amount}',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/draft',
            builder: (_, _) => const AddEditDebtScreen(deferSubmit: true),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [debtRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
          ),
        ),
      );
      await tester.tap(find.text('Open Draft Form'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows "Debt Details" title and a "Continue" button, not "Add Debt"',
      (tester) async {
        await pumpDraftScreen(tester, repository: mockRepository);

        expect(find.text('Debt Details'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'submitting pops with a DebtDraft instead of calling the create API',
      (tester) async {
        await pumpDraftScreen(tester, repository: mockRepository);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '500.00',
        );
        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pumpAndSettle();

        verifyNever(
          () => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ),
        );
        expect(find.text('Draft: 500.00'), findsOneWidget);
      },
    );

    testWidgets(
      'a picked invoice travels inside the popped DebtDraft (no upload here — no debt id yet)',
      (tester) async {
        final mockAttachmentRepository = _MockAttachmentRepository();
        tester.view.physicalSize = const Size(400, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        DebtDraft? popped;
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    popped = await context.push<DebtDraft>('/draft');
                  },
                  child: Text(
                    popped == null
                        ? 'Open Draft Form'
                        : 'Draft invoice: ${popped!.invoiceFile?.name}',
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/draft',
              builder: (_, _) => const AddEditDebtScreen(deferSubmit: true),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              debtRepositoryProvider.overrideWithValue(mockRepository),
              attachmentCameraProvider.overrideWithValue(
                () async => (path: '/tmp/invoice.jpg', name: 'invoice.jpg'),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: _localizationsDelegates,
            ),
          ),
        );
        await tester.tap(find.text('Open Draft Form'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '500.00',
        );
        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Scan Invoice'));
        await tester.pumpAndSettle();
        expect(find.text('invoice.jpg'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Draft invoice: invoice.jpg'), findsOneWidget);
        verifyNever(
          () => mockAttachmentRepository.uploadAttachment(
            entityPathPrefix: any(named: 'entityPathPrefix'),
            filePath: any(named: 'filePath'),
            fileName: any(named: 'fileName'),
            description: any(named: 'description'),
          ),
        );
      },
    );
  });

  group('Invoice attachment (P2.6/P2.7)', () {
    testWidgets(
      'Add mode: a picked invoice is uploaded to the newly created debt id',
      (tester) async {
        final mockAttachmentRepository = _MockAttachmentRepository();
        when(
          () => mockRepository.createDebt(
            customerId: '01CUST',
            amount: '500.00',
            dueDate: any(named: 'dueDate'),
            notes: null,
          ),
        ).thenAnswer((_) async => (debt: _existingDebt, warning: null));
        when(
          () => mockAttachmentRepository.uploadAttachment(
            entityPathPrefix: 'debts/1',
            filePath: '/tmp/invoice.jpg',
            fileName: 'invoice.jpg',
            description: 'Invoice',
          ),
        ).thenAnswer((_) async => _uploadedInvoice);

        await _pumpScreen(
          tester,
          repository: mockRepository,
          customerId: '01CUST',
          extraOverrides: [
            attachmentRepositoryProvider.overrideWithValue(
              mockAttachmentRepository,
            ),
            attachmentCameraProvider.overrideWithValue(
              () async => (path: '/tmp/invoice.jpg', name: 'invoice.jpg'),
            ),
          ],
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '500.00',
        );
        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Scan Invoice'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
        await tester.pumpAndSettle();

        verify(
          () => mockAttachmentRepository.uploadAttachment(
            entityPathPrefix: 'debts/1',
            filePath: '/tmp/invoice.jpg',
            fileName: 'invoice.jpg',
            description: 'Invoice',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'Edit mode: a picked invoice is uploaded to the existing debt id after saving',
      (tester) async {
        final mockAttachmentRepository = _MockAttachmentRepository();
        when(
          () => mockRepository.fetchDebt('1'),
        ).thenAnswer((_) async => _existingDebt);
        when(
          () => mockRepository.updateDebt(
            debtId: '1',
            dueDate: any(named: 'dueDate'),
            notes: 'Call before 5pm',
          ),
        ).thenAnswer((_) async => _existingDebt);
        when(
          () => mockAttachmentRepository.uploadAttachment(
            entityPathPrefix: 'debts/1',
            filePath: '/tmp/invoice.pdf',
            fileName: 'invoice.pdf',
            description: 'Invoice',
          ),
        ).thenAnswer((_) async => _uploadedInvoice);

        await _pumpScreen(
          tester,
          repository: mockRepository,
          debtId: '1',
          extraOverrides: [
            attachmentRepositoryProvider.overrideWithValue(
              mockAttachmentRepository,
            ),
            attachmentFilePickerProvider.overrideWithValue(
              () async => (path: '/tmp/invoice.pdf', name: 'invoice.pdf'),
            ),
          ],
        );

        await tester.tap(find.text('Upload Invoice'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
        await tester.pumpAndSettle();

        verify(
          () => mockAttachmentRepository.uploadAttachment(
            entityPathPrefix: 'debts/1',
            filePath: '/tmp/invoice.pdf',
            fileName: 'invoice.pdf',
            description: 'Invoice',
          ),
        ).called(1);
      },
    );

    testWidgets('not picking an invoice uploads nothing', (tester) async {
      final mockAttachmentRepository = _MockAttachmentRepository();
      when(
        () => mockRepository.createDebt(
          customerId: '01CUST',
          amount: '500.00',
          dueDate: any(named: 'dueDate'),
          notes: null,
        ),
      ).thenAnswer((_) async => (debt: _existingDebt, warning: null));

      await _pumpScreen(
        tester,
        repository: mockRepository,
        customerId: '01CUST',
        extraOverrides: [
          attachmentRepositoryProvider.overrideWithValue(
            mockAttachmentRepository,
          ),
        ],
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '500.00',
      );
      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockAttachmentRepository.uploadAttachment(
          entityPathPrefix: any(named: 'entityPathPrefix'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      );
    });
  });
}
