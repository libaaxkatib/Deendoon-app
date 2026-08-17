<?php

namespace App\Services;

use App\Models\Customer;
use Illuminate\Validation\ValidationException;

/**
 * Fix #23 — Multiple Customer Phone Numbers. Single owner of every
 * invariant this feature requires (1-3 numbers, exactly one primary) and
 * the declarative reconcile-on-save logic that `CustomerController` and
 * `CustomerImportController` both use instead of duplicating any of this
 * themselves.
 *
 * `customers.phone` is kept as a maintained mirror of the primary row —
 * every existing single-phone read path (duplicate detection, list
 * search, message rendering, an older mobile build that only ever sends
 * `phone`) keeps working completely unmodified.
 */
class CustomerPhoneNumberService
{
    /**
     * Normalizes request input into a consistent entry list. Falls back to
     * treating a lone legacy `phone` string as the sole primary entry when
     * `phone_numbers` is entirely absent from the request — this is what
     * makes an older mobile build (that has never heard of `phone_numbers`)
     * keep working unmodified.
     *
     * @param  array{phone: ?string, phone_numbers: ?array}  $input
     * @return array<int, array{id: ?string, phone: string, is_primary: bool}>
     */
    public function normalizeEntries(array $input): array
    {
        if (! array_key_exists('phone_numbers', $input) || $input['phone_numbers'] === null) {
            return [[
                'id' => null,
                'phone' => (string) $input['phone'],
                'is_primary' => true,
            ]];
        }

        return collect($input['phone_numbers'])->map(fn ($entry) => [
            'id' => $entry['id'] ?? null,
            'phone' => (string) ($entry['phone'] ?? ''),
            'is_primary' => filter_var($entry['is_primary'] ?? false, FILTER_VALIDATE_BOOLEAN),
        ])->all();
    }

    /**
     * @param  array<int, array{id: ?string, phone: string, is_primary: bool}>  $entries
     * @return array<int, string>
     */
    public function validationErrors(array $entries): array
    {
        $count = count($entries);
        $primaryCount = collect($entries)->where('is_primary', true)->count();

        $errors = [];
        if ($count < 1) {
            $errors[] = 'At least one phone number is required.';
        }
        if ($count > 3) {
            $errors[] = 'A customer may have at most 3 phone numbers.';
        }
        if ($count >= 1 && $count <= 3 && $primaryCount !== 1) {
            $errors[] = 'Exactly one phone number must be marked as primary.';
        }

        return $errors;
    }

    /**
     * Reconciles `$customer`'s `customer_phone_numbers` rows against
     * `$entries` (create/update/delete diff — a submitted `id` that
     * doesn't belong to this customer is never matched or written to; it
     * is simply treated as a new entry, since it is scoped to only this
     * customer's own existing rows below) and mirrors the primary entry's
     * phone into `customers.phone`. Must run inside the caller's own DB
     * transaction alongside the rest of the customer save.
     *
     * @param  array<int, array{id: ?string, phone: string, is_primary: bool}>  $entries
     */
    public function reconcile(Customer $customer, array $entries): void
    {
        $errors = $this->validationErrors($entries);
        if ($errors !== []) {
            throw ValidationException::withMessages(['phone_numbers' => $errors]);
        }

        $existingById = $customer->phoneNumbers()->get()->keyBy('id');
        $keptIds = [];

        foreach ($entries as $entry) {
            $existing = $entry['id'] !== null ? $existingById->get($entry['id']) : null;

            if ($existing) {
                $existing->update([
                    'phone' => $entry['phone'],
                    'is_primary' => $entry['is_primary'],
                ]);
                $keptIds[] = $existing->id;
            } else {
                $created = $customer->phoneNumbers()->create([
                    'phone' => $entry['phone'],
                    'is_primary' => $entry['is_primary'],
                ]);
                $keptIds[] = $created->id;
            }
        }

        $customer->phoneNumbers()->whereNotIn('id', $keptIds)->delete();

        $primaryPhone = collect($entries)->firstWhere('is_primary', true)['phone'];
        if ($customer->phone !== $primaryPhone) {
            $customer->phone = $primaryPhone;
            $customer->save();
        }
    }

    /**
     * Import-specific upsert: only ever touches the primary slot (from
     * `primary_phone`) and the secondary slot (from `secondary_phone`,
     * when non-empty) — a third phone number added manually via Customer
     * Edit is never modified or deleted by an import, since import only
     * ever supplies two slots (Fix #23 Decision 11).
     */
    public function upsertFromImport(Customer $customer, string $primaryPhone, ?string $secondaryPhone): void
    {
        $existing = $customer->phoneNumbers()->orderByDesc('is_primary')->orderBy('created_at')->get();
        $primaryRow = $existing->firstWhere('is_primary', true);
        $secondaryRow = $existing->first(fn ($row) => ! $row->is_primary);

        if ($primaryRow) {
            $primaryRow->update(['phone' => $primaryPhone]);
        } else {
            $customer->phoneNumbers()->create(['phone' => $primaryPhone, 'is_primary' => true]);
        }

        if ($secondaryPhone !== null && $secondaryPhone !== '') {
            if ($secondaryRow) {
                $secondaryRow->update(['phone' => $secondaryPhone]);
            } else {
                $customer->phoneNumbers()->create(['phone' => $secondaryPhone, 'is_primary' => false]);
            }
        }

        if ($customer->phone !== $primaryPhone) {
            $customer->phone = $primaryPhone;
            $customer->save();
        }
    }
}
