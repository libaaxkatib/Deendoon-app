<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Subscription Approval + Storage Add-on Approval (Product Owner-approved
 * decision record): no input is required to approve — empty rules, same
 * reasoning as ApproveSubscriptionChangeRequestRequest.
 */
class ApproveStorageAddonRequestRequest extends FormRequest
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
        return [];
    }
}
