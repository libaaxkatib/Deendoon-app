<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\DocumentType;
use App\Enums\NotificationType;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\ProfessionalCollectionRequest;
use App\Models\ProfessionalCollectionRequestAttachment;
use App\Models\ProfessionalCollectionTimelineEvent;
use App\Models\Receipt;
use App\Models\RequestMessage;
use App\Models\Statement;
use App\Models\Tenant;
use App\Models\User;
use App\Policies\ProfessionalCollectionRequestPolicy;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * FR-072–076 — the tenant hand-off of a Collection Case to the Deendoon
 * Platform Administrator. Reuses ReferenceNumberService (PCR- numbering,
 * DD-045 proposed-but-unconfirmed format — same posture already applied
 * to BRL-031's Recovery Stage table under DD-012) and AuditLogService
 * exactly as built for every other module.
 *
 * BRL-079 gives a named linear sequence plus one explicit cycle
 * (Need More Information ⇄ Under Review), but explicitly leaves the full
 * transition matrix beyond that unresolved (DD-043). This service
 * implements exactly the named sequence/cycle, rejecting (409) anything
 * else — the same "implement what's resolved, defer the rest, don't
 * invent" posture used throughout this project.
 */
class ProfessionalCollectionRequestService
{
    private const NON_TERMINAL_TRANSITIONS = [
        'submitted' => ['under_review'],
        'under_review' => ['need_more_information', 'accepted'],
        'need_more_information' => ['under_review'],
        'accepted' => ['assigned'],
        'assigned' => ['in_progress'],
        'in_progress' => [],
    ];

    private const TERMINAL_STATUSES = ['recovered', 'closed'];

    public function __construct(
        private readonly ReferenceNumberService $referenceNumbers,
        private readonly AuditLogService $auditLog,
        private readonly NotificationService $notifications,
        private readonly RiskLevelService $riskLevel,
        private readonly CreditScoreService $creditScore,
        private readonly DocumentService $documents,
    ) {}

    /**
     * BRL-078: a Collection Case may be submitted only while Open and with
     * no other active Request already pending — enforced first here, then
     * again by the database's partial unique index as the fail-safe.
     *
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): `$data` carries the multi-select Reason(s) for Transfer
     * and Requested Service(s) — both already validated against the
     * tenant's active Reference Data by
     * SubmitProfessionalCollectionRequestRequest, so this method only
     * persists them — plus optional free-text notes and the Client
     * Declaration acceptance (also already gated to `true` by that same
     * request; this method only stamps who/when). All existing Customer/
     * Debt documents (Receipt/DemandLetter/Statement/Invoice) already
     * stored for this Case's Debt are linked by reference automatically —
     * never selected manually, never duplicated.
     *
     * @param  array{reasons: array<int, string>, notes: ?string, services: array<int, string>}  $data
     */
    public function submit(CollectionCase $case, array $data, User $actor): ProfessionalCollectionRequest
    {
        if ($case->case_status !== 'open') {
            $this->conflict('Only an open Collection Case may be submitted to Deendoon.');
        }

        if ($case->professionalCollectionRequests()->whereNotIn('status', self::TERMINAL_STATUSES)->exists()) {
            $this->conflict('This Collection Case already has an active Professional Collection Request.');
        }

        return DB::transaction(function () use ($case, $data, $actor) {
            $referenceNumber = $this->referenceNumbers->next('professional_collection_requests', $case->tenant_id, 'PCR');

            $request = new ProfessionalCollectionRequest([
                'collection_case_id' => $case->id,
                'reference_number' => $referenceNumber,
                'status' => 'submitted',
                'transfer_notes' => $data['notes'] ?? null,
            ]);
            $request->tenant_id = $case->tenant_id;
            $request->submitted_by_user_id = $actor->id;
            $request->declaration_accepted_at = now();
            $request->declaration_accepted_by_user_id = $actor->id;
            $request->save();

            foreach (array_unique($data['reasons']) as $reason) {
                $request->reasons()->create(['reason_label' => $reason]);
            }

            foreach (array_unique($data['services']) as $service) {
                $request->requestedServices()->create(['service_label' => $service]);
            }

            $this->linkExistingDocuments($request, $case->debt);

            $this->auditLog->record(
                AuditAction::ProfessionalCollectionRequestSubmitted,
                'professional_collection_request',
                $request->id,
                $actor,
                null,
                $case->tenant_id,
            );

            // Risk Level Engine (Sprint 2B): Professional Collection
            // Request Submitted.
            $this->riskLevel->recalculate($case->debt->customer);
            // Credit Score (FR-026, Business Owner Backend Completion):
            // always recalculated at the exact same trigger points as Risk
            // Level.
            $this->creditScore->recalculate($case->debt->customer);

            return $request->refresh();
        });
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): "automatically include all existing Customer/Debt
     * documents already stored... Existing documents must be linked by
     * reference. Do NOT duplicate files already stored." Reuses the exact
     * same four queries DocumentController::forDebt() already runs — this
     * Case's one Debt (BRL-078/FR-072's one-Debt-per-Case cardinality) —
     * rather than a new document catalog. No storage-quota interaction:
     * these are references to already-counted files, not new bytes.
     */
    private function linkExistingDocuments(ProfessionalCollectionRequest $request, Debt $debt): void
    {
        $receiptIds = Receipt::whereHas('payment', fn ($q) => $q->where('debt_id', $debt->id))->pluck('id');
        $demandLetterIds = $debt->demandLetters()->pluck('id');
        $statementIds = $debt->statements()->pluck('id');
        $invoiceIds = $debt->invoices()->pluck('id');

        $links = [
            ...$receiptIds->map(fn (string $id) => [DocumentType::Receipt, $id]),
            ...$demandLetterIds->map(fn (string $id) => [DocumentType::DemandLetter, $id]),
            ...$statementIds->map(fn (string $id) => [DocumentType::Statement, $id]),
            ...$invoiceIds->map(fn (string $id) => [DocumentType::Invoice, $id]),
        ];

        foreach ($links as [$type, $documentId]) {
            $request->linkedDocuments()->create([
                'document_type' => $type->value,
                'document_id' => $documentId,
            ]);
        }
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision, refined by a follow-up clarification): "Allow uploading
     * Additional Supporting Documents that are specific to the
     * Professional Collection Request... Reuse the existing
     * DocumentService [and its] storage quota enforcement." WHO may call
     * this at the Pre-Assigned/Assigned stages is authorization, enforced
     * entirely by
     * {@see ProfessionalCollectionRequestPolicy::uploadAttachment()}.
     * The terminal-state block below is deliberately duplicated here as a
     * business-rule/data-integrity backstop, not authorization — "Evidence
     * must remain immutable after closure to preserve auditability and
     * legal integrity" is a property of the Request's data, true
     * regardless of which actor might call this method, matching the same
     * defense-in-depth pattern already used by postMessage()'s identical
     * terminal-state guard.
     */
    public function uploadAttachment(ProfessionalCollectionRequest $request, UploadedFile $file, User $actor, ?string $timelineEventId = null): ProfessionalCollectionRequestAttachment
    {
        if (in_array($request->status, self::TERMINAL_STATUSES, true)) {
            $this->conflict('This Professional Collection Request is closed; documents are now read-only.');
        }

        $tenant = Tenant::findOrFail($request->tenant_id);

        return DB::transaction(function () use ($request, $file, $actor, $timelineEventId, $tenant) {
            $stored = $this->documents->storeUploadedFile($file, $tenant, 'professional_collection_requests');

            $attachment = $request->attachments()->create([
                'timeline_event_id' => $timelineEventId,
                'uploaded_by_user_id' => $actor->id,
                'file_path' => $stored['path'],
                'original_filename' => $stored['original_filename'],
                'mime_type' => $stored['mime_type'],
                'file_size' => $stored['size'],
            ]);

            $this->auditLog->record(
                AuditAction::Created,
                'professional_collection_request_attachment',
                $attachment->id,
                $actor,
                "Attachment uploaded: {$stored['original_filename']}",
                $request->tenant_id,
            );

            return $attachment;
        });
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): "Reuse existing Professional Collection Request data. Do
     * not duplicate or denormalize data." Pure aggregation over the
     * tenant's existing rows — no new stored value. "Next Expected
     * Update" is not a value this system produces or stores anywhere (no
     * scheduling/prediction mechanism exists) — substituted here with the
     * most recent real Professional Collection Timeline event, the
     * closest genuine signal available, rather than fabricating a
     * forecast. Scoped to the acting tenant only — like Business Health,
     * there is no cross-tenant "summary" for the Deendoon Platform
     * Administrator to see (enforced by the controller's Gate, not here).
     *
     * @return array{counts_by_status: array<string, int>, total_active: int, total_recovered: int, latest_request: ?ProfessionalCollectionRequest, latest_timeline_event: ?ProfessionalCollectionTimelineEvent}
     */
    public function summary(string $tenantId): array
    {
        $statuses = ['submitted', 'under_review', 'need_more_information', 'accepted', 'assigned', 'in_progress', 'recovered', 'closed'];

        $countsByStatus = [];
        foreach ($statuses as $status) {
            $countsByStatus[$status] = ProfessionalCollectionRequest::where('tenant_id', $tenantId)->where('status', $status)->count();
        }

        $latestRequest = ProfessionalCollectionRequest::where('tenant_id', $tenantId)->orderByDesc('created_at')->first();

        $latestTimelineEvent = $latestRequest
            ? $latestRequest->timelineEvents()->orderByDesc('occurred_at')->first()
            : null;

        return [
            'counts_by_status' => $countsByStatus,
            'total_active' => array_sum(array_diff_key($countsByStatus, array_flip(self::TERMINAL_STATUSES))),
            'total_recovered' => $countsByStatus['recovered'],
            'latest_request' => $latestRequest,
            'latest_timeline_event' => $latestTimelineEvent,
        ];
    }

    public function transitionStatus(ProfessionalCollectionRequest $request, string $newStatus, User $actor): void
    {
        if (in_array($newStatus, self::TERMINAL_STATUSES, true)) {
            $this->conflict('Use the close endpoint to record a final outcome (Recovered/Closed).');
        }

        $allowed = self::NON_TERMINAL_TRANSITIONS[$request->status] ?? [];

        if (! in_array($newStatus, $allowed, true)) {
            $this->conflict("Cannot transition from '{$request->status}' to '{$newStatus}'.");
        }

        $request->update(['status' => $newStatus, 'actioned_by_user_id' => $actor->id]);

        $this->auditLog->record(
            AuditAction::ProfessionalCollectionRequestStatusChanged,
            'professional_collection_request',
            $request->id,
            $actor,
            null,
            $request->tenant_id,
        );

        $this->notifications->notify($request->tenant_id, $request->submitted_by_user_id, NotificationType::ProfessionalCollectionRequestUpdate, 'professional_collection_request', $request->id);
    }

    /**
     * FR-076: callable from any active (non-terminal) status — the
     * approved sequence names In Progress as the expected precursor but
     * does not forbid an earlier closure, and BRL-082 leaves any coupling
     * to the underlying Collection Case's own closure unresolved, so this
     * never touches the Collection Case.
     */
    public function close(ProfessionalCollectionRequest $request, string $outcome, User $actor): void
    {
        if (in_array($request->status, self::TERMINAL_STATUSES, true)) {
            $this->conflict('This Professional Collection Request is already closed.');
        }

        $request->update([
            'status' => $outcome,
            'actioned_by_user_id' => $actor->id,
            'closed_at' => now(),
        ]);

        $this->auditLog->record(
            AuditAction::ProfessionalCollectionRequestStatusChanged,
            'professional_collection_request',
            $request->id,
            $actor,
            'Terminal transition',
            $request->tenant_id,
        );

        // Risk Level Engine (Sprint 2B): Professional Collection Request
        // Successfully Completed — only a `recovered` outcome actually
        // contributes (Formula Spec §2.2); recalculate() no-ops for any
        // other terminal outcome since nothing scored changes. close() is
        // reachable by the Deendoon Platform Administrator (tenant_id
        // NULL), so the CollectionCase/Debt/Customer chain is looked up
        // bypassing BelongsToTenant's scope — same reasoning as
        // AuditLogService's explicit $tenantId override just above:
        // relation-lazy-loading would otherwise filter by the Platform
        // Administrator's own (null) tenant, not the Request's real one.
        if ($customer = $this->customerForRequest($request)) {
            $this->riskLevel->recalculate($customer);
            // Credit Score (FR-026, Business Owner Backend Completion):
            // always recalculated at the exact same trigger points as Risk
            // Level.
            $this->creditScore->recalculate($customer);
        }

        $this->notifications->notify($request->tenant_id, $request->submitted_by_user_id, NotificationType::ProfessionalCollectionRequestUpdate, 'professional_collection_request', $request->id);
    }

    /**
     * BRL-080: either party may post at any time "while the Request is
     * active (Submitted through In Progress)." Whether messaging remains
     * available after a terminal outcome is explicitly unresolved
     * (DD-044) — the more literal, restrictive reading (rejected once
     * terminal) is applied rather than assuming continued access.
     *
     * FR-075/FR-058: "notifies the other party of the new message."
     * `notifications.tenant_id` is NOT NULL, and the Deendoon Platform
     * Administrator has no tenant to attribute a notification to, so only
     * the tenant-facing direction is schema-valid: when the Platform
     * Administrator posts, the submitting tenant user is notified. When
     * the tenant posts, the reverse (notifying the Platform
     * Administrator) cannot be represented in this schema — flagged as a
     * NON-BLOCKING gap in the module report, not silently worked around.
     */
    public function postMessage(ProfessionalCollectionRequest $request, string $content, User $actor): RequestMessage
    {
        if (in_array($request->status, self::TERMINAL_STATUSES, true)) {
            $this->conflict('This Professional Collection Request is closed; new messages are not accepted.');
        }

        $message = $request->messages()->create([
            'sender_user_id' => $actor->id,
            'content' => $content,
        ])->refresh();

        $this->auditLog->record(
            AuditAction::Created,
            'professional_collection_request',
            $request->id,
            $actor,
            'Message posted',
            $request->tenant_id,
        );

        if ((string) $actor->id !== (string) $request->submitted_by_user_id) {
            $this->notifications->notify($request->tenant_id, $request->submitted_by_user_id, NotificationType::ProfessionalCollectionRequestUpdate, 'professional_collection_request', $request->id);
        }

        return $message;
    }

    private function customerForRequest(ProfessionalCollectionRequest $request): ?Customer
    {
        $case = CollectionCase::withoutGlobalScope('tenant')->find($request->collection_case_id);
        $debt = $case ? Debt::withoutGlobalScope('tenant')->find($case->debt_id) : null;

        return $debt ? Customer::withoutGlobalScope('tenant')->find($debt->customer_id) : null;
    }

    private function conflict(string $message): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => null,
        ], 409));
    }
}
