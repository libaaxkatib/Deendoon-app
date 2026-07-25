<?php

namespace App\Enums;

/**
 * Mirrors the demand_letters.template_type CHECK constraint
 * (06_Database_Design.md §6.6) exactly — the four approved templates,
 * including Legal Notice (a template variant, not a separate numbered
 * document type per Module 8's Scope Boundary).
 */
enum DemandLetterTemplate: string
{
    case FirstReminder = 'first_reminder';
    case SecondReminder = 'second_reminder';
    case FinalDemand = 'final_demand';
    case LegalNotice = 'legal_notice';

    public function label(): string
    {
        return match ($this) {
            self::FirstReminder => 'First Reminder',
            self::SecondReminder => 'Second Reminder',
            self::FinalDemand => 'Final Demand',
            self::LegalNotice => 'Legal Notice',
        };
    }
}
