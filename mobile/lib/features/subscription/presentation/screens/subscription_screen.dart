import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/subscription.dart';
import '../../domain/subscription_change_request.dart';
import '../../domain/subscription_plan.dart';
import '../providers/subscription_actions.dart';
import '../providers/subscription_change_request_list_provider.dart';
import '../providers/subscription_providers.dart';
import '../widgets/request_plan_change_sheet.dart';

/// Business Owner Subscription — read-only view of the tenant's own
/// current Subscription (`GET /subscription`) and Change Request history
/// (`GET /subscription/change-requests`), the real Subscription Plan
/// catalog (`GET /subscription/plans`), and the real Upgrade/Downgrade
/// Request flow (`POST /subscription/upgrade-request` +
/// `POST /subscription/change-requests/{id}/cancel`). Every section loads/
/// errors independently (same pattern as `ProfessionalCollectionDetailScreen`'s
/// summary/messages split).
///
/// Selecting a plan is a client-side affordance only — it reveals a
/// "Request Plan Change" button that opens `showRequestPlanChangeSheet`,
/// which collects the payment reference and calls the real
/// `SubscriptionActions.requestUpgrade`. Approval/activation is entirely
/// backend-owned (Platform Administrator only) — this screen only ever
/// shows the request as Pending, never as active, and never computes an
/// expiry date itself.
///
/// "Manage Storage" is this screen's own entry point to `StorageScreen`
/// (Phase 5 Step 6) — reached at `/account/subscription`, with Storage one
/// level deeper at `/account/storage`, matching the approved
/// Account → Subscription → Storage navigation flow (no separate Storage
/// entry on the Account menu itself).
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _plansSectionKey = GlobalKey();
  final _historySectionKey = GlobalKey();
  String? _selectedPlanId;

  void _scrollToPlans() {
    final plansContext = _plansSectionKey.currentContext;
    if (plansContext == null) return;
    Scrollable.ensureVisible(plansContext, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _scrollToHistory() {
    final historyContext = _historySectionKey.currentContext;
    if (historyContext == null) return;
    Scrollable.ensureVisible(historyContext, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _onPlanSelected(String planId) {
    setState(() => _selectedPlanId = _selectedPlanId == planId ? null : planId);
  }

  /// Opens the real request sheet. On a genuine success (the sheet only
  /// pops `true` after `SubscriptionActions.requestUpgrade` actually
  /// succeeds — see `showRequestPlanChangeSheet`), deselects the plan and
  /// scrolls down to the history section, where the new request now shows
  /// with a Pending badge (`subscriptionChangeRequestListProvider` was
  /// already invalidated by the action itself). Never claims the plan is
  /// active — only that the request was submitted.
  Future<void> _onRequestPlanChange(SubscriptionPlan plan) async {
    final messenger = ScaffoldMessenger.of(context);
    final submitted = await showRequestPlanChangeSheet(context, plan);
    if (submitted != true || !mounted) return;

    setState(() => _selectedPlanId = null);
    messenger.showSnackBar(
      SnackBar(content: Text('Plan change request to ${plan.name} submitted — status: Pending.')),
    );
    _scrollToHistory();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionProvider);
          ref.invalidate(subscriptionPlansProvider);
          await ref.read(subscriptionProvider.future);
        },
        child: subscriptionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load your subscription.',
                onRetry: () => ref.invalidate(subscriptionProvider),
              ),
            ),
          ),
          data: (subscription) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CurrentSubscriptionCard(subscription: subscription),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/account/storage'),
                  icon: const Icon(Icons.storage_outlined, size: 18),
                  label: const Text('Manage Storage'),
                ),
              ),
              if (subscription.readOnly) ...[
                const SizedBox(height: 16),
                _ReadOnlyBanner(onUpgradeTap: _scrollToPlans),
              ],
              const SizedBox(height: 24),
              KeyedSubtree(
                key: _plansSectionKey,
                child: SectionHeader(title: 'Available Plans'),
              ),
              const SizedBox(height: 8),
              _AvailablePlansSection(
                currentPlanId: subscription.plan?.id,
                selectedPlanId: _selectedPlanId,
                onSelect: _onPlanSelected,
              ),
              if (_selectedPlanId != null) ...[
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final plans = ref.watch(subscriptionPlansProvider).valueOrNull ?? [];
                    final selectedPlan = plans.where((plan) => plan.id == _selectedPlanId).firstOrNull;
                    if (selectedPlan == null) return const SizedBox.shrink();
                    return ElevatedButton(
                      onPressed: () => _onRequestPlanChange(selectedPlan),
                      child: Text('Request Plan Change to ${selectedPlan.name}'),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              KeyedSubtree(
                key: _historySectionKey,
                child: SectionHeader(title: 'Request History'),
              ),
              const SizedBox(height: 8),
              const _ChangeRequestHistorySection(),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) => date == null ? '—' : date.toIso8601String().split('T').first;

/// Mirrors every field `SubscriptionController::show()` actually returns.
/// `readOnly` is shown as a plain status row here; the actionable
/// explanation + Upgrade Plan CTA is the separate `_ReadOnlyBanner` below,
/// since it needs its own emphasis and a callback.
class _CurrentSubscriptionCard extends StatelessWidget {
  final Subscription subscription;

  const _CurrentSubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subscription.planName ?? 'No Plan',
                  style: AppTypography.subheading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subscription.subscriptionStatus != null) ...[
                const SizedBox(width: 8),
                StatusBadge(status: subscription.subscriptionStatus!),
              ],
            ],
          ),
          const Divider(height: 32, color: AppColors.background),
          _InfoRow(label: 'Monthly Price', value: subscription.planPrice ?? '—'),
          if (subscription.onTrial) ...[
            const SizedBox(height: 12),
            _InfoRow(label: 'Trial Ends', value: _formatDate(subscription.trialEndsAt)),
          ],
          const SizedBox(height: 12),
          _InfoRow(label: 'Start Date', value: _formatDate(subscription.startedAt)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Expiry Date', value: _formatDate(subscription.expiresAt)),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Customers',
            value: '${subscription.customerUsage} / ${subscription.customerLimit?.toString() ?? 'Unlimited'}',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Storage Used', value: _formatFileSize(subscription.storageUsageBytes)),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Storage Limit',
            value: subscription.storageLimit == null ? 'Unlimited' : '${subscription.storageLimit} GB',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Analytics', value: subscription.analyticsEnabled ? 'Included' : 'Not Included'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Account Status', value: subscription.readOnly ? 'Read-only' : 'Normal'),
        ],
      ),
    );
  }
}

