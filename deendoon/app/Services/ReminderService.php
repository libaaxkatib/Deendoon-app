<?php

namespace App\Services;

use App\Enums\ReminderType;
use App\Models\Reminder;
use App\Models\User;
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
}
