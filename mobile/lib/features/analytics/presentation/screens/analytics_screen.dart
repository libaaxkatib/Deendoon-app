import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import 'overview_tab.dart';
import 'reports_tab.dart';
import 'trends_tab.dart';

/// §5 Analytics — "Three tabs: Overview, Reports, and Trends." Overview is
/// the default tab on entering Analytics, per §5.1. Every underlying
/// report/analytics endpoint is gated backend-side by the `view-analytics`
/// Gate (`AppServiceProvider.php`), which additionally requires
/// `SubscriptionService::analyticsEnabled()` — a Free-plan tenant gets a
/// 403 on every single call. Rather than let each of the ~10 analytics
/// sections independently fail with a generic, indistinguishable "Could
/// not load" error, this screen checks the same `analyticsEnabled` flag
/// (already fetched for the Subscription screen, `Subscription.
/// analyticsEnabled`) once, up front, and shows a real "Upgrade your
/// plan" state instead of ever attempting the calls. Backend remains
/// authoritative — this is a UX improvement, not a duplicated rule; if the
/// subscription fetch itself fails, this fails open (shows the tabs) so a
/// transient network error here doesn't block an entitled tenant, and the
/// real backend Gate is still the actual enforcement either way.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _AnalyticsTabs(),
        data: (subscription) =>
            subscription.analyticsEnabled ? const _AnalyticsTabs() : const _AnalyticsLockedState(),
      ),
    );
  }
}

class _AnalyticsTabs extends StatelessWidget {
  const _AnalyticsTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(20),
              labelColor: context.colors.background,
              unselectedLabelColor: context.colors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: l10n.analyticsTabOverview),
                Tab(text: l10n.analyticsTabReports),
                Tab(text: l10n.analyticsTabTrends),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                OverviewTab(),
                ReportsTab(),
                TrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLockedState extends StatelessWidget {
  const _AnalyticsLockedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.analyticsNotIncludedTitle,
                    style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analyticsNotIncludedMessage,
                style: AppTypography.body.copyWith(color: context.colors.textPrimary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/account/subscription'),
                child: Text(l10n.analyticsUpgradePlanButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