/// `read_only` (`SubscriptionController::show()`) is set exclusively by
/// the customer-count-driven enforcement path (`Customer.is_read_only`) —
/// never by storage — so the explanation here is deliberately specific to
/// the customer limit, not a generic "plan limit reached" claim.
class _ReadOnlyBanner extends StatelessWidget {
  final VoidCallback onUpgradeTap;

  const _ReadOnlyBanner({required this.onUpgradeTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Limit Reached',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "You've reached your current plan's customer limit, so adding new customers is blocked. "
            'Your existing data remains fully accessible. Upgrade your plan to add more customers.',
            style: AppTypography.body,
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onUpgradeTap, child: const Text('Upgrade Plan')),
        ],
      ),
    );
  }
}

class _AvailablePlansSection extends ConsumerWidget {
  final String? currentPlanId;
  final String? selectedPlanId;
  final ValueChanged<String> onSelect;

  const _AvailablePlansSection({required this.currentPlanId, required this.selectedPlanId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return plansAsync.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: 'Could not load subscription plans.',
        onRetry: () => ref.invalidate(subscriptionPlansProvider),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No plans available.', style: AppTypography.body),
          );
        }
        return Column(
          children: [
            for (final plan in plans) ...[
              _PlanCard(
                plan: plan,
                isCurrent: plan.id == currentPlanId,
                isSelected: plan.id == selectedPlanId,
                onTap: plan.id == currentPlanId ? null : () => onSelect(plan.id),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlanCard({required this.plan, required this.isCurrent, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppCard.radius),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(plan.name, style: AppTypography.subheading, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Current Plan',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                else if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
            const Divider(height: 24, color: AppColors.background),
            _InfoRow(label: 'Monthly Price', value: plan.monthlyPrice),
            const SizedBox(height: 8),
            _InfoRow(label: 'Customer Limit', value: plan.customerLimit?.toString() ?? 'Unlimited'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Storage Limit', value: plan.storageLimit == null ? 'Unlimited' : '${plan.storageLimit} GB'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Analytics', value: plan.analyticsEnabled ? 'Included' : 'Not Included'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The tenant's own Subscription Change Request history
/// (`GET /subscription/change-requests`, newest first) — surfaces the
/// business rule "only one Pending request at a time" implicitly: a
/// Pending request, if any, is always the most recent one and appears
/// first. Cancel is only offered on a Pending request; Rejected/Cancelled
/// ones are shown as history only — the Business Owner can start a new
/// request afterward from Available Plans above, nothing here blocks that.
class _ChangeRequestHistorySection extends ConsumerWidget {
  const _ChangeRequestHistorySection();

  Future<void> _cancel(BuildContext context, WidgetRef ref, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subscriptionActionsProvider).cancelChangeRequest(id);
      messenger.showSnackBar(const SnackBar(content: Text('Subscription Change Request cancelled.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(subscriptionChangeRequestListProvider);

    return listAsync.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: 'Could not load your subscription change request history.',
        onRetry: () => ref.invalidate(subscriptionChangeRequestListProvider),
      ),
      data: (state) {
        if (state.changeRequests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No subscription change requests yet.', style: AppTypography.body),
          );
        }
        return Column(
          children: [
            for (final request in state.changeRequests) ...[
              _ChangeRequestCard(
                request: request,
                onCancel: request.status == 'pending' ? () => _cancel(context, ref, request.id) : null,
              ),
              const SizedBox(height: 10),
            ],
            if (state.hasMore) ...[
              const SizedBox(height: 4),
              Center(
                child: state.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: () => ref.read(subscriptionChangeRequestListProvider.notifier).loadMore(),
                        child: const Text('Load More'),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChangeRequestCard extends StatelessWidget {
  final SubscriptionChangeRequest request;
  final VoidCallback? onCancel;

  const _ChangeRequestCard({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final rejectionReasons = request.rejectionReasons;
    final hasRejectionReasons = rejectionReasons != null && rejectionReasons.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.requestedPlan?.name ?? '—',
                  style: AppTypography.subheading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: request.status),
            ],
          ),
          const Divider(height: 24, color: AppColors.background),
          _InfoRow(label: 'From', value: request.currentPlan?.name ?? '—'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Payment Reference', value: request.paymentReference),
          const SizedBox(height: 8),
          _InfoRow(label: 'Requested On', value: _formatDate(request.requestedAt)),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Reviewed On', value: _formatDate(request.reviewedAt)),
          ],
          if (hasRejectionReasons) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Rejection Reason', value: rejectionReasons.join(', ')),
          ] else if (request.rejectionReason != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Rejection Reason', value: request.rejectionReason!),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onCancel, child: const Text('Cancel Request')),
          ],
        ],
      ),
    );
  }
}

/// Same rounding/unit convention as `formatFileSize`
/// (`documents/presentation/widgets/document_type_icon.dart`) — duplicated
/// locally rather than imported cross-feature, matching this codebase's
/// existing precedent (`bulk_import_screen.dart`'s own `_formatFileSize`).
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
