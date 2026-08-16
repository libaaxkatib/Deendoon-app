<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\CreateSupportTicketRequest;
use App\Http\Requests\ReplySupportTicketRequest;
use App\Http\Requests\TransitionSupportTicketStatusRequest;
use App\Http\Requests\UploadSupportTicketAttachmentRequest;
use App\Http\Resources\SupportTicketAttachmentResource;
use App\Http\Resources\SupportTicketMessageResource;
use App\Http\Resources\SupportTicketResource;
use App\Models\SupportTicket;
use App\Models\User;
use App\Policies\SupportTicketAttachmentPolicy;
use App\Policies\SupportTicketPolicy;
use App\Services\AuditLogService;
use App\Services\SupportTicketService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Module 7 — Support & Tickets, Business Owner-facing API. SupportTicket
 * deliberately has no BelongsToTenant scope (see the model's docblock), so
 * every lookup here resolves the row explicitly and applies the
 * tenant-vs-platform-admin masking rule by hand, matching
 * ProfessionalCollectionRequestController exactly: a tenant session gets
 * 404 for another tenant's ticket (never distinguished from "doesn't
 * exist"); the Deendoon Platform Administrator sees every ticket,
 * cross-tenant, by design (though in practice the Admin Panel — a
 * separate Blade surface — is how the Platform Administrator actually
 * manages tickets, not this JSON API).
 */
class SupportTicketController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly SupportTicketService $tickets,
        private readonly SupportTicketPolicy $policy,
        private readonly AuditLogService $auditLog,
    ) {}

    public function store(CreateSupportTicketRequest $request): JsonResponse
    {
        $this->authorize('create', SupportTicket::class);

        $ticket = $this->tickets->create([
            'subject' => $request->validated('subject'),
            'description' => $request->validated('description'),
            'priority' => $request->validated('priority'),
            'category' => $request->validated('category'),
        ], $request->user());

        return $this->successResponse(new SupportTicketResource($ticket), 'Ticket created successfully', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = $this->policy->isPlatformAdmin($user)
            ? SupportTicket::query()
            : SupportTicket::where('tenant_id', $user->tenant_id);

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('status', $status);
        }

        $tickets = $query->orderBy('created_at', 'desc')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'tickets' => SupportTicketResource::collection($tickets->items()),
            'pagination' => [
                'current_page' => $tickets->currentPage(),
                'per_page' => $tickets->perPage(),
                'total' => $tickets->total(),
                'last_page' => $tickets->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('view', $ticket);

        return $this->successResponse(new SupportTicketResource($ticket));
    }

    public function messagesIndex(Request $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('view', $ticket);

        return $this->successResponse(
            SupportTicketMessageResource::collection($ticket->messages()->with('sender:id,name')->orderBy('created_at')->get()),
        );
    }

    public function messagesStore(ReplySupportTicketRequest $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('reply', $ticket);

        $message = $this->tickets->reply($ticket, $request->validated('content'), $request->user());

        return $this->successResponse(new SupportTicketMessageResource($message), 'Reply posted successfully', 201);
    }

    public function updateStatus(TransitionSupportTicketStatusRequest $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('transitionStatus', SupportTicket::class);

        $this->tickets->transitionStatus($ticket, $request->validated('status'), $request->user());

        return $this->successResponse(new SupportTicketResource($ticket->fresh()), 'Ticket status updated successfully');
    }

    public function close(Request $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('close', SupportTicket::class);

        $this->tickets->close($ticket, $request->user());

        return $this->successResponse(new SupportTicketResource($ticket->fresh()), 'Ticket closed successfully');
    }

    public function reopen(Request $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('reopen', SupportTicket::class);

        $this->tickets->reopen($ticket, $request->user());

        return $this->successResponse(new SupportTicketResource($ticket->fresh()), 'Ticket reopened successfully');
    }

    public function attachmentsIndex(Request $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('view', $ticket);

        return $this->successResponse(
            SupportTicketAttachmentResource::collection($ticket->attachments()->orderBy('created_at')->get()),
        );
    }

    public function attachmentsStore(UploadSupportTicketAttachmentRequest $request, string $id): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('uploadAttachment', $ticket);

        $attachment = $this->tickets->uploadAttachment($ticket, $request->file('file'), $request->user());

        return $this->successResponse(new SupportTicketAttachmentResource($attachment), 'Attachment uploaded successfully', 201);
    }

    public function attachmentsDownload(Request $request, string $id, string $attachment): StreamedResponse
    {
        $ticket = $this->resolve($id, $request->user());

        $this->authorize('view', $ticket);

        $attachment = $ticket->attachments()->findOrFail($attachment);

        return Storage::disk('local')->download($attachment->file_path, $attachment->original_filename);
    }

    /**
     * Mobile Fix #4A (Attachment Delete): either the tenant's Business
     * Owner or the Deendoon Platform Administrator may delete an
     * attachment, but only the one who uploaded it, and never once the
     * Ticket is closed — see
     * {@see SupportTicketAttachmentPolicy}. DB row removed
     * first (inside the transaction, alongside the Audit Trail entry);
     * the file itself is deleted from disk only after that commits.
     */
    public function attachmentsDestroy(Request $request, string $id, string $attachment): JsonResponse
    {
        $ticket = $this->resolve($id, $request->user());
        $attachmentModel = $ticket->attachments()->findOrFail($attachment);

        $this->authorize('delete', $attachmentModel);

        DB::transaction(function () use ($request, $ticket, $attachmentModel) {
            $this->auditLog->record(
                AuditAction::Deleted,
                'support_ticket_attachment',
                $attachmentModel->id,
                $request->user(),
                null,
                $ticket->tenant_id,
            );

            $attachmentModel->delete();
        });

        Storage::disk('local')->delete($attachmentModel->file_path);

        return $this->successResponse(null, 'Attachment deleted successfully');
    }

    private function resolve(string $id, User $user): SupportTicket
    {
        $ticket = SupportTicket::findOrFail($id);

        if (! $this->policy->isPlatformAdmin($user) && $ticket->tenant_id !== $user->tenant_id) {
            abort(404);
        }

        return $ticket;
    }
}
