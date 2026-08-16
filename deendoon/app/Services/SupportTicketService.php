<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\NotificationType;
use App\Models\SupportTicket;
use App\Models\SupportTicketAttachment;
use App\Models\SupportTicketMessage;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * Module 7 — Support & Tickets (Product Owner-approved V1). Mirrors
 * ProfessionalCollectionRequestService's shape closely — the closest
 * existing precedent for a bimodal (tenant + Platform Administrator),
 * conversation + attachment-bearing entity with a linear status workflow.
 *
 * Status workflow (Decision 4): Open -> In Progress -> Resolved is a
 * strict linear sequence (no skipping, matching
 * ProfessionalCollectionRequestService::NON_TERMINAL_TRANSITIONS'
 * precedent exactly); Close is reachable from any non-closed status
 * (Decision 9 states no precondition, matching
 * ProfessionalCollectionRequestService::close()'s "callable from any
 * active status" precedent); Reopen is reachable only from Closed
 * (Decision 4: "Closed -> Open").
 */
class SupportTicketService
{
    private const NON_TERMINAL_TRANSITIONS = [
        'open' => ['in_progress'],
        'in_progress' => ['resolved'],
        'resolved' => [],
    ];

    public function __construct(
        private readonly ReferenceNumberService $referenceNumbers,
        private readonly AuditLogService $auditLog,
        private readonly NotificationService $notifications,
        private readonly DocumentService $documents,
    ) {}

    /**
     * @param  array{subject: string, description: string, priority: string, category: string}  $data
     */
    public function create(array $data, User $actor): SupportTicket
    {
        return DB::transaction(function () use ($data, $actor) {
            $referenceNumber = $this->referenceNumbers->next('support_tickets', $actor->tenant_id, 'SUP');

            $ticket = new SupportTicket([
                'subject' => $data['subject'],
                'description' => $data['description'],
                'status' => 'open',
                'priority' => $data['priority'],
                'category' => $data['category'],
                'reference_number' => $referenceNumber,
            ]);
            $ticket->tenant_id = $actor->tenant_id;
            $ticket->submitted_by_user_id = $actor->id;
            $ticket->save();

            $this->auditLog->record(AuditAction::Created, 'support_ticket', $ticket->id, $actor, null, $actor->tenant_id);

            $this->notifications->notify($actor->tenant_id, (string) $actor->id, NotificationType::SupportTicketCreated, 'support_ticket', $ticket->id);

            return $ticket->refresh();
        });
    }

    /**
     * Either party may post while the ticket is not closed. When the
     * Platform Administrator replies, the submitting Business Owner is
     * notified; when the Business Owner replies, no notification fires —
     * they already know they just sent it, and the Platform Administrator
     * has no in-app notification channel (notifications.tenant_id is NOT
     * NULL — the same schema constraint documented on
     * ProfessionalCollectionRequestService::postMessage()).
     */
    public function reply(SupportTicket $ticket, string $content, User $actor): SupportTicketMessage
    {
        if ($ticket->status === 'closed') {
            $this->conflict('This ticket is closed; new replies are not accepted. Reopen it first.');
        }

        $message = $ticket->messages()->create([
            'sender_user_id' => $actor->id,
            'content' => $content,
        ])->refresh();

        $this->auditLog->record(AuditAction::Created, 'support_ticket', $ticket->id, $actor, 'Reply posted', $ticket->tenant_id);

        if ((string) $actor->id !== (string) $ticket->submitted_by_user_id) {
            $this->notifications->notify($ticket->tenant_id, $ticket->submitted_by_user_id, NotificationType::SupportTicketReplied, 'support_ticket', $ticket->id);
        }

        return $message;
    }

    public function transitionStatus(SupportTicket $ticket, string $newStatus, User $actor): void
    {
        if ($newStatus === 'closed') {
            $this->conflict('Use the close action to close a ticket.');
        }

        $allowed = self::NON_TERMINAL_TRANSITIONS[$ticket->status] ?? [];

        if (! in_array($newStatus, $allowed, true)) {
            $this->conflict("Cannot transition from '{$ticket->status}' to '{$newStatus}'.");
        }

        $ticket->update(['status' => $newStatus]);

        $this->auditLog->record(AuditAction::StatusChanged, 'support_ticket', $ticket->id, $actor, null, $ticket->tenant_id);

        $this->notifications->notify($ticket->tenant_id, $ticket->submitted_by_user_id, NotificationType::SupportTicketStatusChanged, 'support_ticket', $ticket->id);
    }

    public function close(SupportTicket $ticket, User $actor): void
    {
        if ($ticket->status === 'closed') {
            $this->conflict('This ticket is already closed.');
        }

        $ticket->update(['status' => 'closed', 'closed_at' => now()]);

        $this->auditLog->record(AuditAction::StatusChanged, 'support_ticket', $ticket->id, $actor, 'Closed', $ticket->tenant_id);

        $this->notifications->notify($ticket->tenant_id, $ticket->submitted_by_user_id, NotificationType::SupportTicketClosed, 'support_ticket', $ticket->id);
    }

    public function reopen(SupportTicket $ticket, User $actor): void
    {
        if ($ticket->status !== 'closed') {
            $this->conflict('Only a closed ticket can be reopened.');
        }

        $ticket->update(['status' => 'open', 'closed_at' => null, 'reopened_at' => now()]);

        $this->auditLog->record(AuditAction::StatusChanged, 'support_ticket', $ticket->id, $actor, 'Reopened', $ticket->tenant_id);

        $this->notifications->notify($ticket->tenant_id, $ticket->submitted_by_user_id, NotificationType::SupportTicketReopened, 'support_ticket', $ticket->id);
    }

    /**
     * Reuses DocumentService's existing storage-quota enforcement, exactly
     * like ProfessionalCollectionRequestService::uploadAttachment(). The
     * terminal-state guard mirrors that method's own reasoning: a closed
     * ticket's evidence stays immutable until it is reopened.
     */
    public function uploadAttachment(SupportTicket $ticket, UploadedFile $file, User $actor): SupportTicketAttachment
    {
        if ($ticket->status === 'closed') {
            $this->conflict('This ticket is closed; attachments are now read-only. Reopen it first.');
        }

        $tenant = Tenant::findOrFail($ticket->tenant_id);

        return DB::transaction(function () use ($ticket, $file, $actor, $tenant) {
            $stored = $this->documents->storeUploadedFile($file, $tenant, 'support_tickets');

            $attachment = $ticket->attachments()->create([
                'uploaded_by_user_id' => $actor->id,
                'file_path' => $stored['path'],
                'original_filename' => $stored['original_filename'],
                'mime_type' => $stored['mime_type'],
                'file_size' => $stored['size'],
            ]);

            $this->auditLog->record(AuditAction::Created, 'support_ticket_attachment', $attachment->id, $actor, "Attachment uploaded: {$stored['original_filename']}", $ticket->tenant_id);

            return $attachment;
        });
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
