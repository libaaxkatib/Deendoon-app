<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Enums\NotificationType;
use App\Http\Requests\LogCallRequest;
use App\Http\Requests\SendManualReminderRequest;
use App\Http\Resources\DebtResource;
use App\Models\Debt;
use App\Services\AuditLogService;
use App\Services\FollowUpHistoryService;
use App\Services\NotificationService;
use App\Services\RecoveryStageService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * FR-030: Manual Reminder (WhatsApp / SMS / Call). Records that the action
 * was taken — actual WhatsApp/SMS provider delivery is out of scope
 * (Notifications Delivery, explicitly excluded from this module).
 *
 * FR-058's own Precondition list cites FR-029 (automated reminder
 * scheduling, still deferred — no scheduler infrastructure exists) as the
 * source of "Reminder Sent" notifications, not FR-030. Since FR-029 has no
 * implementation and 'reminder_sent' is otherwise unreachable, this hooks
 * the notification into the manual flow instead — the only currently-real
 * "reminder sent" occurrence in the system — as a deliberate, flagged
 * judgment call, not a strict reading of that citation.
 */
class ReminderController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly AuditLogService $auditLog,
        private readonly RecoveryStageService $recoveryStage,
        private readonly NotificationService $notifications,
    ) {}

    public function whatsapp(SendManualReminderRequest $request, Debt $debt): JsonResponse
    {
        return $this->logChannelReminder($request, $debt, FollowUpActionType::ManualWhatsapp, 'WhatsApp reminder logged successfully');
    }

    public function sms(SendManualReminderRequest $request, Debt $debt): JsonResponse
    {
        return $this->logChannelReminder($request, $debt, FollowUpActionType::ManualSms, 'SMS reminder logged successfully');
    }

    public function call(LogCallRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('manageRecovery', $debt);

        DB::transaction(function () use ($request, $debt) {
            $this->followUpHistory->record($debt, FollowUpActionType::CallLogged, $request->user(), $request->validated('details'));

            // No audit_log.action value corresponds to a phone call
            // specifically (BRL-030's approved catalog only has
            // reminder_sent); reusing it for calls too since FR-030
            // treats WhatsApp/SMS/Call uniformly as "Manual Reminder."
            $this->auditLog->record(AuditAction::ReminderSent, 'debt', $debt->id, $request->user(), 'Call logged');

            // BRL-031 Stage 3 — Phone Follow-up: entered when a Call reminder is logged.
            $this->recoveryStage->advanceTo($debt, 3, 'Recovery Stage advanced to 3 (Phone Follow-up): call logged', $request->user());

            $this->notifications->notify($debt->tenant_id, (string) $request->user()->id, NotificationType::ReminderSent, 'debt', $debt->id);
        });

        return $this->successResponse(new DebtResource($debt->fresh()), 'Call logged successfully');
    }

    private function logChannelReminder(SendManualReminderRequest $request, Debt $debt, FollowUpActionType $actionType, string $message): JsonResponse
    {
        $this->authorize('manageRecovery', $debt);

        DB::transaction(function () use ($request, $debt, $actionType) {
            $this->followUpHistory->record($debt, $actionType, $request->user(), $request->validated('details'));
            $this->auditLog->record(AuditAction::ReminderSent, 'debt', $debt->id, $request->user());

            // BRL-031 Stage 2 — Late Reminder: entered when the Debt is
            // already Overdue and a subsequent reminder is sent.
            if ($debt->debt_status === 'overdue') {
                $this->recoveryStage->advanceTo($debt, 2, 'Recovery Stage advanced to 2 (Late Reminder): reminder sent while Overdue', $request->user());
            }

            $this->notifications->notify($debt->tenant_id, (string) $request->user()->id, NotificationType::ReminderSent, 'debt', $debt->id);
        });

        return $this->successResponse(new DebtResource($debt->fresh()), $message);
    }
}
