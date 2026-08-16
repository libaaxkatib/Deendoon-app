<?php

namespace App\Http\Controllers\Admin;

use App\Enums\ProfessionalCollectionTimelineEventType;
use App\Http\Controllers\Controller;
use App\Http\Requests\CloseProfessionalCollectionRequestRequest;
use App\Http\Requests\PostRequestMessageRequest;
use App\Http\Requests\StoreProfessionalCollectionTimelineEventRequest;
use App\Http\Requests\TransitionRequestStatusRequest;
use App\Http\Requests\UploadProfessionalCollectionAttachmentRequest;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Receipt;
use App\Models\Statement;
use App\Services\ProfessionalCollectionRequestService;
use App\Services\ProfessionalCollectionTimelineService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Admin Panel — Professional Collection (full operational workflow, per
 * Product Owner Decision 1-C). Every write here delegates to the existing,
 * already-tested {@see ProfessionalCollectionRequestService}/
 * {@see ProfessionalCollectionTimelineService} — the exact same methods
 * the tenant/platform-admin API (`ProfessionalCollectionRequestController`/
 * `ProfessionalCollectionTimelineController`) already calls. Nothing here
 * reimplements the status-transition matrix, close/outcome rules, message
 * terminal-state guard, or attachment terminal-state guard.
 *
 * Scoping — a third pattern, distinct from both prior categories:
 * `ProfessionalCollectionRequest` (confirmed by reading the model
 * directly) uses NO scoping trait at all — bimodal visibility is hand-
 * scoped in the tenant-facing API controller's `resolve()`, which masks a
 * cross-tenant request as 404 for a tenant session. This whole Admin
 * Panel is Platform-Administrator-only (`can:platform-admin-only` route
 * gate) and the Policy already grants that actor unconditional `view`, so
 * no masking is needed here and implicit route-model binding on
 * `ProfessionalCollectionRequest` is safe. `RequestMessage`/
 * `ProfessionalCollectionTimelineEvent`/`ProfessionalCollectionRequest
 * Attachment` carry no `tenant_id` of their own either — reached only via
 * the already-resolved parent Request.
 *
 * `CollectionCase`/`Debt`/`Customer`/`Receipt`/`DemandLetter`/`Statement`/
 * `Invoice`, reached via relations FROM a Professional Collection Request,
 * DO use plain `BelongsToTenant` (fail-closed for the Platform
 * Administrator) — `withoutGlobalScope('tenant')` is applied explicitly
 * at every level for these, matching the established Debt/Customer/
 * Payment/Debtors convention.
 *
 * One deliberate exception to "route middleware is enough" (matching
 * every other admin controller): `uploadAttachment()` calls
 * `$this->authorize('uploadAttachment', ...)` explicitly, because that
 * Policy ability is genuinely state-dependent (pre-Assigned = tenant-
 * only, Assigned/In-Progress = Platform-Administrator-only, terminal =
 * nobody) — unlike every other ability on this Policy, which is a plain
 * `isPlatformAdmin()` check already equivalent to the route gate. Skipping
 * this one call would let the Platform Administrator upload during a
 * phase the approved, tested Policy reserves for the tenant.
 *
 * No new migration: the audit found every requested field already exists.
 * No new Policy: the existing `ProfessionalCollectionRequestPolicy` is
 * already fully Platform-Administrator-aware. No separate "Reject"
 * action exists or is added here (Decision 6-B) — the only negative
 * terminal outcome the backend supports is `close(outcome: 'closed')`.
 */
class AdminProfessionalCollectionController extends Controller
{
    use AuthorizesRequests;

    public const STATUS_LABELS = [
        'submitted' => 'Submitted',
        'under_review' => 'Under Review',
        'need_more_information' => 'Need More Information',
        'accepted' => 'Accepted',
        'assigned' => 'Assigned',
        'in_progress' => 'In Progress',
        'recovered' => 'Recovered',
        'closed' => 'Closed',
    ];

