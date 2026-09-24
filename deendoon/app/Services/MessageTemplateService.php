<?php

namespace App\Services;

use App\Enums\MessageChannel;
use App\Models\MessageTemplate;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Collection;

/**
 * docs/Backend_v2.1_UI_Mapping.md §7 (Shared Services) — retrieval only;
 * template management (create/edit) is not specified anywhere in the
 * approved documents, so none is built here.
 *
 * Backend Completion Audit (Phase 1) — provisionDefaults() is the single
 * source of the 7 approved default Somali WhatsApp/SMS templates, called
 * both at tenant registration (AuthController::register()) and by
 * MessageTemplateSeeder for tenants that already existed before this
 * fix. Kept here rather than duplicated in the seeder, per "Do not
 * duplicate business logic."
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

    /**
     * Idempotent: looks up by tenant_id + name + channel and updates the
     * body in place if found, so calling this more than once for the same
     * tenant (e.g. re-running the seeder) never creates duplicates.
     *
     * `tenant_id` is set via direct property assignment rather than
     * `updateOrCreate()`'s mass-assignment, because `MessageTemplate`
     * deliberately excludes `tenant_id` from its Fillable list
     * (`BelongsToTenant`'s docblock: "tenant_id must never be settable via
     * mass assignment") — passing it through `updateOrCreate()` would be
     * silently dropped on create. `withoutGlobalScope('tenant')` guards
     * the lookup in case this is ever called with an authenticated user of
     * a different tenant than `$tenant` (it's a no-op today, since neither
     * call site — the seeder or mid-registration — has an authenticated
     * Sanctum user).
     */
    public function provisionDefaults(Tenant $tenant): void
    {
        foreach ($this->defaultTemplates() as $template) {
            foreach ([MessageChannel::WhatsApp, MessageChannel::Sms] as $channel) {
                $model = MessageTemplate::withoutGlobalScope('tenant')
                    ->where('tenant_id', $tenant->id)
                    ->where('name', $template['name'])
                    ->where('channel', $channel)
                    ->first() ?? new MessageTemplate;

                $model->tenant_id = $tenant->id;
                $model->name = $template['name'];
                $model->channel = $channel;
                $model->body = $template['body'];
                $model->save();
            }
        }
    }

    /**
     * The 7 approved default templates (Somali). Each body references all
     * four placeholders `MessageRenderingService::renderForReminder()`
     * substitutes ({customer_name}/{amount_due}/{due_date}/{company_name})
     * so no template ever renders partially. Seeded once per channel
     * (whatsapp + sms) with identical body text, matching the approved
     * doc's requirement that the same 7 templates appear under both
     * channel pickers.
     *
     * @return array<int, array{name: string, body: string}>
     */
    private function defaultTemplates(): array
    {
        return [
            [
                'name' => 'First Reminder',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Waxaan rajaynaynaa inaad caafimaad qabto.\n"
                    ."\n"
                    ."Waxaan ku xusuusinaynaa in lagugu leeyahay deyn dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}.\n"
                    ."\n"
                    ."Waxaan si xushmad leh kaaga codsanaynaa inaad bixiso deyntaada.\n"
                    ."\n"
                    ."Haddii ay jirto cabasho ama warbixin dheeraad ah, fadlan nala wadaag sida ugu dhaqsaha badan.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Second Reminder',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Tani waa xasuusintii 2aad. Waxaa lagugu leeyahay deyn dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}.\n"
                    ."\n"
                    ."Ilaa hadda ma aanan helin lacagtii deynta. Haddii aad qabto caqabado dhinaca lacagta ah, fadlan nala soo xiriir si aan uga wada hadalno qorshe lacag-bixin oo kugu habboon.\n"
                    ."\n"
                    ."Jawaabtaada degdegga ah waxay naga caawinaysaa inaan arrintan si fudud u dhamayno.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Third Reminder',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Inkasta oo aan hore kuugu dirnay xasuusino hore, waxaa kugu taagan lacag dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}, welina lama bixin.\n"
                    ."\n"
                    ."Waxaan si xushmad leh kaaga codsanaynaa inaad nala soo xiriirto ama aad bixiso deyntaada 2 maalmood gudahood. Haddii ay jirto sabab kaa hor istaagaysa bixinta, fadlan nala wadaag si aan u helno xal ku habboon.\n"
                    ."\n"
                    ."Waxaan rajaynaynaa jawaabtaada sida ugu dhaqsaha badan.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Last Reminder',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Inkasta oo aan hore kuugu soo dirnay xasuusino hore, tani waa xasuusintii ugu dambeysay ee ku saabsan deyntaada oo dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}.\n"
                    ."\n"
                    ."Waxaan dhowr jeer isku daynay inaan kula xiriirno fariimo iyo wicitaanno, balse kama aanan helin wax jawaab ah. Fadlan nala soo xiriir ama bixi deyntaada 7 maalmood gudahood.\n"
                    ."\n"
                    ."Haddii aan jawaab kaa helin muddadaas, {company_name} wuxuu go'aansan karaa inuu kiiska u gudbiyo habab kale oo sharci waafaqsan.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Meeting Request',
                // Original approved text referenced a phone-number
                // placeholder ({phone_number}); dropped because
                // MessageRenderingService only substitutes
                // {customer_name}/{amount_due}/{due_date}/{company_name} —
                // confirmed with the Product Owner before seeding.
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Waxaan jeclaan lahayn inaan kulan kula yeelanno si aan uga wada hadalno deyntaada oo dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}, si aan u helno xal ku habboon labada dhinac.\n"
                    ."\n"
                    ."Fadlan noo sheeg waqtiga kugu habboon.\n"
                    ."\n"
                    ."Waxaan rajaynaynaa wada-shaqeyn wanaagsan.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Phone Call Follow-up',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Waxaan isku daynay inaan telefoon kugula xiriirno, waxaana kugu taagan deyn dhan {amount_due}, taas oo lagaa rabay inaad bixiso ugu dambayn {due_date}, laakiin kuma aanan helin.\n"
                    ."\n"
                    ."Fadlan nala soo xiriir marka kuugu horreysa si aan uga wada hadalno arrintan.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
            [
                'name' => 'Promise to Pay Confirmation',
                'body' => "Walaal {customer_name},\n"
                    ."\n"
                    ."Waad ku mahadsan tahay xaqiijinta ballantaada.\n"
                    ."\n"
                    ."Sida aan ku heshiinnay, waxaad ballan qaaday inaad bixiso {amount_due} taariikhda {due_date}.\n"
                    ."\n"
                    ."Waxaan rajaynaynaa inaad u fuliso ballantaas waqtigeeda.\n"
                    ."\n"
                    ."Mahadsanid,\n"
                    .'{company_name}',
            ],
        ];
    }
}
