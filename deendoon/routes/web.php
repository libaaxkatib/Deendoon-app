<?php

use App\Http\Controllers\Admin\AdminAuditLogController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminCustomerController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminDebtController;
use App\Http\Controllers\Admin\AdminNotificationController;
use App\Http\Controllers\Admin\AdminPaymentController;
use App\Http\Controllers\Admin\AdminProfessionalCollectionController;
use App\Http\Controllers\Admin\AdminReportController;
use App\Http\Controllers\Admin\AdminSettingsController;
use App\Http\Controllers\Admin\AdminSubscriptionController;
use App\Http\Controllers\Admin\AdminSupportTicketController;
use App\Http\Controllers\Admin\AdminSystemController;
use App\Http\Controllers\Admin\AdminTenantController;
use App\Http\Controllers\LegalController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/**
 * Public, unauthenticated legal pages (Mobile Play Store Readiness, Fix
 * #3 Part A) — Google Play Console requires a publicly accessible HTTPS
 * Privacy Policy URL; Terms & Conditions is served alongside it for the
 * same purpose. No session, no tenant scoping, content mirrors the
 * mobile app's existing in-app copy exactly.
 */
Route::get('/privacy-policy', [LegalController::class, 'privacyPolicy'])->name('legal.privacy-policy');
Route::get('/terms-conditions', [LegalController::class, 'termsConditions'])->name('legal.terms-conditions');

