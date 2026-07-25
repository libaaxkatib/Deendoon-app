<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['business_name', 'logo_path', 'address', 'contact_email', 'contact_phone'])]
class Tenant extends Model
{
    use HasUlids;

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
