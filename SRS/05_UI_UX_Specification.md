# 05. UI/UX Specification

| Field | Value |
|---|---|
| **Document ID** | SRS-DEENDOON-05 |
| **Document Title** | UI/UX Specification |
| **Version** | 1.11 |
| **Status** | Reopened — RBAC Architecture Amendment (retroactive) applied; SRS Final Alignment (Product Owner Decision) applied; Subscription & Storage Self-Service Catch-Up (Product Owner Decision) applied; Documentation Consistency Sweep applied; Manual Mobile-Money Subscription Payment Flow Amendment (Product Owner Decision) applied; SCR-053 redesigned and SCR-054 retired by the final UX direction (Product Owner Decision); SCR-053 gains a third operator, E-DAHAB (Product Owner Decision) |
| **Author** | Business Analyst / Solution Architect (Claude) |
| **Approved By** | Product Owner |
| **Last Updated** | 2026-08-20 |
| **Scope Baseline** | `01_Project_Overview.md` (Reopened, v1.6) · `02_Business_Requirements.md` (Reopened, v1.7) · `03_Functional_Requirements.md` (v1.19) · `04_Business_Rules.md` (Reopened, v1.13) |

---

## Revision History

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0 | 2026-07-24 | Initial draft: Design Principles, Design System, Layout Standards, Navigation, Component Library, Form/Table/Dashboard Standards, full Screen Inventory and Specifications for all 48 Version 1 screens/states, UX Behavior, Accessibility, Responsive Rules, UI State Catalog, UX Consistency Rules, Traceability, and Validation Checklist. | Claude |
| 1.1 | 2026-07-24 | Integrated Professional Collection Requests (FR-072–FR-076) into the existing UI architecture: one new screen (SCR-049, Super Admin review, reusing the existing Table + Detail Drawer pattern); amended SCR-005, SCR-006, and SCR-025 to add the tenant-facing submission action, dashboard visibility, and status/conversation surface; extended the Status Chip component and added a Conversation Thread component; updated Navigation, Screen Inventory, Traceability, and Validation Checklist. No new application interface, actor, or RBAC role was introduced — everything lives inside the two approved interfaces (Customer Mobile App, Deendoon Super Admin Web Panel). | Claude |
| 1.2 | 2026-07-31 | **Scope Baseline metadata correction (Documentation Consistency Audit — Scope Baseline synchronization).** Updated the Scope Baseline field to cite the current approved versions of `02`, `03`, and `04` (previously stale). No requirement, business rule, UI/UX specification, or approved content changed. | Claude |
| 1.3 | 2026-07-31 | **Product Vision Amendment (Product Owner Decision) — this document had never been updated for the RBAC Architecture Amendment.** Removed all remaining references to Operations Manager, Collection Officer (as a tenant role), Finance Staff, Support Staff, and Viewer across SCR-005, SCR-007, SCR-018, and SCR-024 — Version 1 has exactly one tenant-side role (Business Owner), matching `02_Business_Requirements.md` v1.4 and `08_Security_and_RBAC.md` v1.2. SCR-026 (Collection Case Assignment Modal) marked **Retired**, matching FR-041's retirement in `03_Functional_Requirements.md` v1.8 — content preserved for history, not deleted. SCR-024 and SCR-025 updated to remove the retired Assigned Officer field/Reassign action; SCR-025's Navigation Exit and SCR-024's Navigation Exit no longer point to the retired SCR-026. Screen Inventory and Traceability tables updated to mark SCR-026 Retired. No workflow, screen behavior, or functionality changed beyond removing what FR-041's retirement already removed — role references and dead navigation targets only. | Claude |
| 1.4 | 2026-07-31 | **Product Vision Amendment (generic "staff" sweep, Product Owner Decision).** SCR-005's Purpose line ("Give the business owner/staff...") updated to "Give the Business Owner..." — a missed sibling of the earlier SCR-005 Users fix (v1.3). No other content changed. | Claude |
| 1.5 | 2026-07-31 | **Final architecture consistency audit correction.** SCR-039/SCR-040/SCR-041 (Super Admin's deprecated-but-functional User/Role Administration screens, FR-066/FR-067) still referenced "six/seven approved roles" — missed by every prior sweep since these screens live on the Super Admin Web Panel, not the Customer Mobile App. Updated to reflect the single approved role (Business Owner, `admin`); DD-039 correctly cited as resolved/moot rather than pending. No screen, workflow, or functionality changed — role references only. | Claude |
| 1.6 | 2026-08-08 | **SRS Final Alignment (Product Owner Decision): current implemented app + backend are the final product.** SCR-025's Deendoon Hand-off tab and Validation rule amended: Submit Case to Deendoon is a Form, not a zero-field confirmation — it requires at least one Reason for Transfer and at least one Requested Service (both Reference Data-backed multi-select), optional Notes, and Client Declaration acceptance, matching `03_Functional_Requirements.md` v1.12 (FR-072) and `04_Business_Rules.md` v1.8 (BRL-078). The Deendoon Hand-off tab's Displayed Data now also lists Reasons, Requested Services, Notes, and the Declaration acceptance record for an existing Request. This corrects a discrepancy where this document still described the pre-amendment "no additional fields required" workflow. Scope Baseline updated to cite `03` v1.12 and `04` v1.8. | Claude |
| 1.7 | 2026-08-08 | **Subscription & Storage Self-Service Catch-Up (Product Owner Decision): current implemented app + backend are the final product.** Integrated Module 13 (`03_Functional_Requirements.md` FR-077–FR-084) into the existing UI architecture: two new screens — **SCR-050 Subscription (Business Owner)** and **SCR-051 Storage (Business Owner)** — both live-verified against the implemented Customer Mobile App, reusing the existing single-column Form/List screen pattern rather than introducing a new interaction model; the "Request Plan Change" and "Request Storage Add-on" actions are documented as bottom-sheet Forms embedded within their parent screen's own Sections/Validation, matching how SCR-025 already documents "Submit Case to Deendoon" as an embedded action rather than a separate screen. Amended SCR-046 (My Profile / Account Settings) to note the Account menu's "Subscription" tile (Business Owner only) as the entry point into SCR-050, which is itself the entry point into SCR-051 (no separate top-level "Storage" menu entry). Updated §4 Navigation Specification, §9 Screen Inventory, and §17 Traceability to include SCR-050/SCR-051, matching how the Professional Collection Requests addition (v1.1) updated the same three places. No new application interface, actor, or RBAC role was introduced — both screens live inside the existing Customer Mobile App, reachable only by the Business Owner. Scope Baseline updated to cite `03` v1.13 and `04` v1.9. | Claude |
| 1.8 | 2026-08-08 | **Documentation Consistency Sweep (Product Owner Decision): current implemented app + backend are the final product.** Corrected every remaining "Notes & Attachments" reference to match reality: the Component Library's File Upload entry no longer lists Notes as a use case (Notes is a plain text field, not a file upload); SCR-008 (Customer Details) had its "Notes" tab removed entirely — the Customer entity carries no Notes field in the final product, unlike Debt and Collection Case, which do (`02_Business_Requirements.md` v1.7, BR-022); SCR-014 (Debt Details) and SCR-025 (Collection Case Details) now list "Notes (free-text, BR-022)" instead of "Notes & Attachments." No screen was added or removed beyond SCR-008's tab count change; no workflow changed. | Claude |
| 1.9 | 2026-08-19 | **Manual Mobile-Money Subscription Payment Flow Amendment (Product Owner-approved decision), extending Module 13.** SCR-050's "Request This Plan" action now navigates to three new screens instead of opening the original single-field bottom sheet: **SCR-052 Payment Information** (Payment Phone required, Transaction Reference optional, Plan/Amount/Business Name read-only), **SCR-053 Payment Saved / Send Money** (confirmation, Platform Payment Destination Number, "Dir Lacagta" device-dialer action that never marks the request paid), and **SCR-054 Payment Status** (focused Pending Verification / Approved / Rejected view, with "Try Again" on Rejected). The original bottom sheet is retired — it could not collect the now-required Payment Phone (BRL-092). SCR-051 (Storage) and its Request Storage Add-on bottom sheet are unchanged; this amendment is scoped to Subscription Change Requests only. Updated §9 Screen Inventory and §17 Traceability to add SCR-052/053/054. No new application interface, actor, or RBAC role was introduced — all three screens live inside the existing Customer Mobile App, reachable only by the Business Owner. Scope Baseline updated to cite `03` v1.17 and `04` v1.11. | Claude |
| 1.10 | 2026-08-20 | **Final UX direction for the Manual Mobile-Money Subscription Payment Flow (Product Owner-approved decision), superseding v1.9's SCR-053/054 shape.** **SCR-053** (renamed "Payment Instructions / Send Money") redesigned: removed the Plan/Amount/Duration summary Card, the generic "Dir Lacagta" button, the "Payment Status: Pending Verification" notice, and "View Payment Status"; replaced with two fixed-label buttons, **SAALAM BANK** (`*799*32666663*5#`) and **EVC PLUS** (`*712*615514692*5#`) — Product-Owner-given USSD codes, not sourced from the backend and not admin-configurable — and a "Done" exit. **SCR-054 (Payment Status) marked Retired** (content preserved for history, matching this document's SCR-026 precedent) — no dedicated status view exists anymore in this flow. Added **SCR-055 — Thank You / Support**: a static terminal screen ("Mahadsanid") reusing the existing Contact Deendoon Support component as-is, with no payment/subscription outcome displayed anywhere. Updated §9 Screen Inventory and §17 Traceability accordingly. No new application interface, actor, or RBAC role introduced; no backend change of any kind. Scope Baseline updated to cite `03` v1.18 and `04` v1.12. | Claude |
| 1.11 | 2026-08-20 | **Third payment operator added (Product Owner-approved decision), extending v1.10's SCR-053.** Added a third fixed-label button, **E-DAHAB** (`*712*625514692*5#`), alongside SAALAM BANK and EVC PLUS — same USSD-launch mechanism, same non-status-changing guarantee. Updated §9 Screen Inventory and §17 Traceability only where the operator count is mentioned; no other section changed. No new application interface, actor, or RBAC role introduced; no backend change. Scope Baseline updated to cite `03` v1.19 and `04` v1.13. | Claude |

---

## Document Purpose

This document is the authoritative UI/UX design specification for Deendoon Version 1 — the reference designers and developers use before Figma/implementation work begins. It defines user experience, navigation, screens, components, layouts, interactions, validation display, loading behavior, accessibility, and responsive behavior for every approved capability in `03_Functional_Requirements.md`.

**This document does not define:** business rules (`04_Business_Rules.md`), API contracts (`07_API_Design.md`), database schema (`06_Database_Design.md`), or security implementation (`08_Security_and_RBAC.md`). Where a screen's behavior depends on one of those, this document references it rather than restating it.

**Design Constraints:** This specification supports every approved Functional Requirement and Business Rule, introduces zero new functionality, introduces zero Version 2 features, never redesigns an approved workflow, never changes module ownership, and never contradicts the approved architecture in Documents 01–04.

---

## 1. Design Principles

- **Clean Enterprise Design** — uncluttered layouts, generous whitespace, information hierarchy over decoration.
- **Mobile First** — the Customer Mobile App is the primary daily-use surface; every pattern is designed for mobile first, then scaled up.
- **Responsive Desktop Layout** — the Super Admin Web Panel and any desktop use of the Customer Mobile App's web build scale layouts up, never down.
- **Minimal Cognitive Load** — one primary action per screen; secondary actions are visually subordinate.
- **Fast Navigation** — no action requiring a core recovery task (record payment, send reminder, view a debt) should be more than two taps/clicks from the Dashboard.
- **Consistent Component Usage** — one component per purpose; no visual variants invented per screen.
- **Accessibility First** — accessibility is a baseline requirement of every component, not a later pass (see §15).
- **Professional SaaS Appearance** — the product must read as production-grade financial software, consistent with its positioning as a Smart Debt Recovery Assistant, not a prototype.

---

## 2. Design System

**Colors:** This document uses neutral placeholder tokens only — `--color-primary`, `--color-secondary`, `--color-success`, `--color-warning`, `--color-danger`, `--color-neutral-50` through `--color-neutral-900`. No brand hex values are specified here; brand colors are defined separately and mapped onto these tokens without changing this document.

### Typography
| Token | Usage |
|---|---|
| Display | Dashboard KPI numerals only |
| H1 | Page titles |
| H2 | Section headings within a page |
| H3 | Card/panel headings |
| Body | Default text, form labels' associated values |
| Label | Form field labels, table column headers |
| Caption | Helper text, timestamps, secondary metadata |

Font family: a single system-standard sans-serif placeholder (e.g., Inter/Roboto-equivalent) across all platforms; final brand typeface substituted later without layout impact. One weight scale: Regular / Medium / Semibold — no more than three weights in use at once on a single screen.

### Spacing System
4px base grid. Standard scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64. Component-internal padding uses 8/12/16; layout gutters use 16/24/32; section separation uses 32/48/64.

### Border Radius
Small (4px) — inputs, chips, badges. Medium (8px) — buttons, cards. Large (16px) — modals, drawers, bottom sheets.

### Elevation
Level 0 — flat page background. Level 1 — cards, table rows on hover. Level 2 — dropdowns, popovers, tooltips. Level 3 — modals, drawers. Level 4 — toasts/snackbars (always topmost).

### Icon Style
Single icon family, outline (line) style, consistent stroke weight, 20px/24px sizes only. Icons never carry meaning alone — always paired with a text label or accessible name (see §15, Color Independence).

### Button Hierarchy
- **Primary** — one per screen/section; the single recommended next action (e.g., "Save," "Record Payment").
- **Secondary** — alternate actions available alongside Primary (e.g., "Cancel," "Save as Draft").
- **Tertiary / Text** — low-emphasis actions (e.g., "View All," inline links).
- **Destructive** — Archive/Delete-class actions; always paired with a Confirmation Dialog (§7, Confirmation Dialog).
- **Icon Button** — compact actions in tables/toolbars; always carries an accessible label.

### Color Usage Principles
Color communicates status (success/warning/danger/neutral) but never carries meaning alone (§15). Primary color is reserved for primary actions and active/selected navigation states. Neutral grays carry the majority of the UI surface, consistent with Clean Enterprise Design.

---

## 3. Layout Standards

### Desktop (≥ 1280px — Super Admin Web Panel primary target)
Fixed left Sidebar (240px) + Top Bar (64px) + scrollable Content area (max content width 1440px, centered beyond that). Content area uses a 12-column grid, 24px gutters.

