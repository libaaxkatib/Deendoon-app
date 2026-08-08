<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\ProfessionalCollectionRequest;
use App\Models\ProfessionalCollectionTimelineEvent;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision): the Deendoon Recovery Team's own operational recovery
 * activity log. Deliberately independent of AuditLogService's records
 * (which capture system/data changes, e.g. "Professional Collection
 * Request Submitted") — this is domain data in its own right (who did
 * what recovery activity, when, with what outcome), not a change log —
 * though every write here is still separately audit-logged too, reusing
 * AuditLogService exactly as every other module does, per "reuse
 * existing audit logging."
 */
class ProfessionalCollectionTimelineService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly DocumentService $documents,
    ) {}

    /**
     * @param  array{event_type: string, occurred_at: ?string, notes: ?string, outcome: ?string, attachments?: array<int, UploadedFile>}  $data
     */
    public function recordEvent(ProfessionalCollectionRequest $request, array $data, User $actor): ProfessionalCollectionTimelineEvent
    {
        $tenant = Tenant::findOrFail($request->tenant_id);

        return DB::transaction(function () use ($request, $data, $actor, $tenant) {
            $event = $request->timelineEvents()->create([
                'event_type' => $data['event_type'],
                'officer_user_id' => $actor->id,
                'occurred_at' => $data['occurred_at'] ?? now(),
                'notes' => $data['notes'] ?? null,
                'outcome' => $data['outcome'] ?? null,
            ]);

            // Optional Attachments — reuses the exact same storage-quota
            // enforcement as a submission-time attachment, just linked to
            // this specific event instead of left unlinked.
            foreach ($data['attachments'] ?? [] as $file) {
                $stored = $this->documents->storeUploadedFile($file, $tenant, 'professional_collection_requests');

                $request->attachments()->create([
                    'timeline_event_id' => $event->id,
                    'uploaded_by_user_id' => $actor->id,
                    'file_path' => $stored['path'],
                    'original_filename' => $stored['original_filename'],
                    'mime_type' => $stored['mime_type'],
                    'file_size' => $stored['size'],
                ]);
            }

            $this->auditLog->record(
                AuditAction::Created,
                'professional_collection_timeline_event',
                $event->id,
                $actor,
                "Timeline event recorded: {$data['event_type']}",
                $request->tenant_id,
            );

            return $event->refresh();
        });
    }

    /**
     * @param  array{event_type?: string, occurred_at?: string, notes?: ?string, outcome?: ?string}  $data
     */
    public function updateEvent(ProfessionalCollectionTimelineEvent $event, array $data, User $actor): void
    {
        $event->update($data);

        $this->auditLog->record(
            AuditAction::Edited,
            'professional_collection_timeline_event',
            $event->id,
            $actor,
            null,
            $event->request->tenant_id,
        );
    }
}
