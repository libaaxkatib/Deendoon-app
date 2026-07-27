<?php

namespace App\Http\Controllers;

use App\Models\Debt;
use App\Models\FollowUpHistory;
use App\Models\PromiseToPay;
use App\Models\Reminder;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * FR-062/BRL-068 — read-only aggregation over data already owned by
 * Modules 3/5: Debt Due Dates, Promise to Pay dates, and manual-reminder
 * ("Call Reminder") activity. Never owns, writes, or schedules anything.
 *
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §7.6): also aggregates the
 * Reminder Center's Reminders (all five types), which did not exist when
 * this controller was first built — the one addition this sprint makes
 * here, since §7.6 explicitly requires it.
 *
 * Not aggregated (see the module report):
 * - Collection Appointments (Module 7) — BRL-068 itself flags this as
 *   unresolved (DD-036): "Collection Appointments are not a distinct
 *   schedulable entity in Module 7... exactly how a future-dated
 *   Collection Activity becomes a Calendar entry is undefined." There is
 *   no date field on `collection_cases` to aggregate.
 */
class CalendarController extends Controller
{
    use ApiResponse;

    private const CLOSED_DEBT_STATUSES = ['paid', 'cancelled', 'written_off'];

    private const FOLLOW_UP_TYPES = ['manual_whatsapp', 'manual_sms', 'call_logged'];

    public function index(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $from = $request->filled('from') ? $request->date('from')->toDateString() : now()->startOfMonth()->toDateString();
        $to = $request->filled('to') ? $request->date('to')->toDateString() : now()->endOfMonth()->toDateString();

        $dueDates = Debt::query()
            ->whereNotIn('debt_status', self::CLOSED_DEBT_STATUSES)
            ->whereDate('due_date', '>=', $from)
            ->whereDate('due_date', '<=', $to)
            ->get()
            ->map(fn (Debt $debt) => [
                'type' => 'due_date',
                'date' => $debt->due_date->toDateString(),
                'related_entity_type' => 'debt',
                'related_entity_id' => $debt->id,
                'label' => $debt->reference_number,
            ]);

        $promises = PromiseToPay::query()
            ->where('status', 'open')
            ->whereDate('promised_date', '>=', $from)
            ->whereDate('promised_date', '<=', $to)
            ->get()
            ->map(fn (PromiseToPay $promise) => [
                'type' => 'promise_to_pay',
                'date' => $promise->promised_date->toDateString(),
                'related_entity_type' => 'promise_to_pay',
                'related_entity_id' => $promise->id,
                'label' => null,
            ]);

        $followUps = FollowUpHistory::query()
            ->whereIn('action_type', self::FOLLOW_UP_TYPES)
            ->whereDate('occurred_at', '>=', $from)
            ->whereDate('occurred_at', '<=', $to)
            ->get()
            ->map(fn (FollowUpHistory $entry) => [
                'type' => 'follow_up',
                'date' => $entry->occurred_at->toDateString(),
                'related_entity_type' => 'debt',
                'related_entity_id' => $entry->debt_id,
                'label' => $entry->action_type,
            ]);

        $reminders = Reminder::query()
            ->whereNull('completed_at')
            ->whereDate('due_date', '>=', $from)
            ->whereDate('due_date', '<=', $to)
            ->get()
            ->map(fn (Reminder $reminder) => [
                'type' => 'reminder',
                'date' => $reminder->due_date->toDateString(),
                'related_entity_type' => 'reminder',
                'related_entity_id' => $reminder->id,
                'label' => $reminder->type->label(),
            ]);

        $entries = $dueDates->concat($promises)->concat($followUps)->concat($reminders)->sortBy('date')->values();

        return $this->successResponse([
            'from' => $from,
            'to' => $to,
            'entries' => $entries,
        ]);
    }
}