### Tablet (768–1279px)
Sidebar collapses to icon-only (72px) with label-on-hover/tap; Top Bar retains full width; Content area single-column or 2-column card grids.

### Mobile (< 768px — Customer Mobile App primary target)
No persistent Sidebar. Top Bar (56px) + bottom Tab Bar (primary navigation, 5 items max) + single-column Content. Secondary navigation surfaces as a Drawer (slide-in from left) or full-screen "More" menu.

### Content Width
Forms and reading content cap at 720px on desktop/tablet for readability even inside a wider Content area; tables and dashboards use full Content width.

### Sidebar Behavior (Desktop/Tablet, Super Admin Web Panel)
Persistent, collapsible by user preference (persisted per session). Shows Primary Navigation only (§4). Active section highlighted with Primary color + left accent bar.

### Top Navigation
Contains: current Page Title, Global Search entry point (§4), Notification Bell (component, §7), Quick Actions entry (mobile: floating action button; desktop: Top Bar button), Avatar/Account menu.

### Breadcrumbs
Shown on desktop/tablet for any screen nested more than one level deep (e.g., Customer List → Customer Details → Debt Details). Not shown on mobile; Back Navigation (§4) substitutes.

### Page Titles
Every screen has exactly one H1 Page Title, left-aligned, paired with an optional Action Bar on the same row (desktop) or below (mobile).

### Action Bars
Right-aligned (desktop) / full-width stacked (mobile) row containing the screen's Primary and Secondary actions (e.g., "Add Customer," "Export").

### Card Layout
Used for Dashboard KPIs, list-view items on mobile, and grouped detail sections. Consistent internal padding (16px), Medium radius, Level 1 elevation.

### Table Layout
Used for all list views on desktop/tablet (Customers, Debts, Collection Cases, Reports, Audit Trail, Users). On mobile, tables collapse to a stacked Card list (§9).

### Modal Layout
Centered overlay (desktop/tablet), full-screen sheet (mobile). Used for focused single-task actions with a clear Primary/Secondary action pair (e.g., Receive Payment, Promise to Pay, Recovery Stage Override).

### Drawer Layout
Slide-in panel (right on desktop for detail-peek/filters; left on mobile for navigation). Used for Advanced Filters and mobile secondary navigation.

---

## 4. Navigation Specification

**Primary Navigation** (role-filtered per RBAC): Dashboard, Customers, Debts, Collection Cases, Reports, Calendar, Administration (Super Admin Web Panel role-gated). Mobile: Dashboard, Customers, Debts, Notifications, More (Tab Bar, 5 items max, remaining items in "More"). Professional Collection Requests has **no separate top-level entry** on the Customer Mobile App — it is reached via the Dashboard widget (SCR-005) or from within a specific Collection Case (SCR-025), consistent with it being a hand-off *of* a Case rather than a distinct object the tenant manages independently. On the Super Admin Web Panel, **Professional Collection Requests is a peer Sidebar item to Administration**, not nested under it — it is Deendoon's own operational queue (reviewing/actioning submitted cases), not platform configuration, so it does not belong in the Administration information architecture (SCR-039–045).

**Subscription & Storage Navigation** *(added — Subscription & Storage Self-Service, Module 13)*: Subscription/Storage also has **no separate top-level entry** on the Customer Mobile App — it is reached via the Account menu's "Subscription" tile (SCR-046 → SCR-050), consistent with it being a Business Owner-only account/billing concern rather than a day-to-day operational object like Customers or Debts. Storage (SCR-051) has no menu entry of its own — it is reached only from within the Subscription screen (**Account → Subscription → Storage**), mirroring how Storage's own effective allowance is itself derived from the Subscription (plan base allowance plus active Storage Add-ons). The Deendoon Platform Administrator's Approval Center for these requests is not a separate screen specified here — it reuses the same Table + Detail Drawer pattern already established for SCR-049 (see `03_Functional_Requirements.md` FR-084); a dedicated SCR number is not assigned since Module 13's Approval Center is intentionally documented at the same "briefly, not a full screen spec" depth the Guardian process applied to Module 7's admin side before SCR-049 was added, and no live-verified screen design for it exists to specify.

**Secondary Navigation**: Within a section, tabs (e.g., Customer Details: Profile / Debts / Documents / Notes; Debt Details: Details / Timeline / Payments / Follow-up History).

**Breadcrumb Behavior**: Reflects the navigation hierarchy actually traversed (Customer List → [Customer Name] → [Debt Reference]); each segment is a clickable link back to that level.

**Back Navigation**: Mobile always shows a Back control in the Top Bar returning to the previous screen in-stack (not necessarily the parent in hierarchy, if the user arrived via Global Search or a Notification).

**Deep Linking**: Every Debt, Customer, Collection Case, and Document detail screen is addressable via a stable identifier (its Auto Numbering ID where applicable) so Notifications, Calendar entries, and exports can link directly to it.

**Search Accessibility**: Global Search (SCR-038) is reachable from every screen via the Top Bar, and via a keyboard shortcut on desktop (e.g., `/`).

**Keyboard Navigation**: All interactive elements are reachable and operable via Tab/Shift+Tab, Enter/Space, and Escape (to dismiss modals/drawers/popovers) — see §15.

---

## 5. Component Library

Each entry defines behavior only — visual styling follows §2.

- **Buttons** — five variants (§2); disabled state reduces opacity and removes pointer affordance; loading state replaces label with a Loading Spinner and disables re-submission.
- **Inputs (text)** — label above field; helper text below; error state replaces helper text with error message + red border/icon (never color alone).
- **Textarea** — as Inputs; auto-grows up to a max height, then scrolls internally (e.g., Notes fields).
- **Dropdown (Select)** — single-select from an enumerated list (e.g., Customer Status, Recovery Stage override target); native-feeling on mobile, custom popover on desktop.
- **Autocomplete** — type-ahead over a searchable set (e.g., selecting a Customer when creating a Debt); shows matching results with highlighted match text; "No results" empty state.
- **Checkbox** — binary/multi-select (e.g., bulk selection in tables).
- **Radio** — mutually exclusive choice among a small visible set (e.g., closure outcome, when its value set is confirmed per `04_Business_Rules.md` DD-024).
- **Switch (Toggle)** — binary on/off setting (e.g., a System Preference flag).
- **Date Picker** — calendar overlay; supports single-date selection (Due Date, Promise to Pay date) and range selection (Reports date filters).
- **Currency Input** — right-aligned numerals, thousands separators, 2-decimal precision (per `04_Business_Rules.md` rounding convention), currency symbol as a fixed prefix.
- **Phone Input** — validates format per the configured identifier/contact rules (Module 1/12); no country-code assumption is hardcoded here (deferred to configuration).
- **Search Box** — persistent placeholder text describing scope (e.g., "Search customers by name or phone"); clears with a visible "x" control.
- **Cards** — see §3.
- **Tables** — see §9.
- **Pagination** — page-number + Previous/Next controls (desktop); "Load more" infinite scroll pattern (mobile).
- **Badges** — small, static label chips for counts (e.g., unread Notification count on the bell icon).
- **Status Chips** — color-coded (with icon, never color alone) chips for Customer Status, Debt Status, Recovery Stage, Collection Case Status, and (as of this update) Professional Collection Request Status (Submitted, Under Review, Need More Information, Accepted, Assigned, In Progress, Recovered, Closed) — one consistent chip component reused everywhere these values appear. "Assigned" renders identically to the other in-progress states; it does not denote a different person or team, only that the Deendoon Super Admin has accepted ownership and started handling the Request (`04_Business_Rules.md`, BRL-079).
- **Timeline** — vertical stepper component used for Recovery Timeline (read-only, per Module 3 FR-024).
- **Activity Feed** — reverse-chronological list used for Follow-up History, Collection Case History, Audit Trail.
- **Conversation Thread** *(added)* — a bidirectional extension of Activity Feed: the same reverse-chronological, read-only message list, plus a persistent compose Input and Send button anchored below it. Used for the Professional Collection Request Conversation (FR-075), shared verbatim between the tenant's view (embedded in Collection Case Details, SCR-025) and the Super Admin's view (embedded in SCR-049) — both render the same underlying thread. Each message shows sender, timestamp, and content; no edit or delete affordance exists (BRL-080), consistent with the Audit Trail's own immutability.
- **Tabs** — Secondary Navigation within a detail screen (§4).
- **Accordion** — collapsible sections for long forms (e.g., System Preferences groups) or FAQ-style content.
- **Tooltip** — hover/long-press reveal for icon-only controls and truncated text.
- **Popover** — lightweight floating panel for Quick Actions on desktop, filter menus.
- **Toast** — transient, non-blocking confirmation (e.g., "Payment recorded"); auto-dismisses; does not block further action.
- **Snackbar** — as Toast, but may include an inline action (e.g., "Customer archived — Undo"), where Undo is available.
- **Notification Bell** — Top Bar icon with unread-count Badge; opens the Notification Center (SCR-036) as a Drawer (desktop) or full screen (mobile).
- **Avatar** — user identity indicator (initials placeholder by default); opens the Account menu (SCR-046).
- **File Upload** — drag-and-drop + browse fallback; used for Customer Import (FR-016), Company Logo (FR-068); shows filename, size, and a remove control before submission. **(Corrected, SRS Final Alignment)** Notes (BR-022) is a plain free-text field, not a File Upload use — no attachment-upload capability was implemented for Customer, Debt, or Collection Case.
- **Progress Indicator** — determinate bar for multi-step flows (e.g., Customer Import: Upload → Preview → Validate → Import).
- **Loading Spinner** — indeterminate, used for short (< 2s expected) waits.
- **Skeleton Loader** — used for list/table/card content taking longer than a spinner is appropriate for; mirrors the shape of the content it replaces.
- **Charts Placeholder** — a bounded container reserving space for Aging Analysis pie/bar charts (Module 9); actual charting library/visual spec is an implementation concern, not defined here.
- **Confirmation Dialog** — required before every Destructive action (Archive) and every override requiring a mandatory reason (Recovery Stage Override); always presents the consequence in plain language and requires explicit confirmation, never a default-confirmed state.
- **Empty State** — icon/illustration placeholder + short explanatory text + a Primary action where one applies (e.g., "No customers yet — Add Customer").
- **Error State** — icon + plain-language message + Retry action where the error is transient.
- **Permission Denied State** — icon + message explaining the user's role does not permit this view/action; never reveals data the role cannot access.
- **404 State** — icon + message + link back to Dashboard.

---

## 6. Form Standards

- **Required field indicator**: asterisk (*) after the label; never color alone.
- **Validation timing**: field-level validation on blur; form-level (submit) validation always runs on submit regardless of field-level state.
- **Inline validation**: error message appears directly below the offending field, replacing helper text.
- **Submit validation**: if any field fails, submission is blocked, the first invalid field receives focus, and an Error Summary (below) is shown.
- **Error summary**: for forms with more than 3 fields, a summary block above the form lists every error with anchor links to each field.
- **Success message**: Toast/Snackbar on successful submission (§5); for multi-step flows (Import), a dedicated success screen/state instead.
- **Disabled state**: reduced-opacity, non-interactive, tooltip explains why where the reason is not obvious (e.g., "Restore this record to edit it").
- **Read-only state**: value shown as static text, not an empty-looking disabled input, to avoid implying editability.
- **Autosave policy**: **Not specified for Version 1** — no screen in this specification assumes autosave; every form requires explicit Save/Submit, consistent with no FR describing autosave behavior.
- **Reset behavior**: "Cancel" always discards unsaved changes and returns to the prior screen/state without confirmation unless the form is long (> 5 fields) or destructive-adjacent, in which case a Confirmation Dialog guards discarding.
- **Confirmation before destructive actions**: mandatory for Archive (Customer, Debt, Collection Case is not archivable as a distinct destructive path per Module 7) and Recovery Stage Override (mandatory reason capture doubles as this confirmation).

---

## 7. Table Standards

- **Sorting**: single-column sort, ascending/asc toggled via column header click; sort indicator icon shown.
- **Filtering**: Advanced Filters Drawer (§3) reachable from a persistent "Filter" control in the table's Action Bar; applied filters shown as removable chips above the table.
- **Searching**: an inline Search Box (§5) scoped to the current table (per Module 2 FR-015 / Module 9 FR-056 pattern), distinct from Global Search.
- **Pagination**: see §5; default page size is a UI/NFR concern, not defined here.
- **Bulk selection**: checkbox column when the table supports a bulk action (e.g., bulk export); a contextual action bar appears once ≥ 1 row is selected.
- **Column resizing**: desktop only; persisted per user session, not per Business Rule (a UI/NFR-level preference).
- **Column visibility**: user may show/hide non-essential columns via a "Columns" control; at least one identifying column is always locked visible.
- **Sticky header**: table header remains visible while scrolling long result sets.
- **Row actions**: right-aligned icon-button menu ("⋮") per row for secondary actions (Archive, Restore, Assign); the row's primary action (View/Open) is triggered by clicking the row itself.
- **Empty tables**: Empty State component (§5), scoped to the current filters (e.g., "No customers match these filters" vs. "No customers yet").
- **Loading tables**: Skeleton Loader rows (§5) matching the table's column structure.

---

## 8. Dashboard Standards

- **KPI Cards**: fixed set per Module 9 (Total Outstanding Amount, Total Collected (Period), Recovery Rate, Total Overdue Debts, Customers Over Credit Limit, Active Collection Cases); each Card shows the metric, its historical-period selector (day/week/month/year, per BR-024), and drill-through to the relevant list/report on click.
- **Charts**: Aging Analysis pie and bar charts (Module 9, FR-054) rendered via the Charts Placeholder component (§5).
- **Recent Activity**: not a standing Dashboard section in Version 1 — Version 1 approved scope provides Follow-up History, Collection Case History, and Audit Trail as module-scoped activity views (see §17, Consistency Rules), not a separate Dashboard-level "Recent Activity" feed (which was explicitly excluded from Version 1 per `03_Functional_Requirements.md`, Module 11).
- **Quick Actions**: fixed set per Module 11, FR-065 (Add Debt, Receive Payment, Send WhatsApp, Call Customer, Generate Receipt, Generate Statement); rendered as a button row (desktop) or floating action button + sheet (mobile).
- **Professional Collection Requests widget** *(added)*: on the Customer Mobile App Dashboard (SCR-005), a Card containing a compact Table (Case, Status chip, Submitted Date) of the tenant's own Requests, reusing the same Card + Table pattern as the Aging Analysis widget; each row drills through to that Request's home on Collection Case Details (SCR-025). On the Super Admin Web Panel Dashboard (SCR-006), a single summary Card ("Pending Professional Collection Requests: N") drills through to SCR-049. Neither widget introduces a new component — both reuse existing Card, Table, and Status Chip patterns.
- **Responsive behavior**: KPI Cards reflow from a 6-across row (large monitor) → 3×2 grid (desktop) → 2×3 grid (tablet) → single column stack (mobile).
- **Refresh behavior**: manual pull-to-refresh (mobile) / refresh control (desktop); automatic refresh cadence is a Non-Functional Requirement, not defined here (see `04_Business_Rules.md` BRL-059/DD notes on KPI timing).

