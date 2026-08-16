import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_repository.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket_page.dart';
import 'package:mobile/features/support_tickets/presentation/providers/support_ticket_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportTicketRepository extends Mock
    implements SupportTicketRepository {}

const _ticketOne = SupportTicket(
  id: '1',
  tenantId: '01TENANT',
  referenceNumber: 'TKT-0001',
  subject: 'Cannot record a payment',
  description: 'Getting an error on submit.',
  status: 'open',
  priority: 'high',
  category: 'bug',
  submittedByUserId: '01USER',
  businessName: 'Somali Builders',
  createdAt: '2026-08-01T00:00:00.000000Z',
  updatedAt: '2026-08-01T00:00:00.000000Z',
  closedAt: null,
  reopenedAt: null,
);

const _ticketTwo = SupportTicket(
  id: '2',
  tenantId: '01TENANT',
  referenceNumber: 'TKT-0002',
  subject: 'How do I export a report?',
  description: 'Looking for the export button.',
  status: 'open',
  priority: 'low',
  category: 'question',
  submittedByUserId: '01USER',
  businessName: 'Somali Builders',
  createdAt: '2026-08-02T00:00:00.000000Z',
  updatedAt: '2026-08-02T00:00:00.000000Z',
  closedAt: null,
  reopenedAt: null,
);

void main() {
  late _MockSupportTicketRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockSupportTicketRepository();
    container = ProviderContainer(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no status filter', () async {
    when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
      (_) async => const SupportTicketPage(
        tickets: [_ticketOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(supportTicketListProvider.future);

    expect(state.tickets, [_ticketOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [_ticketOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(supportTicketListProvider.future);

      when(() => mockRepository.fetchTickets(page: 2, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [_ticketTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(supportTicketListProvider.notifier).loadMore();

      final state = container.read(supportTicketListProvider).value!;
      expect(state.tickets, [_ticketOne, _ticketTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [_ticketOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(supportTicketListProvider.future);

      when(
        () => mockRepository.fetchTickets(page: 2, status: null),
      ).thenThrow(Exception('network error'));

      await container.read(supportTicketListProvider.notifier).loadMore();

      final state = container.read(supportTicketListProvider).value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.tickets, [_ticketOne]);
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [_ticketOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(supportTicketListProvider.future);

      when(
        () => mockRepository.fetchTickets(page: 2, status: null),
      ).thenThrow(Exception('network error'));
      await container.read(supportTicketListProvider.notifier).loadMore();
      expect(
        container.read(supportTicketListProvider).value!.loadMoreError,
        isTrue,
      );

      when(() => mockRepository.fetchTickets(page: 2, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [_ticketTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(supportTicketListProvider.notifier).loadMore();

      final state = container.read(supportTicketListProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.tickets, [_ticketOne, _ticketTwo]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchTickets(page: 2, status: null),
      ).called(2);
    },
  );
}