    /**
     * Non-terminal statuses only — `recovered`/`closed` are reached
     * exclusively via the dedicated Close action, matching the service's
     * own `transitionStatus()` rejecting either as a 409. This list is
     * presentation-only (which options the dropdown offers); the service
     * remains the sole authority on whether a given transition is
     * actually valid — an invalid choice is rejected with a friendly
     * error, never silently allowed here.
     */
    public const NON_TERMINAL_STATUSES = [
        'submitted' => 'Submitted',
        'under_review' => 'Under Review',
        'need_more_information' => 'Need More Information',
        'accepted' => 'Accepted',
        'assigned' => 'Assigned',
        'in_progress' => 'In Progress',
    ];

    public function __construct(
        private readonly ProfessionalCollectionRequestService $requests,
        private readonly ProfessionalCollectionTimelineService $timeline,
    ) {}

    public function index(Request $request): View
    {
        $requests = ProfessionalCollectionRequest::with([
            'collectionCase' => fn ($q) => $q->withoutGlobalScope('tenant')
                ->with(['debt' => fn ($q2) => $q2->withoutGlobalScope('tenant')
                    ->with(['customer' => fn ($q3) => $q3->withoutGlobalScope('tenant')->with('tenant')])]),
        ])
            ->when($request->filled('search'), fn ($query) => $this->applySearch($query, (string) $request->string('search')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->filled('date_from'), fn ($query) => $query->whereDate('created_at', '>=', $request->string('date_from')))
            ->when($request->filled('date_to'), fn ($query) => $query->whereDate('created_at', '<=', $request->string('date_to')))
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        return view('admin.professional-collection.index', [
            'title' => 'Professional Collection',
            'requests' => $requests,
            'statuses' => self::STATUS_LABELS,
        ]);
    }

    private function applySearch($query, string $term)
    {
        $needle = '%'.mb_strtolower($term).'%';

        return $query->where(function ($q) use ($needle) {
            $q->whereRaw('LOWER(reference_number) LIKE ?', [$needle])
                ->orWhereHas('collectionCase', fn ($cc) => $cc->withoutGlobalScope('tenant')
                    ->whereHas('debt', fn ($d) => $d->withoutGlobalScope('tenant')
                        ->where(function ($d2) use ($needle) {
                            $d2->whereRaw('LOWER(reference_number) LIKE ?', [$needle])
                                ->orWhereHas('customer', fn ($c) => $c->withoutGlobalScope('tenant')
                                    ->whereRaw('LOWER(name) LIKE ?', [$needle]));
                        })));
        });
    }

    public function show(ProfessionalCollectionRequest $professionalCollectionRequest): View
    {
        $professionalCollectionRequest->load([
            'collectionCase' => fn ($q) => $q->withoutGlobalScope('tenant')
                ->with(['debt' => fn ($q2) => $q2->withoutGlobalScope('tenant')
                    ->with(['customer' => fn ($q3) => $q3->withoutGlobalScope('tenant')->with('tenant')])]),
            'reasons',
            'requestedServices',
            'linkedDocuments',
            'attachments' => fn ($q) => $q->orderByDesc('created_at'),
            'timelineEvents' => fn ($q) => $q->with('attachments')->orderBy('occurred_at'),
            'messages' => fn ($q) => $q->with('sender:id,name')->orderBy('created_at'),
        ]);

        return view('admin.professional-collection.show', [
            'title' => 'Professional Collection',
            'pageTitle' => $professionalCollectionRequest->reference_number,
            'pcr' => $professionalCollectionRequest,
            'statuses' => self::STATUS_LABELS,
            'nonTerminalStatuses' => self::NON_TERMINAL_STATUSES,
            'linkedDocuments' => $this->resolveLinkedDocuments($professionalCollectionRequest),
            'timelineEventTypes' => array_map(
                fn ($case) => ucwords(str_replace('_', ' ', $case->value)),
                ProfessionalCollectionTimelineEventType::cases(),
            ),
        ]);
    }

    /**
     * @return array<string, Collection>
     */
    private function resolveLinkedDocuments(ProfessionalCollectionRequest $pcr): array
    {
        $links = $pcr->linkedDocuments->groupBy(fn ($link) => $link->document_type->value);

        return [
            'receipt' => Receipt::withoutGlobalScope('tenant')->whereIn('id', $links->get('receipt', collect())->pluck('document_id'))->get(),
            'demand_letter' => DemandLetter::withoutGlobalScope('tenant')->whereIn('id', $links->get('demand_letter', collect())->pluck('document_id'))->get(),
            'statement' => Statement::withoutGlobalScope('tenant')->whereIn('id', $links->get('statement', collect())->pluck('document_id'))->get(),
            'invoice' => Invoice::withoutGlobalScope('tenant')->whereIn('id', $links->get('invoice', collect())->pluck('document_id'))->get(),
        ];
    }

    public function transitionStatus(TransitionRequestStatusRequest $request, ProfessionalCollectionRequest $professionalCollectionRequest): RedirectResponse
    {
        try {
            $this->requests->transitionStatus($professionalCollectionRequest, $request->validated('status'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.professional-collection.show', $professionalCollectionRequest)
            ->with('status', 'Status updated.');
    }

    public function close(CloseProfessionalCollectionRequestRequest $request, ProfessionalCollectionRequest $professionalCollectionRequest): RedirectResponse
    {
        try {
            $this->requests->close($professionalCollectionRequest, $request->validated('outcome'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.professional-collection.show', $professionalCollectionRequest)
            ->with('status', 'Professional Collection Request closed.');
    }

    public function postMessage(PostRequestMessageRequest $request, ProfessionalCollectionRequest $professionalCollectionRequest): RedirectResponse
    {
        try {
            $this->requests->postMessage($professionalCollectionRequest, $request->validated('content'), $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.professional-collection.show', $professionalCollectionRequest)
            ->with('status', 'Message posted.');
    }

    public function uploadAttachment(UploadProfessionalCollectionAttachmentRequest $request, ProfessionalCollectionRequest $professionalCollectionRequest): RedirectResponse
    {
        $this->authorize('uploadAttachment', $professionalCollectionRequest);

        try {
            $this->requests->uploadAttachment(
                $professionalCollectionRequest,
                $request->file('file'),
                $request->user(),
                $request->validated('timeline_event_id'),
            );
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.professional-collection.show', $professionalCollectionRequest)
            ->with('status', 'Attachment uploaded.');
    }

    public function recordTimelineEvent(StoreProfessionalCollectionTimelineEventRequest $request, ProfessionalCollectionRequest $professionalCollectionRequest): RedirectResponse
    {
        $this->timeline->recordEvent($professionalCollectionRequest, [
            'event_type' => $request->validated('event_type'),
            'occurred_at' => $request->validated('occurred_at'),
            'notes' => $request->validated('notes'),
            'outcome' => $request->validated('outcome'),
            'attachments' => $request->file('attachments', []),
        ], $request->user());

        return redirect()->route('admin.professional-collection.show', $professionalCollectionRequest)
            ->with('status', 'Timeline event recorded.');
    }

    public function downloadDocument(ProfessionalCollectionRequest $professionalCollectionRequest, string $documentType, string $documentId): StreamedResponse
    {
        $exists = $professionalCollectionRequest->linkedDocuments()
            ->where('document_type', $documentType)
            ->where('document_id', $documentId)
            ->exists();

        abort_unless($exists, 404);

        $model = match ($documentType) {
            'receipt' => Receipt::withoutGlobalScope('tenant')->findOrFail($documentId),
            'demand_letter' => DemandLetter::withoutGlobalScope('tenant')->findOrFail($documentId),
            'statement' => Statement::withoutGlobalScope('tenant')->findOrFail($documentId),
            'invoice' => Invoice::withoutGlobalScope('tenant')->findOrFail($documentId),
            default => abort(404),
        };

        return Storage::disk('local')->download($model->file_path, "{$model->reference_number}.pdf");
    }

    public function downloadAttachment(ProfessionalCollectionRequest $professionalCollectionRequest, string $attachment): StreamedResponse
    {
        $attachment = $professionalCollectionRequest->attachments()->findOrFail($attachment);

        return Storage::disk('local')->download($attachment->file_path, $attachment->original_filename);
    }

    /**
     * ProfessionalCollectionRequestService/ProfessionalCollectionTimelineService
     * signal an invalid transition/action via `HttpResponseException`
     * wrapping a JSON 409 (the shape the API controller returns directly)
     * — the Blade panel converts that into a friendly redirect-back with
     * an error message instead of surfacing a raw JSON body.
     */
    private function backWithServiceError(HttpResponseException $e): RedirectResponse
    {
        $message = $e->getResponse()->getData(true)['message'] ?? 'This action could not be completed.';

        return back()->withErrors(['action' => $message]);
    }
}
