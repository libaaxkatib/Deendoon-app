<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\ReplySupportTicketRequest;
use App\Http\Requests\TransitionSupportTicketStatusRequest;
use App\Http\Requests\UploadSupportTicketAttachmentRequest;
use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Services\SupportTicketService;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Admin Panel — Support & Tickets (Module 7, full operational workflow per
 * Decision 1). Every write here delegates to the existing, already-tested
 * {@see SupportTicketService} — the exact same methods the tenant-facing
 * API (`SupportTicketController`) already calls. Nothing here reimplements
 * the status-transition matrix, close/reopen rules, or reply/attachment
 * terminal-state guards.
 *
 * Scoping — matches AdminProfessionalCollectionController exactly:
 * `SupportTicket` (confirmed by reading the model directly) uses NO
 * scoping trait at all — bimodal visibility is hand-scoped in the
 * tenant-facing API controller's `resolve()`. This whole Admin Panel is
 * Platform-Administrator-only (`can:platform-admin-only` route gate) and
 * the Policy already grants that actor unconditional `view`, so no masking
 * is needed here and implicit route-model binding on `SupportTicket` is
 * safe. `SupportTicketMessage`/`SupportTicketAttachment` carry no
 * `tenant_id` of their own either — reached only via the already-resolved
 * parent ticket.
 *
 * No debtor/debt drill-down: a ticket's `category`/free-text
 * `description`/messages carry no foreign key to any Customer/Debt/
 * Collection Case — there is nothing in the schema to safely link from,
 * so none is added (a `category` value like `debt_recovery` only labels
 * the general topic, it never identifies a specific record).
 */
class AdminSupportTicketController extends Controller
{
    public const STATUS_LABELS = [
        'open' => 'Open',
        'in_progress' => 'In Progress',
        'resolved' => 'Resolved',
        'closed' => 'Closed',
    ];

    public const NON_TERMINAL_STATUSES = [
        'in_progress' => 'In Progress',
        'resolved' => 'Resolved',
    ];

    public const PRIORITY_LABELS = [
        'low' => 'Low',
        'medium' => 'Medium',
        'high' => 'High',
        'urgent' => 'Urgent',
    ];

    public const CATEGORY_LABELS = [
        'technical_issue' => 'Technical Issue',
        'payment_billing' => 'Payment / Billing',
        'account' => 'Account',
        'subscription' => 'Subscription',
        'debt_recovery' => 'Debt & Recovery',
        'professional_collection' => 'Professional Collection',
        'feature_request' => 'Feature Request',
        'other' => 'Other',
    ];

    public function __construct(private readonly SupportTicketService $tickets) {}

    public function index(Request $request): View
    {
        $tickets = SupportTicket::with('tenant:id,business_name')
            ->when($request->filled('search'), fn ($query) => $this->applySearch($query, (string) $request->string('search')))
            ->when($request->filled('tenant_id'), fn ($query) => $query->where('tenant_id', $request->string('tenant_id')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->filled('priority'), fn ($query) => $query->where('priority', $request->string('priority')))
            ->when($request->filled('category'), fn ($query) => $query->where('category', $request->string('category')))
            ->when($request->filled('date_from'), fn ($query) => $query->whereDate('created_at', '>=', $request->string('date_from')))
            ->when($request->filled('date_to'), fn ($query) => $query->whereDate('created_at', '<=', $request->string('date_to')))
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        return view('admin.support-tickets.index', [
            'title' => 'Support & Tickets',
            'tickets' => $tickets,
            'statuses' => self::STATUS_LABELS,
            'priorities' => self::PRIORITY_LABELS,
            'categories' => self::CATEGORY_LABELS,
            'tenants' => Tenant::orderBy('business_name')->get(['id', 'business_name']),
        ]);
    }

    private function applySearch($query, string $term)
    {
        $needle = '%'.mb_strtolower($term).'%';

        return $query->where(function ($q) use ($needle) {
            $q->whereRaw('LOWER(reference_number) LIKE ?', [$needle])
                ->orWhereRaw('LOWER(subject) LIKE ?', [$needle])
                ->orWhereHas('tenant', fn ($t) => $t->whereRaw('LOWER(business_name) LIKE ?', [$needle]));
        });
    }

    public function show(SupportTicket $supportTicket): View
    {
        $supportTicket->load([
            'tenant',
            'submittedBy:id,name,email',
            'messages' => fn ($q) => $q->with('sender:id,name')->orderBy('created_at'),
            'attachments' => fn ($q) => $q->orderByDesc('created_at'),
        ]);

        return view('admin.support-tickets.show', [
            'title' => 'Support & Tickets',
            'pageTitle' => $supportTicket->reference_number,
            'ticket' => $supportTicket,
            'statuses' => self::STATUS_LABELS,
            'nonTerminalStatuses' => self::NON_TERMINAL_STATUSES,
            'priorities' => self::PRIORITY_LABELS,
            'categories' => self::CATEGORY_LABELS,
        ]);
    }

    public function transitionStatus(TransitionSupportTicketStatusRequest $request, SupportTicket $supportTicket): RedirectResponse
    {
        try {
            $this->tickets->transitionStatus($supportTicket, $request->validated('status'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.support-tickets.show', $supportTicket)->with('status', 'Status updated.');
    }

    public function close(Request $request, SupportTicket $supportTicket): RedirectResponse
    {
        try {
            $this->tickets->close($supportTicket, $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.support-tickets.show', $supportTicket)->with('status', 'Ticket closed.');
    }

    public function reopen(Request $request, SupportTicket $supportTicket): RedirectResponse
    {
        try {
            $this->tickets->reopen($supportTicket, $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.support-tickets.show', $supportTicket)->with('status', 'Ticket reopened.');
    }

    public function postMessage(ReplySupportTicketRequest $request, SupportTicket $supportTicket): RedirectResponse
    {
        try {
            $this->tickets->reply($supportTicket, $request->validated('content'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.support-tickets.show', $supportTicket)->with('status', 'Reply posted.');
    }

    public function uploadAttachment(UploadSupportTicketAttachmentRequest $request, SupportTicket $supportTicket): RedirectResponse
    {
        try {
            $this->tickets->uploadAttachment($supportTicket, $request->file('file'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.support-tickets.show', $supportTicket)->with('status', 'Attachment uploaded.');
    }

    public function downloadAttachment(SupportTicket $supportTicket, string $attachment): StreamedResponse
    {
        $attachment = $supportTicket->attachments()->findOrFail($attachment);

        return Storage::disk('local')->download($attachment->file_path, $attachment->original_filename);
    }

    /**
     * SupportTicketService signals an invalid transition/action via
     * `HttpResponseException` wrapping a JSON 409 — the Blade panel
     * converts that into a friendly redirect-back with an error message,
     * matching AdminProfessionalCollectionController's identical pattern.
     */
    private function backWithServiceError(HttpResponseException $e): RedirectResponse
    {
        $message = $e->getResponse()->getData(true)['message'] ?? 'This action could not be completed.';

        return back()->withErrors(['action' => $message]);
    }
}
