<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreProfessionalCollectionTimelineEventRequest;
use App\Http\Requests\UpdateProfessionalCollectionTimelineEventRequest;
use App\Http\Resources\ProfessionalCollectionTimelineEventResource;
use App\Models\ProfessionalCollectionRequest;
use App\Models\User;
use App\Policies\ProfessionalCollectionRequestPolicy;
use App\Services\ProfessionalCollectionTimelineService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): the Deendoon Recovery Team's own operational recovery
 * activity log for a Professional Collection Request — deliberately
 * independent of the Audit Log (system/data changes) and the existing,
 * unchanged Customer Collection Timeline (DebtController::timeline()).
 * "Business Owners may view the timeline. Recovery Team members may
 * create/update timeline events according to permissions." Resolves the
 * parent Request with the same bimodal tenant-vs-platform-admin masking
 * rule as ProfessionalCollectionRequestController, since this table is
 * equally unscoped and equally bimodal.
 */
class ProfessionalCollectionTimelineController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly ProfessionalCollectionTimelineService $timeline,
        private readonly ProfessionalCollectionRequestPolicy $policy,
    ) {}

    public function index(Request $request, string $id): JsonResponse
    {
        $pcr = $this->resolveRequest($id, $request->user());

        $this->authorize('viewTimeline', $pcr);

        $events = $pcr->timelineEvents()->with('attachments')->orderBy('occurred_at')->get();

        return $this->successResponse(ProfessionalCollectionTimelineEventResource::collection($events));
    }

    public function store(StoreProfessionalCollectionTimelineEventRequest $request, string $id): JsonResponse
    {
        $pcr = $this->resolveRequest($id, $request->user());

        $this->authorize('createTimelineEvent', ProfessionalCollectionRequest::class);

        $event = $this->timeline->recordEvent($pcr, [
            'event_type' => $request->validated('event_type'),
            'occurred_at' => $request->validated('occurred_at'),
            'notes' => $request->validated('notes'),
            'outcome' => $request->validated('outcome'),
            'attachments' => $request->file('attachments', []),
        ], $request->user());

        $event->load('attachments');

        return $this->successResponse(new ProfessionalCollectionTimelineEventResource($event), 'Timeline event recorded successfully', 201);
    }

    public function update(UpdateProfessionalCollectionTimelineEventRequest $request, string $id, string $eventId): JsonResponse
    {
        $pcr = $this->resolveRequest($id, $request->user());

        $this->authorize('updateTimelineEvent', ProfessionalCollectionRequest::class);

        $event = $pcr->timelineEvents()->findOrFail($eventId);

        $this->timeline->updateEvent($event, $request->validated(), $request->user());

        return $this->successResponse(new ProfessionalCollectionTimelineEventResource($event->fresh('attachments')), 'Timeline event updated successfully');
    }

    private function resolveRequest(string $id, User $user): ProfessionalCollectionRequest
    {
        $pcr = ProfessionalCollectionRequest::findOrFail($id);

        if (! $this->policy->isPlatformAdmin($user) && $pcr->tenant_id !== $user->tenant_id) {
            abort(404);
        }

        return $pcr;
    }
}
