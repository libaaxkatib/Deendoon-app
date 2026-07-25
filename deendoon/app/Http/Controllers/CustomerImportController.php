<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\CommitCustomerImportRequest;
use App\Http\Requests\ImportCustomersRequest;
use App\Imports\CustomerImportSheet;
use App\Models\Customer;
use App\Models\ImportBatch;
use App\Models\ImportRow;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\CustomerDuplicateDetectionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;
use Throwable;

class CustomerImportController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly CustomerDuplicateDetectionService $duplicateDetection,
        private readonly AuditLogService $auditLog,
    ) {}

    /**
     * FR-016 Main Flow steps 1-4: upload, parse, validate each row, and
     * flag likely duplicates. Nothing is created or updated here — this is
     * Preview only (Main Flow does not create records until commit, step 7).
     */
    public function store(ImportCustomersRequest $request): JsonResponse
    {
        $this->authorize('import', Customer::class);

        $sheet = new CustomerImportSheet;

        try {
            Excel::import($sheet, $request->file('file'));
        } catch (Throwable) {
            // E1: file format unsupported or corrupted — rejected before Preview.
            return $this->errorResponse('The uploaded file could not be read. It may be corrupted or in an unsupported format.', null, 422);
        }

        $user = $request->user();

        $batch = new ImportBatch([
            'file_name' => $request->file('file')->getClientOriginalName(),
            'status' => 'preview',
        ]);
        $batch->uploaded_by_user_id = $user->id;
        $batch->save();

        $rowsPayload = [];

        foreach ($sheet->rows as $index => $sourceRow) {
            $rowNumber = $index + 1;

            $name = trim((string) ($sourceRow['name'] ?? ''));
            $phone = trim((string) ($sourceRow['phone'] ?? ''));
            $creditLimit = $sourceRow['credit_limit'] ?? null;

            $errors = $this->validateRow($name, $phone, $creditLimit);
            $isValid = empty($errors);

            $duplicate = $isValid
                ? $this->duplicateDetection->findPotentialDuplicate($user->tenant_id, $name, $phone)
                : null;

            $importRow = ImportRow::create([
                'batch_id' => $batch->id,
                'row_number' => $rowNumber,
                'row_data' => ['name' => $name, 'phone' => $phone, 'credit_limit' => $creditLimit],
                'validation_status' => $isValid ? 'valid' : 'invalid',
                'validation_errors' => $isValid ? null : $errors,
                'duplicate_match_customer_id' => $duplicate?->id,
            ]);

            $rowsPayload[] = $this->rowToArray($importRow, $duplicate);
        }

        return $this->successResponse([
            'batch_id' => $batch->id,
            'status' => $batch->status,
            'rows' => $rowsPayload,
        ], 'Import file parsed successfully', 201);
    }

    /**
     * FR-016 Main Flow steps 5-7: apply the client's per-row resolution and
     * create/update Customer records accordingly.
     *
     * DD-005 (partial-import validation failure behavior) is unresolved in
     * 04_Business_Rules.md. This does not decide it: a row already marked
     * invalid during Preview is simply never turned into a Customer record,
     * regardless of any resolution submitted for it — it has no valid
     * payload to act on. Rows with a duplicate match but no submitted
     * resolution default to "skip" — the only safe behavior that neither
     * silently creates a duplicate nor silently overwrites existing data.
     */
    public function commit(CommitCustomerImportRequest $request, ImportBatch $batch): JsonResponse
    {
        $this->authorize('import', Customer::class);

        if ($batch->status === 'committed') {
            return $this->errorResponse('This import batch has already been committed.', null, 422);
        }

        $resolutionsByRow = collect($request->validated('resolutions', []))->keyBy('row_number');
        $user = $request->user();
        $results = [];

        DB::transaction(function () use ($batch, $resolutionsByRow, $user, &$results) {
            foreach ($batch->rows as $row) {
                $results[] = $this->processRow($row, $resolutionsByRow, $user);
            }

            $batch->update(['status' => 'committed']);
        });

        return $this->successResponse([
            'batch_id' => $batch->id,
            'status' => 'committed',
            'results' => $results,
        ], 'Import committed successfully');
    }

    /**
     * @return array<string, mixed>
     */
    private function processRow(ImportRow $row, Collection $resolutionsByRow, User $user): array
    {
        if ($row->validation_status === 'invalid') {
            return ['row_number' => $row->row_number, 'outcome' => 'skipped_invalid'];
        }

        $data = $row->row_data;
        $resolution = $row->duplicate_match_customer_id
            ? ($resolutionsByRow->get($row->row_number)['resolution'] ?? 'skip')
            : 'new';

        if ($resolution === 'skip') {
            $row->update(['resolution' => 'skip']);

            return ['row_number' => $row->row_number, 'outcome' => 'skipped'];
        }

        if ($resolution === 'update' && $row->duplicate_match_customer_id) {
            $customer = Customer::findOrFail($row->duplicate_match_customer_id);
            $customer->update([
                'name' => $data['name'],
                'phone' => $data['phone'],
                'credit_limit' => $data['credit_limit'],
            ]);

            $this->auditLog->record(AuditAction::Edited, 'customer', $customer->id, $user);
            $row->update(['resolution' => 'update', 'resulting_customer_id' => $customer->id]);

            return ['row_number' => $row->row_number, 'outcome' => 'updated', 'customer_id' => $customer->id];
        }

        $customer = Customer::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'customer_status' => 'active',
            'credit_limit' => $data['credit_limit'],
        ]);

        $this->auditLog->record(AuditAction::Created, 'customer', $customer->id, $user);
        $row->update(['resolution' => 'new', 'resulting_customer_id' => $customer->id]);

        return ['row_number' => $row->row_number, 'outcome' => 'created', 'customer_id' => $customer->id];
    }

    /**
     * @return array<int, string>
     */
    private function validateRow(string $name, string $phone, mixed $creditLimit): array
    {
        $errors = [];

        if ($name === '') {
            $errors[] = 'name is required';
        }

        if ($phone === '') {
            $errors[] = 'phone is required';
        }

        if ($creditLimit === null || $creditLimit === '' || ! is_numeric($creditLimit) || (float) $creditLimit < 0) {
            $errors[] = 'credit_limit is required and must be a non-negative number';
        }

        return $errors;
    }

    /**
     * @return array<string, mixed>
     */
    private function rowToArray(ImportRow $importRow, ?Customer $duplicate): array
    {
        return [
            'row_number' => $importRow->row_number,
            'data' => $importRow->row_data,
            'validation_status' => $importRow->validation_status,
            'validation_errors' => $importRow->validation_errors,
            'duplicate_match' => $duplicate ? [
                'customer_id' => $duplicate->id,
                'name' => $duplicate->name,
            ] : null,
        ];
    }
}
