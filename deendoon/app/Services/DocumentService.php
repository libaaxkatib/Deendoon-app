<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\DemandLetterTemplate;
use App\Enums\DocumentEventType;
use App\Enums\DocumentType;
use App\Enums\NotificationType;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\DocumentEvent;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Throwable;

/**
 * FR-047/048/049 — Module 8 is the sole owner of document generation.
 * Reuses ReferenceNumberService (RCT-/DL-/ST- numbering, BRL-053) and
 * AuditLogService exactly as built for every other module. Branding
 * (BRL-054) uses tenants.business_name/logo_path/address/contact_* —
 * these ARE the approved FR-068 Company Profile fields, folded into the
 * tenants table per 06_Database_Design.md §3 — so this reads whatever is
 * currently on the tenant row directly, now administratively editable via
 * Module 12 (AdminSettingsController). Demand Letter body text (FR-069's
 * "Document Templates") is likewise read from AdminSettingsService at
 * generation time, falling back to the original placeholder wording for
 * any tenant that has not customized a given template.
 *
 * Also creates a "Document Available" Notification (FR-058, Module 10) on
 * every generation — synchronously, in the same call, via
 * NotificationService.
 *
 * Storage: S3-compatible object storage is the approved architecture
 * (09_Non_Functional_Requirements.md), with tenant-scoped key prefixing
 * (08 §11). No real S3-compatible provider is configured in this
 * environment, so the 'local' disk is used via Laravel's Storage facade
 * — the same abstraction that already targets 's3' in config/filesystems.php
 * — keeping the code disk-agnostic; switching disks is a config change,
 * not a code change.
 */
class DocumentService
{
    private const DISK = 'local';

    public function __construct(
        private readonly ReferenceNumberService $referenceNumbers,
        private readonly AuditLogService $auditLog,
        private readonly NotificationService $notifications,
        private readonly AdminSettingsService $settings,
    ) {}

