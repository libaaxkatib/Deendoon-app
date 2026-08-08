<?php

namespace App\Http\Controllers;

use App\Enums\MessageChannel;
use App\Http\Requests\RenderMessageRequest;
use App\Http\Requests\SendMessageRequest;
use App\Http\Resources\MessageTemplateResource;
use App\Http\Resources\SentMessageResource;
use App\Models\MessageTemplate;
use App\Models\Reminder;
use App\Services\MessageDeliveryService;
use App\Services\MessageRenderingService;
use App\Services\MessageTemplateService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * docs/Backend_v2.1_REST_API_Specification.md §8 (Shared APIs) — Message
 * Templates, Render, and Send via WhatsApp/SMS, used by Reminder Center's
 * WhatsApp/SMS Preview (§7.7, §7.8). Scoped to Reminder-sourced rendering/
 * sending this sprint — Document Share (§8.8) reuses these same
 * endpoints once the Documents module sprint builds that flow.
 */
class MessageController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly MessageTemplateService $templates,
        private readonly MessageRenderingService $rendering,
        private readonly MessageDeliveryService $delivery,
    ) {}

    public function templates(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $channel = $request->filled('channel') ? MessageChannel::from($request->string('channel')->value()) : null;

        return $this->successResponse(
            MessageTemplateResource::collection($this->templates->forChannel($channel)),
        );
    }

    public function render(RenderMessageRequest $request): JsonResponse
    {
        $template = MessageTemplate::findOrFail($request->validated('template_id'));
        $reminder = Reminder::findOrFail($request->validated('reminder_id'));

        $this->authorize('view', $reminder);

        return $this->successResponse($this->rendering->renderForReminder($template, $reminder));
    }

    public function sendWhatsApp(SendMessageRequest $request): JsonResponse
    {
        return $this->send($request, MessageChannel::WhatsApp);
    }

    public function sendSms(SendMessageRequest $request): JsonResponse
    {
        return $this->send($request, MessageChannel::Sms);
    }

    private function send(SendMessageRequest $request, MessageChannel $channel): JsonResponse
    {
        $template = MessageTemplate::findOrFail($request->validated('template_id'));
        $reminder = Reminder::findOrFail($request->validated('reminder_id'));

        $this->authorize('send', $reminder);

        $sentMessage = $this->delivery->sendReminder($reminder, $template, $channel, $request->user());

        return $this->successResponse(new SentMessageResource($sentMessage), 'Message sent successfully');
    }
}
