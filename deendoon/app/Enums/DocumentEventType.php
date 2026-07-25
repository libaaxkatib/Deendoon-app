<?php

namespace App\Enums;

/**
 * Mirrors the document_events.event_type CHECK constraint
 * (06_Database_Design.md §6.6) exactly. Only a subset is written today —
 * 'regenerated' exists because the database constraint already allows it,
 * but BRL-056 (regeneration policy) is unresolved, so nothing writes it yet.
 */
enum DocumentEventType: string
{
    case Generated = 'generated';
    case Downloaded = 'downloaded';
    case Regenerated = 'regenerated';
}
