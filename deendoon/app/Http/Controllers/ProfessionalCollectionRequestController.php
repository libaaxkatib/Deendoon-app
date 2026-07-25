<?php

namespace App\Http\Controllers;

use App\Http\Requests\CloseProfessionalCollectionRequestRequest;
use App\Http\Requests\PostRequestMessageRequest;
use App\Http\Requests\SubmitProfessionalCollectionRequestRequest;
use App\Http\Requests\TransitionRequestStatusRequest;
use App\Http\Resources\ProfessionalCollectionRequestResource;
use App\Http\Resources\RequestMessageResource;
use App\Models\CollectionCase;
use App\Models\ProfessionalCollectionRequest;
use App\Models\User;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Services\ProfessionalCollectionRequestService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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

    public function __construct(
        private readonly ProfessionalCollectionRequestService $requests,
        private readonly ProfessionalCollectionRequestPolicy $policy,
    ) {}

    public function store(SubmitProfessionalCollectionRequestRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('submit', ProfessionalCollectionRequest::class);

        $pcr = $this->requests->submit($case, $request->user());

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

        $requests = $query->orderBy('created_at', 'desc')->paginate(
            perPage: $request->integer('perPage', 15),
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

    public function show(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolve($id, $request->user());

        $this->authorize('view', $pcr);

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

    private function resolve(string $id, User $user): ProfessionalCollectionRequest
    {
        $pcr = ProfessionalCollectionRequest::findOrFail($id);

        if (! $this->policy->isPlatformAdmin($user) && $pcr->tenant_id !== $user->tenant_id) {
            abort(404);
        }

        return $pcr;
    }
}
