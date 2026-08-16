import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/providers/business_profile_providers.dart';
import '../../../account/presentation/providers/settings_providers.dart';
import '../../../analytics/presentation/providers/aging_analysis_provider.dart';
import '../../../analytics/presentation/providers/collection_analytics_provider.dart';
import '../../../analytics/presentation/providers/report_collection_cases_provider.dart';
import '../../../analytics/presentation/providers/report_credit_risk_provider.dart';
import '../../../analytics/presentation/providers/report_customers_provider.dart';
import '../../../analytics/presentation/providers/report_debts_provider.dart';
import '../../../analytics/presentation/providers/report_payments_provider.dart';
import '../../../analytics/presentation/providers/risk_distribution_provider.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../cases/presentation/providers/case_list_provider.dart';
import '../../../customers/presentation/providers/customer_list_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../documents/presentation/providers/document_detail_providers.dart';
import '../../../documents/presentation/providers/document_list_provider.dart';
import '../../../notifications/presentation/providers/notification_list_provider.dart';
import '../../../professional_collection/presentation/providers/professional_collection_list_provider.dart';
import '../../../professional_collection/presentation/providers/professional_collection_summary_provider.dart';
import '../../../reminders/presentation/providers/reminder_detail_providers.dart';
import '../../../reminders/presentation/providers/reminder_list_provider.dart';
import '../../../subscription/presentation/providers/subscription_change_request_list_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../support_tickets/presentation/providers/support_ticket_list_provider.dart';

/// Every tenant/user-scoped, non-family, keep-alive provider in the app
/// (none use `.autoDispose`, so a stale `AsyncValue` otherwise survives
/// indefinitely in the single, never-recreated `ProviderContainer` from
/// `main.dart`). Called by `AuthNotifier` at both session boundaries —
/// `forceLogout()`/`closeAccount()` (so nothing from the ending session
/// survives) and `login()`/`register()` (so the new session's first read is
/// a guaranteed-fresh, correctly-authenticated fetch).
///
/// Deliberately excludes:
/// - Family-keyed providers (`debtDetailProvider`, `customerDetailProvider`,
///   `caseDetailProvider`, etc.) — keyed by globally-unique ULIDs, so a
///   different tenant can never read another tenant's entry.
/// - `subscriptionPlansProvider` — the plan catalog is identical for every
///   tenant, not tenant data (see its own doc comment).
/// - Device-only preferences (`localeProvider`, `themeModeProvider`,
///   `biometricSupportedProvider`, `biometricEnabledProvider`) — none hold
///   tenant data; the biometric preference's logout-clearing is separately
///   scoped to a future biometric fix, not this one.
///
/// Each entry is only invalidated if `ref.exists(...)` — i.e. only if it
/// was actually built at least once during the ending session. This isn't
/// an optimization: Riverpod eagerly *rebuilds* an invalidated keep-alive
/// provider immediately, even one with zero active listeners, as long as it
/// has ever been read in this container. Invalidating one that was never
/// read at all would still be a correct no-op on its own, but invalidating
/// all 28 unconditionally on every login/logout — most of which a typical
/// session never touches — was verified (via a standalone repro) to fire a
/// real background HTTP request for every one of them regardless of
/// relevance. Guarding on `exists` targets exactly the providers that
/// could actually be holding stale data, and leaves everything else alone.
void resetTenantScopedProviders(Ref ref) {
  final providers = <ProviderBase>[
    // Dashboard
    businessHealthProvider,
    dashboardKpisProvider,
    todaysOverviewProvider,
    recentCasesProvider,

    // Account
    settingsProvider,
    businessProfileProvider,

    // Analytics
    collectionAnalyticsProvider,
    agingAnalysisProvider,
    riskDistributionProvider,
    reportPaymentsProvider,
    reportDebtsProvider,
    reportCustomersProvider,
    reportCreditRiskProvider,
    reportCollectionCasesProvider,

    // Professional Collection
    professionalCollectionSummaryProvider,
    professionalCollectionListProvider,

    // Documents
    storageUsageProvider,
    documentListProvider,

    // Calendar
    calendarMonthProvider,

    // Reminders
    reminderSummaryProvider,
    reminderListProvider,

    // Customers / Cases
    customerListProvider,
    caseListProvider,

    // Subscription
    subscriptionProvider,
    subscriptionStorageProvider,
    subscriptionChangeRequestListProvider,

    // Notifications / Support
    notificationListProvider,
    supportTicketListProvider,
  ];

  for (final provider in providers) {
    if (ref.exists(provider)) ref.invalidate(provider);
  }
}
