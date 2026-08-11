import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_timeline_event.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_timeline_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            SomaliMaterialLocalizationsDelegate(),
            SomaliCupertinoLocalizationsDelegate(),
          ],
          home: ProfessionalCollectionTimelineScreen(requestId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders timeline events with real fields, no write UI', (tester) async {
    when(() => mockRepository.fetchTimeline('1')).thenAnswer((_) async => const [
          ProfessionalCollectionTimelineEvent(
            id: '1',
            professionalCollectionRequestId: '1',
            eventType: 'field_visit',
            officerUserId: '02USER',
            occurredAt: '2026-08-02T00:00:00.000000Z',
            notes: 'Visited the customer premises.',
            outcome: 'no_answer',
            attachments: [],
            createdAt: '2026-08-02T00:00:00.000000Z',
            updatedAt: '2026-08-02T00:00:00.000000Z',
          ),
        ]);

    await pumpScreen(tester);

    expect(find.text('field_visit'), findsOneWidget);
    expect(find.text('Visited the customer premises.'), findsOneWidget);
    expect(find.text('Outcome: no_answer'), findsOneWidget);
    // Read-only: no way to add/edit a timeline event exists on this screen.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('shows the explicit empty state when there are no events yet', (tester) async {
    when(() => mockRepository.fetchTimeline('1')).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No timeline events yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the fetch fails', (tester) async {
    when(() => mockRepository.fetchTimeline('1')).thenThrow(Exception('network down'));

    await pumpScreen(tester);

    expect(find.text('Could not load the timeline.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
