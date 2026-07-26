<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable, SoftDeletes;

    /**
     * FR-066: deactivation follows the Archive/Restore pattern (BC-002),
     * matching Customer/Debt's `archived_at` naming (06 §3) rather than
     * Laravel's default `deleted_at`.
     */
    const DELETED_AT = 'archived_at';

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'archived_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    /**
     * 06 §6.1's approved `users` table pairs `archived_at` with a
     * dedicated `status` column, unlike Customer/Debt, where `archived_at`
     * alone is the complete archival signal (06 §9). SoftDeletes' own
     * restore() already calls save() (persisting every dirty attribute),
     * so setting `status` here on the "restoring" event lands in the same
     * UPDATE as `archived_at` — no separate write needed.
     */
    protected static function booted(): void
    {
        static::restoring(function (User $user) {
            $user->status = 'active';
        });
    }

    /**
     * SoftDeletes' own runSoftDelete() issues a raw UPDATE naming only
     * `archived_at`/`updated_at` (it bypasses save(), so simply setting
     * `status` beforehand would not be persisted). This override adds
     * `status` to that same UPDATE, keeping both columns changing
     * atomically in one query — the same guarantee the trait already
     * gives `archived_at`/`updated_at` together.
     */
    protected function runSoftDelete()
    {
        $query = $this->setKeysForSaveQuery($this->newModelQuery());

        $time = $this->freshTimestamp();

        $columns = [
            $this->getDeletedAtColumn() => $this->fromDateTime($time),
            'status' => 'archived',
        ];

        $this->{$this->getDeletedAtColumn()} = $time;
        $this->status = 'archived';

        if ($this->usesTimestamps() && ! is_null($this->getUpdatedAtColumn())) {
            $this->{$this->getUpdatedAtColumn()} = $time;
            $columns[$this->getUpdatedAtColumn()] = $this->fromDateTime($time);
        }

        $query->update($columns);

        $this->syncOriginalAttributes(array_keys($columns));

        $this->fireModelEvent('trashed', false);
    }
}