---

## 9. Screen Inventory

| ID | Screen | Module |
|---|---|---|
| SCR-001 | Login | 1 |
| SCR-002 | Forgot Password | 1 |
| SCR-003 | Reset Password | 1 |
| SCR-004 | Session Expired Interstitial | 1 |
| SCR-005 | Dashboard — Customer Mobile App | 9, 10, 11, 7 |
| SCR-006 | Dashboard — Super Admin Web Panel | 9, 10, 11, 7 |
| SCR-007 | Customer List | 2 |
| SCR-008 | Customer Details | 2, 4 |
| SCR-009 | Customer Create | 2 |
| SCR-010 | Customer Edit | 2 |
| SCR-011 | Customer Archive Confirmation | 2 |
| SCR-012 | Customer Import | 2 |
| SCR-013 | Debt List | 3 |
| SCR-014 | Debt Details | 3, 5 |
| SCR-015 | Debt Create | 3, 4 |
| SCR-016 | Debt Edit | 3 |
| SCR-017 | Debt Archive Confirmation | 3 |
| SCR-018 | Credit & Risk Panel | 4 |
| SCR-019 | Manual Reminder Modal | 5 |
| SCR-020 | Promise to Pay Modal | 5 |
| SCR-021 | Follow-up History Tab | 5 |
| SCR-022 | Receive Payment Modal | 6 |
| SCR-023 | Payment History Tab | 6 |
| SCR-024 | Collection Case List | 7 |
| SCR-025 | Collection Case Details | 7 |
| SCR-026 | ~~Collection Case Assignment Modal~~ (Retired — FR-041) | 7 |
| SCR-027 | Collection Activity Modal | 7 |
| SCR-028 | Collection Case Closure Modal | 7 |
| SCR-029 | Document Viewer | 8 |
| SCR-030 | Document List / History Tab | 8 |
| SCR-031 | Generate Demand Letter Modal | 8 |
| SCR-032 | Generate Statement Modal | 8 |
| SCR-033 | Aging Analysis Report | 9 |
| SCR-034 | Standard Reports Screen | 9 |
| SCR-035 | Report Export Modal | 9 |
| SCR-036 | Notification Center | 10 |
| SCR-037 | Calendar View | 10 |
| SCR-038 | Global Search Results | 11 |
| SCR-039 | User Administration List | 12 |
| SCR-040 | User Create / Edit | 12 |
| SCR-041 | Role & Permission Management | 12 |
| SCR-042 | Company Profile & Branding | 12 |
| SCR-043 | System Preferences | 12 |
| SCR-044 | Lookup & Reference Data | 12 |
| SCR-045 | Audit Trail Viewer | 12 |
| SCR-046 | My Profile / Account Settings | 1, 12 |
| SCR-047 | Permission Denied (global state) | Cross-cutting |
| SCR-048 | 404 Not Found (global state) | Cross-cutting |
| SCR-049 | Professional Collection Requests (Super Admin) *(added)* | 7 |
| SCR-050 | Subscription (Business Owner) *(added)* | 13 |
| SCR-051 | Storage (Business Owner) *(added)* | 13 |
| SCR-052 | Payment Information (Business Owner) *(added)* | 13 |
| SCR-053 | Payment Instructions / Send Money (Business Owner) *(redesigned, was "Payment Saved / Send Money")* | 13 |
| SCR-054 | Payment Status (Business Owner) *(Retired)* | 13 |
| SCR-055 | Thank You / Support (Business Owner) *(added)* | 13 |

Every Module (1–13) is represented; every screen named in your Screen Inventory request (Authentication, Dashboard, Customer, Debt, Credit & Risk, Recovery Workflow, Payments, Collection Cases, Documents, Reports, Notifications, Calendar, Global Search, Administration, Settings, Audit Trail, Profile, Account) is present above. Professional Collection Requests (Module 7, reopened) is integrated as one new screen (SCR-049) plus amendments to three existing screens (SCR-005, SCR-006, SCR-025) rather than a parallel set of new screens — consistent with the instruction to reuse the existing UX pattern set rather than assume new surfaces are required. Subscription & Storage Self-Service (Module 13, catch-up) is integrated as two new screens (SCR-050, SCR-051) plus an amendment to SCR-046 (Account menu entry point) — both new screens reuse the existing single-column Form/List pattern and the bottom-sheet Form pattern already established elsewhere in this document (§6), not a new interaction model.

---

## 10. Screen Specifications

### SCR-001 — Login
- **Purpose:** Authenticate a user before granting access to any module.
- **Users:** All roles.
- **Layout:** Centered single-column form, no Sidebar/Top Bar.
- **Sections:** Logo/Company mark placeholder, identifier field, credential field, "Forgot Password" link, Submit button.
- **Displayed Data:** None (pre-authentication).
- **Primary Actions:** Log In.
- **Secondary Actions:** Forgot Password (→ SCR-002).
- **Validation:** Both fields required; inline error on blur if empty; submit-time error if credentials invalid (generic message, no indication of which field is wrong, per security best practice deferred to `08_Security_and_RBAC.md`).
- **Empty State:** N/A.
- **Loading State:** Submit button shows Loading Spinner; fields disabled during request.
- **Error State:** Inline error banner above the form ("Invalid identifier or password").
- **Permission Behavior:** N/A (pre-authentication); successful login routes to SCR-005 or SCR-006 per resolved role.
- **Navigation Entry:** App launch / session expiry (SCR-004) / logout.
- **Navigation Exit:** Dashboard (SCR-005/006) on success.
- **Related Functional Requirements:** FR-001, FR-006.

### SCR-002 — Forgot Password
- **Purpose:** Initiate credential recovery.
- **Users:** All roles.
- **Layout:** Centered single-column form.
- **Sections:** Identifier field, explanatory text, Submit, Back to Login link.
- **Displayed Data:** None.
- **Primary Actions:** Send Reset Link.
- **Secondary Actions:** Back to Login (→ SCR-001).
- **Validation:** Identifier required.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Generic confirmation is shown regardless of whether the identifier matches an account (security best practice); true delivery failure shows the Module 1 FR-004 (E1) "contact an administrator" message.
- **Permission Behavior:** N/A (pre-authentication).
- **Navigation Entry:** SCR-001.
- **Navigation Exit:** Confirmation state (same screen) or SCR-003 via emailed/SMS'd link.
- **Related Functional Requirements:** FR-004.

### SCR-003 — Reset Password
- **Purpose:** Complete credential recovery with a valid token.
- **Users:** All roles.
- **Layout:** Centered single-column form.
- **Sections:** New credential field, confirm-credential field, Submit.
- **Displayed Data:** None.
- **Primary Actions:** Reset Password.
- **Secondary Actions:** None.
- **Validation:** Both fields required and must match; submit-time rejection if token expired/used (FR-004, A1), with a link to request a new one (→ SCR-002).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline banner for expired/invalid token.
- **Permission Behavior:** Token-gated, not role-gated.
- **Navigation Entry:** Link from recovery-channel message (FR-004).
- **Navigation Exit:** SCR-001 on success (must log in with new credential).
- **Related Functional Requirements:** FR-004.

### SCR-004 — Session Expired Interstitial
- **Purpose:** Inform the user their session ended and route them to re-authenticate without losing context unnecessarily.
- **Users:** All roles.
- **Layout:** Centered message + Primary action, replacing the current view.
- **Sections:** Message, "Log In Again" button.
- **Displayed Data:** None.
- **Primary Actions:** Log In Again (→ SCR-001).
- **Secondary Actions:** None.
- **Validation:** N/A.
- **Empty State:** N/A.
- **Loading State:** N/A.
- **Error State:** N/A.
- **Permission Behavior:** N/A.
- **Navigation Entry:** Any authenticated screen, on session expiry (FR-003) — including mid-action (FR-003, A2), where the in-progress action is discarded per Business Rule BRL-009.
- **Navigation Exit:** SCR-001.
- **Related Functional Requirements:** FR-003.

### SCR-005 — Dashboard (Customer Mobile App)
- **Purpose:** Give the Business Owner an at-a-glance operational summary and fast entry points into daily work.
- **Users:** Business Owner.
- **Layout:** Mobile-first single column: Top Bar (Search, Notification Bell, Avatar) → KPI Cards → Quick Actions → (Aging summary widget) → **Professional Collection Requests widget** *(added)* → Bottom Tab Bar.
- **Sections:** KPI Cards (§8), Quick Actions (§8), Aging Analysis widget (drill-through to SCR-033), Customers Over Credit Limit widget (drill-through to SCR-007, filtered), **Professional Collection Requests widget** *(added, §8)* — Card + compact Table (Case, Status chip, Submitted Date), drill-through to that Case's Deendoon Hand-off tab (SCR-025).
- **Displayed Data:** Tenant-scoped KPIs (SM-001–006), Aging bucket summary, the tenant's own Professional Collection Requests (FR-074).
- **Primary Actions:** Quick Actions (Add Debt, Receive Payment, Send WhatsApp, Call Customer, Generate Receipt, Generate Statement).
- **Secondary Actions:** Drill-through from any KPI/widget to its detail (SCR-033, SCR-007, SCR-034, SCR-025).
- **Validation:** N/A (read-only screen).
- **Empty State:** New tenant with no Customers/Debts yet — Empty State prompting "Add your first Customer" (→ SCR-009). Professional Collection Requests widget: "No cases submitted to Deendoon yet" (no action — submission happens from SCR-025, not here).
- **Loading State:** Skeleton Loader cards while KPIs compute.
- **Error State:** Error State per KPI card if that metric fails to load, isolated so one failure doesn't block the rest of the dashboard.
- **Permission Behavior:** Not applicable — Version 1 has exactly one tenant-side role (Business Owner); no Quick Action is hidden or disabled by role within a tenant.
- **Navigation Entry:** Login (SCR-001), Tab Bar "Dashboard".
- **Navigation Exit:** Any module via Quick Actions, Tab Bar, or widget drill-through.
- **Related Functional Requirements:** FR-053, FR-054, FR-055, FR-065, FR-074.

