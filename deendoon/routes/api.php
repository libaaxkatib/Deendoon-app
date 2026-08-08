<?php

use App\Http\Controllers\AdminReferenceDataController;
use App\Http\Controllers\AdminSettingsController;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\AuditTrailController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CalendarController;
use App\Http\Controllers\CollectionCaseController;
use App\Http\Controllers\CreditRiskController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\CustomerImportController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DebtController;
use App\Http\Controllers\DemandLetterController;
use App\Http\Controllers\DocumentController;
use App\Http\Controllers\FollowUpHistoryController;
use App\Http\Controllers\InvoiceController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProfessionalCollectionRequestController;
use App\Http\Controllers\ProfessionalCollectionTimelineController;
use App\Http\Controllers\PromiseToPayController;
use App\Http\Controllers\ReceiptController;
use App\Http\Controllers\ReminderCenterController;
use App\Http\Controllers\ReminderController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\StatementController;
use App\Http\Controllers\SubscriptionController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:register');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:login');
    Route::post('forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:forgot-password');
    Route::post('reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:reset-password');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::get('me', [AuthController::class, 'me']);
        Route::post('change-password', [AuthController::class, 'changePassword']);

        Route::get('customers', [CustomerController::class, 'index']);
        Route::post('customers', [CustomerController::class, 'store']);
        Route::post('customers/check-duplicate', [CustomerController::class, 'checkDuplicate']);
        Route::post('customers/import', [CustomerImportController::class, 'store']);
        Route::post('customers/import/{batch}/commit', [CustomerImportController::class, 'commit']);
        Route::post('customers/{customer}/restore', [CustomerController::class, 'restore'])->withTrashed();
        Route::get('customers/{customer}', [CustomerController::class, 'show'])->withTrashed();
        Route::put('customers/{customer}', [CustomerController::class, 'update']);
        Route::post('customers/{customer}/archive', [CustomerController::class, 'archive']);
        Route::patch('customers/{customer}/status', [CustomerController::class, 'updateStatus']);
        Route::get('customers/{customer}/credit-profile', [CustomerController::class, 'creditProfile']);
        Route::patch('customers/{customer}/credit-limit', [CustomerController::class, 'updateCreditLimit']);
        Route::get('customers/{customer}/credit-score', [CreditRiskController::class, 'creditScore']);
        Route::post('customers/{customer}/debts', [DebtController::class, 'store']);
        Route::get('customers/{customer}/payments', [PaymentController::class, 'forCustomer']);
        Route::get('customers/{customer}/documents', [DocumentController::class, 'forCustomer']);
        Route::post('customers/{customer}/statements', [StatementController::class, 'storeForCustomer']);

        Route::get('debts', [DebtController::class, 'index']);
        Route::get('debts/{debt}', [DebtController::class, 'show'])->withTrashed();
        Route::put('debts/{debt}', [DebtController::class, 'update']);
        Route::patch('debts/{debt}/status', [DebtController::class, 'updateStatus']);
        Route::post('debts/{debt}/archive', [DebtController::class, 'archive']);
        Route::post('debts/{debt}/restore', [DebtController::class, 'restore'])->withTrashed();
        Route::get('debts/{debt}/timeline', [DebtController::class, 'timeline']);
        Route::patch('debts/{debt}/recovery-stage', [DebtController::class, 'updateRecoveryStage']);
        Route::get('debts/{debt}/followup-history', [FollowUpHistoryController::class, 'index']);
        Route::post('debts/{debt}/reminders/whatsapp', [ReminderController::class, 'whatsapp']);
        Route::post('debts/{debt}/reminders/sms', [ReminderController::class, 'sms']);
        Route::post('debts/{debt}/reminders/call', [ReminderController::class, 'call']);
        Route::post('debts/{debt}/promise-to-pay', [PromiseToPayController::class, 'store']);
        Route::post('debts/{debt}/payments', [PaymentController::class, 'store']);
        Route::get('debts/{debt}/payments', [PaymentController::class, 'index']);
        Route::post('debts/{debt}/collection-cases', [CollectionCaseController::class, 'store']);
        Route::post('debts/{debt}/demand-letters', [DemandLetterController::class, 'store']);
        Route::post('debts/{debt}/invoices', [InvoiceController::class, 'store']);
        Route::post('debts/{debt}/statements', [StatementController::class, 'storeForDebt']);
        Route::get('debts/{debt}/documents', [DocumentController::class, 'forDebt']);

        Route::get('collection-cases', [CollectionCaseController::class, 'index']);
        Route::get('collection-cases/{case}', [CollectionCaseController::class, 'show']);
        Route::put('collection-cases/{case}', [CollectionCaseController::class, 'update']);
        Route::post('collection-cases/{case}/activities', [CollectionCaseController::class, 'recordActivity']);
        Route::post('collection-cases/{case}/close', [CollectionCaseController::class, 'close']);
        Route::get('collection-cases/{case}/history', [CollectionCaseController::class, 'history']);
        Route::post('collection-cases/{case}/professional-requests', [ProfessionalCollectionRequestController::class, 'store']);

        Route::get('professional-requests', [ProfessionalCollectionRequestController::class, 'index']);
        // Registered ahead of the {id} route below so "summary" is never
        // swallowed as an id (Transfer Case to Deendoon Recovery Team,
        // Product Owner-approved decision — Professional Collection
        // Summary Card).
        Route::get('professional-requests/summary', [ProfessionalCollectionRequestController::class, 'summary']);
        Route::get('professional-requests/{id}', [ProfessionalCollectionRequestController::class, 'show']);
        Route::patch('professional-requests/{id}/status', [ProfessionalCollectionRequestController::class, 'updateStatus']);
        Route::post('professional-requests/{id}/close', [ProfessionalCollectionRequestController::class, 'close']);
        Route::get('professional-requests/{id}/messages', [ProfessionalCollectionRequestController::class, 'messagesIndex']);
        Route::post('professional-requests/{id}/messages', [ProfessionalCollectionRequestController::class, 'messagesStore']);
        Route::get('professional-requests/{id}/documents', [ProfessionalCollectionRequestController::class, 'documents']);
        Route::get('professional-requests/{id}/attachments', [ProfessionalCollectionRequestController::class, 'attachmentsIndex']);
        Route::post('professional-requests/{id}/attachments', [ProfessionalCollectionRequestController::class, 'attachmentsStore']);
        Route::get('professional-requests/{id}/timeline', [ProfessionalCollectionTimelineController::class, 'index']);
        Route::post('professional-requests/{id}/timeline', [ProfessionalCollectionTimelineController::class, 'store']);
        Route::patch('professional-requests/{id}/timeline/{eventId}', [ProfessionalCollectionTimelineController::class, 'update']);

        Route::get('receipts/{receipt}', [ReceiptController::class, 'show']);
        Route::get('documents', [DocumentController::class, 'index']);
        Route::get('documents/storage-usage', [DocumentController::class, 'storageUsage']);
        Route::get('documents/{id}/download', [DocumentController::class, 'download']);
        Route::get('documents/{id}/history', [DocumentController::class, 'history']);
        Route::post('documents/{id}/share', [DocumentController::class, 'share']);
        Route::get('documents/{id}', [DocumentController::class, 'show']);

        Route::get('dashboard/business-health', [DashboardController::class, 'businessHealth']);
        Route::get('dashboard/kpis', [DashboardController::class, 'kpis']);
        Route::get('dashboard/todays-overview', [DashboardController::class, 'todaysOverview']);
        Route::get('dashboard/recent-cases', [DashboardController::class, 'recentCases']);

        Route::get('subscription', [SubscriptionController::class, 'show']);
        Route::get('subscription/plans', [SubscriptionController::class, 'plans']);
        Route::get('subscription/change-requests', [SubscriptionController::class, 'changeRequests']);
        Route::post('subscription/upgrade-request', [SubscriptionController::class, 'upgradeRequest']);
        Route::post('subscription/change-requests/{subscriptionChangeRequest}/cancel', [SubscriptionController::class, 'cancelChangeRequest']);
        Route::get('subscription/storage', [SubscriptionController::class, 'storage']);
        Route::post('subscription/storage-addon-request', [SubscriptionController::class, 'storageAddonRequest']);
        Route::post('subscription/storage-addon-requests/{storageAddon}/cancel', [SubscriptionController::class, 'cancelStorageAddon']);

        // Subscription Approval + Storage Add-on Approval (Product
        // Owner-approved decision record): the Deendoon Platform Admin
        // Approval Center — Gate::authorize('platform-admin-only')
        // restricts every one of these to the Platform Administrator, the
        // mirror of the Business Owner-only routes above.
        Route::get('admin/subscription/change-requests', [SubscriptionController::class, 'changeRequestApprovalCenter']);
        Route::get('admin/subscription/rejection-reasons', [SubscriptionController::class, 'changeRequestRejectionReasons']);
        Route::post('admin/subscription/change-requests/{subscriptionChangeRequest}/approve', [SubscriptionController::class, 'approveChangeRequest']);
        Route::post('admin/subscription/change-requests/{subscriptionChangeRequest}/reject', [SubscriptionController::class, 'rejectChangeRequest']);
        Route::get('admin/storage-addons', [SubscriptionController::class, 'storageAddonApprovalCenter']);
        Route::get('admin/storage-addons/rejection-reasons', [SubscriptionController::class, 'storageAddonRejectionReasons']);
        Route::post('admin/storage-addons/{storageAddon}/approve', [SubscriptionController::class, 'approveStorageAddon']);
        Route::post('admin/storage-addons/{storageAddon}/reject', [SubscriptionController::class, 'rejectStorageAddon']);
        Route::get('reports/aging-analysis', [ReportController::class, 'agingAnalysis']);
        Route::get('reports/customers', [ReportController::class, 'customers']);
        Route::get('reports/debts', [ReportController::class, 'debts']);
        Route::get('reports/collection-cases', [ReportController::class, 'collectionCases']);
        Route::get('reports/payments', [ReportController::class, 'payments']);
        Route::get('reports/credit-risk', [ReportController::class, 'creditRisk']);
        Route::get('reports/collection-analytics', [ReportController::class, 'collectionAnalytics']);
        Route::get('reports/risk-distribution', [ReportController::class, 'riskDistribution']);
        Route::get('reports/collections-trend', [ReportController::class, 'collectionsTrend']);
        Route::get('reports/{reportType}/export', [ReportController::class, 'export']);

        Route::get('notifications', [NotificationController::class, 'index']);
        Route::get('notifications/history', [NotificationController::class, 'history']);
        Route::patch('notifications/mark-all-read', [NotificationController::class, 'markAllRead']);
        Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead']);

        Route::get('calendar', [CalendarController::class, 'index']);

        // Backend v2.1 — Reminder Center (docs/Mobile_UI_V1_Frozen.md §7).
        // Distinct from the debts/{debt}/reminders/* routes above, which
        // remain the pre-existing, unchanged FR-030 manual log actions.
        Route::get('reminders/summary', [ReminderCenterController::class, 'summary']);
        Route::get('reminders', [ReminderCenterController::class, 'index']);
        Route::post('reminders', [ReminderCenterController::class, 'store']);
        Route::get('reminders/{reminder}', [ReminderCenterController::class, 'show']);
        Route::put('reminders/{reminder}', [ReminderCenterController::class, 'update']);
        Route::delete('reminders/{reminder}', [ReminderCenterController::class, 'destroy']);
        Route::patch('reminders/{reminder}/complete', [ReminderCenterController::class, 'complete']);
        Route::post('reminders/{reminder}/send', [ReminderCenterController::class, 'send']);

        Route::get('message-templates', [MessageController::class, 'templates']);
        Route::post('messages/render', [MessageController::class, 'render']);
        Route::post('messages/send/whatsapp', [MessageController::class, 'sendWhatsApp']);
        Route::post('messages/send/sms', [MessageController::class, 'sendSms']);

        Route::get('search', [SearchController::class, 'index']);

        // Deprecated (RBAC Architecture Amendment, Product Owner Decision,
        // 2026-07-30): Version 1 has exactly one account per tenant (the
        // Business Owner) — no second tenant user exists to administer.
        // Left in place and functional pending confirmation of no residual
        // dependency; scheduled for removal in a future cleanup pass.
        Route::get('admin/users', [AdminUserController::class, 'index']);
        Route::post('admin/users', [AdminUserController::class, 'store']);
        Route::get('admin/users/{user}', [AdminUserController::class, 'show']);
        Route::put('admin/users/{user}', [AdminUserController::class, 'update']);
        Route::post('admin/users/{user}/deactivate', [AdminUserController::class, 'deactivate']);
        Route::patch('admin/users/{user}/role', [AdminUserController::class, 'updateRole']);

        Route::get('admin/settings/company-profile', [AdminSettingsController::class, 'companyProfile']);
        Route::put('admin/settings/company-profile', [AdminSettingsController::class, 'updateCompanyProfile']);
        Route::get('admin/settings/preferences', [AdminSettingsController::class, 'preferences']);
        Route::put('admin/settings/preferences', [AdminSettingsController::class, 'updatePreferences']);

        Route::get('admin/reference-data/{category}', [AdminReferenceDataController::class, 'show']);
        Route::put('admin/reference-data/{category}', [AdminReferenceDataController::class, 'update']);

        Route::get('admin/audit-trail', [AuditTrailController::class, 'index']);
    });
});
