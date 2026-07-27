<?php

namespace App\Enums;

/**
 * Mirrors the document_events.document_type CHECK constraint
 * (06_Database_Design.md §6.6) exactly.
 */
enum DocumentType: string
{
    case Receipt = 'receipt';
    case DemandLetter = 'demand_letter';
    case Statement = 'statement';
    case Invoice = 'invoice';
}
