import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/screens/about_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/account/presentation/screens/business_profile_screen.dart';
import '../../features/account/domain/legal_content.dart';
import '../../features/account/presentation/screens/change_password_screen.dart';
import '../../features/account/presentation/screens/legal_content_screen.dart';
import '../../features/account/presentation/screens/profile_screen.dart';
import '../../features/account/presentation/screens/settings_screen.dart';
import '../../features/analytics/presentation/screens/aging_bucket_debts_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/analytics/presentation/screens/average_days_detail_screen.dart';
import '../../features/analytics/presentation/screens/collection_rate_detail_screen.dart';
import '../../features/analytics/presentation/screens/report_collection_cases_screen.dart';
import '../../features/analytics/presentation/screens/report_credit_risk_screen.dart';
import '../../features/analytics/presentation/screens/report_customers_screen.dart';
import '../../features/analytics/presentation/screens/report_debts_screen.dart';
import '../../features/analytics/presentation/screens/report_payments_screen.dart';
import '../../features/attachments/presentation/screens/attachments_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/customer_import/presentation/screens/bulk_import_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/cases/presentation/screens/case_detail_screen.dart';
import '../../features/cases/presentation/screens/case_list_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_cases_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/customer_documents_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/debts/presentation/screens/add_edit_debt_screen.dart';
import '../../features/debts/presentation/screens/debt_detail_screen.dart';
import '../../features/debts/presentation/screens/debt_list_screen.dart';
import '../../features/documents/presentation/screens/document_list_screen.dart';
import '../../features/documents/presentation/screens/document_history_screen.dart';
import '../../features/documents/presentation/screens/document_preview_screen.dart';
import '../../features/documents/presentation/screens/document_share_screen.dart';
import '../../features/documents/presentation/screens/documents_home_screen.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_attachments_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_detail_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_documents_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_list_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_messages_screen.dart';
import '../../features/professional_collection/presentation/screens/professional_collection_timeline_screen.dart';
import '../../features/quick_actions/domain/add_case_review_input.dart';
import '../../features/quick_actions/presentation/screens/add_case_review_screen.dart';
import '../../features/reminders/presentation/screens/message_preview_screen.dart';
import '../../features/reminders/presentation/screens/reminder_detail_screen.dart';
import '../../features/reminders/presentation/screens/reminder_list_screen.dart';
import '../../features/reminders/domain/reminder_entity_preset.dart';
import '../../features/reminders/presentation/screens/reminder_schedule_screen.dart';
import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscription/presentation/screens/storage_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import 'route_paths.dart';
import 'router_refresh_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: RoutePaths.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: RoutePaths.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(
        path: '/customers',
        builder: (_, state) => CustomerListScreen(selectionMode: state.uri.queryParameters['select'] == 'true'),
      ),
      GoRoute(path: '/customers/new', builder: (_, _) => const AddEditCustomerScreen()),
      GoRoute(path: '/customers/draft', builder: (_, _) => const AddEditCustomerScreen(deferSubmit: true)),
      GoRoute(
        path: '/customers/:id',
        builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (_, state) => AddEditCustomerScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/documents',
        builder: (_, state) => CustomerDocumentsScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/cases',
        builder: (_, state) => CustomerCasesScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customers/:id/attachments',
        builder: (_, state) => AttachmentsScreen(
          entityPathPrefix: 'customers/${state.pathParameters['id']}',
          canUpload: state.extra == null ? true : state.extra! as bool,
        ),
      ),
      GoRoute(
        path: '/customers/:id/debts',
        builder: (_, state) => DebtListScreen(
          customerId: state.pathParameters['id']!,
          selectionMode: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(
        path: '/customers/:id/debts/new',
        builder: (_, state) => AddEditDebtScreen(customerId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/debts/draft', builder: (_, _) => const AddEditDebtScreen(deferSubmit: true)),
      GoRoute(
        path: '/debts/:id',
        builder: (_, state) => DebtDetailScreen(debtId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/debts/:id/edit',
        builder: (_, state) => AddEditDebtScreen(debtId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/debts/:id/attachments',
        builder: (_, state) => AttachmentsScreen(entityPathPrefix: 'debts/${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/cases/:id',
        builder: (_, state) => CaseDetailScreen(caseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cases/:id/attachments',
        builder: (_, state) => AttachmentsScreen(entityPathPrefix: 'collection-cases/${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/add-case/review',
        builder: (_, state) => AddCaseReviewScreen(input: state.extra! as AddCaseReviewInput),
      ),
      GoRoute(path: '/professional-requests', builder: (_, _) => const ProfessionalCollectionListScreen()),
      GoRoute(
        path: '/professional-requests/:id',
        builder: (_, state) => ProfessionalCollectionDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/professional-requests/:id/messages',
        builder: (_, state) => ProfessionalCollectionMessagesScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/professional-requests/:id/documents',
        builder: (_, state) => ProfessionalCollectionDocumentsScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/professional-requests/:id/attachments',
        builder: (_, state) => ProfessionalCollectionAttachmentsScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/professional-requests/:id/timeline',
        builder: (_, state) => ProfessionalCollectionTimelineScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
      GoRoute(
        path: '/reminders/new',
        builder: (_, state) => ReminderScheduleScreen(entityPreset: state.extra as ReminderEntityPreset?),
      ),
      GoRoute(
        path: '/reminders/:id',
        builder: (_, state) => ReminderDetailScreen(reminderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reminders/:id/edit',
        builder: (_, state) => ReminderScheduleScreen(reminderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reminders/:id/send',
        builder: (_, state) => MessagePreviewScreen(
          reminderId: state.pathParameters['id']!,
          initialChannel: state.uri.queryParameters['channel'],
        ),
      ),
      GoRoute(path: '/documents/list', builder: (_, _) => const DocumentListScreen()),
      GoRoute(
        path: '/documents/:id',
        builder: (_, state) => DocumentPreviewScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/documents/:id/share',
        builder: (_, state) => DocumentShareScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/documents/:id/history',
        builder: (_, state) => DocumentHistoryScreen(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/analytics/reports/customers',
        builder: (_, state) => ReportCustomersScreen(initialRiskLevel: state.uri.queryParameters['riskLevel']),
      ),
      GoRoute(
        path: '/analytics/reports/debts',
        builder: (_, state) => ReportDebtsScreen(initialStatus: state.uri.queryParameters['status']),
      ),
      GoRoute(
        path: '/analytics/collection-rate-detail',
        builder: (_, _) => const CollectionRateDetailScreen(),
      ),
      GoRoute(
        path: '/analytics/average-days-detail',
        builder: (_, _) => const AverageDaysDetailScreen(),
      ),
      GoRoute(
        path: '/analytics/reports/debts/aging/:bucket',
        builder: (_, state) => AgingBucketDebtsScreen(bucket: state.pathParameters['bucket']!),
      ),
      GoRoute(path: '/analytics/reports/collection-cases', builder: (_, _) => const ReportCollectionCasesScreen()),
      GoRoute(
        path: '/analytics/reports/payments',
        builder: (_, state) => ReportPaymentsScreen(
          initialDateFrom: state.uri.queryParameters['dateFrom'],
          initialDateTo: state.uri.queryParameters['dateTo'],
        ),
      ),
      GoRoute(path: '/analytics/reports/credit-risk', builder: (_, _) => const ReportCreditRiskScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationListScreen()),
      GoRoute(
        path: '/notifications/:id',
        builder: (_, state) => NotificationDetailScreen(notification: state.extra! as AppNotification),
      ),
      GoRoute(path: '/search', builder: (_, _) => const GlobalSearchScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/account/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/account/about', builder: (_, _) => const AboutScreen()),
      GoRoute(
        path: '/account/privacy-policy',
        builder: (_, _) => const LegalContentScreen(title: 'Privacy Policy', content: kPrivacyPolicyContent),
      ),
      GoRoute(
        path: '/account/terms-conditions',
        builder: (_, _) =>
            const LegalContentScreen(title: 'Terms & Conditions', content: kTermsAndConditionsContent),
      ),
      GoRoute(path: '/account/business-profile', builder: (_, _) => const BusinessProfileScreen()),
      GoRoute(path: '/account/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/account/change-password', builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: '/account/bulk-import', builder: (_, _) => const BulkImportScreen()),
      GoRoute(path: '/account/subscription', builder: (_, _) => const SubscriptionScreen()),
      GoRoute(path: '/account/storage', builder: (_, _) => const StorageScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.home, builder: (_, _) => const HomeDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.analytics, builder: (_, _) => const AnalyticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.cases,
              builder: (_, state) => CaseListScreen(initialTab: state.uri.queryParameters['tab']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.reminders,
              builder: (_, state) => ReminderListScreen(initialFilter: state.uri.queryParameters['filter']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.documents, builder: (_, _) => const DocumentsHomeScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Routes reachable without a session — login and both password-recovery
/// screens (there is no reason an authenticated user should be doing
/// password recovery mid-session, so these also bounce to /home if
/// reached while already logged in, same as /login already did).
const _publicRoutes = {
  RoutePaths.login,
  RoutePaths.forgotPassword,
  RoutePaths.resetPassword,
};

String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authProvider);
  final loc = state.matchedLocation;

  if (auth is AuthInitial || auth is AuthRestoring) {
    return loc == RoutePaths.splash ? null : RoutePaths.splash;
  }

  final loggedIn = auth is Authenticated;
  if (!loggedIn) {
    return _publicRoutes.contains(loc) ? null : RoutePaths.login;
  }

  if (_publicRoutes.contains(loc) || loc == RoutePaths.splash) {
    return RoutePaths.home;
  }

  return null;
}
