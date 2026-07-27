<?php

namespace App\Http\Controllers;

use App\Enums\MessageChannel;
use App\Enums\ReminderType;
use App\Http\Requests\SendReminderRequest;
use App\Http\Requests\StoreReminderRequest;
use App\Http\Requests\UpdateReminderRequest;
use App\Http\Resources\ReminderResource;
use App\Http\Resources\SentMessageResource;
use App\Models\MessageTemplate;
use App\Models\Reminder;
use App\Services\MessageDeliveryService;
use App\Services\ReminderService;
use App\Services\SmartReminderEngine;
use App\Traits\ApiResponse;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * docs/Mobile_UI_V1_Frozen.md §7 (Reminder Center); §7.1, §7.3, §7.4, §7.5.
 * Named distinctly from the pre-existing App\Http\Controllers\ReminderController
 * (FR-030's manual, immediate, Debt-scoped WhatsApp/SMS/Call log actions,
 * unchanged and untouched) — this is the new, genuinely distinct
 * schedulable Reminder entity Backend v2.1 requires, not a rename or
 * replacement of that existing, working controller.
 */
class ReminderCenterController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly ReminderService $reminders,
        private readonly SmartReminderEngine $engine,
        private readonly MessageDeliveryService $delivery,
    ) {}

    /**
     * §7.1: total due-today count, per-type sub-counts, Overdue count.
     */
    public function summary(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Reminder::class);

        $dueTodayQuery = Reminder::whereNull('completed_at')
            ->whereDate('due_date', Carbon::today())
            ->where('due_date', '>=', Carbon::now());

        $perType = [];
        foreach (ReminderType::cases() as $type) {
            $perType[$type->value] = (clone $dueTodayQuery)->where('type', $type->value)->count();
        }

        $overdueCount = Reminder::whereNull('completed_at')
            ->where(function (Builder $query) {
                $query->where('due_date', '<', Carbon::today()->startOfDay())
                    ->orWhere(function (Builder $inner) {
                        $inner->whereDate('due_date', Carbon::today())->where('due_date', '<', Carbon::now());
                    });
            })
            ->count();

        return $this->successResponse([
            'total_due_today' => $dueTodayQuery->count(),
            'per_type' => $perType,
            'overdue_count' => $overdueCount,
        ]);
    }

    /**
     * §7.3: filterable by status tab (all/today/upcoming/overdue/completed)
     * and searchable by title/related entity name.
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Reminder::class);

        $query = Reminder::query();

        $this->applyTabFilter($query, $request->string('tab')->trim()->value() ?: 'all');

        $reminders = $query->orderBy('due_date')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'reminders' => ReminderResource::collection($reminders->items()),
            'pagination' => [
                'current_page' => $reminders->currentPage(),
                'per_page' => $reminders->perPage(),
                'total' => $reminders->total(),
                'last_page' => $reminders->lastPage(),
            ],
        ]);
    }

    public function store(StoreReminderRequest $request): JsonResponse
    {
        $this->authorize('create', Reminder::class);

        $reminder = $this->reminders->create($request->validated(), $request->user());

        return $this->successResponse(new ReminderResource($reminder), 'Reminder created successfully', 201);
    }

    public function show(Reminder $reminder): JsonResponse
    {
        $this->authorize('view', $reminder);

        return $this->successResponse(new ReminderResource($reminder));
    }

    public function update(UpdateReminderRequest $request, Reminder $reminder): JsonResponse
    {
        $this->authorize('update', $reminder);

        $reminder = $this->reminders->update($reminder, $request->validated());

        return $this->successResponse(new ReminderResource($reminder), 'Reminder updated successfully');
    }

    public function destroy(Reminder $reminder): JsonResponse
    {
        $this->authorize('delete', $reminder);

        $this->reminders->delete($reminder);

        return $this->successResponse(null, 'Reminder deleted successfully');
    }

    public function complete(Reminder $reminder): JsonResponse
    {
        $this->authorize('complete', $reminder);

        if ($reminder->completed_at !== null) {
            return $this->errorResponse('This reminder is already completed.', null, 409);
        }

        $reminder = $this->reminders->complete($reminder);

        return $this->successResponse(new ReminderResource($reminder), 'Reminder completed successfully');
    }

    /**
     * §7.3's inline "Send Reminder" action.
     */
    public function send(SendReminderRequest $request, Reminder $reminder): JsonResponse
    {
        $this->authorize('send', $reminder);

        $messageChannel = MessageChannel::from($request->validated('channel'));
        $template = MessageTemplate::findOrFail($request->validated('template_id'));

        $sentMessage = $this->delivery->sendReminder($reminder, $template, $messageChannel, $request->user());

        return $this->successResponse(new SentMessageResource($sentMessage), 'Reminder sent successfully');
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §7.3's Business Rule, computed exactly
     * as SmartReminderEngine::status() derives it — see that class for
     * the single source of truth this filter mirrors.
     */
    private function applyTabFilter(Builder $query, string $tab): void
    {
        $today = Carbon::today();
        $now = Carbon::now();

        match ($tab) {
            'today' => $query->whereNull('completed_at')
                ->whereDate('due_date', $today)
                ->where('due_date', '>=', $now),
            'upcoming' => $query->whereNull('completed_at')
                ->where('due_date', '>=', $today->copy()->addDay()->startOfDay()),
            'overdue' => $query->whereNull('completed_at')
                ->where(function (Builder $q) use ($today, $now) {
                    $q->where('due_date', '<', $today->copy()->startOfDay())
                        ->orWhere(function (Builder $inner) use ($today, $now) {
                            $inner->whereDate('due_date', $today)->where('due_date', '<', $now);
                        });
                }),
            'completed' => $query->whereNotNull('completed_at'),
            default => null,
        };
    }
}
