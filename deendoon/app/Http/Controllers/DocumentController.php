<?php

namespace App\Http\Controllers;

use App\Enums\DocumentType;
use App\Http\Resources\DemandLetterResource;
use App\Http\Resources\DocumentEventResource;
use App\Http\Resources\ReceiptResource;
use App\Http\Resources\StatementResource;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\DocumentEvent;
use App\Models\Receipt;
use App\Models\Statement;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * FR-050/051/052 — generic view/download/history across all three document
 * types (Receipt, DemandLetter, Statement), per 07_API_Design.md §5.6's
 * polymorphic `/documents/{id}*` endpoints. Each type keeps its own
 * dedicated Policy/Resource (reused here, not duplicated); this controller
 * only resolves which of the three tables a given ULID belongs to.
 */
class DocumentController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly DocumentService $documents) {}

    public function show(string $id): JsonResponse
    {
        [$model, $resourceClass] = $this->resolve($id);

        $this->authorize('view', $model);

        return $this->successResponse(new $resourceClass($model));
    }

    /**
     * FR-051. Signed, short-lived pre-authorized links (08 §11) are the
     * approved access model for the underlying object storage; this
     * environment has no real S3-compatible provider configured, so bytes
     * are streamed through this authenticated, policy-checked endpoint
     * instead — every request is still individually authorized, never a
     * static public URL. Flagged as a NON-BLOCKING gap in the module
     * report pending real S3-compatible storage.
     */
    public function download(string $id): StreamedResponse
    {
        [$model, , $type] = $this->resolve($id);

        $this->authorize('view', $model);

        $this->documents->recordDownload($type, $model->id, $model->tenant_id, request()->user());

        return Storage::disk('local')->download($model->file_path, "{$model->reference_number}.pdf");
    }

    public function history(string $id): JsonResponse
    {
        [$model, , $type] = $this->resolve($id);

        $this->authorize('view', $model);

        $events = DocumentEvent::where('document_type', $type->value)
            ->where('document_id', $model->id)
            ->orderBy('occurred_at')
            ->get();

        return $this->successResponse(DocumentEventResource::collection($events));
    }

    public function forCustomer(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        $receipts = Receipt::whereHas('payment.debt', fn ($q) => $q->where('customer_id', $customer->id))->get();
        $demandLetters = DemandLetter::whereHas('debt', fn ($q) => $q->where('customer_id', $customer->id))->get();
        $statements = $customer->statements()->get();

        return $this->successResponse($this->combine($receipts, $demandLetters, $statements));
    }

    public function forDebt(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $receipts = Receipt::whereHas('payment', fn ($q) => $q->where('debt_id', $debt->id))->get();
        $demandLetters = $debt->demandLetters()->get();
        $statements = $debt->statements()->get();

        return $this->successResponse($this->combine($receipts, $demandLetters, $statements));
    }

    /**
     * @return array{0: Receipt|DemandLetter|Statement, 1: class-string, 2: DocumentType}
     */
    private function resolve(string $id): array
    {
        if ($receipt = Receipt::find($id)) {
            return [$receipt, ReceiptResource::class, DocumentType::Receipt];
        }

        if ($demandLetter = DemandLetter::find($id)) {
            return [$demandLetter, DemandLetterResource::class, DocumentType::DemandLetter];
        }

        if ($statement = Statement::find($id)) {
            return [$statement, StatementResource::class, DocumentType::Statement];
        }

        abort(404);
    }

    /**
     * @param  Collection<int, Receipt>  $receipts
     * @param  Collection<int, DemandLetter>  $demandLetters
     * @param  Collection<int, Statement>  $statements
     */
    private function combine(Collection $receipts, Collection $demandLetters, Collection $statements): array
    {
        return $receipts->map(fn (Receipt $r) => (new ReceiptResource($r))->resolve())
            ->concat($demandLetters->map(fn (DemandLetter $d) => (new DemandLetterResource($d))->resolve()))
            ->concat($statements->map(fn (Statement $s) => (new StatementResource($s))->resolve()))
            ->sortByDesc('generated_at')
            ->values()
            ->all();
    }
}