/**
 * Admin Panel — Deendoon Super Admin Web Panel (Product Owner decision:
 * Laravel Blade + Tailwind CSS, session auth). Deliberately separate
 * from the API's `/api/v1/*` Sanctum bearer-token surface used by the
 * Flutter app — a distinct `web` prefix here never collides with the
 * existing `/api/v1/admin/*` routes. Business Owners never reach any
 * route in this group (mobile-only, per approved decision); every
 * protected route below is gated on the same `platform-admin-only` Gate
 * the API already uses.
 */
Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('/login', [AdminAuthController::class, 'show'])->name('login');
        Route::post('/login', [AdminAuthController::class, 'login'])->middleware('throttle:login');
    });

    Route::middleware(['auth', 'can:platform-admin-only'])->group(function () {
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

        Route::get('/dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');

        Route::get('/businesses', [AdminTenantController::class, 'index'])->name('businesses.index');
        Route::get('/businesses/{tenant}', [AdminTenantController::class, 'show'])->name('businesses.show');
        Route::post('/businesses/{tenant}/suspend', [AdminTenantController::class, 'suspend'])->name('businesses.suspend');
        Route::post('/businesses/{tenant}/activate', [AdminTenantController::class, 'activate'])->name('businesses.activate');

        Route::get('/recovery-debts', [AdminDebtController::class, 'index'])->name('recovery-debts.index');
        Route::get('/recovery-debts/{debt}', [AdminDebtController::class, 'show'])->name('recovery-debts.show');

        Route::get('/debtors', [AdminCustomerController::class, 'index'])->name('debtors.index');
        Route::get('/debtors/{customer}', [AdminCustomerController::class, 'show'])->name('debtors.show');

        Route::get('/payments', [AdminPaymentController::class, 'index'])->name('payments.index');
        Route::get('/payments/{payment}', [AdminPaymentController::class, 'show'])->name('payments.show');

        Route::get('/subscriptions', [AdminSubscriptionController::class, 'index'])->name('subscriptions.index');
        Route::get('/subscriptions/{tenant}', [AdminSubscriptionController::class, 'show'])->name('subscriptions.show');
        Route::post('/subscriptions/change-requests/{subscriptionChangeRequest}/approve', [AdminSubscriptionController::class, 'approveChangeRequest'])->name('subscriptions.change-requests.approve');
        Route::post('/subscriptions/change-requests/{subscriptionChangeRequest}/reject', [AdminSubscriptionController::class, 'rejectChangeRequest'])->name('subscriptions.change-requests.reject');
        Route::post('/subscriptions/storage-addons/{storageAddon}/approve', [AdminSubscriptionController::class, 'approveStorageAddon'])->name('subscriptions.storage-addons.approve');
        Route::post('/subscriptions/storage-addons/{storageAddon}/reject', [AdminSubscriptionController::class, 'rejectStorageAddon'])->name('subscriptions.storage-addons.reject');

        Route::get('/professional-collection', [AdminProfessionalCollectionController::class, 'index'])->name('professional-collection.index');
        Route::get('/professional-collection/{professionalCollectionRequest}', [AdminProfessionalCollectionController::class, 'show'])->name('professional-collection.show');
        Route::post('/professional-collection/{professionalCollectionRequest}/status', [AdminProfessionalCollectionController::class, 'transitionStatus'])->name('professional-collection.status');
        Route::post('/professional-collection/{professionalCollectionRequest}/close', [AdminProfessionalCollectionController::class, 'close'])->name('professional-collection.close');
        Route::post('/professional-collection/{professionalCollectionRequest}/messages', [AdminProfessionalCollectionController::class, 'postMessage'])->name('professional-collection.messages');
        Route::post('/professional-collection/{professionalCollectionRequest}/attachments', [AdminProfessionalCollectionController::class, 'uploadAttachment'])->name('professional-collection.attachments.store');
        Route::get('/professional-collection/{professionalCollectionRequest}/attachments/{attachment}/download', [AdminProfessionalCollectionController::class, 'downloadAttachment'])->name('professional-collection.attachments.download');
        Route::post('/professional-collection/{professionalCollectionRequest}/timeline', [AdminProfessionalCollectionController::class, 'recordTimelineEvent'])->name('professional-collection.timeline');
        Route::get('/professional-collection/{professionalCollectionRequest}/documents/{documentType}/{documentId}/download', [AdminProfessionalCollectionController::class, 'downloadDocument'])->name('professional-collection.documents.download');

        Route::prefix('reports-analytics')->name('reports.')->group(function () {
            Route::get('/', [AdminReportController::class, 'overview'])->name('overview');
            Route::get('/debt-recovery', [AdminReportController::class, 'debtRecovery'])->name('debt-recovery');
            Route::get('/debtor-risk', [AdminReportController::class, 'debtorRisk'])->name('debtor-risk');
            Route::get('/payments', [AdminReportController::class, 'payments'])->name('payments');
            Route::get('/professional-collection', [AdminReportController::class, 'professionalCollection'])->name('professional-collection');
            Route::get('/subscriptions', [AdminReportController::class, 'subscriptions'])->name('subscriptions');
            Route::get('/business-growth', [AdminReportController::class, 'businessGrowth'])->name('business-growth');

            Route::get('/{report}/export/{format}', [AdminReportController::class, 'export'])
                ->whereIn('report', ['debt-recovery', 'debtor-risk', 'payments', 'professional-collection', 'subscriptions', 'business-growth'])
                ->whereIn('format', ['pdf', 'excel', 'csv'])
                ->name('export');
            Route::get('/{report}/print', [AdminReportController::class, 'print'])
                ->whereIn('report', ['debt-recovery', 'debtor-risk', 'payments', 'professional-collection', 'subscriptions', 'business-growth'])
                ->name('print');
        });

        Route::prefix('support-tickets')->name('support-tickets.')->group(function () {
            Route::get('/', [AdminSupportTicketController::class, 'index'])->name('index');
            Route::get('/{supportTicket}', [AdminSupportTicketController::class, 'show'])->name('show');
            Route::post('/{supportTicket}/status', [AdminSupportTicketController::class, 'transitionStatus'])->name('status');
            Route::post('/{supportTicket}/close', [AdminSupportTicketController::class, 'close'])->name('close');
            Route::post('/{supportTicket}/reopen', [AdminSupportTicketController::class, 'reopen'])->name('reopen');
            Route::post('/{supportTicket}/messages', [AdminSupportTicketController::class, 'postMessage'])->name('messages');
            Route::post('/{supportTicket}/attachments', [AdminSupportTicketController::class, 'uploadAttachment'])->name('attachments.store');
            Route::get('/{supportTicket}/attachments/{attachment}/download', [AdminSupportTicketController::class, 'downloadAttachment'])->name('attachments.download');
        });

        Route::prefix('system')->name('system.')->group(function () {
            Route::get('/', [AdminSystemController::class, 'health'])->name('health');
            Route::get('/platform-administrators', [AdminSystemController::class, 'platformAdministrators'])->name('platform-administrators');
            Route::get('/security-events', [AdminSystemController::class, 'securityEvents'])->name('security-events');
            Route::get('/backup', [AdminSystemController::class, 'backup'])->name('backup');
            Route::post('/backup', [AdminSystemController::class, 'createBackup'])->name('backup.create');
            Route::get('/scheduler', [AdminSystemController::class, 'scheduler'])->name('scheduler');
        });

        Route::prefix('notifications')->name('notifications.')->group(function () {
            Route::get('/', [AdminNotificationController::class, 'index'])->name('index');
            Route::post('/', [AdminNotificationController::class, 'store'])->name('store');
            Route::get('/history', [AdminNotificationController::class, 'history'])->name('history');
        });

        Route::get('/audit-logs', [AdminAuditLogController::class, 'index'])->name('audit-logs.index');

        Route::prefix('settings')->name('settings.')->group(function () {
            Route::get('/', [AdminSettingsController::class, 'index'])->name('index');
            Route::get('/create', [AdminSettingsController::class, 'create'])->name('create');
            Route::post('/', [AdminSettingsController::class, 'store'])->name('store');
            Route::get('/{subscriptionPlan}/edit', [AdminSettingsController::class, 'edit'])->name('edit');
            Route::put('/{subscriptionPlan}', [AdminSettingsController::class, 'update'])->name('update');
            Route::post('/{subscriptionPlan}/activate', [AdminSettingsController::class, 'activate'])->name('activate');
            Route::post('/{subscriptionPlan}/deactivate', [AdminSettingsController::class, 'deactivate'])->name('deactivate');
        });
    });
});
