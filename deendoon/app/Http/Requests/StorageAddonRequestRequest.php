<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Backend Completion Roadmap, Phase 3.3. Only `storage_package` is
 * client-supplied; `storage_size`/`monthly_price` are always derived
 * server-side from the approved package pricing
 * (SubscriptionController::PACKAGES) — never trusted from client input.
 *
 * `payment_reference` required per Product Owner correction: a Storage
 * Add-on Request cannot be created without one.
 */
class StorageAddonRequestRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'storage_package' => ['required', 'string', Rule::in(['10gb', '25gb', '50gb', '100gb'])],
            'payment_reference' => ['required', 'string', 'max:100'],
        ];
    }
}
