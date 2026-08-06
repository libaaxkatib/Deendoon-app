<?php

namespace App\Services;

use App\Enums\ReminderType;
use App\Models\Reminder;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * docs/Backend_v2.1_UI_Mapping.md §5 — core reminder create/read/update/
 * delete and status logic. Reminder create/update/delete is deliberately
 * not written to the shared audit_log: docs/Backend_v2.1_Database_Alignment.md
 * §8 scopes Reminder auditing to the record's own immutable Created
 * By/Created On fields only, not a separate audit trail entry — unlike
 * Customers/Debts/Cases, which do use AuditLogService.
 */
class ReminderService
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function create(array $data, User $actor): Reminder
    {
        return DB::transaction(function () use ($data, $actor) {
            $type = ReminderType::from($data['type']);

            $reminder = new Reminder($data);
            $reminder->created_by_user_id = (string) $actor->id;

            // Backend Completion Roadmap (Phase 4.1): no Reminder instance
            // exists yet at the controller's normal authorize() point, so
            // this check lives here instead of ReminderPolicy::create() —
            // throwing AuthorizationException directly renders through
            // this app's existing AccessDeniedHttpException handler
            // (bootstrap/app.php), the same 403 shape a Policy denial
            // produces.
            if ($reminder->relatedCustomer()?->is_read_only) {
                throw new AuthorizationException('This action is unauthorized.');
            }

            // §7.4: Amount Due is omitted for types that don't carry one,
            // regardless of what the caller sent.
            if (! $type->carriesAmountDue()) {
                $reminder->amount_due = null;
            }

            $reminder->save();

            return $reminder->refresh();
        });
    }

    /**
     * §7.5/§7.9 (Reschedule): retains the original Created By/Created On,
     * updates only the fields a schedule change or edit touches.
     *
     * @param  array<string, mixed>  $data
     */
    public function update(Reminder $reminder, array $data): Reminder
    {
        return DB::transaction(function () use ($reminder, $data) {
            $type = isset($data['type']) ? ReminderType::from($data['type']) : $reminder->type;

            if (! $type->carriesAmountDue()) {
                $data['amount_due'] = null;
            }

            $reminder->update($data);

            return $reminder->fresh();
        });
    }

    public function complete(Reminder $reminder): Reminder
    {
        $reminder->update(['completed_at' => now()]);

        return $reminder->fresh();
    }

    public function delete(Reminder $reminder): void
    {
        $reminder->delete();
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §7.1: total due-today count, per-type
     * sub-counts, Overdue count. Extracted from
     * ReminderCenterController::summary() in Sprint 6 so Home Dashboard's
     * Today's Overview (§4.3, "reuses the Reminder Summary Service") can
     * call the identical computation instead of duplicating it — no
     * behavior change from what that controller already returned.
     *
     * @return array{total_due_today: int, per_type: array<string, int>, overdue_count: int}
     */
    public function summary(): array
    {
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

        return [
            'total_due_today' => $dueTodayQuery->count(),
            'per_type' => $perType,
            'overdue_count' => $overdueCount,
        ];
    }
}