    /**
     * FR-047: automatic, system-initiated only (BR-019) — the audit event
     * is attributed to "System" (no actor), matching FR-047 step 4's
     * literal text, and matching 06 §6.6's note that the Receipt's
     * `generated` DocumentEvent has a NULL user_id. E1: a generation
     * failure must never roll back Payment Recording — caught here and
     * logged, never rethrown, so PaymentService's transaction always
     * commits regardless of PDF/storage outcome. Returns null on failure;
     * callers must not depend on a Receipt always existing.
     */
    public function generateReceipt(Payment $payment): ?Receipt
    {
        try {
            $debt = $payment->debt;
            $customer = $debt->customer;
            $tenantId = $debt->tenant_id;
            $referenceNumber = $this->referenceNumbers->next('receipts', $tenantId, 'RCT');

            $receipt = new Receipt([
                'payment_id' => $payment->id,
                'reference_number' => $referenceNumber,
                'generated_at' => now(),
            ]);
            $rendered = $this->render('documents.receipt', [
                'tenant' => $debt->tenant,
                'receipt' => $receipt,
                'payment' => $payment,
                'debt' => $debt,
                'customer' => $customer,
            ], $tenantId, 'receipts', $referenceNumber);
            $receipt->file_path = $rendered['path'];
            $receipt->file_size = $rendered['size'];
            $receipt->save();

            $this->auditLog->record(AuditAction::ReceiptGenerated, 'payment', $payment->id, null, null, $tenantId);
            $this->recordEvent(DocumentType::Receipt, $receipt->id, DocumentEventType::Generated, null, $tenantId);

            // FR-058: no acting user exists for this automatic generation
            // (FR-047: "System"-initiated only). recorded_by_user_id — the
            // real, already-known user who recorded the underlying Payment
            // — is the most relevant recipient available, not an invented
            // one.
            $this->notifications->notify($tenantId, $payment->recorded_by_user_id, NotificationType::DocumentAvailable, 'receipt', $receipt->id);

            return $receipt->refresh();
        } catch (Throwable $e) {
            Log::error('Receipt generation failed', ['payment_id' => $payment->id, 'exception' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * FR-048/BRL-055: template is always explicitly selected by the caller
     * — no auto-selection exists. BRL-054: branding read at generation
     * time only.
     */
    public function generateDemandLetter(Debt $debt, DemandLetterTemplate $template, User $actor): DemandLetter
    {
        $customer = $debt->customer;
        $tenantId = $debt->tenant_id;
        $referenceNumber = $this->referenceNumbers->next('demand_letters', $tenantId, 'DL');

        $demandLetter = new DemandLetter([
            'debt_id' => $debt->id,
            'template_type' => $template->value,
            'reference_number' => $referenceNumber,
            'generated_at' => now(),
        ]);
        $rendered = $this->render('documents.demand-letter', [
            'tenant' => $debt->tenant,
            'demandLetter' => $demandLetter,
            'templateLabel' => $template->label(),
            'bodyText' => $this->settings->templateContent($tenantId, $template),
            'debt' => $debt,
            'customer' => $customer,
        ], $tenantId, 'demand_letters', $referenceNumber);
        $demandLetter->file_path = $rendered['path'];
        $demandLetter->file_size = $rendered['size'];
        $demandLetter->save();

        $this->auditLog->record(AuditAction::DemandLetterGenerated, 'debt', $debt->id, $actor, null, $tenantId);
        $this->recordEvent(DocumentType::DemandLetter, $demandLetter->id, DocumentEventType::Generated, $actor, $tenantId);

        $this->notifications->notify($tenantId, (string) $actor->id, NotificationType::DocumentAvailable, 'demand_letter', $demandLetter->id);

        return $demandLetter->refresh();
    }

    /**
     * Sprint 4.1. Manual generation only — Business Rule: "Invoice
     * generation is a manual business action. Do NOT generate invoices
     * automatically." Mirrors generateDemandLetter() exactly; no template
     * choice, since no approved document describes multiple Invoice
     * templates.
     */
    public function generateInvoice(Debt $debt, User $actor): Invoice
    {
        $tenantId = $debt->tenant_id;
        $referenceNumber = $this->referenceNumbers->next('invoices', $tenantId, 'INV');

        $invoice = new Invoice([
            'debt_id' => $debt->id,
            'reference_number' => $referenceNumber,
            'generated_at' => now(),
        ]);
        $rendered = $this->render('documents.invoice', [
            'tenant' => $debt->tenant,
            'invoice' => $invoice,
            'debt' => $debt,
            'customer' => $debt->customer,
        ], $tenantId, 'invoices', $referenceNumber);
        $invoice->file_path = $rendered['path'];
        $invoice->file_size = $rendered['size'];
        $invoice->save();

        $this->auditLog->record(AuditAction::InvoiceGenerated, 'debt', $debt->id, $actor, null, $tenantId);
        $this->recordEvent(DocumentType::Invoice, $invoice->id, DocumentEventType::Generated, $actor, $tenantId);

        $this->notifications->notify($tenantId, (string) $actor->id, NotificationType::DocumentAvailable, 'invoice', $invoice->id);

        return $invoice->refresh();
    }

    /**
     * FR-049: always consolidates the Customer's full debt and payment
     * history — the Main Flow describes no single-debt variant. $debt is
     * traceability metadata only, recorded when triggered from Debt
     * Details (FR-049 A1's scope question is unresolved; the more literal
     * reading — full account — is applied rather than inventing a
     * single-debt filter).
     */
    public function generateStatement(Customer $customer, ?Debt $debt, User $actor): Statement
    {
        $tenantId = $customer->tenant_id;
        $referenceNumber = $this->referenceNumbers->next('statements', $tenantId, 'ST');

        $statement = new Statement([
            'customer_id' => $customer->id,
            'debt_id' => $debt?->id,
            'reference_number' => $referenceNumber,
            'generated_at' => now(),
        ]);
        $rendered = $this->render('documents.statement', [
            'tenant' => $customer->tenant,
            'statement' => $statement,
            'customer' => $customer,
            'debts' => $customer->debts()->withTrashed()->get(),
            'payments' => $customer->payments()->with('debt')->get(),
        ], $tenantId, 'statements', $referenceNumber);
        $statement->file_path = $rendered['path'];
        $statement->file_size = $rendered['size'];
        $statement->save();

        $this->auditLog->record(AuditAction::StatementGenerated, 'customer', $customer->id, $actor, null, $tenantId);
        $this->recordEvent(DocumentType::Statement, $statement->id, DocumentEventType::Generated, $actor, $tenantId);

        $this->notifications->notify($tenantId, (string) $actor->id, NotificationType::DocumentAvailable, 'statement', $statement->id);

        return $statement->refresh();
    }

    /**
     * FR-051/FR-052: downloading is a DocumentEvent only — no audit_log
     * entry, matching FR-050/051's text (unlike FR-047/048/049, neither
     * mentions "records an event in the Audit Trail").
     */
    public function recordDownload(DocumentType $type, string $documentId, string $tenantId, User $actor): void
    {
        $this->recordEvent($type, $documentId, DocumentEventType::Downloaded, $actor, $tenantId);
    }

    private function recordEvent(DocumentType $type, string $documentId, DocumentEventType $eventType, ?User $actor, string $tenantId): DocumentEvent
    {
        return DocumentEvent::create([
            'tenant_id' => $tenantId,
            'document_type' => $type->value,
            'document_id' => $documentId,
            'event_type' => $eventType->value,
            'user_id' => $actor?->id,
            'occurred_at' => now(),
        ]);
    }

    /**
     * @return array{path: string, size: int}
     */
    private function render(string $view, array $data, string $tenantId, string $folder, string $referenceNumber): array
    {
        $pdf = Pdf::loadView($view, $data);
        $output = $pdf->output();
        $path = "documents/{$tenantId}/{$folder}/{$referenceNumber}.pdf";
        Storage::disk(self::DISK)->put($path, $output);

        return ['path' => $path, 'size' => strlen($output)];
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.1 Storage Usage. Computed live from
     * each document table's file_size, per docs/Backend_v2.1_Database_Alignment.md
     * §11's own conclusion that this may be "computed live or maintained
     * incrementally — an implementation choice, not a UI requirement."
     * The quota itself is not defined by any approved document; a
     * conservative, operator-configurable default is used rather than an
     * invented fixed business rule.
     *
     * @return array{used_bytes: int, total_bytes: int, used_percentage: float}
     */
    public function storageUsage(string $tenantId): array
    {
        $usedBytes = (int) Receipt::where('tenant_id', $tenantId)->sum('file_size')
            + (int) DemandLetter::where('tenant_id', $tenantId)->sum('file_size')
            + (int) Statement::where('tenant_id', $tenantId)->sum('file_size');

        $totalBytes = (int) env('DOCUMENT_STORAGE_QUOTA_BYTES', 10 * 1024 * 1024 * 1024);

        return [
            'used_bytes' => $usedBytes,
            'total_bytes' => $totalBytes,
            'used_percentage' => $totalBytes > 0 ? round(($usedBytes / $totalBytes) * 100, 2) : 0.0,
        ];
    }
}
