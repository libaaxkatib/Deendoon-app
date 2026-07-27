<?php

namespace App\Services;

use App\Enums\MessageChannel;
use App\Models\MessageTemplate;
use Illuminate\Database\Eloquent\Collection;

/**
 * docs/Backend_v2.1_UI_Mapping.md §7 (Shared Services) — retrieval only;
 * template management (create/edit) is not specified anywhere in the
 * approved documents, so none is built here.
 */
class MessageTemplateService
{
    public function forChannel(?MessageChannel $channel = null): Collection
    {
        $query = MessageTemplate::query();

        if ($channel !== null) {
            $query->where('channel', $channel->value);
        }

        return $query->orderBy('name')->get();
    }
}
