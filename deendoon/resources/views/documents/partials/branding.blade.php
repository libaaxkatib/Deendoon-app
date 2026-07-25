{{--
    Company Profile branding (06_Database_Design.md §3: tenants.business_name/
    logo_path/address/contact_email/contact_phone ARE the approved FR-068
    Company Profile fields, folded into the tenants table). Module 12's
    dedicated management UI doesn't exist yet, so this renders whatever is
    currently on the tenant row — placeholder/default branding per the
    Development Roadmap's Phase 9 note, with no fabricated values.
--}}
<div style="border-bottom: 2px solid #333; padding-bottom: 10px; margin-bottom: 20px;">
    @if ($tenant->logo_path)
        <img src="{{ $tenant->logo_path }}" alt="Logo" style="max-height: 60px;">
    @endif
    <h1 style="font-size: 20px; margin: 4px 0;">{{ $tenant->business_name }}</h1>
    @if ($tenant->address)
        <div style="font-size: 11px; color: #555;">{{ $tenant->address }}</div>
    @endif
    @if ($tenant->contact_email || $tenant->contact_phone)
        <div style="font-size: 11px; color: #555;">
            {{ collect([$tenant->contact_email, $tenant->contact_phone])->filter()->implode(' &middot; ') }}
        </div>
    @endif
</div>
