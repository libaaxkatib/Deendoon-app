<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\CollectionCase;
use App\Models\ProfessionalCollectionRequest;
use App\Models\RequestMessage;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
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
    ) {}

    /**
     * BRL-078: a Collection Case may be submitted only while Open and with
     * no other active Request already pending — enforced first here, then
     * again by the database's partial unique index as the fail-safe.
     */
    public function submit(CollectionCase $case, User $actor): ProfessionalCollectionRequest
    {
        if ($case->case_status !== 'open') {
            $this->conflict('Only an open Collection Case may be submitted to Deendoon.');
        }

        if ($case->professionalCollectionRequests()->whereNotIn('status', self::TERMINAL_STATUSES)->exists()) {
            $this->conflict('This Collection Case already has an active Professional Collection Request.');
        }

        return DB::transaction(function () use ($case, $actor) {
            $referenceNumber = $this->referenceNumbers->next('professional_collection_requests', $case->tenant_id, 'PCR');

            $request = new ProfessionalCollectionRequest([
                'collection_case_id' => $case->id,
                'reference_number' => $referenceNumber,
                'status' => 'submitted',
            ]);
            $request->tenant_id = $case->tenant_id;
            $request->submitted_by_user_id = $actor->id;
            $request->save();

            $this->auditLog->record(
                AuditAction::ProfessionalCollectionRequestSubmitted,
                'professional_collection_request',
                $request->id,
                $actor,
                null,
                $case->tenant_id,
            );

            return $request->refresh();
        });
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
    }

    /**
     * BRL-080: either party may post at any time "while the Request is
     * active (Submitted through In Progress)." Whether messaging remains
     * available after a terminal outcome is explicitly unresolved
     * (DD-044) — the more literal, restrictive reading (rejected once
     * terminal) is applied rather than assuming continued access.
     */
    public function postMessage(ProfessionalCollectionRequest $request, string $content, User $actor): RequestMessage
    {
        if (in_array($request->status, self::TERMINAL_STATUSES, true)) {
            $this->conflict('This Professional Collection Request is closed; new messages are not accepted.');
        }

        return $request->messages()->create([
            'sender_user_id' => $actor->id,
            'content' => $content,
        ])->refresh();
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
