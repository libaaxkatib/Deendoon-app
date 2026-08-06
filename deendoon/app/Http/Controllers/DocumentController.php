<?php

namespace App\Http\Controllers;

use App\Enums\DocumentType;
use App\Enums\MessageChannel;
use App\Http\Requests\DocumentShareRequest;
use App\Http\Resources\DemandLetterResource;
use App\Http\Resources\DocumentEventResource;
use App\Http\Resources\InvoiceResource;
use App\Http\Resources\ReceiptResource;
use App\Http\Resources\SentMessageResource;
use App\Http\Resources\StatementResource;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\DocumentEvent;
use App\Models\Invoice;
use App\Models\MessageTemplate;
use App\Models\Receipt;
use App\Models\Statement;
use App\Services\DocumentService;
use App\Services\MessageDeliveryService;
use App\Traits\ApiResponse;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
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

    public function __construct(
        private readonly DocumentService $documents,
        private readonly MessageDeliveryService $delivery,
    ) {}

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.1 (All Documents) —
     * docs/Backend_v2.1_REST_API_Specification.md §7's "List Documents".
     * Sprint 7 finding: no tenant-wide document list existed anywhere —
     * only the per-customer/per-debt variants (forCustomer/forDebt)
     * built in Sprint 4/4.1. "type" mirrors §8.1's four tabs exactly
     * (Invoices/Receipts/Letters map to their own type; "Other" is
     * Statement, the one type not named by the first three tabs).
     * Paginates the same combine() output the other list methods already
     * produce, rather than introducing a raw cross-table SQL UNION.
     */
    public function index(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $type = $request->string('type')->trim()->lower()->value() ?: 'all';
        $search = $request->string('search')->trim()->value();

        // combine() requires an Eloquent Collection (it calls ->map() with
        // model-typed closures elsewhere); the base Support Collection
        // collect() returns is a different class and fails that type hint.
        $receipts = in_array($type, ['all', 'receipts'], true)
            ? $this->searchByReferenceNumber(Receipt::query(), $search)->get() : new Collection;
        $demandLetters = in_array($type, ['all', 'letters'], true)
            ? $this->searchByReferenceNumber(DemandLetter::query(), $search)->get() : new Collection;
        $statements = in_array($type, ['all', 'other'], true)
            ? $this->searchByReferenceNumber(Statement::query(), $search)->get() : new Collection;
        $invoices = in_array($type, ['all', 'invoices'], true)
            ? $this->searchByReferenceNumber(Invoice::query(), $search)->get() : new Collection;

        $all = collect($this->combine($receipts, $demandLetters, $statements, $invoices));

        $perPage = $this->perPage($request);
        $page = max(1, $request->integer('page', 1));
        $items = $all->slice(($page - 1) * $perPage, $perPage)->values();

        return $this->successResponse([
            'documents' => $items,
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total' => $all->count(),
                'last_page' => max(1, (int) ceil($all->count() / $perPage)),
            ],
        ]);
    }

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

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.1 Storage Usage.
     */
    public function storageUsage(): JsonResponse
    {
        Gate::authorize('view-reports');

        return $this->successResponse($this->documents->storageUsage(request()->user()->tenant));
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.8 — reuses the Sprint 3
     * MessageDeliveryService built for Reminder sending; no new provider
     * or PDF work involved, since the document is already generated.
     */
    public function share(DocumentShareRequest $request, string $id): JsonResponse
    {
        [$model, , $type] = $this->resolve($id);

        $this->authorize('view', $model);

        $channel = MessageChannel::from($request->validated('channel'));
        $template = MessageTemplate::findOrFail($request->validated('template_id'));

        $sentMessage = $this->delivery->sendDocument($model, $type, $template, $channel, $request->user());

        return $this->successResponse(new SentMessageResource($sentMessage), 'Document shared successfully');
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
        $invoices = Invoice::whereHas('debt', fn ($q) => $q->where('customer_id', $customer->id))->get();

        return $this->successResponse($this->combine($receipts, $demandLetters, $statements, $invoices));
    }

    public function forDebt(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $receipts = Receipt::whereHas('payment', fn ($q) => $q->where('debt_id', $debt->id))->get();
        $demandLetters = $debt->demandLetters()->get();
        $statements = $debt->statements()->get();
        $invoices = $debt->invoices()->get();

        return $this->successResponse($this->combine($receipts, $demandLetters, $statements, $invoices));
    }

    private function searchByReferenceNumber(Builder $query, string $search): Builder
    {
        if ($search !== '') {
            $query->whereRaw('LOWER(reference_number) LIKE ?', ['%'.mb_strtolower($search).'%']);
        }

        return $query;
    }

    /**
     * @return array{0: Receipt|DemandLetter|Statement|Invoice, 1: class-string, 2: DocumentType}
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

        if ($invoice = Invoice::find($id)) {
            return [$invoice, InvoiceResource::class, DocumentType::Invoice];
        }

        abort(404);
    }

    /**
     * @param  Collection<int, Receipt>  $receipts
     * @param  Collection<int, DemandLetter>  $demandLetters
     * @param  Collection<int, Statement>  $statements
     * @param  Collection<int, Invoice>  $invoices
     */
    private function combine(Collection $receipts, Collection $demandLetters, Collection $statements, Collection $invoices): array
    {
        return $receipts->map(fn (Receipt $r) => (new ReceiptResource($r))->resolve())
            ->concat($demandLetters->map(fn (DemandLetter $d) => (new DemandLetterResource($d))->resolve()))
            ->concat($statements->map(fn (Statement $s) => (new StatementResource($s))->resolve()))
            ->concat($invoices->map(fn (Invoice $i) => (new InvoiceResource($i))->resolve()))
            ->sortByDesc('generated_at')
            ->values()
            ->all();
    }
}