### SCR-006 — Dashboard (Super Admin Web Panel)
- **Purpose:** Give platform/administrative users a system-wide operational summary.
- **Users:** Platform Administrator, Super Admin.
- **Layout:** Desktop-first: Sidebar + Top Bar → KPI Cards grid → Aging/Reports widgets → **Pending Professional Collection Requests card** *(added)*.
- **Sections:** Same KPI set as SCR-005, scoped system-wide rather than per-tenant, per Module 9 FR-053. **Pending Professional Collection Requests card** *(added, §8)* — a single summary Card showing the count of Requests not yet in a terminal state, drill-through to SCR-049.
- **Displayed Data:** System-wide KPIs (SM-001–006), pending Professional Collection Request count.
- **Primary Actions:** Drill-through to Reports (SCR-034), Administration (SCR-039–045), Professional Collection Requests (SCR-049).
- **Secondary Actions:** Export (→ SCR-035).
- **Validation:** N/A.
- **Empty State:** N/A at platform level (assumes at least one tenant exists). Pending Requests card shows "0" plainly rather than an Empty State treatment (it's a count, not a list).
- **Loading State:** Skeleton Loader cards.
- **Error State:** Per-card Error State, isolated.
- **Permission Behavior:** Full visibility restricted to Super Admin/Platform Administrator roles per `08_Security_and_RBAC.md`.
- **Navigation Entry:** Login (SCR-001), Sidebar "Dashboard".
- **Navigation Exit:** Sidebar to any Administration screen, or to SCR-049.
- **Related Functional Requirements:** FR-053, FR-054, FR-055, FR-073.

### SCR-007 — Customer List
- **Purpose:** Browse, search, and filter Customers; entry point to Customer Details and Create.
- **Users:** All roles with Customer view permission.
- **Layout:** Table Layout (desktop/tablet) / stacked Card list (mobile), per §9.
- **Sections:** Search Box, Filter control (Customer Status, Risk Level, Credit Score range), Table/Card list, Pagination.
- **Displayed Data:** Name, phone, Customer Status chip, Credit Limit, Outstanding Balance, Risk Level chip.
- **Primary Actions:** Add Customer (→ SCR-009).
- **Secondary Actions:** Row action menu: View, Edit, Archive, Restore (if Archived and included in view), Import (→ SCR-012).
- **Validation:** N/A (list screen).
- **Empty State:** "No customers yet — Add Customer" (new tenant) vs. "No customers match these filters" (filtered).
- **Loading State:** Skeleton table rows / skeleton cards.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Not applicable — Version 1 has exactly one tenant-side role (Business Owner); no row action is hidden by role within a tenant.
- **Navigation Entry:** Primary Navigation "Customers"; Global Search result; Dashboard widget drill-through.
- **Navigation Exit:** SCR-008 (row click), SCR-009, SCR-012.
- **Related Functional Requirements:** FR-015, FR-010, FR-011.

### SCR-008 — Customer Details
- **Purpose:** Full Customer profile: identity, Credit Profile, Risk, Status, related Debts and Documents.
- **Users:** All roles with Customer view permission (fields vary by role, per FR-008 A1).
- **Layout:** Header (name, Status chip) + Tabs: Profile / Debts / Documents.
- **Sections:** Credit & Risk Panel (SCR-018, embedded), Debts tab (→ SCR-013 scoped to this Customer), Documents tab (→ SCR-030 scoped). **(Corrected, SRS Final Alignment)** removed the Notes tab — the Customer entity carries no Notes field in the final implemented product (unlike Debt and Collection Case, which do; BR-022).
- **Displayed Data:** Name, phone, Customer Status, Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, Credit Score.
- **Primary Actions:** Edit (→ SCR-010), Add Debt (→ SCR-015), Generate Statement (→ SCR-032).
- **Secondary Actions:** Archive (→ SCR-011), Generate Demand Letter (→ SCR-031, if an active Debt exists), Change Customer Status (inline control).
- **Validation:** Customer Status change validated against the approved 7-value set (inline Dropdown, §5).
- **Empty State:** Debts tab: "No debts yet — Add Debt." Documents tab: "No documents yet."
- **Loading State:** Skeleton for header + tab content independently.
- **Error State:** Error State with Retry, scoped per tab.
- **Permission Behavior:** Archived Customer shown read-only with a "Restore" Primary action replacing Edit (per FR-008, BR-032).
- **Navigation Entry:** SCR-007 row click, Global Search, Notification, Debt Details breadcrumb.
- **Navigation Exit:** SCR-010, SCR-011, SCR-013 (scoped), SCR-015, SCR-030 (scoped), SCR-031, SCR-032.
- **Related Functional Requirements:** FR-008, FR-012, FR-013.

### SCR-009 — Customer Create
- **Purpose:** Create a new Customer record.
- **Users:** Roles with Customer create permission.
- **Layout:** Single-column form, max content width per §3.
- **Sections:** Identity fields (name, phone), optional Credit Limit field, Submit/Cancel Action Bar.
- **Displayed Data:** N/A (empty form).
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Name and phone required; Credit Limit optional, numeric, non-negative (per BRL-012); Duplicate Detection modal interrupts submission when a likely match is found (FR-014), offering "Open Existing Customer" or "Continue Anyway."
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline field errors; Error Summary if > 3 fields invalid.
- **Permission Behavior:** Screen not reachable for roles without create permission (action hidden at SCR-007).
- **Navigation Entry:** SCR-007 "Add Customer," SCR-012 (Import as New per-row).
- **Navigation Exit:** SCR-008 (new record) on save; SCR-007 on cancel.
- **Related Functional Requirements:** FR-007, FR-014.

### SCR-010 — Customer Edit
- **Purpose:** Update an existing Customer's details.
- **Users:** Roles with Customer edit permission.
- **Layout:** Same as SCR-009, pre-populated.
- **Sections:** Same fields as Create, plus read-only Outstanding Balance display (§6, read-only state) since it is maintained exclusively by Modules 3/6.
- **Displayed Data:** Current Customer field values.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Same as Create; re-runs Duplicate Detection only if name/phone changed (FR-009).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline field errors.
- **Permission Behavior:** Not reachable for Archived Customers (must Restore first, SCR-008).
- **Navigation Entry:** SCR-008 "Edit."
- **Navigation Exit:** SCR-008 on save/cancel.
- **Related Functional Requirements:** FR-009, FR-013 (Credit Limit field), FR-014.

### SCR-011 — Customer Archive Confirmation
- **Purpose:** Confirm an irreversible-feeling (though recoverable) Archive action.
- **Users:** Roles with Customer archive permission.
- **Layout:** Confirmation Dialog (§5).
- **Sections:** Consequence message ("This customer will be archived and removed from default lists. It can be restored later."), Confirm/Cancel.
- **Displayed Data:** Customer name.
- **Primary Actions:** Archive (destructive-styled).
- **Secondary Actions:** Cancel.
- **Validation:** None.
- **Empty State:** N/A.
- **Loading State:** Confirm button Loading Spinner.
- **Error State:** Toast on failure.
- **Permission Behavior:** Dialog only reachable via SCR-008's Archive action, already permission-gated.
- **Navigation Entry:** SCR-008.
- **Navigation Exit:** SCR-007 (list) or SCR-008 (now read-only/restore-eligible) on confirm; dismiss returns to SCR-008.
- **Related Functional Requirements:** FR-010.

### SCR-012 — Customer Import
- **Purpose:** Bulk-create/update Customers from an Excel file.
- **Users:** Roles with Import permission.
- **Layout:** Multi-step wizard with a Progress Indicator: Upload → Preview → Resolve Duplicates → Confirm.
- **Sections:** Step 1 File Upload (component §5); Step 2 Preview table (parsed rows, validation flags); Step 3 per-row duplicate resolution (Skip Duplicate / Update Existing / Import as New); Step 4 summary + Confirm.
- **Displayed Data:** Parsed row data, per-row validation status, per-row duplicate-match status.
- **Primary Actions:** Next (per step), Confirm Import (final step).
- **Secondary Actions:** Cancel (any step, discards without confirmation prompt unless past Step 2).
- **Validation:** Per-row field validation shown in the Preview table; unsupported file format rejected before Preview (FR-016, E1).
- **Empty State:** N/A.
- **Loading State:** Progress Indicator during parse and during commit.
- **Error State:** File-level error banner (unsupported format); row-level error flags in Preview table.
- **Permission Behavior:** Screen not reachable without Import permission.
- **Navigation Entry:** SCR-007 "Import."
- **Navigation Exit:** SCR-007 (filtered to newly imported records) on success.
- **Related Functional Requirements:** FR-016, FR-014.

### SCR-013 — Debt List
- **Purpose:** Browse Debts, globally or scoped to a Customer.
- **Users:** All roles with Debt view permission.
- **Layout:** Table (desktop/tablet) / Card list (mobile), per §9.
- **Sections:** Search/Filter (Debt Status, Recovery Stage, Date Range, Outstanding Amount), Table, Pagination.
- **Displayed Data:** Debt reference (`DBT-000001`), Customer name (global view), amount, due date, Debt Status chip, Recovery Stage chip.
- **Primary Actions:** Add Debt (→ SCR-015).
- **Secondary Actions:** Row menu: View, Edit, Archive.
- **Validation:** N/A.
- **Empty State:** "No debts yet" / "No debts match these filters."
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Actions hidden per role.
- **Navigation Entry:** Primary Navigation "Debts"; Customer Details "Debts" tab (scoped).
- **Navigation Exit:** SCR-014, SCR-015, SCR-016.
- **Related Functional Requirements:** FR-021 (display), Module 11 FR-064 (filtering).

### SCR-014 — Debt Details
- **Purpose:** Full Debt record: financial state, Recovery Stage/Timeline, related Payments and Documents.
- **Users:** All roles with Debt view permission.
- **Layout:** Header (Debt reference, amount, Debt Status chip, Recovery Stage chip) + Tabs: Details / Timeline / Payments / Follow-up History.
- **Sections:** Recovery Timeline (Timeline component, §5, read-only), Recovery Stage display + Override control, Credit Limit Soft Warning history (if applicable), Payments tab (→ SCR-023), Follow-up History tab (→ SCR-021).
- **Displayed Data:** Amount, due date, Debt Status, Recovery Stage, Remaining Balance, linked Customer, Notes (free-text, BR-022).
- **Primary Actions:** Receive Payment (→ SCR-022), Edit (→ SCR-016).
- **Secondary Actions:** Archive (→ SCR-017), Send WhatsApp/SMS/Call (→ SCR-019), Record Promise to Pay (→ SCR-020), Generate Demand Letter (→ SCR-031), Override Recovery Stage (inline Confirmation Dialog with mandatory Reason field).
- **Validation:** Recovery Stage Override requires a non-empty Reason (BR-015).
- **Empty State:** Timeline: stages not yet reached shown as pending/greyed, not an "empty" screen state.
- **Loading State:** Skeleton per section.
- **Error State:** Error State with Retry, scoped per tab.
- **Permission Behavior:** Override control hidden for roles without override permission; Archived Debt shown read-only with "Restore" replacing Edit.
- **Navigation Entry:** SCR-013 row click, Customer Details "Debts" tab, Notification, Calendar entry, Global Search.
- **Navigation Exit:** SCR-016, SCR-017, SCR-019, SCR-020, SCR-022, SCR-031.
- **Related Functional Requirements:** FR-019, FR-020, FR-021, FR-024, FR-025.

### SCR-015 — Debt Create
- **Purpose:** Create a new Debt against a Customer.
- **Users:** Roles with Debt create permission.
- **Layout:** Single-column form; Customer pre-selected if entered from Customer Details, otherwise an Autocomplete Customer picker.
- **Sections:** Customer picker (if not pre-selected), amount (Currency Input), due date (Date Picker), notes, Submit/Cancel.
- **Displayed Data:** If Customer pre-selected: name, current Credit Limit/Outstanding Balance shown for context.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Amount required, positive; due date required, valid; Credit Limit Soft Warning modal (Confirmation-Dialog-style, "Continue Anyway" / "Cancel") interrupts submission when the approved threshold is exceeded (FR-018) — never a hard block.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline field errors.
- **Permission Behavior:** Screen not reachable without create permission; referenced Customer must not be Archived (FR-017, E3).
- **Navigation Entry:** SCR-013 "Add Debt," SCR-008 "Add Debt," Dashboard Quick Action.
- **Navigation Exit:** SCR-014 (new record) on save; prior screen on cancel.
- **Related Functional Requirements:** FR-017, FR-018.

### SCR-016 — Debt Edit
- **Purpose:** Update a Debt's non-financial details.
- **Users:** Roles with Debt edit permission.
- **Layout:** Same as SCR-015, pre-populated; amount/financial fields read-only (owned by Modules 6/BRL-022) except where BRL-020's default-status question is resolved to permit early correction.
- **Sections:** Due date, notes; Debt Status manual controls (Cancelled/Written Off) shown only to authorized roles (per BRL-021).
- **Displayed Data:** Current Debt field values.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Due date valid; manual Debt Status transition restricted to the valid transitions in the Debt Status matrix (`04_Business_Rules.md`, BRL-021) — attempting an undefined transition (e.g., forcing Paid) is rejected.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Not reachable for Archived Debts.
- **Navigation Entry:** SCR-014 "Edit."
- **Navigation Exit:** SCR-014 on save/cancel.
- **Related Functional Requirements:** FR-020, FR-021.

### SCR-017 — Debt Archive Confirmation
- **Purpose:** Confirm Debt Archive.
- **Users:** Roles with Debt archive permission.
- **Layout:** Confirmation Dialog.
- **Sections:** Consequence message, Confirm/Cancel.
- **Displayed Data:** Debt reference, amount.
- **Primary Actions:** Archive.
- **Secondary Actions:** Cancel.
- **Validation:** None.
- **Empty State:** N/A.
- **Loading State:** Confirm button Loading Spinner.
- **Error State:** Toast on failure.
- **Permission Behavior:** Gated by SCR-014's Archive action.
- **Navigation Entry:** SCR-014.
- **Navigation Exit:** SCR-013 or SCR-014 (read-only/restore-eligible).
- **Related Functional Requirements:** FR-022.

### SCR-018 — Credit & Risk Panel
- **Purpose:** Display and (where permitted) maintain a Customer's Credit Limit, Outstanding Balance, Remaining Credit, Risk Level, and Credit Score in one place.
- **Users:** All roles with Customer view permission (edit controls gated further).
- **Layout:** Embedded panel within SCR-008 (Customer Details), not a standalone route.
- **Sections:** Credit Limit (editable inline for authorized roles), Outstanding Balance (read-only), Remaining Credit (computed, read-only), Risk Level (editable Dropdown for authorized roles), Credit Score (read-only, system-computed) with band Status Chip.
- **Displayed Data:** Values per BRL-017, BRL-022, BRL-026 (Module 4).
- **Primary Actions:** Edit Credit Limit (inline), Edit Risk Level (inline).
- **Secondary Actions:** None.
- **Validation:** Credit Limit non-negative numeric (FR-013, E2); Risk Level restricted to the approved value set once confirmed (`04_Business_Rules.md`, DD-010).
- **Empty State:** N/A (always shows values, defaults applied per BRL-012).
- **Loading State:** Skeleton within the panel.
- **Error State:** Inline error on failed inline-edit save.
- **Permission Behavior:** Credit Score and Risk Level are never directly editable by the same control (independently maintained, BRL-006).
- **Navigation Entry:** Embedded in SCR-008.
- **Navigation Exit:** N/A (embedded).
- **Related Functional Requirements:** FR-013, FR-026, FR-027, FR-028.

### SCR-019 — Manual Reminder Modal
- **Purpose:** Send a manual WhatsApp/SMS reminder or log a phone call against a Debt.
- **Users:** Roles with manual-reminder permission.
- **Layout:** Modal with a channel selector (tabs: WhatsApp / SMS / Call).
- **Sections:** Channel tabs; WhatsApp/SMS: message preview + Send; Call: outcome notes field + Log Call.
- **Displayed Data:** Customer name/phone context.
- **Primary Actions:** Send (WhatsApp/SMS) / Log Call.
- **Secondary Actions:** Cancel.
- **Validation:** Call outcome notes optional (FR-030, A1 permits logging with no outcome).
- **Empty State:** N/A.
- **Loading State:** Send/Log button Loading Spinner.
- **Error State:** Inline banner on delivery failure (FR-030, E2), logged regardless per Follow-up History.
- **Permission Behavior:** Not reachable without permission.
- **Navigation Entry:** SCR-014 "Send WhatsApp/SMS/Call."
- **Navigation Exit:** SCR-014 on send/log or cancel.
- **Related Functional Requirements:** FR-030.

### SCR-020 — Promise to Pay Modal
- **Purpose:** Record a Customer's commitment to pay by a specific date.
- **Users:** Roles with Promise to Pay permission.
- **Layout:** Modal, single field group.
- **Sections:** Promised Date (Date Picker), optional notes, Submit/Cancel.
- **Displayed Data:** Debt/Customer context.
- **Primary Actions:** Save Promise.
- **Secondary Actions:** Cancel.
- **Validation:** Date required, must be a future date (implementation detail; exact same-day handling deferred where not specified).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Not reachable without permission.
- **Navigation Entry:** SCR-014 "Record Promise to Pay."
- **Navigation Exit:** SCR-014 on save/cancel; the promise also appears on SCR-037 (Calendar).
- **Related Functional Requirements:** FR-031.

### SCR-021 — Follow-up History Tab
- **Purpose:** Show the chronological log of recovery actions on a Debt/Customer.
- **Users:** All roles with view permission.
- **Layout:** Activity Feed component within SCR-014/SCR-008.
- **Sections:** Reverse-chronological entries (reminders, calls, promises, escalations).
- **Displayed Data:** Action type, timestamp, initiating user ("System" for automated).
- **Primary Actions:** None (read-only).
- **Secondary Actions:** None.
- **Validation:** N/A.
- **Empty State:** "No follow-up activity yet."
- **Loading State:** Skeleton feed entries.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Read-only for all roles with view access.
- **Navigation Entry:** Embedded tab in SCR-014/SCR-008.
- **Navigation Exit:** N/A (embedded).
- **Related Functional Requirements:** FR-033.

### SCR-022 — Receive Payment Modal
- **Purpose:** Record a full or partial payment against a Debt.
- **Users:** Roles with payment-recording permission.
- **Layout:** Modal, single field group.
- **Sections:** Amount (Currency Input), Date (Date Picker, defaults today), reference notes, Submit/Cancel.
- **Displayed Data:** Debt remaining balance shown for context.
- **Primary Actions:** Record Payment.
- **Secondary Actions:** Cancel.
- **Validation:** Amount required, positive numeric; overpayment handling per pending Business Rule (`04_Business_Rules.md`, DD-016) — UI shows a warning banner if amount exceeds remaining balance, pending that decision, but does not block submission ahead of the Business Rule being finalized.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Not reachable without permission; not reachable against an Archived Debt (must Restore first).
- **Navigation Entry:** SCR-014 "Receive Payment," Dashboard Quick Action.
- **Navigation Exit:** SCR-014 on save (Debt Status/Balance updated); a Toast confirms Receipt generation is in progress (→ SCR-029 once available).
- **Related Functional Requirements:** FR-034, FR-036, FR-037.

### SCR-023 — Payment History Tab
- **Purpose:** Show a Debt's or Customer's chronological payment history.
- **Users:** All roles with view permission.
- **Layout:** Table/Activity Feed within SCR-014/SCR-008.
- **Sections:** Chronological list: amount, date, reference.
- **Displayed Data:** Payment records.
- **Primary Actions:** None (read-only in Version 1 — see `04_Business_Rules.md` BRL-042, payment correction unresolved).
- **Secondary Actions:** View linked Receipt (→ SCR-029).
- **Validation:** N/A.
- **Empty State:** "No payments recorded yet."
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Read-only for all roles with view access.
- **Navigation Entry:** Embedded tab in SCR-014/SCR-008.
- **Navigation Exit:** SCR-029.
- **Related Functional Requirements:** FR-035.

### SCR-024 — Collection Case List
- **Purpose:** Browse Collection Cases.
- **Users:** Roles with Collection view permission.
- **Layout:** Table (desktop/tablet) / Card list (mobile).
- **Sections:** Search/Filter (Status), Table, Pagination.
- **Displayed Data:** Case reference (`COL-000001`), linked Debt/Customer, status.
- **Primary Actions:** None (cases are created via escalation, not manually from this list, per FR-040 — a manual-escalation entry point appears on SCR-014 instead, pending DD-014).
- **Secondary Actions:** Row menu: View.
- **Validation:** N/A.
- **Empty State:** "No collection cases yet."
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Not applicable — Version 1 has exactly one tenant-side role (Business Owner), who sees all Collection Cases for their own tenant.
- **Navigation Entry:** Primary Navigation "Collection Cases."
- **Navigation Exit:** SCR-025.
- **Related Functional Requirements:** FR-042.

### SCR-025 — Collection Case Details
- **Purpose:** Full Collection Case record: linked Debt, activity, closure, and (as of this update) its Deendoon hand-off status.
- **Users:** Business Owner.
- **Layout:** Header (Case reference, status chip) + Tabs: Details / Activity / History / **Deendoon Hand-off** *(added)*.
- **Sections:** Linked Debt summary (→ SCR-014), Notes (free-text, BR-022), Activity log (Activity Feed). **Deendoon Hand-off tab** *(added)*: if no Request has been submitted, a single explanatory line plus a "Submit Case to Deendoon" action; if a Request exists, its Status Chip (Professional Collection Request Status, §5), its Reasons for Transfer, Requested Services, Notes, and Client Declaration acceptance record, plus the shared Conversation Thread component (§5).
- **Displayed Data:** Per FR-042. Deendoon Hand-off tab additionally shows the linked Request's Reasons, Requested Services, Notes, Declaration acceptance record, status, and message history, per FR-072/FR-073/FR-074/FR-075.
- **Primary Actions:** Record Activity (→ SCR-027), Close Case (→ SCR-028).
- **Secondary Actions:** Generate Demand Letter (→ SCR-031), **Submit Case to Deendoon** *(added, Deendoon Hand-off tab only, shown only when the Case has no active Request)*.
- **Validation:** N/A (view screen); actions validated in their own modals. Submit Case to Deendoon is confirmed via a Form (§5) — **(amended, Product Owner-approved, final implemented behavior)** at least one Reason for Transfer (multi-select) and at least one Requested Service (multi-select), both Reference Data-backed, are required; free-text Notes are optional; the Client Declaration checkbox must be accepted before the Submit action is enabled (FR-072, BRL-078).
- **Empty State:** Activity tab: "No activity recorded yet." Deendoon Hand-off tab: "This case hasn't been submitted to Deendoon" (with the Submit action).
- **Loading State:** Skeleton per section.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Record Activity/Close hidden once Case is Closed, pending reopening decision (`04_Business_Rules.md`, DD-025). Submit Case to Deendoon hidden once an active Request already exists (FR-072, A1).
- **Navigation Entry:** SCR-024 row click, SCR-014 (linked case), Notification.
- **Navigation Exit:** SCR-014, SCR-027, SCR-028, SCR-031.
- **Related Functional Requirements:** FR-042, FR-043, FR-046, FR-072, FR-074, FR-075.

### SCR-026 — Collection Case Assignment Modal

> **Retired (RBAC Architecture Amendment, Product Owner Decision, 2026-07-31).** FR-041 (Collection Case Assignment) was retired in `03_Functional_Requirements.md` v1.8 — Version 1 has exactly one account per tenant (the Business Owner), so there is no second tenant user to assign a Case to, and Collection Officer is no longer a tenant-side role. This screen is preserved below for history, not deleted, per this project's Documentation Rules; it does not correspond to any implemented screen.

- **Purpose:** Assign/reassign a Collection Officer to a Case.
- **Users:** Roles with assignment permission.
- **Layout:** Modal, single field.
- **Sections:** Collection Officer Autocomplete picker, Submit/Cancel.
- **Displayed Data:** Currently assigned Officer, if any.
- **Primary Actions:** Assign.
- **Secondary Actions:** Cancel.
- **Validation:** Selected user must hold the Collection Officer role (FR-041, E2).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline error.
- **Permission Behavior:** Not reachable without permission.
- **Navigation Entry:** SCR-024, SCR-025.
- **Navigation Exit:** SCR-025 on save/cancel.
- **Related Functional Requirements:** FR-041.

### SCR-027 — Collection Activity Modal
- **Purpose:** Log a collection activity against a Case.
- **Users:** Roles with activity-recording permission.
- **Layout:** Modal, single field group.
- **Sections:** Activity type/notes field, Submit/Cancel.
- **Displayed Data:** Case context.
- **Primary Actions:** Log Activity.
- **Secondary Actions:** Cancel.
- **Validation:** Notes required (minimum content); rejected if the Case is Closed (FR-044, E2).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Not reachable without permission.
- **Navigation Entry:** SCR-025 "Record Activity."
- **Navigation Exit:** SCR-025 on save/cancel.
- **Related Functional Requirements:** FR-044.

### SCR-028 — Collection Case Closure Modal
- **Purpose:** Close a Collection Case with a recorded outcome.
- **Users:** Roles with closure permission.
- **Layout:** Modal, single field.
- **Sections:** Outcome selector (Dropdown/Radio, value set pending `04_Business_Rules.md` DD-024), Submit/Cancel.
- **Displayed Data:** Case context.
- **Primary Actions:** Close Case.
- **Secondary Actions:** Cancel.
- **Validation:** Outcome required.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Not reachable without permission; not reachable on an already-Closed Case (FR-045, E2).
- **Navigation Entry:** SCR-025 "Close Case."
- **Navigation Exit:** SCR-025 (now read-only/reopen-eligible pending DD-025) on save/cancel.
- **Related Functional Requirements:** FR-045.

### SCR-029 — Document Viewer
- **Purpose:** View a generated Receipt, Demand Letter, or Statement.
- **Users:** Roles with document view permission.
- **Layout:** Full-screen (mobile) / centered viewer (desktop) with embedded PDF rendering.
- **Sections:** Document render area, Download action.
- **Displayed Data:** Document content, its Auto Numbering ID, generation date.
- **Primary Actions:** Download (→ file, per FR-051).
- **Secondary Actions:** Close (returns to origin screen).
- **Validation:** N/A.
- **Empty State:** N/A.
- **Loading State:** Skeleton/Spinner while document renders.
- **Error State:** Error State ("Document could not be loaded") with Retry.
- **Permission Behavior:** Not reachable without permission (FR-050, E1).
- **Navigation Entry:** SCR-023, SCR-030, Notification (Document Available).
- **Navigation Exit:** Origin screen on Close.
- **Related Functional Requirements:** FR-050, FR-051.

### SCR-030 — Document List / History Tab
- **Purpose:** Show all documents generated for a Customer/Debt.
- **Users:** Roles with document view permission.
- **Layout:** Table/list within SCR-008/SCR-014.
- **Sections:** Document type, reference ID, generated date, lifecycle events (Generated/Downloaded/Regenerated, per BRL-057).
- **Displayed Data:** Per FR-052.
- **Primary Actions:** View (→ SCR-029).
- **Secondary Actions:** None.
- **Validation:** N/A.
- **Empty State:** "No documents generated yet."
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Read-only for all roles with view access.
- **Navigation Entry:** Embedded tab in SCR-008/SCR-014.
- **Navigation Exit:** SCR-029.
- **Related Functional Requirements:** FR-052.

### SCR-031 — Generate Demand Letter Modal
- **Purpose:** Generate a Demand Letter against a Debt, selecting one of the four approved templates.
- **Users:** Roles with document-generation permission.
- **Layout:** Modal, single selector.
- **Sections:** Template selector (First Reminder / Second Reminder / Final Demand / Legal Notice — Radio group), preview, Generate/Cancel.
- **Displayed Data:** Debt/Customer context; template preview reflecting current Company branding (BRL-054).
- **Primary Actions:** Generate.
- **Secondary Actions:** Cancel.
- **Validation:** Template selection required (explicit per template selection, BRL-055 — no auto-selection).
- **Empty State:** N/A.
- **Loading State:** Generate button Loading Spinner.
- **Error State:** Inline error on generation failure.
- **Permission Behavior:** Not reachable without permission; not reachable for an Archived Debt.
- **Navigation Entry:** SCR-008, SCR-014, SCR-025.
- **Navigation Exit:** SCR-029 (view generated document) on success.
- **Related Functional Requirements:** FR-048.

### SCR-032 — Generate Statement Modal
- **Purpose:** Generate a Customer Statement of Account.
- **Users:** Roles with document-generation permission.
- **Layout:** Modal, minimal confirmation.
- **Sections:** Scope confirmation (full Customer account vs. this Debt only, pending `04_Business_Rules.md` DD scope decision for the Debt-Details entry point), Generate/Cancel.
- **Displayed Data:** Customer/Debt context.
- **Primary Actions:** Generate.
- **Secondary Actions:** Cancel.
- **Validation:** None beyond permission.
- **Empty State:** N/A.
- **Loading State:** Generate button Loading Spinner.
- **Error State:** Inline error on failure.
- **Permission Behavior:** Not reachable without permission.
- **Navigation Entry:** SCR-008, SCR-014.
- **Navigation Exit:** SCR-029 on success.
- **Related Functional Requirements:** FR-049.

### SCR-033 — Aging Analysis Report
- **Purpose:** Show receivables categorized by days-overdue.
- **Users:** Roles with reporting view permission.
- **Layout:** Desktop-first: filter bar + Chart Placeholder (pie + bar) + detail table.
- **Sections:** Bucket summary (Current/1-30/31-60/61-90/Over 90), pie chart, bar chart, full filterable table.
- **Displayed Data:** Bucket totals and per-Debt detail, per BRL-060.
- **Primary Actions:** Export (→ SCR-035).
- **Secondary Actions:** Filter (Drawer), drill-through from a bucket to SCR-013 filtered to that bucket.
- **Validation:** N/A.
- **Empty State:** "No outstanding debts" (zero-state, all buckets empty).
- **Loading State:** Skeleton charts/table.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Scoped to what the role may report on.
- **Navigation Entry:** Dashboard widget, Primary Navigation "Reports."
- **Navigation Exit:** SCR-013 (filtered), SCR-035.
- **Related Functional Requirements:** FR-054, FR-056.

### SCR-034 — Standard Reports Screen
- **Purpose:** Read-only reports over Customer, Debt, Collection, Payment, and Credit Risk data.
- **Users:** Roles with reporting view permission.
- **Layout:** Tabbed report categories + filterable table per category.
- **Sections:** Category tabs (Customer / Debt / Collection / Payment / Credit Risk), Filter bar, Table.
- **Displayed Data:** Existing entity data per category, read-only (BRL-063).
- **Primary Actions:** Export (→ SCR-035).
- **Secondary Actions:** Filter (Drawer), drill-through to the underlying record's detail screen.
- **Validation:** N/A.
- **Empty State:** "No records match these filters."
- **Loading State:** Skeleton table.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Categories a role cannot view are hidden, not merely disabled (FR-055, E1).
- **Navigation Entry:** Primary Navigation "Reports."
- **Navigation Exit:** SCR-008, SCR-014, SCR-025, SCR-023, SCR-035.
- **Related Functional Requirements:** FR-055, FR-056.

### SCR-035 — Report Export Modal
- **Purpose:** Export the currently viewed report/table.
- **Users:** Roles with export permission.
- **Layout:** Small modal.
- **Sections:** Format selector (PDF / Excel / CSV), Export/Cancel.
- **Displayed Data:** Confirmation of scope ("Exporting N records with current filters applied").
- **Primary Actions:** Export.
- **Secondary Actions:** Cancel.
- **Validation:** Format selection required.
- **Empty State:** N/A.
- **Loading State:** Export button Loading Spinner; Progress Indicator for large exports.
- **Error State:** Inline error; size-limit rejection per `09_Non_Functional_Requirements.md` (not a Business Rule, per BRL-062).
- **Permission Behavior:** Not reachable without export permission.
- **Navigation Entry:** SCR-033, SCR-034.
- **Navigation Exit:** File download; modal closes on success.
- **Related Functional Requirements:** FR-057.

### SCR-036 — Notification Center
- **Purpose:** Display in-app notifications of business events.
- **Users:** All authenticated roles.
- **Layout:** Drawer (desktop, from Top Bar bell) / full screen (mobile).
- **Sections:** Type filter, Mark All as Read, reverse-chronological notification list.
- **Displayed Data:** Notification type, related entity summary, timestamp, read/unread state.
- **Primary Actions:** Mark All as Read.
- **Secondary Actions:** Mark individual Read, tap-through to the related entity (Debt, Payment, Document, Collection Case).
- **Validation:** N/A.
- **Empty State:** "No notifications yet."
- **Loading State:** Skeleton list.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Only shows notifications for entities the user's role permits viewing (FR-058, E1).
- **Navigation Entry:** Top Bar Notification Bell (any screen).
- **Navigation Exit:** Related entity's detail screen; History view (same screen, "show read" toggle).
- **Related Functional Requirements:** FR-058, FR-059, FR-060, FR-061.

### SCR-037 — Calendar View
- **Purpose:** Read-only aggregated view of Due Dates, Promises, Call Reminders, and Collection activity.
- **Users:** All authenticated roles.
- **Layout:** Month/week/day calendar grid (desktop); agenda-style list (mobile).
- **Sections:** Period navigation, entry list per day.
- **Displayed Data:** Due Dates (Module 3), Promise to Pay dates and Call reminders (Module 5), Collection Activities where future-dated (Module 7, pending DD-036).
- **Primary Actions:** None (read-only); tap/click an entry to open its source (Debt, Case).
- **Secondary Actions:** Period navigation (Prev/Next, Today).
- **Validation:** N/A.
- **Empty State:** "Nothing scheduled" for an empty period.
- **Loading State:** Skeleton calendar.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Only shows entries for entities the user's role permits viewing.
- **Navigation Entry:** Primary Navigation "Calendar."
- **Navigation Exit:** SCR-014, SCR-025.
- **Related Functional Requirements:** FR-062.

### SCR-038 — Global Search Results
- **Purpose:** Search across Customers, Debts, Payments, Documents, and Collection Cases.
- **Users:** All authenticated roles.
- **Layout:** Overlay/full-screen results view triggered from the Top Bar Search Box.
- **Sections:** Search input (persistent at top), grouped results by entity type.
- **Displayed Data:** Matching records, grouped, each with enough context to identify it (name, reference ID, status).
- **Primary Actions:** Select a result → navigates to its detail screen.
- **Secondary Actions:** "Include archived" toggle.
- **Validation:** N/A.
- **Empty State:** "No results for '[term]'."
- **Loading State:** Skeleton result groups (debounced as the user types).
- **Error State:** Error State with Retry.
- **Permission Behavior:** Entity types a role cannot view are omitted entirely from results (FR-063, E2), not shown-then-blocked.
- **Navigation Entry:** Top Bar Search Box (any screen), keyboard shortcut (desktop).
- **Navigation Exit:** SCR-008, SCR-014, SCR-023, SCR-029, SCR-025.
- **Related Functional Requirements:** FR-063.

### SCR-039 — User Administration List

> **Amended (RBAC Architecture Amendment, Product Owner Decision, 2026-07-31).** This screen and SCR-040/SCR-041 below describe the deprecated-but-functional `AdminUserController` flow (`03_Functional_Requirements.md` FR-066/FR-067). Version 1 has exactly one tenant-side role (Business Owner) — Role fields, selectors, and validation throughout these three screens now reflect that single value rather than the retired six/seven-role model. Not retired outright, matching FR-067's own "deprecated, left functional" status.

- **Purpose:** Browse and manage user accounts.
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Table (desktop-only screen — Super Admin Web Panel).
- **Sections:** Search, Table (name, identifier, Role, status), Pagination.
- **Displayed Data:** Per FR-066.
- **Primary Actions:** Add User (→ SCR-040).
- **Secondary Actions:** Row menu: Edit, Deactivate, Restore, Change Role (→ SCR-041 scoped).
- **Validation:** N/A.
- **Empty State:** N/A (at least one Super Admin always exists).
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** Sidebar "Administration → Users."
- **Navigation Exit:** SCR-040, SCR-041.
- **Related Functional Requirements:** FR-066.

### SCR-040 — User Create / Edit
- **Purpose:** Create or update a user account.
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Single-column form.
- **Sections:** Name, identifier, initial credential/invitation mechanism (pending `04_Business_Rules.md` DD-037), Role assignment (→ inline or SCR-041).
- **Displayed Data:** Existing values on Edit.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Required fields per BRL-069/BRL-071; Role must be Business Owner (`admin`) — the only approved role (RBAC Architecture Amendment, FR-067).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** SCR-039 "Add User"/"Edit."
- **Navigation Exit:** SCR-039 on save/cancel.
- **Related Functional Requirements:** FR-066, FR-067.

### SCR-041 — Role & Permission Management
- **Purpose:** Assign/change a user's Role.
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Modal or dedicated panel from SCR-039/SCR-040.
- **Sections:** Role selector (one approved role: Business Owner), current-role display.
- **Displayed Data:** Current Role.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Role required; Business Owner (`admin`) is the only approved value — DD-039 (multi-role support) is moot under the one-role model (`04_Business_Rules.md` BRL-071).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline error.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** SCR-039, SCR-040.
- **Navigation Exit:** SCR-039 on save/cancel.
- **Related Functional Requirements:** FR-067.

### SCR-042 — Company Profile & Branding
- **Purpose:** Configure Company Profile fields used on generated documents.
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Single-column form with File Upload for logo.
- **Sections:** Business name, logo (File Upload), address, contact details.
- **Displayed Data:** Current values.
- **Primary Actions:** Save.
- **Secondary Actions:** Cancel.
- **Validation:** Business name required; logo format/size constraints per `05`/`09` (not a Business Rule, BRL-073).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline errors.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** Sidebar "Administration → Company Profile."
- **Navigation Exit:** Same screen (confirmation Toast) on save.
- **Related Functional Requirements:** FR-068.

### SCR-043 — System Preferences
- **Purpose:** Configure Credit Policy, Recovery Policy, Notification Settings, and Document Templates.
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Accordion sections, one per policy group.
- **Sections:** Credit Policy (Default Credit Limit, Credit Limit Reminder, Soft Limit Warning), Recovery Policy (Reminder timing per channel, Professional Collection Threshold), Notification Settings, Document Templates (edit the four Demand Letter templates).
- **Displayed Data:** Current configured values.
- **Primary Actions:** Save (per section or globally).
- **Secondary Actions:** Cancel/Reset section.
- **Validation:** Numeric fields non-negative; invalid values rejected (FR-069, E2); exact ranges pending `04_Business_Rules.md` DD-040.
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner per section.
- **Error State:** Inline errors per section.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** Sidebar "Administration → System Preferences."
- **Navigation Exit:** Same screen on save.
- **Related Functional Requirements:** FR-069.

### SCR-044 — Lookup & Reference Data
- **Purpose:** Manage configurable value sets (Risk Level, Payment Method, Collection closure outcomes, once formally defined).
- **Users:** Super Admin / Platform Administrator.
- **Layout:** Category selector + editable list.
- **Sections:** Category tabs, value list with Add/Edit/Remove per value.
- **Displayed Data:** Current value sets.
- **Primary Actions:** Add Value.
- **Secondary Actions:** Edit, Remove.
- **Validation:** Value required, non-duplicate within category; removing an in-use value shows a warning pending `04_Business_Rules.md` DD-041.
- **Empty State:** "No values defined for this category yet."
- **Loading State:** Skeleton list.
- **Error State:** Inline error.
- **Permission Behavior:** Screen restricted to Super Admin/Platform Administrator.
- **Navigation Entry:** Sidebar "Administration → Lookup & Reference Data."
- **Navigation Exit:** Same screen on save.
- **Related Functional Requirements:** FR-070.

### SCR-045 — Audit Trail Viewer
- **Purpose:** View the immutable Audit Trail.
- **Users:** Roles with audit-view permission.
- **Layout:** Table with filters.
- **Sections:** Filter bar (user, date range, module/entity, action type — per Module 11 architecture), Table.
- **Displayed Data:** User, Timestamp, Action, Entity, Reason (where applicable) — per FR-071.
- **Primary Actions:** None (strictly read-only, no edit/delete affordance anywhere on this screen, per BRL-076).
- **Secondary Actions:** Filter, Export (→ SCR-035, if extended to Audit Trail).
- **Validation:** N/A.
- **Empty State:** "No matching audit entries."
- **Loading State:** Skeleton rows.
- **Error State:** Error State with Retry.
- **Permission Behavior:** Screen restricted per `08_Security_and_RBAC.md`.
- **Navigation Entry:** Sidebar "Administration → Audit Trail."
- **Navigation Exit:** Linked entity's detail screen (e.g., click a Debt reference in an audit row → SCR-014).
- **Related Functional Requirements:** FR-071.

### SCR-046 — My Profile / Account Settings
- **Purpose:** Let a user view their own account and change their password. On the Customer Mobile App, this screen's Avatar-menu entry point also opens onto the Business Owner's broader Account menu — Business Profile, **Subscription** *(added — Module 13)*, Settings, Notifications, About, Bulk Import — of which Change Password/Log Out (below) is one part; the menu itself is not separately specified beyond noting the entry points it exposes.
- **Users:** All authenticated roles.
- **Layout:** Single-column form/panel from the Avatar menu.
- **Sections:** Identity display (read-only), Change Password sub-form (current + new credential), Log Out action. *(Added — Module 13)* On the Customer Mobile App, a **"Subscription"** menu entry (Business Owner only) sits alongside these, navigating to SCR-050.
- **Displayed Data:** User's own name, identifier, assigned Role (read-only — Role change is Administration-only, SCR-041).
- **Primary Actions:** Change Password (Save).
- **Secondary Actions:** Log Out; *(added)* navigate to Subscription (Business Owner only, → SCR-050).
- **Validation:** Current credential must validate; new credential confirmation must match (FR-005, E1).
- **Empty State:** N/A.
- **Loading State:** Submit button Loading Spinner.
- **Error State:** Inline error on mismatch.
- **Permission Behavior:** Always reachable to the authenticated user for their own account only; the Subscription entry is shown only to the Business Owner role.
- **Navigation Entry:** Top Bar Avatar (any screen).
- **Navigation Exit:** Same screen on save; SCR-001 on Log Out; *(added)* SCR-050 on "Subscription."
- **Related Functional Requirements:** FR-002, FR-005; *(added)* FR-077 (Subscription entry point).

### SCR-047 — Permission Denied (Global State)
- **Purpose:** Inform a user their role does not permit the requested view/action, without revealing restricted data.
- **Users:** All roles.
- **Layout:** Centered icon + message, replacing the attempted screen's content area.
- **Sections:** Message, link back to Dashboard.
- **Displayed Data:** None.
- **Primary Actions:** Return to Dashboard.
- **Secondary Actions:** None.
- **Validation:** N/A.
- **Empty State:** N/A (this is itself a state).
- **Loading State:** N/A.
- **Error State:** N/A (this is a distinct state from Error).
- **Permission Behavior:** This is the permission-denied behavior itself, applied wherever an FR's Exceptions specify "action is not available" / "access is denied."
- **Navigation Entry:** Any screen/action attempted without sufficient role permission.
- **Navigation Exit:** Dashboard (SCR-005/006).
- **Related Functional Requirements:** Cross-cutting — every FR with a permission-based Exception.

### SCR-048 — 404 Not Found (Global State)
- **Purpose:** Inform a user that a requested resource does not exist or is inaccessible via deep link.
- **Users:** All roles.
- **Layout:** Centered icon + message.
- **Sections:** Message, link back to Dashboard.
- **Displayed Data:** None.
- **Primary Actions:** Return to Dashboard.
- **Secondary Actions:** None.
- **Validation:** N/A.
- **Empty State:** N/A.
- **Loading State:** N/A.
- **Error State:** N/A (distinct state).
- **Permission Behavior:** Shown instead of Permission Denied when the record genuinely does not exist (vs. exists but is restricted).
- **Navigation Entry:** Invalid/stale deep link.
- **Navigation Exit:** Dashboard (SCR-005/006).
- **Related Functional Requirements:** Cross-cutting.

---

### SCR-049 — Professional Collection Requests (Super Admin) *(added)*
- **Purpose:** The Deendoon Super Admin's single operational surface for reviewing and actioning every tenant's submitted Professional Collection Requests. Reuses the existing Table + Detail Drawer pattern already established for every other list-type screen in this document (e.g., SCR-024/SCR-025's List/Details pairing) rather than introducing a new interaction model.
- **Users:** Deendoon Platform Administrator (Super Admin) only. No other actor exists on the Deendoon side (`01_Project_Overview.md` §1.5).
- **Layout:** Desktop-first Table Layout (main content) + Detail Drawer (§3, "right on desktop for detail-peek") that opens on row selection — the same pattern already defined for peeking at a record without a full navigation change.
- **Sections:** Search/Filter (Status, Date Range), Table (Case reference, tenant business name, Status chip, Submitted Date); Detail Drawer on row select: linked Collection Case/Debt summary (read-only), Status transition control, Conversation Thread (§5), and a closure action once In Progress.
- **Displayed Data:** All Requests platform-wide, per FR-073/FR-074 (Super Admin side). Status transition control offers only the next valid status/statuses per the transition matrix (`04_Business_Rules.md`, BRL-079) — "Assigned" is presented as "Accept & Start Handling," making the accepted-ownership meaning explicit in the UI copy itself rather than relying on the label "Assigned" alone.
- **Primary Actions:** Advance Status (Drawer), Close Request with Outcome (Drawer, once In Progress).
- **Secondary Actions:** Post a message (Conversation Thread, Drawer), Filter, open linked Collection Case (→ SCR-025, tenant's own view).
- **Validation:** Status advancement restricted to valid transitions (FR-073, E1); Close Request requires an outcome selection (FR-076).
- **Empty State:** "No Professional Collection Requests yet."
- **Loading State:** Skeleton table rows; Skeleton Drawer content while a selected Request's detail loads.
- **Error State:** Error State with Retry, scoped to the table or the open Drawer independently.
- **Permission Behavior:** Screen restricted to the Deendoon Platform Administrator (Super Admin) role, per `08_Security_and_RBAC.md`. No other tenant or Deendoon-side role can reach this screen — it is not part of any tenant's Customer Mobile App.
- **Navigation Entry:** Sidebar "Professional Collection Requests" (peer to Administration, not nested under it — §4), SCR-006 "Pending Professional Collection Requests" card.
- **Navigation Exit:** SCR-025 (linked Collection Case, read-only from the Super Admin's perspective — Case data itself remains tenant-owned).
- **Related Functional Requirements:** FR-073, FR-075, FR-076.

---

### SCR-050 — Subscription (Business Owner) *(added — Subscription & Storage Self-Service, Module 13)*
- **Purpose:** The Business Owner's single screen for viewing their tenant's current Subscription, browsing the fixed Plan Catalog, requesting a plan change, and reviewing/cancelling their own Subscription Change Request history.
- **Users:** Business Owner only.
- **Layout:** Single-column screen: summary Card at top, Plan Catalog list/grid below, Change Request history as a scrollable list beneath.
- **Sections:** Current Subscription summary Card (plan name, price, trial/subscription status with end/expiry date if applicable, Customer usage vs. limit, Storage usage vs. effective limit, Analytics availability, read-only-state indicator if applicable, per FR-077); Plan Catalog (five plan Cards: Trial, Free, Small Business, Medium Business, Corporate, each showing price, Customer Limit or "Unlimited," Storage allowance, Analytics included/not, and a "Request This Plan" action, disabled on the tenant's current plan); Change Request History list (requested plan, prior plan, Status Chip, submitted date; a Cancel action on the one Pending entry, if any).
- **Displayed Data:** Per FR-077 (current Subscription, Plan Catalog) and FR-079 (Change Request history).
- **Primary Actions:** Request This Plan (per Plan Catalog Card, → **SCR-052 Payment Information**, Manual Mobile-Money Subscription Payment Flow amendment, Revision History 1.7 → 1.9 — replaces the original single-field bottom sheet cited in earlier revisions of this document, since the now-required Payment Phone (BRL-092) cannot be collected by a Payment-Reference-only Form); Navigate to Storage (→ SCR-051).
- **Secondary Actions:** Cancel (on the one Pending Change Request entry, if any).
- **Validation:** "Request This Plan" disabled on the tenant's current plan (FR-078, E4) and disabled entirely while another Change Request is already Pending (FR-078, E3); Payment Information field validation lives on SCR-052.
- **Empty State:** Change Request History: "No plan change requests yet."
- **Loading State:** Skeleton for the summary Card and Plan Catalog; Skeleton rows for history.
- **Error State:** Error State with Retry (screen-level).
- **Permission Behavior:** Screen restricted to the Business Owner role; not reachable by the Deendoon Platform Administrator (a distinct interface, Section 4).
- **Navigation Entry:** SCR-046 "Subscription" menu tile.
- **Navigation Exit:** SCR-051 (Storage); SCR-052 (Payment Information, on "Request This Plan"); SCR-046 (Back).
- **Related Functional Requirements:** FR-077, FR-078, FR-079.

### SCR-051 — Storage (Business Owner) *(added — Subscription & Storage Self-Service, Module 13)*
- **Purpose:** The Business Owner's screen for viewing Storage usage/allowance, requesting a Storage Add-on, and reviewing/cancelling their own Storage Add-on Request history.
- **Users:** Business Owner only.
- **Layout:** Single-column screen: usage summary Card at top, purchased Add-ons list beneath.
- **Sections:** Storage Overview summary Card (usage in GB, effective allowance in GB, remaining allowance, per FR-080); Purchased Storage Add-ons list (package size, price, Status Chip — Pending/Active/Rejected/Cancelled — start/expiry date where applicable; a Cancel action on the one Pending entry, if any). **Request Storage Add-on bottom sheet** *(embedded modal Form, same pattern as SCR-050's Request Plan Change)*: opened from a "Request Storage Add-on" action — Package selector (10GB/25GB/50GB/100GB, each showing its price, Radio group) and Payment Reference text field (required); Submit/Cancel.
- **Displayed Data:** Per FR-080 (Storage Overview) and FR-082 (Add-on Request history).
- **Primary Actions:** Request Storage Add-on (→ Request Storage Add-on bottom sheet).
- **Secondary Actions:** Cancel (on the one Pending Add-on Request, if any).
- **Validation:** Request Storage Add-on bottom sheet: Package selection and Payment Reference both required (FR-081, E2); "Request Storage Add-on" disabled while another Add-on Request is already Pending (FR-081, E3).
- **Empty State:** Purchased Add-ons list: "No storage add-ons purchased yet."
- **Loading State:** Skeleton for the summary Card; Skeleton rows for the Add-ons list; bottom sheet Submit button Loading Spinner.
- **Error State:** Error State with Retry (screen-level); inline error on bottom sheet submission failure.
- **Permission Behavior:** Screen restricted to the Business Owner role.
- **Navigation Entry:** SCR-050 "Navigate to Storage."
- **Navigation Exit:** SCR-050 (Back).
- **Related Functional Requirements:** FR-080, FR-081, FR-082.

### SCR-052 — Payment Information (Business Owner) *(added — Manual Mobile-Money Subscription Payment Flow, Revision History 1.9)*
- **Purpose:** Collect the mobile-money payment phone number (required) and an optional transaction reference for a Subscription Change Request, with the selected Plan, Amount, and the tenant's own Business Name shown read-only.
- **Users:** Business Owner only.
- **Layout:** Single-column Form screen.
- **Sections:** Read-only summary (Business Name, Selected Plan, Amount — none re-enterable); Payment Phone text field (required); Transaction Reference text field (optional, with helper text noting it may be added later).
- **Displayed Data:** Business Name and current tenant context; the Plan selected on SCR-050 (name, monthly price), per FR-078.
- **Primary Actions:** Continue Payment (→ **SCR-053 Payment Instructions / Send Money**, on success).
- **Secondary Actions:** Back (→ SCR-050, no request created).
- **Validation:** Payment Phone required (FR-078, E2); Transaction Reference has no required-ness validation (optional, BRL-092).
- **Empty State:** Not applicable (a Form screen).
- **Loading State:** Continue Payment button Loading Spinner while the request is submitted.
- **Error State:** Inline error on submission failure (e.g., a pending request already exists, FR-078 E3); screen stays on the Form.
- **Permission Behavior:** Screen restricted to the Business Owner role.
- **Navigation Entry:** SCR-050 "Request This Plan."
- **Navigation Exit:** SCR-053 (Payment Instructions, on success); SCR-050 (Back).
- **Related Functional Requirements:** FR-078.

### SCR-053 — Payment Instructions / Send Money (Business Owner) *(redesigned — Manual Mobile-Money Subscription Payment Flow, Revision History 1.10; third operator added, Revision History 1.11; originally added under Revision History 1.9)*

> **Redesigned 2026-08-20 (Product Owner final UX direction).** The Plan/Amount/Duration summary Card, the generic single "Dir Lacagta" button, the "Payment Status: Pending Verification" notice, and the "View Payment Status" exit are all removed from this screen; replaced by named-operator USSD buttons and a "Done" exit to the new SCR-055. This is the same screen/route as before (Payment Saved and Send Money were always the same step; the name is tightened to match), not a new one. **Amended again, Revision History 1.11:** a third operator button, E-DAHAB, added.

- **Purpose:** Confirm the Subscription Change Request was saved (status Pending), show the Platform Payment Destination Number (FR-086), and let the Business Owner open their device's dialer pre-filled with one of three fixed, Product-Owner-approved USSD codes for the three supported mobile-money operators.
- **Users:** Business Owner only.
- **Layout:** Single-column confirmation screen.
- **Sections:** Success message ("Xogtaada waa la keydiyay." / "Your information has been saved.") and instruction line ("Fadlan lacagta ku dir lambarka Deendoon ee hoose." / "Please send the money to the Deendoon number below."); Platform Payment Destination Number (or an explicit "not set yet" message if the Deendoon Platform Administrator hasn't set one); three fixed-label buttons, **SAALAM BANK**, **EVC PLUS**, and **E-DAHAB**.
- **Displayed Data:** The live Platform Payment Destination Number (FR-086, `GET /subscription/payment-info` — never hardcoded client-side). The three USSD codes themselves are **not** displayed data — they are fixed application constants (BRL-092), not sourced from the backend and not admin-configurable, distinct from the destination-number display above them.
- **Primary Actions:**
  - **SAALAM BANK** — opens the device dialer pre-filled with `*799*32666663*5#` (`tel:*799*32666663*5%23`, percent-encoded).
  - **EVC PLUS** — opens the device dialer pre-filled with `*712*615514692*5#` (`tel:*712*615514692*5%23`, percent-encoded).
  - **E-DAHAB** — opens the device dialer pre-filled with `*712*625514692*5#` (`tel:*712*625514692*5%23`, percent-encoded).
  - No button changes the request's status regardless of outcome (BRL-092/Scope Boundary — the system never assumes or simulates a successful payment; there is no reliable signal that the user completed anything in the external dialer app).
  - **Done** — a neutral navigation action (not a success claim) to **SCR-055 (Thank You / Support)**, tapped by the Business Owner once they return to Deendoon from the external dialer/mobile-money app.
- **Secondary Actions:** None.
- **Validation:** Not applicable (a confirmation/display screen).
- **Empty State:** Destination number not yet set → explicit message; the three USSD buttons remain available regardless (they don't depend on the destination-number display).
- **Loading State:** Skeleton while the destination number loads.
- **Error State:** Snackbar if the device dialer fails to open for any button.
- **Permission Behavior:** Screen restricted to the Business Owner role.
- **Navigation Entry:** SCR-052 "Continue Payment," on success.
- **Navigation Exit:** SCR-055 (Thank You / Support, on "Done").
- **Related Functional Requirements:** FR-078, FR-086.

### SCR-054 — Payment Status (Business Owner) — **Retired** *(Manual Mobile-Money Subscription Payment Flow, Revision History 1.10)*

> **Retired 2026-08-20 (Product Owner final UX direction).** No dedicated Payment Status screen exists anymore — the flow terminates at SCR-055 (Thank You / Support) without displaying Pending/Approved/Rejected state, "Subscription Activated," or a "Try Again" action anywhere in this flow. The existing Subscription Change Request history on SCR-050 (unchanged) remains the only in-app place status is ever shown, and the backend Platform Administrator approval workflow (unchanged) remains the sole source of truth for the eventual outcome. Content below preserved for history, matching this document's existing precedent for retired screens (e.g. SCR-026), not deleted.

- **Purpose:** A focused, single-request view of a Subscription Change Request's current status — Pending Verification, Approved, or Rejected — as a nicer presentation of the same data SCR-050's Change Request History already shows, adding no new backend surface.
- **Users:** Business Owner only.
- **Layout:** Single-column status screen.
- **Sections:** Status Card: 🟠 Pending Verification (with an explanatory message), 🟢 Approved (heading "Subscription Activated," the plan name, and — once available — the resulting Subscription's expiry date, per FR-077), or 🔴 Rejected (with the selected Rejection Reason(s) and any free-text notes, per FR-084); a "Check for Updates" action re-fetches the Change Request (reusing FR-079's history endpoint, matched by id — there is no dedicated single-request endpoint).
- **Displayed Data:** Per FR-078 (the request itself) and, once Approved, FR-077 (the resulting Subscription's expiry date).
- **Primary Actions:** Try Again (Rejected state only, → SCR-050, to submit a new request — a Rejected request never blocks a new one, BRL-084).
- **Secondary Actions:** Check for Updates (pull-to-refresh and an explicit button).
- **Validation:** Not applicable (a display screen).
- **Empty State:** Not applicable.
- **Loading State:** Spinner on the refresh action.
- **Error State:** Snackbar if the refresh fails; the last-known status remains displayed.
- **Permission Behavior:** Screen restricted to the Business Owner role.
- **Navigation Entry:** SCR-053 "View Payment Status."
- **Navigation Exit:** SCR-050 (on "Try Again," Rejected state only).

### SCR-055 — Thank You / Support (Business Owner) *(added — Manual Mobile-Money Subscription Payment Flow, Revision History 1.10)*
- **Purpose:** The terminal screen of the Manual Mobile-Money Subscription Payment Flow — thanks the Business Owner and offers a way to contact Support, without displaying or implying any payment/subscription outcome.
- **Users:** Business Owner only.
- **Layout:** Single-column screen.
- **Sections:** "Mahadsanid" heading; "Waad ku mahadsan tahay isticmaalka Deendoon." message; the existing Contact Deendoon Support component (Section 6 component library — Phone/WhatsApp/Email actions), embedded as-is, not a new or duplicated support-contact affordance.
- **Displayed Data:** None specific to this screen beyond the reused Support component's own already-approved data (phone, WhatsApp, email — unchanged).
- **Primary Actions:** None (Support's own Phone/WhatsApp/Email actions belong to the reused component, not a new action of this screen).
- **Secondary Actions:** None.
- **Validation:** Not applicable.
- **Empty State:** Not applicable.
- **Loading State:** Not applicable (fully static).
- **Error State:** Handled entirely within the reused Support component (unchanged).
- **Permission Behavior:** Screen restricted to the Business Owner role.
- **Navigation Entry:** SCR-053 "Done."
- **Navigation Exit:** None forward — this is the flow's terminal screen; standard back navigation only.
- **Related Functional Requirements:** FR-078.

---

## 11. UX Behavior

- **Loading:** Spinner for < 2s expected waits; Skeleton Loader for list/table/dashboard content; Progress Indicator for multi-step/long operations (Import, Export).
- **Searching:** Debounced input (no immediate per-keystroke request); loading state shown per §5/§9.
- **Filtering:** Applied filters persist for the duration of the session on a given screen (not across sessions, pending `04_Business_Rules.md` DD on filter persistence being resolved).
- **Refreshing:** Manual pull-to-refresh (mobile) / refresh control (desktop) on list and dashboard screens.
- **Offline behavior:** **Out of Version 1 scope** (`01_Project_Overview.md` §1.7) — screens assume connectivity; no offline queuing or offline-first data entry is specified here.
- **Slow network behavior:** Loading/Skeleton states remain visible until response or timeout; no silent hangs.
- **Retry behavior:** Every Error State includes a Retry action re-attempting the same request.
- **Long-running operations:** Progress Indicator with step labels (Import, Export); user may navigate away and be notified on completion via the Notification Center where the underlying event supports it (e.g., Document Generated).
- **Progress indicators:** Determinate where step count is known (Import wizard); indeterminate (Spinner) otherwise.
- **Optimistic vs. pessimistic updates:** Version 1 uses **pessimistic** updates throughout (UI waits for server confirmation before reflecting a change) — consistent with this being financial data where an optimistic-then-rolled-back state would be confusing or risky; no screen in this specification assumes optimistic UI.

---

## 12. Accessibility

- **Keyboard navigation:** Every interactive element (buttons, links, form fields, table rows with actions, modal controls) is reachable via Tab/Shift+Tab and operable via Enter/Space; Escape dismisses the topmost modal/drawer/popover.
- **Focus order:** Follows visual/reading order (top-to-bottom, left-to-right); modals trap focus within themselves until dismissed.
- **ARIA expectations:** Semantic roles/labels on all custom components (Dropdown, Autocomplete, Tabs, Accordion, Toast) sufficient for assistive technology to announce their purpose and state.
- **Screen reader compatibility:** All icons, chips, and status indicators have an accessible text equivalent (never icon-only, color-only meaning).
- **Color independence:** Status Chips, Badges, and validation states always pair color with an icon and/or text label — color is never the sole differentiator (directly supports §2 Color Usage Principles).
- **Touch targets:** Minimum 44×44px touch target on mobile for all interactive elements, including row action menus and icon buttons.
- **Contrast requirements:** Text and meaningful icons meet at least WCAG 2.1 AA contrast ratios against their background, using the neutral placeholder palette's contrast relationships (final brand colors must preserve these ratios when substituted).
- **Error announcement:** Inline validation errors and Error States are announced to assistive technology (e.g., via `aria-live`) at the moment they appear, not only visually.

---

## 13. Responsive Rules

- **Desktop (≥ 1280px):** Full Sidebar + Top Bar + multi-column layouts per §3.
- **Tablet (768–1279px):** Collapsed icon Sidebar, 2-column card/grid layouts, tables remain tabular (not collapsed to cards).
- **Mobile (< 768px):** No Sidebar; Bottom Tab Bar; single-column; tables collapse to stacked Cards (§9).
- **Very small screens (< 360px):** KPI Cards and Action Bars stack to a single column with no horizontal scrolling; text truncates with ellipsis + Tooltip rather than wrapping unpredictably.
- **Large monitors (> 1920px):** Content area caps at max-width (§3) and centers; it does not stretch to fill ultra-wide viewports edge-to-edge.

---

## 14. UI State Catalog

For every screen with meaningful state variation (all detail/list screens in §10), the following states apply as documented per-screen above; this table summarizes the standard set:

| State | Standard Treatment |
|---|---|
| Default | Normal populated view. |
| Loading | Skeleton Loader (lists/tables/dashboards) or Loading Spinner (short waits/buttons). |
| Empty | Empty State component: icon + message + Primary action where applicable (§5). |
| Success | Toast/Snackbar confirmation; for multi-step flows, a dedicated success step. |
| Validation Error | Inline field errors + Error Summary for forms > 3 fields (§6). |
| Server Error | Error State component with Retry (§5). |
| Permission Denied | SCR-047 pattern, or hidden action/field where the denial is partial (field-level per FR-008 A1, FR-019 A1). |
| Archived Record | Read-only rendering with a Restore Primary action replacing Edit/Archive (per BRL-004 visibility). |
| No Search Results | Empty State variant: "No results for '[term]'" / "No records match these filters," distinguishing a truly empty set from a filtered-to-empty set. |

---

## 15. UX Consistency Rules

These standards are identical everywhere in the application — no screen introduces a local variant:

- **Button placement:** Primary action bottom-right of a form/modal (desktop) or full-width bottom (mobile); Cancel/Secondary to its left (desktop) or above it (mobile).
- **Modal actions:** Always Primary + Secondary pair, Primary on the right (desktop) / bottom (mobile) consistent with the above.
- **Confirmation dialogs:** Always used for Archive and for Recovery Stage Override (mandatory reason); never used for Restore (reversible, low-risk) or for standard form Cancel.
- **Table actions:** Row-click opens the record; a right-aligned "⋮" menu holds secondary actions — never inline text links mixed into data cells.
- **Search placement:** Global Search always in the Top Bar; table-scoped Search always directly above its table, left-aligned.
- **Filter placement:** Always a "Filter" control adjacent to the scoped Search Box, opening a Drawer; active filters always shown as removable chips directly below.
- **Save behavior:** Always labeled "Save" (not "Submit," "OK," or "Done") for form persistence; always pessimistic (§11).
- **Cancel behavior:** Always discards unsaved changes and returns to the immediately prior screen/state.
- **Delete behavior:** There is no "Delete" in Version 1 — only "Archive," consistent with BC-002/BRL-004; the word "Delete" never appears in the UI where "Archive" is meant.
- **Navigation consistency:** Breadcrumbs on desktop/tablet, Back control on mobile — never both, never neither, on any given screen.
- **Status chip usage:** One Status Chip component, reused for Customer Status, Debt Status, Recovery Stage, and Collection Case Status — never a bespoke chip style per entity.
- **Badge usage:** Reserved for counts only (e.g., unread Notifications); never used to convey status (that's the Status Chip's role).
- **Icons:** One icon family (§2); the same icon always means the same action across the app (e.g., the Archive icon is never reused for a different action).
- **Spacing:** 4px-grid scale (§2) applied uniformly; no screen introduces ad hoc spacing values.
- **Typography:** The token set in §2 is exhaustive; no screen introduces a new heading level or text style.

---

## 16. Design Constraints (Confirmation)

This specification supports every approved Functional Requirement in `03_Functional_Requirements.md`, including Module 7's Professional Collection Requests addition (FR-072–FR-076), and every approved Business Rule in `04_Business_Rules.md`, including BRL-078–082. It introduces zero new functionality and zero Version 2 features. Where an approved Business Rule is still a Deferred Decision (e.g., overpayment handling, closure-outcome value set, multi-role assignment, the full Professional Collection Request transition matrix), the corresponding screen is specified to accommodate either resolution without redesign — it does not pre-decide the outcome. No approved workflow has been redesigned; no module ownership has changed; nothing here contradicts the architecture in Documents 01–04.

**Reopened-scope confirmation:** Professional Collection Requests is integrated using only the two approved application interfaces (Customer Mobile App, Deendoon Super Admin Web Panel). No new dashboard, portal, actor, or RBAC role is introduced anywhere in this document — SCR-049 is a screen within the existing Deendoon Super Admin Web Panel, operated by the existing Deendoon Platform Administrator (Super Admin) actor, exactly as required by the corrected 01/02/03/04.

**Subscription & Storage Self-Service confirmation (Module 13, catch-up):** SCR-050 and SCR-051 are screens within the existing Customer Mobile App, reachable only by the existing Business Owner actor via the existing Account menu. No new application interface, actor, or RBAC role is introduced. This specification supports `03_Functional_Requirements.md` FR-077–FR-084 and `04_Business_Rules.md` BRL-083–091, introduces zero new functionality beyond what the audit confirmed is already implemented and live-verified, and does not pre-decide DD-047 (Storage Add-on expiration) — SCR-051 simply displays whatever Add-on status the backend returns, including a currently-unreachable "Expired" state, without assuming a UI treatment for a transition that doesn't yet occur.

---

## 17. Traceability

| Screen | Related Functional Requirements |
|---|---|
| SCR-001 Login | FR-001, FR-006 |
| SCR-002 Forgot Password | FR-004 |
| SCR-003 Reset Password | FR-004 |
| SCR-004 Session Expired | FR-003 |
| SCR-005 Dashboard (Mobile) | FR-053, FR-054, FR-055, FR-065, FR-074 |
| SCR-006 Dashboard (Web Panel) | FR-053, FR-054, FR-055, FR-073 |
| SCR-007 Customer List | FR-015, FR-010, FR-011 |
| SCR-008 Customer Details | FR-008, FR-012, FR-013 |
| SCR-009 Customer Create | FR-007, FR-014 |
| SCR-010 Customer Edit | FR-009, FR-013, FR-014 |
| SCR-011 Customer Archive Confirmation | FR-010 |
| SCR-012 Customer Import | FR-016, FR-014 |
| SCR-013 Debt List | FR-021, FR-064 |
| SCR-014 Debt Details | FR-019, FR-020, FR-021, FR-024, FR-025 |
| SCR-015 Debt Create | FR-017, FR-018 |
| SCR-016 Debt Edit | FR-020, FR-021 |
| SCR-017 Debt Archive Confirmation | FR-022 |
| SCR-018 Credit & Risk Panel | FR-013, FR-026, FR-027, FR-028 |
| SCR-019 Manual Reminder Modal | FR-030 |
| SCR-020 Promise to Pay Modal | FR-031 |
| SCR-021 Follow-up History Tab | FR-033 |
| SCR-022 Receive Payment Modal | FR-034, FR-036, FR-037 |
| SCR-023 Payment History Tab | FR-035 |
| SCR-024 Collection Case List | FR-042 |
| SCR-025 Collection Case Details | FR-042, FR-043, FR-046, FR-072, FR-074, FR-075 |
| ~~SCR-026 Collection Case Assignment Modal~~ (Retired) | FR-041 |
| SCR-027 Collection Activity Modal | FR-044 |
| SCR-028 Collection Case Closure Modal | FR-045 |
| SCR-029 Document Viewer | FR-050, FR-051 |
| SCR-030 Document List / History | FR-052 |
| SCR-031 Generate Demand Letter Modal | FR-048 |
| SCR-032 Generate Statement Modal | FR-049 |
| SCR-033 Aging Analysis Report | FR-054, FR-056 |
| SCR-034 Standard Reports Screen | FR-055, FR-056 |
| SCR-035 Report Export Modal | FR-057 |
| SCR-036 Notification Center | FR-058, FR-059, FR-060, FR-061 |
| SCR-037 Calendar View | FR-062 |
| SCR-038 Global Search Results | FR-063 |
| SCR-039 User Administration List | FR-066 |
| SCR-040 User Create / Edit | FR-066, FR-067 |
| SCR-041 Role & Permission Management | FR-067 |
| SCR-042 Company Profile & Branding | FR-068 |
| SCR-043 System Preferences | FR-069 |
| SCR-044 Lookup & Reference Data | FR-070 |
| SCR-045 Audit Trail Viewer | FR-071 |
| SCR-046 My Profile / Account Settings | FR-002, FR-005 |
| SCR-047 Permission Denied | Cross-cutting |
| SCR-048 404 Not Found | Cross-cutting |
| SCR-049 Professional Collection Requests (Super Admin) | FR-073, FR-075, FR-076 |
| SCR-050 Subscription (Business Owner) | FR-077, FR-078, FR-079 |
| SCR-051 Storage (Business Owner) | FR-080, FR-081, FR-082 |
| SCR-052 Payment Information (Business Owner) | FR-078 |
| SCR-053 Payment Instructions / Send Money (Business Owner) | FR-078, FR-086 |
| SCR-054 Payment Status (Business Owner) — Retired | FR-078, FR-084 |
| SCR-055 Thank You / Support (Business Owner) | FR-078 |

Every Functional Requirement from FR-001 through FR-084 is covered by at least one screen above. FR-072 and FR-074 are covered by SCR-005/SCR-025 as noted; FR-073, FR-075, and FR-076 are covered by SCR-049 (Super Admin side) and, for FR-075, also by SCR-025 (tenant side of the shared Conversation Thread). FR-083 (subscription-driven Customer read-only) is covered by SCR-050's summary Card (read-only-state indicator) and, on the Customer side, by the existing Archived/read-only rendering already specified for SCR-008/SCR-010 (§14 UI State Catalog, "Archived Record" row) — no new UI state is introduced for it. FR-084 (Platform Administrator review) has no dedicated screen in this document (see §4's Subscription & Storage Navigation note) — it is not omitted, but deliberately not specified beyond that note, since no live-verified Super Admin Web Panel screen design exists to document.

---

## 18. Validation Checklist

- [x] Every Module (1–13) is represented — see §9 Screen Inventory, "Module" column.
- [x] Every major screen is documented — 51 screens specified in §10 (48 original + SCR-049 + SCR-050 + SCR-051).
- [x] Every reusable component is specified — §5 covers all components listed in your Component Library request, plus the Conversation Thread component added for FR-075; SCR-050/051's bottom sheets reuse existing Form/Modal components, no new component was introduced for them.
- [x] No business logic appears — all rule-dependent behavior (e.g., overpayment handling, closure outcomes, transition matrices, Storage Add-on expiration gap DD-047) is referenced by pointer to `04_Business_Rules.md`, never restated or decided here.
- [x] No API definitions appear — no endpoint, payload, or contract detail is present anywhere in this document.
- [x] No database schema appears — no table/field/type definitions are present; entities are referenced by name only, as already established in `03_Functional_Requirements.md`.
- [x] No new functionality has been introduced — every screen maps to an existing, approved Functional Requirement (§17); SCR-047/048 are cross-cutting UI states required by any RBAC/routing system, not new features; SCR-049 maps to the reopened Module 7's FR-072–FR-076; SCR-050/051 map to the retroactively-documented Module 13's FR-077–FR-084, a real capability confirmed already implemented and live-verified, not a new one being designed here.
- [x] No approved workflow has changed — screens implement the Main Flows/Alternate Flows/Exceptions already defined in `03_Functional_Requirements.md` without altering their sequence or outcome.
- [x] Only the two approved application interfaces are used — every Professional Collection Requests and Subscription & Storage Self-Service surface lives inside the Customer Mobile App or the Deendoon Super Admin Web Panel; no third interface, portal, or dashboard was introduced.
- [x] No new actor or RBAC role was introduced — SCR-049 is operated exclusively by the already-approved Deendoon Platform Administrator (Super Admin); SCR-050/051 are operated exclusively by the already-approved Business Owner; no "Recovery Specialist" or equivalent appears anywhere in this document.
- [x] "Assigned" is described consistently with `03`/`04` wherever it appears (§5 Status Chips, SCR-049) — accepted ownership by the Super Admin, not reassignment to another system user.

---

**End of 05_UI_UX_Specification.md — Approved. Frozen (v1.7).** No further changes are permitted unless an approved scope change, contradiction, security issue, or architecture issue requires reopening (Project Guardian rule, consistent with 01–04). This document was reopened once for Professional Collection Requests (v1.1) and again for Subscription & Storage Self-Service (v1.7) — both times to retroactively document a real, already-implemented capability per Product Owner decision, never to design new, unimplemented functionality.
