<?php

namespace App\Http\Controllers;

use App\Http\Requests\CloseProfessionalCollectionRequestRequest;
use App\Http\Requests\PostRequestMessageRequest;
use App\Http\Requests\SubmitProfessionalCollectionRequestRequest;
use App\Http\Requests\TransitionRequestStatusRequest;
use App\Http\Requests\UploadProfessionalCollectionAttachmentRequest;
use App\Http\Resources\DemandLetterResource;
use App\Http\Resources\InvoiceResource;
use App\Http\Resources\ProfessionalCollectionRequestAttachmentResource;
use App\Http\Resources\ProfessionalCollectionRequestResource;
use App\Http\Resources\ProfessionalCollectionTimelineEventResource;
use App\Http\Resources\ReceiptResource;
use App\Http\Resources\RequestMessageResource;
use App\Http\Resources\StatementResource;
use App\Models\CollectionCase;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\User;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Services\ProfessionalCollectionRequestService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * FR-072–076. ProfessionalCollectionRequest deliberately has no
 * BelongsToTenant scope (see the model's docblock), so every lookup here
 * resolves the row explicitly and applies the tenant-vs-platform-admin
 * masking rule by hand (07_API_Design.md §10, "Authorization detail
 * specific to this resource"): a tenant session gets 404 for another
 * tenant's Request (never distinguished from "doesn't exist," matching
 * every other module's masking rule); the Deendoon Platform Administrator
 * sees every Request, cross-tenant, by design.
 */
class ProfessionalCollectionRequestController extends Controller
{
    use ApiResponse;

    private const WITH_SELECTIONS = ['reasons', 'requestedServices'];

    public function __construct(
        private readonly ProfessionalCollectionRequestService $requests,
        private readonly ProfessionalCollectionRequestPolicy $policy,
    ) {}

    public function store(SubmitProfessionalCollectionRequestRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('submit', ProfessionalCollectionRequest::class);

        $pcr = $this->requests->submit($case, [
            'reasons' => $request->validated('reasons'),
            'notes' => $request->validated('notes'),
            'services' => $request->validated('services'),
        ], $request->user());

        $pcr->load(self::WITH_SELECTIONS);

        return $this->successResponse(new ProfessionalCollectionRequestResource($pcr), 'Professional Collection Request submitted successfully', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = $this->policy->isPlatformAdmin($user)
            ? ProfessionalCollectionRequest::query()
            : ProfessionalCollectionRequest::where('tenant_id', $user->tenant_id);

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('status', $status);
        }

        $requests = $query->with(self::WITH_SELECTIONS)->orderBy('created_at', 'desc')->paginate(
            perPage: $this->perPage($request),
        );

        return $this->successResponse([
            'professional_requests' => ProfessionalCollectionRequestResource::collection($requests->items()),
            'pagination' => [
                'current_page' => $requests->currentPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
                'last_page' => $requests->lastPage(),
            ],
        ]);
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): the Professional Collection Summary Card. Registered
     * ahead of show()'s {id} route (routes/api.php) so "summary" is never
     * swallowed as an id. Visible to Business Owner only — like Business
     * Health, there is no cross-tenant "summary" for the Deendoon
     * Platform Administrator to see.
     */
    public function summary(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');

        $summary = $this->requests->summary($request->user()->tenant_id);

        return $this->successResponse([
            'counts_by_status' => $summary['counts_by_status'],
            'total_active' => $summary['total_active'],
            'total_recovered' => $summary['total_recovered'],
            'latest_request' => $summary['latest_request'] ? new ProfessionalCollectionRequestResource($summary['latest_request']) : null,
            'latest_timeline_event' => $summary['latest_timeline_event'] ? new ProfessionalCollectionTimelineEventResource($summary['latest_timeline_event']) : null,
        ]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('view', $pcr);

        $pcr->load(self::WITH_SELECTIONS);

        return $this->successResponse(new ProfessionalCollectionRequestResource($pcr));
    }

    public function updateStatus(TransitionRequestStatusRequest $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('transitionStatus', ProfessionalCollectionRequest::class);

        $this->requests->transitionStatus($pcr, $request->validated('status'), $request->user());

        return $this->successResponse(new ProfessionalCollectionRequestResource($pcr->fresh()), 'Professional Collection Request status updated successfully');
    }

    public function close(CloseProfessionalCollectionRequestRequest $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('close', ProfessionalCollectionRequest::class);

        $this->requests->close($pcr, $request->validated('outcome'), $request->user());

        return $this->successResponse(new ProfessionalCollectionRequestResource($pcr->fresh()), 'Professional Collection Request closed successfully');
    }

    public function messagesIndex(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('view', $pcr);

        return $this->successResponse(RequestMessageResource::collection($pcr->messages()->orderBy('created_at')->get()));
    }

    public function messagesStore(PostRequestMessageRequest $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('postMessage', $pcr);

        $message = $this->requests->postMessage($pcr, $request->validated('content'), $request->user());

        return $this->successResponse(new RequestMessageResource($message), 'Message posted successfully', 201);
    }

    /**
     * Transfer Case to Deendoon Recovery Team (Product Owner-approved
     * decision): the existing Customer/Debt documents auto-linked at
     * submission — resolved to their real Receipt/DemandLetter/Statement/
     * Invoice rows and returned via those types' own existing Resources
     * (ReceiptResource etc.), never a duplicated/denormalized shape.
     */
    public function documents(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('viewDocuments', $pcr);

        $links = $pcr->linkedDocuments()->get()->groupBy(fn ($link) => $link->document_type->value);

        $receipts = Receipt::whereIn('id', $links->get('receipt', collect())->pluck('document_id'))->get();
        $demandLetters = DemandLetter::whereIn('id', $links->get('demand_letter', collect())->pluck('document_id'))->get();
        $statements = Statement::whereIn('id', $links->get('statement', collect())->pluck('document_id'))->get();
        $invoices = Invoice::whereIn('id', $links->get('invoice', collect())->pluck('document_id'))->get();

        $documents = $receipts->map(fn (Receipt $r) => (new ReceiptResource($r))->resolve())
            ->concat($demandLetters->map(fn (DemandLetter $d) => (new DemandLetterResource($d))->resolve()))
            ->concat($statements->map(fn (Statement $s) => (new StatementResource($s))->resolve()))
            ->concat($invoices->map(fn (Invoice $i) => (new InvoiceResource($i))->resolve()))
            ->values();

        return $this->successResponse($documents);
    }

    public function attachmentsIndex(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('viewDocuments', $pcr);

        return $this->successResponse(
            ProfessionalCollectionRequestAttachmentResource::collection($pcr->attachments()->orderBy('created_at')->get()),
        );
    }

    public function attachmentsStore(UploadProfessionalCollectionAttachmentRequest $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('uploadAttachment', $pcr);

        $attachment = $this->requests->uploadAttachment(
            $pcr,
            $request->file('file'),
            $request->user(),
            $request->validated('timeline_event_id'),
        );

        return $this->successResponse(new ProfessionalCollectionRequestAttachmentResource($attachment), 'Attachment uploaded successfully', 201);
    }

    private function resolve(string $id, User $user): ProfessionalCollectionRequest
    {
        $pcr = ProfessionalCollectionRequest::findOrFail($id);

        if (! $this->policy->isPlatformAdmin($user) && $pcr->tenant_id !== $user->tenant_id) {
            abort(404);
        }

        return $pcr;
    }
}
