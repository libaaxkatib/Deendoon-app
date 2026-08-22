import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/domain/subscription_change_request.dart';
import 'package:mobile/features/subscription/domain/subscription_change_request_page.dart';
import 'package:mobile/features/subscription/presentation/providers/subscription_change_request_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

final _requestOne = SubscriptionChangeRequest(
  id: '1',
  tenantId: '01TENANT',
  tenantName: null,
  requestedPlan: null,
  currentPlan: null,
  paymentPhone: '+252611234567',
  paymentReference: 'REF-0001',
  status: 'pending',
  requestedAt: DateTime.parse('2026-08-01T00:00:00.000000Z'),
  reviewedBy: null,
  reviewedAt: null,
  rejectionReason: null,
  rejectionReasons: null,
);

final _requestTwo = SubscriptionChangeRequest(
  id: '2',
  tenantId: '01TENANT',
  tenantName: null,
  requestedPlan: null,
  currentPlan: null,
  paymentPhone: '+252611234567',
  paymentReference: 'REF-0002',
  status: 'approved',
  requestedAt: DateTime.parse('2026-07-01T00:00:00.000000Z'),
  reviewedBy: '01ADMIN',
  reviewedAt: DateTime.parse('2026-07-02T00:00:00.000000Z'),
  rejectionReason: null,
  rejectionReasons: null,
);

void main() {
  late _MockSubscriptionRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockSubscriptionRepository();
    container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1', () async {
    when(() => mockRepository.fetchChangeRequests(page: 1)).thenAnswer(
      (_) async => SubscriptionChangeRequestPage(
        changeRequests: [_requestOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(
      subscriptionChangeRequestListProvider.future,
    );

    expect(state.changeRequests, [_requestOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(() => mockRepository.fetchChangeRequests(page: 1)).thenAnswer(
        (_) async => SubscriptionChangeRequestPage(
          changeRequests: [_requestOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(subscriptionChangeRequestListProvider.future);

      when(() => mockRepository.fetchChangeRequests(page: 2)).thenAnswer(
        (_) async => SubscriptionChangeRequestPage(
          changeRequests: [_requestTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container
          .read(subscriptionChangeRequestListProvider.notifier)
          .loadMore();

      final state = container
          .read(subscriptionChangeRequestListProvider)
          .value!;
      expect(state.changeRequests, [_requestOne, _requestTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(() => mockRepository.fetchChangeRequests(page: 1)).thenAnswer(
        (_) async => SubscriptionChangeRequestPage(
          changeRequests: [_requestOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(subscriptionChangeRequestListProvider.future);

      when(
        () => mockRepository.fetchChangeRequests(page: 2),
      ).thenThrow(Exception('network error'));

      await container
          .read(subscriptionChangeRequestListProvider.notifier)
          .loadMore();

      final state = container
          .read(subscriptionChangeRequestListProvider)
          .value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.changeRequests, [_requestOne]);
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(() => mockRepository.fetchChangeRequests(page: 1)).thenAnswer(
        (_) async => SubscriptionChangeRequestPage(
          changeRequests: [_requestOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(subscriptionChangeRequestListProvider.future);

      when(
        () => mockRepository.fetchChangeRequests(page: 2),
      ).thenThrow(Exception('network error'));
      await container
          .read(subscriptionChangeRequestListProvider.notifier)
          .loadMore();
      expect(
        container
            .read(subscriptionChangeRequestListProvider)
            .value!
            .loadMoreError,
        isTrue,
      );

      when(() => mockRepository.fetchChangeRequests(page: 2)).thenAnswer(
        (_) async => SubscriptionChangeRequestPage(
          changeRequests: [_requestTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container
          .read(subscriptionChangeRequestListProvider.notifier)
          .loadMore();

      final state = container
          .read(subscriptionChangeRequestListProvider)
          .value!;
      expect(state.loadMoreError, isFalse);
      expect(state.changeRequests, [_requestOne, _requestTwo]);
      expect(state.hasMore, isFalse);
      verify(() => mockRepository.fetchChangeRequests(page: 2)).called(2);
    },
  );
}
