import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../cases/presentation/widgets/case_card.dart';
import '../providers/customer_detail_providers.dart';

/// Customer Detail's "Cases" destination — `GET /collection-cases?customer_id={id}`
/// (`CollectionCaseController::index`'s `customer_id` filter). Flat,
/// unpaginated list, same style as `CustomerDocumentsScreen`/
/// `CustomerRecentPayments` — a customer realistically has few enough
/// cases that infinite-scroll pagination isn't warranted here.
class CustomerCasesScreen extends ConsumerWidget {
  final String customerId;

  const CustomerCasesScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(customerCasesProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Cases')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerCasesProvider(customerId));
          await ref.read(customerCasesProvider(customerId).future);
        },
        child: casesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: RetrySection(
              message: 'Could not load cases.',
              onRetry: () => ref.invalidate(customerCasesProvider(customerId)),
            ),
          ),
          data: (cases) {
            if (cases.isEmpty) {
              return const Center(child: Text('No collection cases yet', style: AppTypography.body));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cases[index];
                return CaseCard(
                  collectionCase: item,
                  activeTab: null,
                  onTap: () => context.push('/cases/${item.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
