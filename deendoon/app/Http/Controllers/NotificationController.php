<?php

namespace App\Http\Controllers;

use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * FR-058–061. Notifications are strictly personal — every query here is
 * scoped to the authenticated user's own recipient_user_id, in addition
 * to the tenant scoping BelongsToTenant already applies. No
 * `POST /notifications` endpoint exists (07_API_Design.md §11: deliberate,
 * not an omission) — every row is created internally by the owning
 * module's own service, never via this controller.
 */
class NotificationController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Notification::where('recipient_user_id', (string) $request->user()->id);

        if ($type = $request->string('type')->trim()->value()) {
            $query->where('type', $type);
        }

        $notifications = $query->orderBy('created_at', 'desc')->paginate(perPage: $request->integer('perPage', 15));

        return $this->successResponse([
            'notifications' => NotificationResource::collection($notifications->items()),
            'pagination' => $this->paginationMeta($notifications),
        ]);
    }

    public function history(Request $request): JsonResponse
    {
        $notifications = Notification::where('recipient_user_id', (string) $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->paginate(perPage: $request->integer('perPage', 15));

        return $this->successResponse([
            'notifications' => NotificationResource::collection($notifications->items()),
            'pagination' => $this->paginationMeta($notifications),
        ]);
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        $notification = $this->resolve($id, $request);

        $notification->update(['read_at' => now()]);

        return $this->successResponse(new NotificationResource($notification->fresh()), 'Notification marked as read');
    }

    public function markAllRead(Request $request): JsonResponse
    {
        Notification::where('recipient_user_id', (string) $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->successResponse(null, 'All notifications marked as read');
    }

    /**
     * A Notification belonging to another user in the same tenant is
     * masked as 404, not 403 — its existence for that other recipient is
     * not something this endpoint should confirm.
     */
    private function resolve(string $id, Request $request): Notification
    {
        $notification = Notification::findOrFail($id);

        if (! $request->user()->can('view', $notification)) {
            abort(404);
        }

        return $notification;
    }

    private function paginationMeta($paginator): array
    {
        return [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
        ];
    }
}
