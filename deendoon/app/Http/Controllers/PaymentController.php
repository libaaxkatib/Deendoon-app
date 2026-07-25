<?php

namespace App\Http\Controllers;

use App\Http\Requests\RecordPaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Customer;
use App\Models\Debt;
use App\Services\PaymentService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class PaymentController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly PaymentService $payments) {}

    public function store(RecordPaymentRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('recordPayment', $debt);

        $payment = $this->payments->record($debt, $request->validated(), $request->user());

        return $this->successResponse(new PaymentResource($payment), 'Payment recorded successfully', 201);
    }

    public function index(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $payments = $debt->payments()->orderBy('payment_date', 'desc')->get();

        return $this->successResponse(PaymentResource::collection($payments));
    }

    public function forCustomer(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        $payments = $customer->payments()->orderBy('payment_date', 'desc')->get();

        return $this->successResponse(PaymentResource::collection($payments));
    }
}
