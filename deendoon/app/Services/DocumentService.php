<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\DemandLetterTemplate;
use App\Enums\DocumentEventType;
use App\Enums\DocumentType;
use App\Enums\NotificationType;
use App\Models\CollectionCaseAttachment;
use App\Models\Customer;
use App\Models\CustomerAttachment;
use App\Models\Debt;
use App\Models\DebtAttachment;
use App\Models\DemandLetter;
use App\Models\DocumentEvent;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequestAttachment;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\SupportTicketAttachment;
use App\Models\Tenant;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
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
        private readonly StorageAddonService $storageAddons,
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
            $this->renderAndSave($receipt, 'documents.receipt', [
                'tenant' => $debt->tenant,
                'receipt' => $receipt,
                'payment' => $payment,
                'debt' => $debt,
                'customer' => $customer,
            ], $tenantId, 'receipts', $referenceNumber);

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
        $this->renderAndSave($demandLetter, 'documents.demand-letter', [
            'tenant' => $debt->tenant,
            'demandLetter' => $demandLetter,
            'templateLabel' => $template->label(),
            'bodyText' => $this->settings->templateContent($tenantId, $template),
            'debt' => $debt,
            'customer' => $customer,
        ], $tenantId, 'demand_letters', $referenceNumber);

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
        $this->renderAndSave($invoice, 'documents.invoice', [
            'tenant' => $debt->tenant,
            'invoice' => $invoice,
            'debt' => $debt,
            'customer' => $debt->customer,
        ], $tenantId, 'invoices', $referenceNumber);

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
        $this->renderAndSave($statement, 'documents.statement', [
            'tenant' => $customer->tenant,
            'statement' => $statement,
            'customer' => $customer,
            'debts' => $customer->debts()->withTrashed()->get(),
            'payments' => $customer->payments()->with('debt')->get(),
        ], $tenantId, 'statements', $referenceNumber);

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
     * Backend Completion Roadmap (Phase 4.2, Product Owner-directed race
     * fix): wraps the storage-limit check, PDF render, and the model's
     * own save() inside one transaction. The lock
     * {@see lockAndGetEffectiveAllowanceBytes()} takes on the tenant's
     * row must be held from the check until the row's `file_size` is
     * durably saved — releasing it any earlier (e.g. if render() and
     * save() were left as two separate statements outside a shared
     * transaction, as they were before this fix) would let a second
     * concurrent request's own check run against a count that doesn't
     * yet reflect this one's still-uncommitted write, defeating the
     * lock entirely. `render()` remains the single hook shared by all 4
     * document types; this is the transaction boundary around it.
     */
    private function renderAndSave(Receipt|DemandLetter|Invoice|Statement $document, string $view, array $data, string $tenantId, string $folder, string $referenceNumber): void
    {
        DB::transaction(function () use ($document, $view, $data, $tenantId, $folder, $referenceNumber) {
            $rendered = $this->render($view, $data, $tenantId, $folder, $referenceNumber);
            $document->file_path = $rendered['path'];
            $document->file_size = $rendered['size'];
            $document->save();
        });
    }

    /**
     * @return array{path: string, size: int}
     */
    private function render(string $view, array $data, string $tenantId, string $folder, string $referenceNumber): array
    {
        // Backend Completion Roadmap (Phase 4.2, Storage Limit
        // Enforcement): checked once, before the (expensive) PDF render
        // + disk write, and shared by all 4 generate*() methods since
        // they all call this one private method. $data['tenant'] is
        // already present in every caller (needed for the view itself),
        // so this adds no extra query. Always called from inside
        // renderAndSave()'s transaction, so the lock this takes is held
        // for the correct duration.
        $this->assertCanUpload($data['tenant']);

        $pdf = Pdf::loadView($view, $data);
        $output = $pdf->output();
        $path = "documents/{$tenantId}/{$folder}/{$referenceNumber}.pdf";
        Storage::disk(self::DISK)->put($path, $output);

        return ['path' => $path, 'size' => strlen($output)];
    }

    /**
     * Backend Completion Roadmap (Phase 4.2, Storage Limit Enforcement).
     * "Before every upload: ... If Usage >= Allowance: Reject upload."
     * Checked literally as stated — usage vs. the tenant's current
     * allowance, not usage-plus-the-incoming-file's-own-size — so a
     * tenant one byte under their allowance is still let through even if
     * the resulting file would itself push them over (the next upload is
     * what then gets blocked), matching how Phase 4.1's Customer Limit
     * check works (`count() < limit`, not "would this row be the Nth").
     *
     * Race-safe (Product Owner-directed follow-up, mirroring Phase 4.1's
     * `CustomerReadOnlyService::assertCanCreateCustomer()` exactly):
     * {@see lockAndGetEffectiveAllowanceBytes()} takes a
     * `SELECT ... FOR UPDATE` lock on the tenant's own row before
     * resolving the allowance. On Postgres (production) this serializes
     * concurrent uploads for the same tenant — a second concurrent call
     * blocks until the first's enclosing transaction (see
     * {@see renderAndSave()} for document generation; the logo path is
     * wrapped by AdminSettingsController) commits, so the usage it then
     * reads already reflects the first upload's write. This method must
     * therefore only ever be called from inside an open transaction that
     * also performs the resulting write — calling it standalone would
     * still correctly reject an already-over-limit tenant, but would NOT
     * close the race for a tenant near the limit, since the lock would
     * be released the instant this method returns instead of being held
     * through the write. On SQLite (the test suite's driver)
     * `lockForUpdate()` compiles to no additional SQL — a correctness
     * no-op there, not a gap, since SQLite already serializes writers at
     * the database-file level and tests run single-threaded regardless
     * (same reasoning as Phase 4.1's identical SQLite note).
     *
     * Called from {@see render()} (Receipt/DemandLetter/Invoice/Statement
     * generation) and, directly, from AdminSettingsController for the
     * company logo upload — the only two file-write paths in this
     * backend, so this one method is upload enforcement's single source
     * of truth.
     */
    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): "Reuse the existing DocumentService... existing storage
     * quota enforcement." A third caller of assertCanUpload() alongside
     * document generation (render()) and the company logo upload — for an
     * arbitrary uploaded file (a Professional Collection Request
     * attachment) rather than a system-rendered PDF. Must be called from
     * inside the same transaction as the resulting database write,
     * exactly like renderAndSave() — the lock assertCanUpload() takes
     * must be held until that write durably lands.
     *
     * @return array{path: string, size: int, original_filename: string, mime_type: string}
     */
    public function storeUploadedFile(UploadedFile $file, Tenant $tenant, string $folder): array
    {
        $this->assertCanUpload($tenant);

        $extension = $file->getClientOriginalExtension();
        $filename = Str::ulid()->toString().($extension !== '' ? ".{$extension}" : '');
        $path = "documents/{$tenant->id}/{$folder}/{$filename}";

        Storage::disk(self::DISK)->put($path, file_get_contents($file->getRealPath()));

        return [
            'path' => $path,
            'size' => $file->getSize(),
            'original_filename' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType(),
        ];
    }

    public function assertCanUpload(Tenant $tenant): void
    {
        $allowanceBytes = $this->lockAndGetEffectiveAllowanceBytes($tenant);

        if ($this->storageUsage($tenant)['used_bytes'] >= $allowanceBytes) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'Storage limit reached. Please free up space or purchase additional storage before uploading.',
                'data' => null,
                'errors' => ['storage' => ['Storage limit reached.']],
            ], 422));
        }
    }

    /**
     * Locks the tenant's own row for the remainder of the caller's
     * transaction, then resolves its effective storage allowance in
     * bytes. Fails closed to 0 (see {@see assertCanUpload()}'s
     * docblock) — never null/unlimited, so the return type here is a
     * plain `int`, not `?int`.
     */
    private function lockAndGetEffectiveAllowanceBytes(Tenant $tenant): int
    {
        Tenant::where('id', $tenant->id)->lockForUpdate()->first();

        $allowanceGb = $this->storageAddons->totalStorageAllowance($tenant);

        return $allowanceGb === null ? 0 : $allowanceGb * 1024 ** 3;
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
     * Backend Completion Roadmap (Phase 4.2, Product Owner Decision):
     * `used_bytes` now also includes Invoice (previously omitted — a
     * pre-existing bug fixed as a prerequisite for correct Storage Limit
     * Enforcement, not new scope) and the tenant's company logo, read
     * directly off disk since there is no database column tracking its
     * size (no new column was added, per Product Owner instruction).
     * Transfer Case to Deendoon Recovery Team: also includes Professional
     * Collection Request attachments' file_size — the same single source
     * of truth used to enforce the quota those uploads go through
     * (storeUploadedFile()/assertCanUpload()), so usage accounting never
     * drifts from enforcement.
     * Final Product Completion Roadmap, P1.6: also includes Customer/
     * Debt/CollectionCase attachments' file_size, folded in the same way.
     * Module 7 (Support & Tickets): also includes Support Ticket
     * attachments' file_size, folded in the same way — the same single
     * source of truth used to enforce the quota those uploads go through
     * (SupportTicketService::uploadAttachment()).
     * `total_bytes`/`used_percentage` are deliberately left untouched —
     * still the pre-existing flat env-var quota, not
     * {@see StorageAddonService::totalStorageAllowance()} — since
     * changing that was not part of what was approved; see the Phase 4.2
     * report's Risks section.
     *
     * @return array{used_bytes: int, total_bytes: int, used_percentage: float}
     */
    public function storageUsage(Tenant $tenant): array
    {
        $usedBytes = (int) Receipt::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) DemandLetter::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) Statement::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) Invoice::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) ProfessionalCollectionRequestAttachment::whereHas(
                'request',
                fn ($q) => $q->where('tenant_id', $tenant->id),
            )->sum('file_size')
            + (int) CustomerAttachment::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) DebtAttachment::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) CollectionCaseAttachment::where('tenant_id', $tenant->id)->sum('file_size')
            + (int) SupportTicketAttachment::whereHas(
                'ticket',
                fn ($q) => $q->where('tenant_id', $tenant->id),
            )->sum('file_size')
            + $this->logoBytes($tenant);

        $totalBytes = (int) env('DOCUMENT_STORAGE_QUOTA_BYTES', 10 * 1024 * 1024 * 1024);

        return [
            'used_bytes' => $usedBytes,
            'total_bytes' => $totalBytes,
            'used_percentage' => $totalBytes > 0 ? round(($usedBytes / $totalBytes) * 100, 2) : 0.0,
        ];
    }

    /**
     * The company logo (AdminSettingsService::updateCompanyProfile()) has
     * no `file_size` column anywhere to sum, unlike the four generated
     * document tables — its size is read directly off the same `local`
     * disk it was written to. 0 when the tenant has no logo, or if the
     * path on `logo_path` no longer exists on disk.
     */
    private function logoBytes(Tenant $tenant): int
    {
        if ($tenant->logo_path === null) {
            return 0;
        }

        return Storage::disk(self::DISK)->exists($tenant->logo_path)
            ? Storage::disk(self::DISK)->size($tenant->logo_path)
            : 0;
    }
}
