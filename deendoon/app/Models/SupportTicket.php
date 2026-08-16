<?php

namespace App\Models;

use Database\Factories\SupportTicketFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Module 7 — Support & Tickets. Deliberately does NOT use BelongsToTenant,
 * matching ProfessionalCollectionRequest's exact precedent: this table is
 * bimodal by design — visible to its submitting tenant AND, without any
 * tenant filter at all, to the Deendoon Platform Administrator
 * (tenant_id IS NULL). Every query against this model is scoped explicitly
 * in SupportTicketController/AdminSupportTicketController/SupportTicketPolicy
 * instead.
 */
#[Fillable(['subject', 'description', 'status', 'priority', 'category', 'reference_number', 'submitted_by_user_id', 'closed_at', 'reopened_at'])]
class SupportTicket extends Model
{
    /** @use HasFactory<SupportTicketFactory> */
    use HasFactory, HasUlids;

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
            'closed_at' => 'datetime',
            'reopened_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by_user_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(SupportTicketMessage::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(SupportTicketAttachment::class);
    }
}
