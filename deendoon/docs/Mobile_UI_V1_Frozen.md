# Deendoon Mobile Application — UI Specification

## DEENDOON MOBILE APP — UI VERSION 1.0 — STATUS: FROZEN

This document is the official UI Specification for the Deendoon Mobile
Application. It is the master reference for Backend Development, Flutter
Development, QA Testing, and all future product releases.

> **Amendment note (2026-07-31, Product Vision Amendment, Product Owner Decision).** All Permissions sections throughout this document previously listed Sales & Finance Staff and Collections Staff alongside Business Owner/Administrator — Version 1 has exactly one tenant-side role, the Business Owner, matching `SRS/08_Security_and_RBAC.md` v1.4 and `docs/00_PROJECT_GOVERNANCE.md`. Every Permissions section now reads "Business Owner" only. No UI layout, navigation, workflow, or business logic was changed — role references only.
>
> **Second amendment note (2026-07-31, same decision).** The Case Actions component's "Assign Officer" action, and its Required APIs entry, were retired — Version 1 has no second tenant user to assign a Case to.
>
> **Third amendment note (2026-07-31, same decision, generic "staff" sweep).** Fifteen Business Objective lines used the generic word "staff" ("Let staff...", "Give staff...") — Version 1 has no tenant employees, so every one now reads "Let the Business Owner..." / "Give the Business Owner..." instead. No screen, layout, workflow, or business logic was changed — prose wording only.
>
> **Fourth amendment note (2026-07-31, final architecture consistency audit correction).** The Reminder Details screen's Permissions line still referenced "the reminder's creator or a manager-level role" — missed by every prior sweep. Updated to "the reminder's creator" only, matching the same fix already applied to `Backend_v2.1_UI_Mapping.md` and `Backend_v2.1_REST_API_Specification.md`.
>
> **Fifth amendment note (2026-08-02, V1 Scope Expansion, Product Owner Decision).** Two modules are added to Version 1: **Notifications** (new Section 9) and **Account / Profile** (new Section 10). Sections 9–13 of the prior document (Reusable Components, UX Rules, Business Rules, Version History, Freeze Declaration) are renumbered 11–15 accordingly. The Home Dashboard's header (Section 4) now opens with a Notification Bell in place of the prior plain Logout icon; Logout itself moves into the new Account / Profile section (Section 10.5), reached by tapping the greeting. Notifications (Section 9) is **not new backend scope** — it implements `SRS/03_Functional_Requirements.md` Module 10 (FR-058–062), already approved and frozen there, against `NotificationController`'s four already-built endpoints (`GET /notifications`, `GET /notifications/history`, `PATCH /notifications/{id}/read`, `PATCH /notifications/mark-all-read`); this amendment only closes the pre-existing gap between that already-approved backend module and the Flutter UI. Account / Profile (Section 10) **is** new scope: Profile and Change Password are real (cached `{id, name, email}` from `UserResource`; `POST /change-password`), but Business Profile and Settings have no Business-Owner-reachable backend yet — the only company-profile endpoint (`GET/PUT /admin/settings/company-profile`) is Super Admin-only, and no personal-settings endpoint exists at all. Per Product Owner decision, both are built now as real navigation destinations with an honest "not yet connected" empty state, explicitly not fabricated data and not a disabled/"Not Available" treatment — their repository layers are marked `TODO(Backend Required)` for later wiring.
>
> **Sixth amendment note (2026-08-05, V1 Implementation Alignment, Product Owner Decision).** After a Flutter-vs-documentation compliance review, the Product Owner confirmed that the shipped Version 1 Flutter implementation — not the pre-implementation wording of several sections in this document — is the approved Version 1 behavior. This amendment updates the documentation to match that approved implementation. No screen was redesigned and no new feature was introduced; the changes are: **(1) §4.4 Quick Actions** are now Add Case, Record Payment, Add Reminder, and Global Search (the earlier "Scan Invoice" and "Send Message" tiles are retired). **(2) §7.7 / §7.8 WhatsApp & SMS** are sent by rendering the message and then launching the user's own installed WhatsApp/SMS app (native app intent first, `wa.me` browser fallback for WhatsApp), where the user manually presses Send — no WhatsApp Business API, no paid messaging gateway, no server-side send record, and no automatic delivery tracking in Version 1. **(3) §7.4 Reminder Details** actions are split into two approved operational groupings — Client Visit (Navigate, Check In, Log Visit Outcome, Mark as Completed) and Follow-up (Call, WhatsApp, SMS, Mark as Completed, Reschedule). **(4) §7.1 / §7.6 Calendar** is reached from the Reminder Center's AppBar Calendar icon. **(5) §10 Account** now documents the real Business Profile form (wired to `GET/PUT /admin/settings/company-profile`, reachable by the Business Owner, who holds the tenant admin role) and the real Settings screen (Language, Notifications, Business, and Security groups), replacing the earlier "honest empty" placeholders, and documents the Bulk Import (Customer Import, §10.6) and About (§10.7) destinations, both approved parts of the Account module. **(6) §13** the audit-trail rule is narrowed to reflect that Version 1 does not record WhatsApp/SMS sends. Backend endpoints, APIs, database schema, and business logic are unchanged by this amendment — documentation only.

---

## 1. Introduction

### 1.1 Purpose

This document defines, screen by screen, the complete and final functional
specification of the Deendoon Mobile Application's user interface,
Version 1.0. It establishes what every screen must do, what data it must
present, what actions a user may take, and what rules govern its
behavior. It is the single authoritative reference against which Backend
Development, Flutter Development, and QA Testing are built and validated.

### 1.2 Scope

This specification covers the complete Deendoon Mobile Application as
approved: the five primary destinations reachable from the Bottom
Navigation (Home Dashboard, Analytics, Cases, Reminder Center, Documents)
and every screen, sub-screen, and workflow reachable from them, including
Case Details, Reminder Scheduling, Smart Calendar, WhatsApp and SMS
Preview, and document Preview/Download/Share. It also covers Notifications
(Section 9) and Account / Profile (Section 10), both reached from the Home
Dashboard's header rather than the Bottom Navigation, which remains fixed
at exactly five destinations (Section 3). It also defines the global
design standards, reusable components, cross-cutting UX rules, and
business rules that apply across the entire application.

### 1.3 Design Principles

The Deendoon Mobile Application is built on the following principles:

- **Clarity first.** Every screen leads with the number or status that
  matters most (an amount, a count, a risk level) before supporting detail.
- **One tap to the next action.** The most frequent tasks — recording a
  payment, adding a case, sending a reminder — are never more than one or
  two taps away from any primary screen.
- **Consistent visual language.** Status, risk, and urgency are always
  communicated through the same color and icon vocabulary, regardless of
  which screen they appear on.
- **Task-oriented organization.** Screens are organized around what the
  user is trying to accomplish (review performance, work a case, action a
  reminder, retrieve a document), not around how the data is stored.
- **Mobile-first density.** Information density is calibrated for a
  single-column mobile viewport, prioritizing vertical scanning over
  horizontal layout.

### 1.4 Freeze Policy

UI Version 1.0 is FROZEN. Effective from the date of this document:

- No screen, layout, component, navigation path, label, or workflow
  described herein may be altered, reorganized, renamed, or reinterpreted
  by any team without a formal, documented Product Owner approval.
- Backend Development, Flutter Development, and QA Testing must each
  build and validate against this specification exactly as written.
- Any ambiguity encountered during implementation must be resolved by
  reference back to this document and, where this document is silent, by
  escalation to the Product Owner — never by independent design judgment.
- A future revision of the approved UI will be issued as a new, distinct
  version (e.g., Version 1.1, Version 2.0) with its own specification
  document. This document remains the authoritative record of Version 1.0
  for as long as Version 1.0 is in production use.

---

## 2. Global UI Standards

### 2.1 Color Palette

- **Background:** near-black charcoal, used as the base surface for every
  screen.
- **Surface / Card:** a dark gray, one step lighter than the background,
  used for every card, list row, and panel to create visual separation
  without introducing a light theme.
- **Primary / Brand:** a bright green, used for the Deendoon brand mark,
  primary call-to-action buttons ("Send Reminder," "Send via WhatsApp"),
  active tab indicators, and positive/healthy status indicators.
- **Text — Primary:** white / near-white, used for headings, values, and
  primary labels.
- **Text — Secondary:** muted gray, used for subtext, timestamps, and
  supporting labels.
- **Success:** green — Low Risk, Healthy status, Completed, positive
  deltas.
- **Warning:** amber/orange — Medium Risk, Follow Up, Upcoming, Contract
  Renewal.
- **Danger:** red — High Risk, Overdue, destructive actions (e.g.,
  "Reschedule").
- **Informational:** blue/purple — Promise Due, Client Visit and
  Follow-up Call reminder types, informational badges.

### 2.2 Typography

A single sans-serif type family is used throughout, with the following
hierarchy:

- **Display:** largest weight and size, reserved for headline monetary
  and numeric values (e.g., outstanding totals, KPI figures).
- **Heading:** screen titles and major section titles.
- **Subheading:** card titles and list-item primary labels (e.g., a
  customer name, a reminder title).
- **Body:** standard descriptive and label text.
- **Caption:** timestamps, metadata, and secondary annotations (e.g.,
  "Last activity: Today, 09:30 AM").

Text color always follows the Primary/Secondary rule in 2.1: the most
important word on any card or row is always rendered in Primary text
color and a heavier weight.

### 2.3 Spacing

- Consistent internal padding is applied within every card and list row.
- A consistent vertical rhythm separates major sections on every screen
  (header, summary, tabs, list).
- A consistent horizontal gutter separates items within any grid layout
  (e.g., the KPI grid, the Quick Actions grid).
- List items within a scrollable section are separated by a consistent,
  uniform gap.

### 2.4 Components

The application is built from a fixed set of reusable components,
catalogued in full in Section 11: header bars, tab selectors, KPI cards,
list rows/cards, donut charts, line charts, progress bars, buttons,
status badges/pills, icons with colored backgrounds, form inputs, and the
calendar grid.

### 2.5 Icons

Every entity type and reminder/document type is represented by a
dedicated icon on a colored, rounded-square or circular background. The
icon and its background color are consistent everywhere that entity or
type appears (e.g., the Payment Due icon and its color are identical on
the Home Dashboard, the Reminder Center, and the Smart Calendar). Customer
and case entries without a photo use a colored circular avatar containing
the entity's initial.

### 2.6 Cards

The card is the primary content container across the application: a
rounded-rectangle surface, one shade lighter than the page background,
used for KPI values, the Business Health summary, case entries, document
entries, reminder entries, and settings panels. Cards never nest another
card inside them.

### 2.7 Buttons

- **Primary button:** filled, brand green, full-width where it is the
  single most important action on the screen (e.g., "Send Reminder,"
  "Send via WhatsApp").
- **Secondary button:** outlined or neutral-filled, used for a supporting
  action alongside a primary button (e.g., "Mark as Completed," "Send via
  SMS").
- **Destructive button:** filled red, used for actions that end or reset
  a workflow state (e.g., "Reschedule").
- **Icon button:** circular, compact, used for header-level actions (back,
  search, filter, add, edit, delete).

### 2.8 Navigation

Two navigation patterns are used throughout:

- **Primary screens** (Home, Analytics, Cases, Reminders, Documents) are
  always reachable through the persistent Bottom Navigation bar (Section
  3), and always display it.
- **Secondary screens** (e.g., Reminder Details, Reminder Scheduling,
  Smart Calendar, WhatsApp Preview, SMS Preview) are reached by drilling
  into a primary screen, use a header with a back arrow and a screen
  title, and do not display the Bottom Navigation bar.

### 2.9 Status Colors

The following color-to-meaning mapping is fixed and used identically
everywhere in the application:

| Color | Meaning |
|---|---|
| Green | Healthy, Low Risk, Today, Completed, positive trend |
| Amber/Orange | Medium Risk, Follow Up, Upcoming, Contract Renewal |
| Red | High Risk, Overdue, destructive action |
| Blue/Purple | Promise Due, informational, scheduled |

### 2.10 Responsive Rules

- The application is designed mobile-first for a single-column portrait
  viewport.
- Grid layouts (KPI cards, Quick Actions) collapse to two columns on
  standard mobile widths and remain two columns across all supported
  device sizes.
- All list-based content (cases, reminders, documents, notifications)
  scrolls vertically within its section; the header and, on primary
  screens, the Bottom Navigation remain fixed in place.
- Charts (donut, line) resize to the available width while preserving
  their aspect ratio and legend placement.

---

## 3. Bottom Navigation

**Purpose:** Provide constant, one-tap access to the five primary areas
of the application from anywhere in the primary navigation flow.

**Business Objective:** Ensure a user is never more than one tap away
from any major functional area, minimizing navigation friction for
daily-use tasks.

**Layout Description:** A fixed bar anchored to the bottom of the screen,
containing five destinations in a fixed order: Home, Analytics, Cases,
Reminders, Documents. Each destination displays an icon and a text label;
the active destination is visually distinguished from the other four.

**Components:** Five navigation items, each with an icon, a label, and an
active/inactive visual state.

**User Actions:** Tap any of the five items to switch the active primary
screen.

**Navigation:** Present on and shared by all five primary screens (Home,
Analytics, Cases, Reminders, Documents). Not present on secondary
screens.

**Validation Rules:** Not applicable.

**Business Rules:** Exactly five destinations, in the fixed order Home →
Analytics → Cases → Reminders → Documents, at all times. The active state
always reflects the currently displayed primary screen.

**Required APIs:** Not applicable — a pure navigation control.

**Required Database Tables:** Not applicable.

**Permissions:** Visible to every authenticated user; the destinations a
given user may enter are governed by that screen's own Permissions
section.

**Empty State:** Not applicable.

**Loading State:** Not applicable.

**Error State:** Not applicable.

**Success State:** The correct primary screen is displayed and its
corresponding navigation item is shown in the active state.

---

## 4. Home Dashboard

**Purpose:** Provide a single, first-view screen summarizing overall
business health, headline financial performance, today's outstanding
follow-up work, one-tap access to frequent actions, and recently active
cases.

**Business Objective:** Give the user a complete daily briefing — how the
business is doing and what needs attention today — without navigating
anywhere else.

**Layout Description:** A header showing the time-of-day greeting and the
signed-in user's name (tappable, opening Account / Profile — Section 10)
and a Notification Bell (Section 4.6). Below the header, top to bottom: a
Business Health card, a 2×2 KPI grid, a Today's Overview list, a Quick
Actions grid, and a Recent Cases section, followed by the Bottom
Navigation bar.

**Components:** Header Greeting and Notification Bell (Section 4.6);
Business Health (Section 4.1); KPI Cards (Section 4.2); Today's Overview
(Section 4.3); Quick Actions (Section 4.4); Recent Cases (Section 4.5).

**User Actions:** As documented in Sections 4.1–4.6: tap the greeting to
open Account / Profile, tap the Notification Bell, tap the Business
Health card, tap any KPI card, tap a Today's Overview row, tap a Quick
Action tile, tap "View All" or a case entry in Recent Cases.

**Navigation:** Entry point after login. Leads to Account / Profile
(Section 10), Notifications (Section 9), Analytics (Section 5), Cases
(Section 6), Reminder Center (Section 7), and each Quick Action's own
workflow, as detailed in Sections 4.1–4.6.

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 4.1–4.5.

**Business Rules:** Governed collectively by the business rules defined
in Sections 4.1–4.5.

**Required APIs:** Business Health Score retrieval API; Dashboard KPI
Summary retrieval API; Today's Reminder Summary retrieval API; Recent
Cases retrieval API; Case creation API; Payment recording API; Reminder
creation API; Search retrieval API.

**Required Database Tables:** Customer records, Debt records, Payment
records, Reminder records, Case records, Invoice records, Message/
Reminder records.

**Permissions:** Visible to Business Owner, with individual Quick Actions further gated per
Section 4.4.

**Empty State:** Each component displays its own defined empty state, as
documented in Sections 4.1–4.5.

**Loading State:** Each component loads independently with its own
placeholder, as documented in Sections 4.1–4.5.

**Error State:** Each component displays its own retry affordance
independently, as documented in Sections 4.1–4.5.

**Success State:** All components display current, accurate data, as
documented in Sections 4.1–4.5.

### 4.1 Business Health

**Purpose:** Communicate, at a glance, whether the business's overall
debt-recovery position is in good standing.

**Business Objective:** Give the business owner an immediate, single-
number confidence signal before reviewing any other detail.

**Layout Description:** A card at the top of the Home Dashboard showing a
status label ("Healthy"), a short encouraging subtext ("You are doing
great!"), and a circular percentage gauge displaying the current score
(e.g., "92%").

**Components:** Status label, subtext line, circular percentage gauge.

**User Actions:** Tap the card to view the detailed breakdown behind the
score (in Analytics).

**Navigation:** Tapping the card navigates to Analytics.

**Validation Rules:** Not applicable.

**Business Rules:** The Business Health Score is a composite measure
derived from collection performance, outstanding exposure, and risk
concentration across the tenant's customer base, expressed as a
percentage from 0–100. The score is mapped to one of three status bands:
Healthy, Needs Attention, and At Risk, each rendered with its own status
color per Section 2.9. The score and label are recalculated continuously
as underlying data changes.

**Required APIs:** Business Health Score retrieval API.

**Required Database Tables:** Customer records, Debt records, Payment
records.

**Permissions:** Visible to Business Owner.

**Empty State:** For a tenant with no recorded debts or payments, the
score displays a neutral baseline state rather than an artificially
computed percentage.

**Loading State:** The card displays a placeholder gauge while the score
is retrieved.

**Error State:** If the score cannot be retrieved, the card displays a
retry affordance in place of the gauge.

**Success State:** The gauge renders the current score with its
corresponding status label and color.

### 4.2 KPI Cards

**Purpose:** Present the four headline financial metrics the business
owner checks most often.

**Business Objective:** Allow a user to assess overall financial exposure
and recent collection performance without navigating elsewhere.

**Layout Description:** A 2×2 grid of cards beneath the Business Health
card, each showing a label, a primary value, and a "vs last month" delta
line: Total Outstanding, Collected This Month, Overdue Amount, High Risk
Customers.

**Components:** Four cards, each with a label, primary value, and delta
indicator (direction and magnitude).

**User Actions:** Tap any KPI card to view its underlying filtered
detail.

**Navigation:** Total Outstanding and Overdue Amount navigate to a
filtered Debts view; High Risk Customers navigates to the Cases screen
filtered to High Risk; Collected This Month navigates to Analytics.

**Validation Rules:** Not applicable.

**Business Rules:**
- Total Outstanding is the sum of remaining balances across all open
  (unpaid, uncancelled, not written-off) debts.
- Collected This Month is the sum of payments recorded within the current
  calendar month.
- Overdue Amount is the sum of remaining balances across all debts
  currently in an overdue state.
- High Risk Customers is the count of customers currently classified as
  High Risk.
- Each card's delta compares its current value against the equivalent
  value for the immediately preceding month.

**Required APIs:** Dashboard KPI Summary retrieval API.

**Required Database Tables:** Debt records, Payment records, Customer
records.

**Permissions:** Visible to Business Owner.

**Empty State:** A tenant with no qualifying records for a given card
displays a zero value with no delta, rather than omitting the card.

**Loading State:** Each card displays a placeholder value while its data
loads.

**Error State:** A card whose data fails to load displays a retry
affordance independently of the other three.

**Success State:** All four cards display current values and correctly
directioned deltas.

### 4.3 Today's Overview

**Purpose:** Summarize the day's outstanding follow-up work in one place.

**Business Objective:** Let a user immediately see how much work is due
today across every type of follow-up, without opening the Reminder
Center.

**Layout Description:** A vertical list of four rows beneath the KPI
grid, each showing an icon, a count, a label, and a forward chevron:
Reminders Due Today, Payments Due, Client Visits, Follow-up Calls.

**Components:** Four count rows, each with icon, count, label, chevron.

**User Actions:** Tap any row to open the corresponding filtered view in
the Reminder Center.

**Navigation:** Tapping "Reminders Due Today" opens Reminder List
(Section 7.3), filtered to today. Tapping Payments Due, Client Visits, or
Follow-up Calls opens the same view filtered to that reminder type.

**Validation Rules:** Not applicable.

**Business Rules:** Each count reflects reminders whose due date is the
current calendar day and whose status is not Completed. Payments Due
reflects Payment Due-type reminders; Client Visits reflects Client
Visit-type reminders; Follow-up Calls reflects Follow-up Call-type
reminders.

**Required APIs:** Today's Reminder Summary retrieval API.

**Required Database Tables:** Reminder records.

**Permissions:** Visible to Business Owner.

**Empty State:** A row with zero items due today displays a zero count
rather than being hidden.

**Loading State:** The list displays a placeholder while counts are
retrieved.

**Error State:** A retry affordance is shown if the summary fails to
load.

**Success State:** All four rows display accurate, current-day counts.

### 4.4 Quick Actions

**Purpose:** Provide one-tap entry into the four most frequently performed
tasks.

**Business Objective:** Minimize the number of taps required to start the
most common workflows.

**Layout Description:** A grid of four tappable tiles beneath Today's
Overview: Add Case, Record Payment, Add Reminder, Global Search.

**Components:** Four tiles, each with an icon and a label.

**User Actions:** Tap a tile to begin the corresponding workflow.

**Navigation:** "Add Case" opens the case-creation flow. "Record Payment"
opens the payment-recording flow. "Add Reminder" opens Reminder
Scheduling (Section 7.5). "Global Search" opens the Global Search screen.

**Validation Rules:** Not applicable at the tile level; each destination
workflow enforces its own validation.

**Business Rules:** All four actions are always available regardless of
current data state (e.g., "Add Case" is always available, not conditional
on existing cases). Each tile is a shortcut into an existing workflow and
introduces no business logic of its own.

**Required APIs:** Case creation API, Payment recording API, Reminder
creation API, Search retrieval API.

**Required Database Tables:** Case records, Payment records, Reminder
records, Customer records.

**Permissions:** Each tile is independently permission-gated by the
role(s) permitted to perform that specific action.

**Empty State:** Not applicable — this is an action grid, not a data
list.

**Loading State:** Not applicable at the grid level; each destination
workflow manages its own loading state.

**Error State:** Not applicable at the grid level.

**Success State:** Tapping a tile reliably opens its corresponding
workflow.

### 4.5 Recent Cases

**Purpose:** Surface the most recently active cases directly on the Home
Dashboard.

**Business Objective:** Let a user resume work on an active case without
navigating to the full Cases screen.

**Layout Description:** A section beneath Quick Actions, presented in the
same list style as the Cases screen's case entries, showing a small
number of the most recently active cases with a "View All" link into the
full Cases screen.

**Components:** Section header with "View All" link; a short list of case
entries, each showing customer name, outstanding amount, and risk badge,
consistent with the case entry style defined in Section 6.1.

**User Actions:** Tap "View All" to open the Cases screen. Tap an
individual case entry to open its Case Details (Section 6.3).

**Navigation:** "View All" navigates to Cases (Section 6). A case entry
navigates to Case Details (Section 6.3).

**Validation Rules:** Not applicable.

**Business Rules:** Cases are ordered by most recent activity, most
recent first. The number of cases shown is limited to a small preview
count, with the full list available via "View All."

**Required APIs:** Recent Cases retrieval API.

**Required Database Tables:** Case records, Customer records, Debt
records.

**Permissions:** Visible to Business Owner.

**Empty State:** If no cases have recent activity, the section displays
an explicit "no recent activity" message.

**Loading State:** Placeholder case entries are displayed while data
loads.

**Error State:** A retry affordance is displayed if the list fails to
load.

**Success State:** The most recently active cases are displayed in the
correct order.

### 4.6 Notification Bell

**Purpose:** Give the Home Dashboard header a primary entry point into
Notifications (Section 9), replacing the prior plain Logout icon there.

**Business Objective:** Let the Business Owner see, at a glance, that a
new business event has occurred, without leaving the Home Dashboard.

**Layout Description:** A bell icon in the Home Dashboard's header,
opposite the greeting. A small dot badge is shown on the bell whenever at
least one unread notification exists on the already-loaded first page of
Notifications; no numeric count is shown, since no unread-count endpoint
exists.

**Components:** Bell icon; unread indicator dot.

**User Actions:** Tap the bell to open Notifications.

**Navigation:** Opens Notifications (Section 9).

**Validation Rules:** Not applicable.

**Business Rules:** The unread indicator reflects only real, already-
fetched notification data — never a fabricated or estimated count.

**Required APIs:** `GET /notifications` (the same call Notifications'
List, Section 9.1, already makes).

**Required Database Tables:** Notification records.

**Permissions:** Visible to Business Owner.

**Empty State:** No unread notifications — the bell shows no badge.

**Loading State:** The bell shows no badge until the first page of
notifications has loaded.

**Error State:** Not applicable — a failed fetch simply shows no badge
rather than an error indicator on the header.

**Success State:** The badge accurately reflects whether at least one
unread notification exists.

---

## 5. Analytics

**Purpose:** Provide deeper financial and collections performance
analysis than the Home Dashboard's headline KPIs, across selectable date
ranges.

**Business Objective:** Let a manager understand collection performance
trends and where outstanding risk is concentrated by aging bucket and
risk classification.

**Layout Description:** Three tabs — Overview, Reports, and Trends —
over a user-selectable date range, each presenting the components
documented in Sections 5.1–5.6.

**Components:** Overview (Section 5.1); Reports (Section 5.2); Trends
(Section 5.3); Collection Analytics (Section 5.4); Aging Analysis
(Section 5.5); Risk Distribution (Section 5.6).

**User Actions:** As documented in Sections 5.1–5.6: switch tabs, adjust
date ranges, select report categories, tap chart legend rows.

**Navigation:** Reached via the Bottom Navigation's "Analytics" tab.
Leads to filtered report, debt, and customer views, as detailed in
Sections 5.1–5.6.

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 5.1–5.6.

**Business Rules:** Governed collectively by the business rules defined
in Sections 5.1–5.6.

**Required APIs:** Analytics Overview retrieval API; Aging Analysis,
Customers, Debts, Collection Cases, Payments, and Credit Risk report
APIs; Report Export API; Collections Trend time-series API; Collection
Analytics KPI retrieval API; Risk Distribution retrieval API.

**Required Database Tables:** Debt records, Payment records, Customer
records, Collection Case records.

**Permissions:** Visible to Business Owner.

**Empty State:** Each tab and component displays its own defined empty
state, as documented in Sections 5.1–5.6.

**Loading State:** Each tab and component loads independently with its
own placeholder, as documented in Sections 5.1–5.6.

**Error State:** Each tab and component displays its own retry
affordance, as documented in Sections 5.1–5.6.

**Success State:** All components display accurate data for the selected
date range, as documented in Sections 5.1–5.6.

### 5.1 Overview

**Purpose:** Present the core collection-performance KPIs and risk
breakdown for the selected period in a single view.

**Business Objective:** Give a manager a complete performance snapshot
for any chosen date range without switching screens.

**Layout Description:** The default tab on Analytics, presenting the date
range selector, the Collection Analytics KPI row, the Collections Trend
chart, and the Aging Analysis chart, in that order.

**Components:** Date range selector; content composed of Sections 5.4 and
5.5.

**User Actions:** Adjust the date range; scroll through the composed
sections; switch to Reports or Trends.

**Navigation:** Default tab shown on entering Analytics. Switching tabs
changes the displayed content within the same screen.

**Validation Rules:** The selected date range must resolve to a valid,
non-inverted start and end date.

**Business Rules:** All figures displayed under Overview recompute
immediately whenever the date range changes.

**Required APIs:** Analytics Overview retrieval API.

**Required Database Tables:** Debt records, Payment records, Customer
records.

**Permissions:** Visible to Business Owner.

**Empty State:** A period with no qualifying activity displays zero
values across all Overview components rather than an error.

**Loading State:** Each composed section loads independently with its own
placeholder.

**Error State:** A retry affordance is shown per failed section.

**Success State:** All Overview content reflects the selected date range
accurately.

### 5.2 Reports

**Purpose:** Provide access to the detailed, entity-level reports
underlying the Overview's aggregate figures.

**Business Objective:** Let a manager drill from a summary figure into
the specific customers, debts, or payments composing it.

**Layout Description:** A tab presenting a set of report categories
(Customers, Debts, Collection Cases, Payments, Credit Risk), each leading
to a filterable, detailed list for that entity.

**Components:** Report category list; filterable detail list per
category.

**User Actions:** Select a report category; apply filters; export the
resulting list.

**Navigation:** Selecting a report category opens its detailed list
within the Reports tab.

**Validation Rules:** Filter values applied to a report (date ranges,
status, risk level, amount ranges) must be internally consistent (e.g., a
minimum value must not exceed its corresponding maximum).

**Business Rules:** Every report reflects live, current data at the
moment it is viewed, filtered per the applied criteria.

**Required APIs:** Aging Analysis report API, Customers report API, Debts
report API, Collection Cases report API, Payments report API, Credit Risk
report API, Report Export API.

**Required Database Tables:** Debt records, Customer records, Collection
Case records, Payment records.

**Permissions:** Visible to Business Owner.

**Empty State:** A report with no matching records displays an explicit
"no records" message.

**Loading State:** The detail list displays a placeholder while loading.

**Error State:** A retry affordance is shown if a report fails to load or
export.

**Success State:** The selected report's detailed list renders correctly
filtered and, where requested, exports successfully.

### 5.3 Trends

**Purpose:** Present collection and risk trends over time, beyond a
single period's snapshot.

**Business Objective:** Let a manager identify directional change in
performance rather than only a point-in-time figure.

**Layout Description:** A tab presenting time-series visualizations of
key metrics (collected amount, outstanding amount, risk concentration)
across a selectable range longer than the default Overview period.

**Components:** Extended-range date selector; one or more trend line
charts.

**User Actions:** Adjust the trend range; switch metrics displayed on the
chart.

**Navigation:** Reached by selecting the Trends tab within Analytics.

**Validation Rules:** The selected range must resolve to a valid,
non-inverted start and end date.

**Business Rules:** Trend data is computed as one data point per interval
(e.g., per day) across the selected range for each displayed metric.

**Required APIs:** Collections Trend time-series API.

**Required Database Tables:** Payment records, Debt records.

**Permissions:** Visible to Business Owner.

**Empty State:** A range with no activity renders a flat, zero-value
trend line rather than an empty chart.

**Loading State:** The chart displays a placeholder while data loads.

**Error State:** A retry affordance is shown if trend data fails to load.

**Success State:** The trend chart renders the correct series for the
selected range and metric.

### 5.4 Collection Analytics

**Purpose:** Present the three headline collection-performance KPIs:
Collection Rate, Total Collected, and Average Days.

**Business Objective:** Let a manager assess how effectively the business
is converting outstanding debt into collected revenue.

**Layout Description:** A three-card row within the Overview tab, each
showing a label, a value, and a "vs previous period" delta.

**Components:** Three KPI cards: Collection Rate, Total Collected, Average
Days.

**User Actions:** Tap a card to view its underlying detail in Reports.

**Navigation:** Tapping a card navigates to the corresponding Reports
category.

**Validation Rules:** Not applicable.

**Business Rules:**
- Collection Rate is the total amount collected during the selected
  period divided by the total amount that became due during that same
  period, expressed as a percentage.
- Total Collected is the sum of payments recorded within the selected
  period.
- Average Days is the mean number of days between a debt's due date and
  the date it was fully paid, computed across debts paid within the
  selected period.

**Required APIs:** Collection Analytics KPI retrieval API.

**Required Database Tables:** Payment records, Debt records.

**Permissions:** Visible to Business Owner.

**Empty State:** A period with no payments displays zero values across
all three cards.

**Loading State:** Each card displays a placeholder while loading.

**Error State:** A retry affordance is shown if a card's data fails to
load.

**Success State:** All three cards display accurate values and deltas for
the selected period.

### 5.5 Aging Analysis

**Purpose:** Show how outstanding debt is distributed across age
brackets.

**Business Objective:** Let a manager identify how much exposure is
recent versus long overdue, to prioritize collection effort.

**Layout Description:** A donut chart with a center total, and a legend
of four brackets — Current (0-30), 31-60 Days, 61-90 Days, 90+ Days —
each showing its value and percentage share.

**Components:** Donut chart, center total label, four legend rows.

**User Actions:** Tap a legend row to view the filtered debt list for
that bracket.

**Navigation:** Tapping a legend row navigates to a Debts report filtered
to that aging bracket.

**Validation Rules:** Not applicable.

**Business Rules:** Each open debt is assigned to exactly one bracket
based on the number of days between its due date and the current date,
computed against its remaining balance, not its original amount. The
center total is the sum of remaining balances across all open debts.

**Required APIs:** Aging Analysis retrieval API.

**Required Database Tables:** Debt records.

**Permissions:** Visible to Business Owner.

**Empty State:** A bracket with no debts renders as a zero-value segment
rather than being omitted from the legend.

**Loading State:** The chart displays a placeholder while loading.

**Error State:** A retry affordance is shown if aging data fails to load.

**Success State:** The donut and legend accurately reflect the current
distribution of open debt by age bracket.

### 5.6 Risk Distribution

**Purpose:** Show how the active customer base is distributed across risk
classifications.

**Business Objective:** Let a manager gauge overall portfolio risk
concentration at a glance.

**Layout Description:** A breakdown chart, consistent in style with the
Aging Analysis donut, with a legend of three segments — High Risk, Medium
Risk, Low Risk — each showing its customer count and percentage share.

**Components:** Breakdown chart, legend of three risk segments.

**User Actions:** Tap a legend segment to view the filtered customer list
for that risk level.

**Navigation:** Tapping a segment navigates to a Customers report
filtered to that risk level.

**Validation Rules:** Not applicable.

**Business Rules:** Every active customer is classified into exactly one
of High, Medium, or Low Risk at any given time; the distribution reflects
the current classification of the full active customer base.

**Required APIs:** Risk Distribution retrieval API.

**Required Database Tables:** Customer records.

**Permissions:** Visible to Business Owner.

**Empty State:** A risk level with zero customers renders as a
zero-value segment.

**Loading State:** The chart displays a placeholder while loading.

**Error State:** A retry affordance is shown if risk data fails to load.

**Success State:** The chart accurately reflects the current risk
distribution of the active customer base.

---

## 6. Cases

**Purpose:** Provide a prioritized, filterable worklist of every
collection case, with a path into full case detail, activity history, and
available actions.

**Business Objective:** Let the Business Owner see what needs attention
and act on it without searching customer-by-customer.

**Layout Description:** A filterable Case List at the top level, leading
into Case Details, which in turn presents a Timeline and Actions;
Filters govern what the Case List displays.

**Components:** Case List (Section 6.1); Filters (Section 6.2); Case
Details (Section 6.3); Timeline (Section 6.4); Actions (Section 6.5).

**User Actions:** As documented in Sections 6.1–6.5: switch filter tabs,
tap a case card, view the timeline, perform an action.

**Navigation:** Reached via the Bottom Navigation's "Cases" tab. Leads to
Case Details, Timeline, and Actions, as detailed in Sections 6.1–6.5.

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 6.1–6.5.

**Business Rules:** Governed collectively by the business rules defined
in Sections 6.1–6.5.

**Required APIs:** Case List retrieval API; Case Details retrieval API;
Case Timeline retrieval API; Payment Recording API; Escalation API;
Case Closure API.

**Required Database Tables:** Case records, Customer records, Debt
records, Promise to Pay records, Case Activity/Follow-Up records, Audit
records, Payment records.

**Permissions:** Visible to Business Owner.

**Empty State:** Each component displays its own defined empty state, as
documented in Sections 6.1–6.5.

**Loading State:** Each component loads independently with its own
placeholder, as documented in Sections 6.1–6.5.

**Error State:** Each component displays its own retry affordance, as
documented in Sections 6.1–6.5.

**Success State:** All components display accurate, current case data,
as documented in Sections 6.1–6.5.

### 6.1 Case List

**Purpose:** Present a scannable, filterable list of all collection
cases.

**Business Objective:** Let the Business Owner see what needs attention
without searching customer-by-customer.

**Layout Description:** A header with a running total case count, four
filter tabs (All, High Risk, Follow Up, Promise Due), and a vertical
scrolling list of case cards. Each card shows an avatar initial, customer
name, outstanding amount, a status pill, a risk badge, and a "Last
activity" timestamp.

**Components:** Total count label; tab selector; case card list.

**User Actions:** Switch tabs; tap a case card to open Case Details;
scroll the list.

**Navigation:** Tapping a case card opens Case Details (Section 6.3).

**Validation Rules:** Not applicable.

**Business Rules:** The total count reflects the number of cases matching
the currently active tab. "Last activity" reflects the most recent
recorded activity against that case.

**Required APIs:** Case List retrieval API.

**Required Database Tables:** Case records, Customer records, Debt
records.

**Permissions:** Visible to Business Owner.

**Empty State:** A tab with zero matching cases displays an explicit "no
cases" message.

**Loading State:** Placeholder case cards are displayed while the list
loads.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** The list renders the correct cases for the active tab
with an accurate total count.

### 6.2 Filters

**Purpose:** Narrow the Case List to a specific subset relevant to the
user's current task.

**Business Objective:** Let the Business Owner quickly isolate the highest-priority or
most relevant cases.

**Layout Description:** A tab selector (All, High Risk, Follow Up,
Promise Due) at the top of the Case List, plus a filter icon exposing
additional criteria.

**Components:** Tab selector; filter icon and its associated filter
panel.

**User Actions:** Select a tab; open the filter panel and apply
additional criteria; clear applied filters.

**Navigation:** Filtering occurs within the Case List; no separate screen
is opened for the four primary tabs.

**Validation Rules:** Any additional filter criteria applied must be
internally consistent (e.g., a valid, non-inverted date range).

**Business Rules:**
- High Risk: cases whose customer is classified as High Risk.
- Follow Up: cases with an active, ongoing follow-up requirement — at
  least one recorded follow-up activity that has not yet resulted in
  payment, closure, or an open Promise to Pay.
- Promise Due: cases with an open, unfulfilled Promise to Pay.

**Required APIs:** Case List retrieval API, accepting filter criteria.

**Required Database Tables:** Case records, Customer records, Promise to
Pay records.

**Permissions:** Same as Section 6.1.

**Empty State:** A filter combination with no matches displays an
explicit "no cases" message.

**Loading State:** The list displays a placeholder while the filtered
result loads.

**Error State:** A retry affordance is shown if the filtered query fails.

**Success State:** The list accurately reflects the applied filter
criteria.

### 6.3 Case Details

**Purpose:** Present the complete profile of a single collection case.

**Business Objective:** Give the Business Owner everything needed to understand and
act on a case without navigating elsewhere.

**Layout Description:** A header with the customer name and case
reference. Below: a summary panel (outstanding amount, risk level, case
status, assigned officer), followed by the debt summary, and access
points to the Timeline and available Actions.

**Components:** Case summary panel; debt summary; links to Timeline and
Actions.

**User Actions:** View case and debt summary; open Timeline; perform an
Action.

**Navigation:** Reached by tapping a case card in the Case List. Leads to
Timeline (Section 6.4) and Actions (Section 6.5).

**Validation Rules:** Not applicable at the view level.

**Business Rules:** The summary panel always reflects the case's current,
live status, risk level, and outstanding amount.

**Required APIs:** Case Details retrieval API.

**Required Database Tables:** Case records, Customer records, Debt
records.

**Permissions:** Same as Section 6.1.

**Empty State:** Not applicable — this screen always represents one
existing case.

**Loading State:** A placeholder detail view is displayed while data
loads.

**Error State:** A retry affordance is shown if case details fail to
load; a not-found state is shown if the case no longer exists.

**Success State:** The complete, current case profile is displayed.

### 6.4 Timeline

**Purpose:** Present the full chronological activity history of a case.

**Business Objective:** Let the Business Owner understand everything that has already
happened on a case before taking further action.

**Layout Description:** A reverse-chronological list of activity entries
(calls, payments, promises, escalations, status changes), each showing an
icon, a description, the actor, and a timestamp.

**Components:** Chronological activity list.

**User Actions:** Scroll the timeline; tap an entry to view its full
detail where applicable (e.g., a payment entry links to its receipt).

**Navigation:** Reached from Case Details. An entry may navigate to its
originating record (e.g., a Document).

**Validation Rules:** Not applicable.

**Business Rules:** Every recorded action against the case appears in the
timeline, in the order it occurred, and the timeline is never
retroactively altered.

**Required APIs:** Case Timeline retrieval API.

**Required Database Tables:** Case Activity/Follow-Up records, Audit
records.

**Permissions:** Same as Section 6.1.

**Empty State:** A case with no recorded activity yet displays an
explicit "no activity" message.

**Loading State:** A placeholder list is displayed while the timeline
loads.

**Error State:** A retry affordance is shown if the timeline fails to
load.

**Success State:** The complete, correctly ordered activity history is
displayed.

### 6.5 Actions

**Purpose:** Provide every action a user may take against a case.

**Business Objective:** Let the Business Owner move a case forward
without leaving Case Details.

**Layout Description:** An actions section on Case Details, presenting
the actions available for the case's current status (e.g., Record
Payment, Schedule Reminder, Escalate, Close Case).

**Components:** A set of action buttons, varying by case status.

**User Actions:** Record a payment; schedule a reminder;
escalate the case; close the case.

> **Retired (Product Vision Amendment, Product Owner Decision, 2026-07-31).** "Assign Officer" is removed from this action set — Version 1 has no second tenant user to assign a Case to.

**Navigation:** "Record Payment" opens payment recording. "Schedule
Reminder" opens Reminder Scheduling (Section 7.5). Other actions complete
in place with a confirmation.

**Validation Rules:** Each action enforces the validation rules of its
own workflow (e.g., closing a case requires a closure outcome to be
selected).

**Business Rules:** Only actions valid for the case's current status are
presented (e.g., a closed case does not offer "Close Case" again).

**Required APIs:** Payment Recording API, Escalation API, Case Closure
API.

**Required Database Tables:** Case records, Debt records, Payment
records.

**Permissions:** Each action is independently permission-gated to the Business Owner.

**Empty State:** Not applicable.

**Loading State:** The action button shows a busy state while its request
is in flight.

**Error State:** A failed action displays an error message and leaves the
case state unchanged.

**Success State:** A successful action updates the case's status and
summary immediately.

---

## 7. Reminder Center

**Purpose:** Serve as the primary hub for all follow-up work — client
visits, calls, payment due dates, contract renewals, and promises to pay.

**Business Objective:** Ensure no follow-up action is missed by
centralizing every kind of due or overdue task in one place.

**Layout Description:** A live summary Dashboard, a fixed Reminder Types
classification, a filterable Reminder List, Reminder Details, Reminder
Scheduling, Smart Calendar, WhatsApp Preview, SMS Preview, and the overall
Reminder Workflow governing all of the above.

**Components:** Dashboard (Section 7.1); Reminder Types (Section 7.2);
Reminder List (Section 7.3); Reminder Details (Section 7.4); Reminder
Scheduling (Section 7.5); Smart Calendar (Section 7.6); WhatsApp Preview
(Section 7.7); SMS Preview (Section 7.8); Reminder Workflow (Section
7.9).

**User Actions:** As documented in Sections 7.1–7.9: view the daily
summary, filter the list, open a reminder's details, schedule or
reschedule a reminder, view the calendar, send a reminder via WhatsApp or
SMS.

**Navigation:** Reached via the Bottom Navigation's "Reminders" tab.
Leads to Reminder Details, Reminder Scheduling, Smart Calendar, WhatsApp
Preview, and SMS Preview, as detailed in Sections 7.1–7.9.

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 7.1–7.9.

**Business Rules:** Governed collectively by the business rules defined
in Sections 7.1–7.9.

**Required APIs:** Reminder Summary retrieval API; Reminder List
retrieval API; Reminder Detail, Update, Deletion, and Completion APIs;
Reminder Creation API; Calendar Aggregation retrieval API; Message
Template retrieval API; Message Rendering API. WhatsApp and SMS are not
sent through a backend API in Version 1 — after the message is rendered,
delivery is handed off to the device's own WhatsApp/SMS app (Sections
7.7 / 7.8).

**Required Database Tables:** Reminder records, Debt records, Promise to
Pay records, Message Template records, Sent Message records.

**Permissions:** Visible to Business Owner.

**Empty State:** Each component displays its own defined empty state, as
documented in Sections 7.1–7.9.

**Loading State:** Each component loads independently with its own
placeholder, as documented in Sections 7.1–7.9.

**Error State:** Each component displays its own retry affordance, as
documented in Sections 7.1–7.9.

**Success State:** All components display accurate, current reminder
data, as documented in Sections 7.1–7.9.

### 7.1 Dashboard

**Purpose:** Present a live summary of the day's follow-up workload.

**Business Objective:** Let the Business Owner immediately see how much work is due
today and how it breaks down by type.

**Layout Description:** A header with a Calendar icon and an add ("+")
icon, followed by a summary row — a total due-today count plus per-type
sub-counts (Visits, Calls, Payments) and an Overdue count.

**Components:** Header with Calendar/add icons; summary row with total and
per-type counts.

**User Actions:** Tap the Calendar icon to open the Smart Calendar; tap
add to open Reminder Scheduling; tap a count to filter the Reminder List
below.

**Navigation:** The Calendar icon opens the Smart Calendar (Section 7.6).
The "+" icon opens Reminder Scheduling (Section 7.5).

**Validation Rules:** Not applicable.

**Business Rules:** The total and per-type counts reflect reminders due
today whose status is not Completed; the Overdue count reflects reminders
past their due date whose status is not Completed.

**Required APIs:** Reminder Summary retrieval API.

**Required Database Tables:** Reminder records.

**Permissions:** Visible to Business Owner.

**Empty State:** A zero-workload day displays all-zero counts.

**Loading State:** A placeholder summary is displayed while counts load.

**Error State:** A retry affordance is shown if the summary fails to
load.

**Success State:** The summary accurately reflects the current day's
workload.

### 7.2 Reminder Types

**Purpose:** Define the complete set of follow-up categories supported by
the Reminder Center.

**Business Objective:** Ensure every kind of follow-up work a business
needs to track has a defined, consistent representation.

**Layout Description:** Each reminder, throughout every Reminder Center
screen, displays a type-specific icon and color, per Section 2.5, drawn
from the fixed set of five types.

**Components:** Five reminder types: Client Visit, Follow-up Call,
Payment Due, Contract Renewal, Promise to Pay — each with a dedicated icon
and color.

**User Actions:** Select a type when scheduling a new reminder.

**Navigation:** Not applicable — this is a data classification, not a
screen.

**Validation Rules:** Every reminder must be assigned exactly one of the
five defined types.

**Business Rules:**
- Client Visit: a scheduled in-person visit to a customer.
- Follow-up Call: a scheduled phone follow-up.
- Payment Due: a reminder tied to an upcoming debt due date.
- Contract Renewal: a reminder tied to an upcoming contract/agreement
  renewal date.
- Promise to Pay: a reminder tied to a customer's committed payment date.

**Required APIs:** Not applicable — a fixed classification, not a
retrieved resource.

**Required Database Tables:** Reminder Type is a field on Reminder
records.

**Permissions:** Not applicable.

**Empty State:** Not applicable.

**Loading State:** Not applicable.

**Error State:** Not applicable.

**Success State:** Not applicable.

### 7.3 Reminder List

**Purpose:** Present every reminder, filterable by status, in one
scrollable list.

**Business Objective:** Let the Business Owner work through their follow-up load
systematically, by status.

**Layout Description:** A tab selector (All, Today, Upcoming, Overdue,
Completed) above a list of reminder cards, each showing a type icon,
title, related customer/entity name, a due label, and a contextual
inline action (Open, Complete, Call, or Send Reminder).

**Components:** Tab selector; reminder card list with inline actions.

**User Actions:** Switch tabs; tap a card to open Reminder Details; use an
inline action directly from the list.

**Navigation:** Tapping a card opens Reminder Details (Section 7.4).

**Validation Rules:** An inline action is only available when the
reminder's current status permits it (e.g., "Complete" is unavailable on
an already-completed reminder).

**Business Rules:** A reminder's status — Today, Upcoming, Overdue, or
Completed — is maintained as a persisted state, transitioning to
Completed only through an explicit user action, not automatically upon
its due date passing.

**Required APIs:** Reminder List retrieval API; Reminder Completion API;
Reminder Send API.

**Required Database Tables:** Reminder records.

**Permissions:** Same as Section 7.1.

**Empty State:** A tab with zero matching reminders displays an explicit
"nothing due" message.

**Loading State:** Placeholder cards are displayed while the list loads.

**Error State:** A retry affordance is shown if the list fails to load; a
failed inline action leaves the reminder in its prior visible state.

**Success State:** The list accurately reflects the active tab, and
inline actions update their card immediately.

### 7.4 Reminder Details

**Purpose:** Present the complete detail of a single reminder and the
actions available on it.

**Business Objective:** Give the Business Owner everything needed to decide and act on
one specific follow-up.

**Layout Description:** A header with edit and delete icons. Below: the
reminder's icon, title, related entity name, and due label. Below: a
details list — Type, Due Date, Amount Due, Related Case, Created By,
Created On. Below: a Notes section. Below: a set of action buttons that
depends on the reminder's operational grouping:
- **Client Visit** reminders (`Client Visit` type): Navigate, Check In,
  Log Visit Outcome, and Mark as Completed. Communication actions (Call/
  WhatsApp/SMS) are never shown for this grouping.
- **Follow-up** reminders (every other type): Call, WhatsApp, SMS, Mark
  as Completed, and Reschedule.

**Components:** Details list; Notes section; the grouping-specific action
buttons above.

**User Actions:** Edit the reminder; delete the reminder; mark it
completed; and, per grouping: navigate to / check in at / log the outcome
of a Client Visit, or Call / WhatsApp / SMS / reschedule a Follow-up.

**Navigation:** Reached from Reminder List or Smart Calendar. On a
Follow-up reminder, "WhatsApp" and "SMS" open the Message Preview screen
(Sections 7.7 / 7.8, pre-selected to the chosen channel); "Call" places a
call — for a debt-related reminder it opens the manual call-log sheet
(FR-030) so the attempt is recorded, otherwise it launches the device's
own phone dialer. On a Client Visit reminder, "Navigate" launches the
device's maps app and "Log Visit Outcome" opens a sheet that saves the
outcome. "Reschedule" opens Reminder Scheduling (7.5), pre-filled with
this reminder's data.

**Validation Rules:** "Mark as Completed" is only available while the
reminder is not already Completed. "Check In" is available once per
screen visit and becomes disabled after use.

**Business Rules:** Amount Due is displayed only for reminder types that
carry a monetary amount (Payment Due, Promise to Pay); it is omitted for
Client Visit, Follow-up Call, and Contract Renewal. Created By and
Created On are fixed at creation and never change. Deleting a reminder is
distinct from completing it: a deleted reminder does not appear in any
subsequent view, whereas a completed reminder remains visible under the
Completed tab. **Check In** records a visit check-in on the device only —
Version 1 has no server field for a check-in timestamp, so it is local,
in-memory state and never claims a server-confirmed result. **Log Visit
Outcome** saves the entered outcome into the reminder's Notes via the
Reminder Update API (no new endpoint or field). The **WhatsApp / SMS**
actions render the message and hand off to the device's own messaging app
per Sections 7.7 / 7.8 — no send is recorded and no delivery is tracked
in Version 1.

**Required APIs:** Reminder Detail retrieval API; Reminder Update API
(also used by Log Visit Outcome and Reschedule); Reminder Deletion API;
Reminder Completion API; Message Rendering API (for the WhatsApp/SMS
preview); Manual Call-Log API (for a debt-related Call).

**Required Database Tables:** Reminder records.

**Permissions:** Viewing is available to the same roles as Section 7.1;
editing and deletion are restricted to the reminder's creator.

**Empty State:** Not applicable — this screen always represents one
existing reminder.

**Loading State:** A placeholder detail view is displayed while the
reminder loads.

**Error State:** A not-found state is shown if the reminder no longer
exists; a failed action displays an error message and leaves the detail
unchanged.

**Success State:** The complete, current reminder detail is displayed,
and each action reflects the reminder's current state.

### 7.5 Reminder Scheduling

**Purpose:** Create a new reminder or reschedule an existing one.

**Business Objective:** Let the Business Owner proactively set up future follow-up
work rather than only reacting to work as it becomes due.

**Layout Description:** A header with a save icon. Below: "When should
this reminder be sent?" with four timing options — 1 day before, Same
day, 1 hour before, Custom time (with Date and Time fields when
selected). Below: a Delivery Methods section with four independently
selectable options — In-App Notification, Push Notification, WhatsApp
Message, SMS Message.

**Components:** Timing selector (four options); conditional Custom
Date/Time fields; Delivery Methods selector (four independent toggles).

**User Actions:** Select a timing option; enter a custom date/time if
applicable; toggle delivery methods; save.

**Navigation:** Reached via the "+" icon on the Dashboard (Section 7.1)
or Reminder List (Section 7.3), via "Reschedule" on Reminder Details, or
via "Schedule Reminder" from Actions (Section 6.5). Saving returns to the
originating screen.

**Validation Rules:** Exactly one timing option must be selected. If
Custom time is selected, both Date and Time are required and must resolve
to a moment on or before the reminder's own due date. At least one
delivery method must be selected before saving.

**Business Rules:** The 1-day-before, same-day, and 1-hour-before options
are always computed relative to the reminder's own due date. Each
selected delivery method is dispatched independently — the success or
failure of one delivery method does not affect any other.

**Required APIs:** Reminder Creation API; Reminder Update API (for
rescheduling).

**Required Database Tables:** Reminder records.

**Permissions:** Same as Section 7.1.

**Empty State:** Not applicable — this is a form.

**Loading State:** The save button displays a busy state while the
request is in flight.

**Error State:** A validation failure displays inline field errors with
all entries preserved; a server-side failure displays an error message
with the form remaining editable.

**Success State:** On save, the user is returned to the originating
screen with the new or updated reminder reflected immediately.

### 7.6 Smart Calendar

**Purpose:** Present all dated follow-up work in a calendar grid, viewable
by Day, Week, or Month.

**Business Objective:** Let the Business Owner see follow-up workload distribution
across time, not only as a flat list.

**Layout Description:** A header with a "+" icon. Below: a Day/Week/Month
toggle. Below: a month navigation header with previous/next controls.
Below: a calendar grid with the current day highlighted and dates
carrying items visually marked. Below the grid: a section header for the
selected date, followed by a flat list of that date's items, each with a
time, type icon, title, and related entity name.

**Components:** View toggle; month navigation; calendar grid; selected-
date item list.

**User Actions:** Switch view (Day/Week/Month); navigate between
periods; tap a marked date to update the item list; tap an item to open
Reminder Details; tap "+" to schedule a new reminder.

**Navigation:** Reached from the Reminder Center's AppBar via the
Calendar icon (Section 7.1). Leads to Reminder Details (7.4) and Reminder
Scheduling (7.5).

**Validation Rules:** Not applicable.

**Business Rules:** The grid aggregates every dated item across the
application that carries a due date or scheduled date, including all
five reminder types, Payment Due dates, and Promise to Pay dates. A date
with at least one item is visually marked; a date with none is not.

**Required APIs:** Calendar Aggregation retrieval API.

**Required Database Tables:** Reminder records, Debt records, Promise to
Pay records.

**Permissions:** Visible to Business Owner.

**Empty State:** A selected date with no items displays an explicit
"nothing scheduled" message.

**Loading State:** The grid and item list load independently, each with
its own placeholder.

**Error State:** A retry affordance is shown if calendar data fails to
load.

**Success State:** The grid correctly marks every date with items, and
the item list matches the currently selected date.

### 7.7 WhatsApp Preview

**Purpose:** Preview and send a fully rendered reminder message to a
customer via WhatsApp.

**Business Objective:** Let the Business Owner confirm the exact wording of an
outbound customer message before it is sent.

**Layout Description:** A WhatsApp / SMS channel toggle at the top. Below:
a recipient row (name, phone number) shown once a template is selected.
Below: a "Use Template" selector row and, beneath it, a message bubble
showing the fully rendered message — greeting, reminder content with the
customer's specific amount and due date, closing, and sender name. Below:
a single contextual send button whose label follows the toggle ("Send via
WhatsApp" or "Send via SMS"). WhatsApp Preview and SMS Preview (Section
7.8) are the same screen with the toggle set to the respective channel.

**Components:** Channel toggle; recipient row; template selector; message
preview bubble; contextual send button.

**User Actions:** Switch channel; change the selected template; send via
the selected channel.

**Navigation:** Reached from a Follow-up reminder's WhatsApp or SMS action
on Reminder Details (Section 7.4). (Document sharing uses its own separate
Share screen — see Section 8.8 — not this reminder preview.) Pressing the
send button hands the rendered message off to the device's own WhatsApp
(or SMS) app and returns to the previous screen.

**Validation Rules:** A template must be selected before sending is
enabled. The recipient's phone number must be present.

**Business Rules:** The message body is generated by substituting live
data — customer name, amount due, due date, sender/company name — into
the selected template, via the Message Rendering API. In Version 1 the
message is **not** sent through any backend or third-party API: pressing
"Send via WhatsApp" launches the user's own installed WhatsApp application
(the native `whatsapp://send` app intent, opening the chat directly; if
WhatsApp is not installed, it falls back to the `wa.me` "click to chat"
web link in the browser) with the recipient and rendered text pre-filled,
and **the user manually presses Send inside WhatsApp**. There is no
WhatsApp Business API, no paid messaging gateway, no server-side
"sent-message" record, and no automatic delivery tracking — the app has
no confirmation that the user actually pressed Send, so it never claims
one.

**Required APIs:** Message Template retrieval API; Message Rendering API.
(No send API is called from the client in Version 1.)

**Required Database Tables:** Message Template records; Reminder records
(read only — no Sent Message record is written by this flow in Version 1).

**Permissions:** Same as Section 7.1.

**Empty State:** If no templates are available for the selected channel,
the template selector displays an empty state and sending is disabled.

**Loading State:** The message preview displays a loading state while
being rendered; the send button displays a busy state while the external
app is being launched.

**Error State:** If the message cannot be rendered, or the device has no
app able to handle the WhatsApp/SMS launch, an error message is shown and
the preview remains available for retry or channel/template change.

**Success State:** The device's WhatsApp app opens to the recipient's
chat with the rendered message pre-filled, ready for the user to send.

### 7.8 SMS Preview

**Purpose:** Preview and send a fully rendered reminder message to a
customer via SMS.

**Business Objective:** Provide an equivalent, reliable delivery channel
for customers not reachable via WhatsApp.

**Layout Description:** The same screen as WhatsApp Preview (Section 7.7)
with the channel toggle set to SMS: recipient row, rendered message
preview, template selector, and a single contextual send button labelled
"Send via SMS".

**Components:** Recipient row; message preview; template selector; send
buttons.

**User Actions:** Change the selected template; send via SMS; send via
WhatsApp.

**Navigation:** Reached from the same entry points as Section 7.7; both
channels are available from the same preview screen.

**Validation Rules:** A template must be selected before sending is
enabled. The recipient's phone number must be present and valid for SMS
delivery.

**Business Rules:** Identical rendering rules as Section 7.7, applied to
the SMS channel. Sending launches the device's own SMS app via the
standard `sms:` URI with the rendered text pre-filled, and the user
manually presses Send there. As with WhatsApp, Version 1 writes no
server-side "sent-message" record and performs no delivery tracking.

**Required APIs:** Message Template retrieval API; Message Rendering API.
(No send API is called from the client in Version 1.)

**Required Database Tables:** Message Template records; Reminder records
(read only — no Sent Message record is written by this flow in Version 1).

**Permissions:** Same as Section 7.1.

**Empty State:** Same as Section 7.7.

**Loading State:** Same as Section 7.7.

**Error State:** Same as Section 7.7.

**Success State:** Same as Section 7.7.

### 7.9 Reminder Workflow

**Purpose:** Define the complete lifecycle a reminder passes through, end
to end.

**Business Objective:** Ensure every reminder, regardless of type, is
handled through one consistent, predictable process.

**Layout Description:** Not a distinct screen — this section defines the
workflow expressed across Sections 7.1–7.8.

**Components:** The reminder lifecycle is expressed through the four
statuses defined in Section 7.3 — Today, Upcoming, Overdue, and
Completed — together with the actions that move a reminder between them:
Schedule (creates a reminder with a due date, per Section 7.5), the
grouping-specific action set on Reminder Details (per Section 7.4 — for a
Follow-up reminder: Call / WhatsApp / SMS, where WhatsApp and SMS render
the message and hand off to the device's own app per Sections 7.7/7.8;
for a Client Visit reminder: Navigate / Check In / Log Visit Outcome),
Complete (per Section 7.4), and Reschedule (per Section 7.5, assigning a
new due date). Version 1 records no server-side send and tracks no
delivery for the manual WhatsApp/SMS actions.

**User Actions:** Create (schedule), send, complete, reschedule, delete —
each as documented in their respective sections above.

**Navigation:** Not applicable — a lifecycle definition, not a screen.

**Validation Rules:** A reminder may only move forward through the
lifecycle via the explicit actions defined in Sections 7.4 and 7.5; no
stage is skipped automatically.

**Business Rules:** A reminder is Overdue whenever its due date has
passed and its status is not Completed, regardless of type. A rescheduled
reminder retains its original creation record (Created By, Created On)
while adopting a new due date and timing rule.

**Required APIs:** Covered collectively by the APIs listed in Sections
7.3, 7.4, and 7.5.

**Required Database Tables:** Reminder records.

**Permissions:** Same as Section 7.1.

**Empty State:** Not applicable.

**Loading State:** Not applicable.

**Error State:** Not applicable.

**Success State:** A reminder's recorded status always accurately
reflects its current position in this lifecycle.

---

## 8. Documents

**Purpose:** Provide central access to every generated document —
invoices, receipts, demand letters, and statements — with storage usage
visibility.

**Business Objective:** Let users quickly find, view, download, and share
any document without navigating through the customer or case it
originated from.

**Layout Description:** A type-filterable All Documents list, narrowed by
Invoices, Receipts, Demand Letters, and Statements, each leading to
Preview, Download, and Share.

**Components:** All Documents (Section 8.1); Invoices (Section 8.2);
Receipts (Section 8.3); Demand Letters (Section 8.4); Statements (Section
8.5); Preview (Section 8.6); Download (Section 8.7); Share (Section 8.8).

**User Actions:** As documented in Sections 8.1–8.8: search, filter,
switch tabs, view a document, download it, share it.

**Navigation:** Reached via the Bottom Navigation's "Documents" tab.
Leads to Preview, Download, and Share, as detailed in Sections 8.1–8.8.

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 8.1–8.8.

**Business Rules:** Governed collectively by the business rules defined
in Sections 8.1–8.8.

**Required APIs:** Document List retrieval API; Storage Usage retrieval
API; Invoice, Receipt, Demand Letter, and Statement List retrieval APIs;
Document Detail retrieval API; Document Download API; Document Share
API; Send via WhatsApp API; Send via SMS API.

**Required Database Tables:** Invoice records, Receipt records, Demand
Letter records, Statement records, Document Event records, Sent Message
records.

**Permissions:** Visible to Business Owner.

**Empty State:** Each component displays its own defined empty state, as
documented in Sections 8.1–8.8.

**Loading State:** Each component loads independently with its own
placeholder, as documented in Sections 8.1–8.8.

**Error State:** Each component displays its own retry affordance, as
documented in Sections 8.1–8.8.

**Success State:** All components display accurate, current document
data, as documented in Sections 8.1–8.8.

### 8.1 All Documents

**Purpose:** Present every document across all types in one searchable,
filterable list.

**Business Objective:** Let the Business Owner find any document quickly without
navigating through the customer or case it originated from.

**Layout Description:** A header with search and filter icons. Below:
five tabs (All, Invoices, Receipts, Letters, Other). Below: a "Recent
Documents" section with a "View All" link, followed by a document card
list, each showing a type icon, filename, a one-line descriptor, date,
and file size. Below: a Storage Usage card with a progress bar and a
used/total label.

**Components:** Tab selector; Recent Documents section; document card
list; Storage Usage card.

**User Actions:** Search; filter; switch tabs; tap "View All"; tap a
document card to open Preview.

**Navigation:** Tapping a document card opens Preview (Section 8.6).

**Validation Rules:** Not applicable.

**Business Rules:** The "All" tab shows every document type; "Invoices,"
"Receipts," and "Letters" each filter to their respective type; "Other"
covers any document type not covered by the first three tabs.

**Required APIs:** Document List retrieval API; Storage Usage retrieval
API.

**Required Database Tables:** Invoice records, Receipt records, Demand
Letter records, Statement records.

**Permissions:** Visible to Business Owner.

**Empty State:** A tab with no matching documents displays an explicit
"no documents" message. A new tenant with no documents at all displays an
empty Recent Documents section.

**Loading State:** Tab content and the Storage Usage card load
independently, each with its own placeholder.

**Error State:** A retry affordance is shown per failed section.

**Success State:** Documents populate correctly per the active tab, and
Storage Usage reflects current, live usage.

### 8.2 Invoices

**Purpose:** Present all invoice documents.

**Business Objective:** Give the Business Owner quick access to every invoice issued
to customers.

**Layout Description:** The "Invoices" tab within All Documents (8.1),
filtered to invoice-type documents only.

**Components:** Filtered document card list.

**User Actions:** Tap an invoice card to open Preview.

**Navigation:** Tapping a card opens Preview (Section 8.6).

**Validation Rules:** Not applicable.

**Business Rules:** An invoice represents the amount billed to a customer
for goods or services rendered, generated at the point a debt is
established, and is immutable once generated.

**Required APIs:** Invoice List retrieval API.

**Required Database Tables:** Invoice records.

**Permissions:** Same as Section 8.1.

**Empty State:** No invoices yet displays an explicit "no invoices"
message.

**Loading State:** Placeholder cards are displayed while loading.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** All invoices are listed correctly.

### 8.3 Receipts

**Purpose:** Present all receipt documents.

**Business Objective:** Give the Business Owner quick access to proof of every payment
collected.

**Layout Description:** The "Receipts" tab within All Documents (8.1),
filtered to receipt-type documents only.

**Components:** Filtered document card list.

**User Actions:** Tap a receipt card to open Preview.

**Navigation:** Tapping a card opens Preview (Section 8.6).

**Validation Rules:** Not applicable.

**Business Rules:** A receipt is generated automatically whenever a
payment is recorded and is immutable once generated.

**Required APIs:** Receipt List retrieval API.

**Required Database Tables:** Receipt records, Payment records.

**Permissions:** Same as Section 8.1.

**Empty State:** No receipts yet displays an explicit "no receipts"
message.

**Loading State:** Placeholder cards are displayed while loading.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** All receipts are listed correctly.

### 8.4 Demand Letters

**Purpose:** Present all demand letter documents.

**Business Objective:** Give the Business Owner quick access to formal collection
correspondence issued to customers.

**Layout Description:** The "Letters" tab within All Documents (8.1),
filtered to demand-letter-type documents only.

**Components:** Filtered document card list.

**User Actions:** Tap a letter card to open Preview.

**Navigation:** Tapping a card opens Preview (Section 8.6).

**Validation Rules:** Not applicable.

**Business Rules:** A demand letter is generated from an approved
template at the point a debt is escalated, and is immutable once
generated.

**Required APIs:** Demand Letter List retrieval API.

**Required Database Tables:** Demand Letter records.

**Permissions:** Same as Section 8.1.

**Empty State:** No demand letters yet displays an explicit "no letters"
message.

**Loading State:** Placeholder cards are displayed while loading.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** All demand letters are listed correctly.

### 8.5 Statements

**Purpose:** Present all account statement documents.

**Business Objective:** Give the Business Owner quick access to full-account
statements for any customer.

**Layout Description:** Presented under the "Other" tab within All
Documents (8.1), filtered to statement-type documents.

**Components:** Filtered document card list.

**User Actions:** Tap a statement card to open Preview.

**Navigation:** Tapping a card opens Preview (Section 8.6).

**Validation Rules:** Not applicable.

**Business Rules:** A statement reflects a customer's full account
history at the point it is generated and is immutable once generated.

**Required APIs:** Statement List retrieval API.

**Required Database Tables:** Statement records.

**Permissions:** Same as Section 8.1.

**Empty State:** No statements yet displays an explicit "no statements"
message.

**Loading State:** Placeholder cards are displayed while loading.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** All statements are listed correctly.

### 8.6 Preview

**Purpose:** Display the full content of a single document before
downloading or sharing it.

**Business Objective:** Let a user confirm a document's content is
correct before acting on it further.

**Layout Description:** A full-screen document viewer with a header
showing the document's filename and type, and access to Download (8.7)
and Share (8.8) actions.

**Components:** Document viewer; header with Download and Share actions.

**User Actions:** View the document; download it; share it; navigate
back.

**Navigation:** Reached by tapping any document card across Sections
8.1–8.5. Leads to Download (8.7) and Share (8.8).

**Validation Rules:** Not applicable.

**Business Rules:** A previewed document always reflects the exact,
final, immutable content generated for it — never a live-recomputed
version.

**Required APIs:** Document Detail retrieval API.

**Required Database Tables:** Invoice, Receipt, Demand Letter, and
Statement records.

**Permissions:** Same as Section 8.1.

**Empty State:** Not applicable — this screen always represents one
existing document.

**Loading State:** A placeholder viewer is displayed while the document
loads.

**Error State:** A not-found state is shown if the document no longer
exists; a retry affordance is shown on a failed load.

**Success State:** The complete document renders correctly.

### 8.7 Download

**Purpose:** Save a document to the user's device.

**Business Objective:** Let a user retain or transfer a document outside
the application.

**Layout Description:** A download action available from the Preview
screen's header.

**Components:** Download icon/button.

**User Actions:** Tap Download to save the document file.

**Navigation:** Available from Preview (Section 8.6); does not navigate
to a new screen.

**Validation Rules:** Not applicable.

**Business Rules:** Every download of a document is recorded against
that document's history for audit purposes.

**Required APIs:** Document Download API.

**Required Database Tables:** Invoice, Receipt, Demand Letter, and
Statement records; Document Event records.

**Permissions:** Same as Section 8.1.

**Empty State:** Not applicable.

**Loading State:** The download control displays a busy state while the
file is prepared.

**Error State:** A failed download displays an error message with a
retry option.

**Success State:** The document file is successfully saved to the
device.

### 8.8 Share

**Purpose:** Send a document directly to a customer via WhatsApp or SMS.

**Business Objective:** Let the Business Owner deliver a document to a customer
without leaving the application.

**Layout Description:** A share action available from the Preview
screen's header, opening the document's own Share screen — a WhatsApp/SMS
channel picker and a message-template selector for the document. This is
distinct from the Reminder WhatsApp/SMS Preview (Sections 7.7 / 7.8):
document Share sends server-side via `POST /documents/{id}/share` (and is
recorded), whereas the Reminder actions hand off to the device's own app
without a record.

**Components:** Share icon/button; channel selection; template selector.

**User Actions:** Tap Share; select a delivery channel; select a
template; send.

**Navigation:** Available from Preview (Section 8.6). Opens the document's
Share screen and, on send, returns to Preview.

**Validation Rules:** The recipient's contact information must be present
and valid for the selected channel.

**Business Rules:** Every share of a document is recorded against that
document's history and against the recipient's record, for audit
purposes.

**Required APIs:** Document Share API; Send via WhatsApp API; Send via
SMS API.

**Required Database Tables:** Invoice, Receipt, Demand Letter, and
Statement records; Document Event records; Sent Message records.

**Permissions:** Same as Section 8.1.

**Empty State:** Not applicable.

**Loading State:** The share action displays a busy state while the send
request is in flight.

**Error State:** A failed share displays an error message with a retry
option.

**Success State:** A confirmation is shown, and the share is recorded in
the document's history.

---

## 9. Notifications

**Purpose:** Present every business event generated elsewhere in the
system (Reminder Engine, Payment Tracking, Document Generation, Credit &
Risk Management, Professional Collection) as an in-app, consumption-only
notification.

**Business Objective:** Ensure the Business Owner never misses a
qualifying business event without having to check every module
individually.

**Layout Description:** A List (Section 9.1) reached from the Home
Dashboard's Notification Bell (Section 4.6), leading into a Detail view
(Section 9.2) for any tapped entry.

**Components:** List (Section 9.1); Detail (Section 9.2).

**User Actions:** As documented in Sections 9.1–9.2: view the list, mark
one or all notifications read, tap an entry to view its detail, open the
entry's related record where resolvable.

**Navigation:** Reached from the Home Dashboard's Notification Bell
(Section 4.6). Leads to Detail (Section 9.2) and, where resolvable, the
related Debt, Customer, or Professional Collection Request record.

**Validation Rules:** Not applicable.

**Business Rules:** This module is strictly consumption-only, per
`01_Project_Overview.md` §1.8/§1.9 — it never generates, schedules, or
originates an event itself; every notification is created as a passive
consequence of a qualifying event in its owning module. There is no
create endpoint (`07_API_Design.md` §11) and no single-item retrieval
endpoint — a notification is only ever reached from an already-loaded
List entry, never deep-linked.

**Required APIs:** `GET /notifications` (paginated, optional `type`
filter); `GET /notifications/history`; `PATCH /notifications/{id}/read`;
`PATCH /notifications/mark-all-read`.

**Required Database Tables:** Notification records.

**Permissions:** Every notification is strictly personal — scoped to the
authenticated user's own `recipient_user_id`, in addition to tenant
scoping. Visible to Business Owner.

**Empty State:** No notifications yet displays an explicit "No
notifications yet" message.

**Loading State:** The list displays a loading indicator while the first
page loads.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** All components display accurate, current notification
data, as documented in Sections 9.1–9.2.

### 9.1 List

**Purpose:** Present every notification, most recent first, in one
scrollable list.

**Business Objective:** Let the Business Owner scan every recent business
event in one place.

**Layout Description:** A list of notification rows, each showing a
type-specific icon (Section 2.5 convention), a type label, the related
entity type, a timestamp, and an unread indicator dot. An app bar action
to mark every notification read appears whenever at least one unread
notification is present.

**Components:** Notification row list; "Mark all read" action.

**User Actions:** Tap a row (marks it read and opens Detail, Section
9.2); tap "Mark all read"; pull to refresh; scroll to load more.

**Navigation:** Tapping a row opens Detail (Section 9.2).

**Validation Rules:** Not applicable.

**Business Rules:** Tapping a row marks that notification read via the
real endpoint before opening Detail — never a client-only state change.
"Mark all read" calls the real bulk endpoint and updates every visible
row.

**Required APIs:** `GET /notifications`; `PATCH /notifications/{id}/read`;
`PATCH /notifications/mark-all-read`.

**Required Database Tables:** Notification records.

**Permissions:** Same as Section 9.

**Empty State:** No notifications yet displays an explicit "No
notifications yet" message.

**Loading State:** A loading indicator is displayed while the first page
loads; a smaller one while loading the next page.

**Error State:** A retry affordance is shown if the list fails to load.

**Success State:** The list accurately reflects current notification
data, and read/unread state updates immediately after each action.

### 9.2 Detail

**Purpose:** Present the complete detail of a single notification.

**Business Objective:** Give the Business Owner the full context of one
event and, where possible, a direct path to the record it concerns.

**Layout Description:** A type icon and label, the related entity type
and reference id, the received timestamp, read/unread status, and — only
for entity types this app can resolve to a real screen (`debt`,
`customer`, `professional_collection_request`) — an "Open" button.

**Components:** Notification detail panel; conditional "Open" button.

**User Actions:** View the detail; tap "Open" where available.

**Navigation:** Reached only from an already-loaded List (Section 9.1)
entry, never deep-linked (there is no single-item retrieval endpoint).
"Open" navigates to the related Debt, Customer, or Professional
Collection Request Detail screen.

**Validation Rules:** Not applicable.

**Business Rules:** "Open" is offered only for entity types this app
confidently resolves to an existing screen and id space; document-
generating types (`receipt`, `invoice`, `demand_letter`, `statement`) and
`payment` are not offered an "Open" action rather than guessing at an
unconfirmed id space.

**Required APIs:** None beyond Section 9.1's `GET /notifications` — this
screen renders data already fetched by the List.

**Required Database Tables:** Notification records.

**Permissions:** Same as Section 9.

**Empty State:** Not applicable — this screen always represents one
already-loaded notification.

**Loading State:** Not applicable — no additional fetch occurs.

**Error State:** Not applicable.

**Success State:** The complete notification detail is displayed
accurately.

---

## 10. Account / Profile

**Purpose:** Provide the Business Owner a single place to view their
profile, change their password, and reach Business Profile, Settings,
Notifications, and Bulk Import, plus Logout.

**Business Objective:** Consolidate account-level actions off the Home
Dashboard header (which now leads with the Notification Bell, Section
4.6) into one dedicated destination.

**Layout Description:** A screen reached by tapping the Home Dashboard's
greeting/avatar. It opens with a profile summary card (avatar, name,
email) that itself is the entry point to the Profile screen (Section
10.2), followed by a grouped menu — Business Profile, Settings,
Notifications, About, Bulk Import — and a separated Logout action below.

**Components:** Menu (Section 10.1); Profile (Section 10.2); Business
Profile (Section 10.3); Settings (Section 10.4); Logout (Section 10.5);
Bulk Import (Section 10.6); About (Section 10.7).

**User Actions:** As documented in Sections 10.1–10.7: open any menu
item, view profile, change password, run a customer import, read the
About screen, log out.

**Navigation:** Reached by tapping the greeting on the Home Dashboard
(Section 4). Leads to Profile (10.2), Business Profile (10.3), Settings
(10.4), Notifications (Section 9), Bulk Import (10.6), About (10.7),
and Logout (10.5).

**Validation Rules:** Governed collectively by the validation rules
defined in Sections 10.1–10.7.

**Business Rules:** Governed collectively by the business rules defined
in Sections 10.1–10.7.

**Required APIs:** `POST /change-password` (Section 10.2);
`GET / PUT /admin/settings/company-profile` (Business Profile, Section
10.3); `GET / PUT /admin/settings/preferences` (Settings, Section 10.4);
`POST /customers/import` and `POST /customers/import/{batch}/commit`
(Bulk Import, Section 10.6); `POST /logout` (Section 10.5). All are
reachable by the Business Owner, who holds the tenant admin role.

**Required Database Tables:** User records, Tenant records, System
Settings records, Customer records, Import Batch/Row records.

**Permissions:** Visible to Business Owner.

**Empty State:** Each component displays its own defined state, as
documented in Sections 10.1–10.5.

**Loading State:** Not applicable at the menu level.

**Error State:** Not applicable at the menu level.

**Success State:** Each menu item reliably opens its corresponding
screen.

### 10.1 Menu

**Purpose:** List every Account / Profile destination.

**Business Objective:** Give the Business Owner one predictable place to
find every account-level action.

**Layout Description:** A tappable profile summary card at the top
(avatar, name, email → Profile, Section 10.2), then a grouped menu card
with rows in order — Business Profile, Settings, Notifications, About,
Bulk Import — each with an icon and a label, and a separated Logout
action beneath the group.

**Components:** Profile summary card; grouped menu rows; Logout action.

**User Actions:** Tap the profile card or any menu row.

**Navigation:** As listed in Section 10's own Navigation.

**Validation Rules:** Not applicable.

**Business Rules:** All rows are always shown.

**Required APIs:** Not applicable — a pure navigation menu.

**Required Database Tables:** Not applicable.

**Permissions:** Visible to Business Owner.

**Empty State:** Not applicable.

**Loading State:** Not applicable.

**Error State:** Not applicable.

**Success State:** All rows are displayed and each reliably opens its
destination.

### 10.2 Profile

**Purpose:** Show the signed-in user's own name and email, and provide
access to Change Password.

**Business Objective:** Let the Business Owner confirm their own account
identity and update their credential.

**Layout Description:** Name and email (read-only), and a Change Password
row.

**Components:** Name/email display; Change Password row.

**User Actions:** View name/email; tap Change Password.

**Navigation:** Change Password opens a form on the same flow, submitting
directly (no separate confirmation screen).

**Validation Rules:** Change Password requires the current password and a
new password meeting the platform-wide policy (minimum 12 characters),
confirmed by re-entry.

**Business Rules:** Name and email are the same `{id, name, email}`
already cached from login/refresh (`UserResource`) — no separate profile-
retrieval call is made. There is no self-service update-profile endpoint,
so name and email are read-only; no edit action is offered.

**Required APIs:** `POST /change-password`.

**Required Database Tables:** User records.

**Permissions:** Visible to the signed-in user, for their own account
only.

**Empty State:** Not applicable.

**Loading State:** Not applicable — data is already cached.

**Error State:** An incorrect current password displays the server's own
message inline; the form remains editable.

**Success State:** Change Password displays a confirmation on success.

### 10.3 Business Profile

**Purpose:** Show the Business Owner's own business/company details.

**Business Objective:** Let the Business Owner view their business's
identifying information from within the mobile app.

**Layout Description:** An editable form pre-filled with the business's
current details: a Logo picker, Company Name, Contact Email, Contact
Phone, and Business Address, with a "Save Changes" button.

**Components:** Logo picker; Company Name field; Contact Email field;
Contact Phone field; Business Address field; Save button.

**User Actions:** Edit any field; pick a new logo image; save the changes.

**Navigation:** Reached from the Account / Profile menu (10.1). Saving
remains on the screen and shows a success confirmation.

**Validation Rules:** Company Name is required. Contact Email, if
entered, must be a valid email address. A picked logo must be a JPEG or
PNG image no larger than 2 MB (enforced client-side before upload).

**Business Rules:** The screen is wired to `GET / PUT /admin/settings/
company-profile` and is reachable by the Business Owner, who holds the
tenant admin role. Fields map to the `CompanyProfileResource` shape
(`business_name`, `logo_path`, `address`, `contact_email`,
`contact_phone`). The logo is the one file-upload field in the app; it is
sent as multipart (`POST` with `_method=PUT`). A previously-saved logo is
acknowledged with a neutral icon rather than an image preview, because
`logo_path` is a private-disk storage path with no servable URL — only a
logo just picked on the device is shown as an image preview.

**Required APIs:** `GET /admin/settings/company-profile`;
`PUT /admin/settings/company-profile` (sent as `POST` + `_method=PUT` to
carry the multipart logo).

**Required Database Tables:** Tenant records.

**Permissions:** Visible to Business Owner.

**Empty State:** Not applicable — the form always represents the tenant's
current company profile.

**Loading State:** A loading indicator is shown while the profile is
retrieved; the Save button shows a busy state while the update is in
flight.

**Error State:** A failed load shows a retry affordance; a failed save
shows the server's error message and leaves the form editable.

**Success State:** On save, a "Business Profile updated successfully"
confirmation is displayed.

### 10.4 Settings

**Purpose:** Let the Business Owner view and change the app and
tenant-level settings available in Version 1.

**Business Objective:** Give the Business Owner one predictable place for
language, notification, business-policy, and security preferences.

**Layout Description:** A grouped settings screen with four sections:
- **General** — Language selection (persisted locally on the device; no
  backend).
- **Notifications** — Push, Reminder, and Payment notification toggles,
  plus the per-channel reminder-day schedules (WhatsApp / SMS / Call days).
- **Business** — Default Credit Limit, Credit-Limit Reminder toggle, Soft
  Limit Warning Threshold, and Professional Collection Threshold (days).
- **Security** — Change Password (opens Section 10.2's Change Password
  form) and a Biometric Login toggle.

Default Currency and Default Date Format are shown as an honest
"unavailable — no backend endpoint" section, since no such field exists
in the backend.

**Components:** Section groups; toggles; numeric/day-list fields; a Save
button; the honest unavailable section for currency/date-format.

**User Actions:** Change language; toggle notification and biometric
settings; edit business-policy values; save; open Change Password.

**Navigation:** Reached from the Account / Profile menu (10.1). Change
Password opens Section 10.2's form.

**Validation Rules:** Reminder-day lists must be whole numbers between 1
and 365. Business-policy numeric fields follow the backend's own
validation on save.

**Business Rules:** The Notifications and Business groups are wired to
`GET / PUT /admin/settings/preferences` (System Preferences, FR-069) and
are reachable by the Business Owner, who holds the tenant admin role.
Language is device-local only. Biometric Login performs a real device
capability check and a real biometric prompt and is persisted locally
only; on a device without biometric hardware it is shown as unavailable.

**Required APIs:** `GET /admin/settings/preferences`;
`PUT /admin/settings/preferences`.

**Required Database Tables:** System Settings records.

**Permissions:** Visible to Business Owner.

**Empty State:** Not applicable — the screen always represents the
current settings.

**Loading State:** A loading indicator is shown while preferences are
retrieved; the Save button shows a busy state while the update is in
flight.

**Error State:** A failed load shows a retry affordance; a failed save
shows the server's error message and leaves the form editable.

**Success State:** On save, a success confirmation is displayed.

### 10.5 Logout

**Purpose:** End the current session.

**Business Objective:** Let the Business Owner securely sign out.

**Layout Description:** A Logout row at the bottom of the Account /
Profile menu (10.1) — moved here from the Home Dashboard header, which
now leads with the Notification Bell (Section 4.6) instead.

**Components:** Logout row.

**User Actions:** Tap Logout.

**Navigation:** Returns to Login.

**Validation Rules:** Not applicable.

**Business Rules:** A best-effort server-side token revocation is
attempted; local session state is always cleared regardless of whether
the network call succeeds.

**Required APIs:** `POST /logout`.

**Required Database Tables:** Not applicable (token revocation only).

**Permissions:** Visible to the signed-in user.

**Empty State:** Not applicable.

**Loading State:** Not applicable.

**Error State:** Not applicable — logout always succeeds locally even if
the server call fails.

**Success State:** The session ends and the user is returned to Login.

### 10.6 Bulk Import

**Purpose:** Let the Business Owner import many customers at once from an
Excel spreadsheet (the Customer Import module).

**Business Objective:** Save the Business Owner from entering existing
customers one by one when onboarding.

**Layout Description:** A screen with a Sample Template section, an Upload
File section (accepted formats: `.xlsx`, `.xls`) with a file picker and a
selected-file card, a single "Import" button, and — after a run — an
Import Summary card (Imported Successfully, Skipped (Duplicate), Failed)
followed by a Failed Rows list showing each failed row's validation
errors.

**Components:** Sample Template section; file picker / selected-file card;
Import button; Import Summary card; Failed Rows list.

**User Actions:** Pick an Excel file; start the import; review the
summary.

**Navigation:** Reached from the Account / Profile menu (10.1).

**Validation Rules:** Only `.xlsx` / `.xls` files are accepted. Per-row
validation is performed server-side; invalid rows are reported back
individually in the Failed Rows list.

**Business Rules:** The screen wraps the real two-step backend flow —
`POST /customers/import` (preview) then
`POST /customers/import/{batch}/commit` — behind a single "Import"
button. Version 1 has no per-row duplicate-resolution UI: every duplicate
match defaults to `skip` server-side (the backend's documented safe
default). Row outcomes map to the summary as: `created`/`updated` →
Imported Successfully; `skipped` → Skipped (Duplicate); `skipped_invalid`
→ Failed. The Sample Template download is shown as unavailable, since no
backend endpoint provides a template file.

**Required APIs:** `POST /customers/import`;
`POST /customers/import/{batch}/commit`.

**Required Database Tables:** Customer records, Import Batch records,
Import Row records.

**Permissions:** Visible to Business Owner.

**Empty State:** Before a file is chosen, the upload prompt is shown; a
run that finds no rows reports "No rows found in the uploaded file."

**Loading State:** The Import button shows a busy state while the
preview + commit run.

**Error State:** A failed import shows the error with a retry affordance;
individual invalid rows are listed under Failed Rows with their
validation messages.

**Success State:** The Import Summary displays the counts of imported,
skipped-duplicate, and failed rows.

### 10.7 About

**Purpose:** Present the app's branding, description, version information,
and legal/support links in one dedicated destination.

**Business Objective:** Give the Business Owner a single place to learn
what Deendoon is and to find the app's version and support/legal entries.

**Layout Description:** A scrollable screen with: the Deendoon brand mark
and tagline; an "About" description section (Hordhac Deendoon); a
"what Deendoon helps you do" benefits list; a closing summary (Gunaanad);
an information card (Macluumaad) showing Version, Build Number, and
Copyright; and a "KUWA KALE" (Other) menu of four rows — Privacy Policy,
Terms & Conditions, Contact Support, and Rate the App.

**Components:** Brand mark; description/benefits/summary cards;
information card; four-row Other menu.

**User Actions:** Read the app description; view the version/build/
copyright; tap any of the four Other rows.

**Navigation:** Reached from the Account / Profile menu (10.1).

**Validation Rules:** Not applicable.

**Business Rules:** The descriptive copy is the Product Owner's approved
text. Version and Build Number are read from the installed app bundle at
runtime (never hardcoded), and Copyright shows the current year. The four
Other rows (Privacy Policy, Terms & Conditions, Contact Support, Rate the
App) have no live destination in Version 1 — each shows an honest
"coming soon" acknowledgement rather than a fabricated screen or a dead
link, since no content source or store listing exists for them yet.

**Required APIs:** None — all content is static app copy or read from the
local app bundle.

**Required Database Tables:** Not applicable.

**Permissions:** Visible to Business Owner.

**Empty State:** Not applicable.

**Loading State:** The Version/Build values render once the app bundle
info resolves.

**Error State:** Not applicable.

**Success State:** The About content renders with the real installed
version and build number.

---

## 11. Reusable Components

The following components recur across multiple screens and are governed
by the standards in Section 2 wherever they appear:

- **Header Bar** — used on every screen; primary screens show a greeting
  or title with contextual icons; secondary screens show a back arrow,
  title, and contextual icons.
- **Tab Selector** — used on Analytics, Cases, and Reminder List/Reminder
  Center to switch between filtered views of the same underlying data.
- **KPI Card** — used on Home Dashboard and Analytics to present a
  labeled value with an optional delta.
- **List Card / Row** — used for case entries, reminder entries, document
  entries, and notification entries; always presents an icon, a primary
  label, and supporting metadata.
- **Donut Chart with Legend** — used for Aging Analysis and Risk
  Distribution.
- **Line Chart** — used for Collections Trend and other time-series
  displays.
- **Progress Bar** — used for Storage Usage.
- **Status Badge/Pill** — used to display risk level, case status, and
  reminder status, always following the Status Colors defined in Section
  2.9.
- **Primary/Secondary/Destructive Buttons** — used consistently for
  affirmative, supporting, and workflow-ending actions respectively.
- **Calendar Grid** — used in Smart Calendar.
- **Message Preview Bubble** — used in WhatsApp Preview and SMS Preview.

---

## 12. UX Rules

- Every screen must present its most important value or status before
  any supporting detail.
- Every list-based screen must define and display an explicit empty
  state; a zero-result state must never be visually indistinguishable
  from a failed or loading state.
- Every destructive or workflow-ending action (Reschedule, Delete, Close
  Case) must use the Destructive button style and must not be reachable
  by a single accidental tap without visual distinction from surrounding
  actions.
- Every action that sends customer-facing communication (WhatsApp, SMS)
  must present a preview of the exact content before sending; no
  customer-facing message may be sent without an explicit confirmation
  action.
- Status, risk, and urgency must always be communicated using the fixed
  color vocabulary in Section 2.9, with no screen introducing an
  alternate meaning for any of these colors.
- Every count or value shown on a summary screen (Home Dashboard,
  Reminder Center Dashboard) must be tappable through to the detailed
  view backing it.
- The Bottom Navigation must remain visible and functional on all five
  primary screens at all times; it must never be obscured by a modal or
  overlay without an explicit dismiss action.

---

## 13. Business Rules

The following business rules apply globally, across multiple screens:

- **Open Debt:** a debt not in a Paid, Cancelled, or Written-Off state.
  This definition governs Total Outstanding, Overdue Amount, and Aging
  Analysis consistently.
- **Risk Classification:** every active customer carries exactly one risk
  level at any time — High, Medium, or Low — governing High Risk KPIs,
  Case filtering, and Risk Distribution consistently.
- **Case Status Lifecycle:** a case is Open until formally closed with a
  recorded closure outcome; a closed case cannot be reopened through any
  action documented in this specification.
- **Reminder Lifecycle:** governed in full by Section 7.9; a reminder's
  status is always an explicit, persisted state, never purely inferred
  from its due date.
- **Document Immutability:** every generated document (Invoice, Receipt,
  Demand Letter, Statement) is fixed at the moment of generation and is
  never subsequently altered.
- **Audit Trail:** every document download, every document share (which
  is sent server-side via `POST /documents/{id}/share`, Section 8.8), and
  every debt-related manual reminder-log action (FR-030 Call/WhatsApp/SMS
  log) is recorded for audit purposes, attributing the action to the user
  and the time it occurred. In Version 1, the manual WhatsApp and SMS
  actions on Reminder Details (Sections 7.7 / 7.8) hand the message off to
  the device's own messaging app and are **not** recorded — the app has
  no confirmation the user actually sent the message, so it never fabricates
  a send record.
- **Tenant Isolation:** all data displayed on any screen is scoped to the
  authenticated user's own business; no screen displays data belonging to
  another business.

---

## 14. Version History

| Version | Date | Status | Description |
|---|---|---|---|
| 1.0 | 2026-07-27 | **FROZEN** | Initial approved UI specification, covering Home Dashboard, Analytics, Cases, Reminder Center, and Documents, and all screens reachable from them. |
| 1.0 (amended) | 2026-08-02 | **FROZEN** | V1 Scope Expansion (Product Owner Decision): added Section 9 (Notifications, implementing already-approved/frozen SRS Module 10 against its already-built backend) and Section 10 (Account / Profile, new scope — Profile and Change Password real; Business Profile and Settings honestly empty pending backend). Home Dashboard header (Section 4) now leads with a Notification Bell (Section 4.6) in place of the prior Logout icon, which moved to Section 10.5. See the fifth amendment note at the top of this document. |
| 1.0 (amended) | 2026-08-05 | **FROZEN** | V1 Implementation Alignment (Product Owner Decision): documentation synchronized to the shipped Version 1 Flutter implementation. §4.4 Quick Actions are Add Case, Record Payment, Add Reminder, Global Search (Scan Invoice / Send Message retired). §7.7 / §7.8 WhatsApp & SMS are sent by rendering the message and launching the device's own WhatsApp/SMS app (manual send, no WhatsApp Business API, no paid gateway, no send record, no delivery tracking). §7.4 Reminder Details actions split into Client Visit (Navigate, Check In, Log Visit Outcome, Mark as Completed) and Follow-up (Call, WhatsApp, SMS, Mark as Completed, Reschedule) groupings. §7.1 / §7.6 Calendar reached from the Reminder Center AppBar Calendar icon. §10 documents the real Business Profile and Settings screens and adds Bulk Import (§10.6) and About (§10.7). §13 audit-trail rule narrowed to exclude unrecorded manual WhatsApp/SMS sends. See the sixth amendment note at the top of this document. |

---

## 15. Freeze Declaration

**DEENDOON MOBILE APP — UI VERSION 1.0 — STATUS: FROZEN**

This specification, as written, is the final and complete definition of
Deendoon Mobile Application UI Version 1.0. It has been reviewed and
approved by the Product Owner.

Effective immediately:

- No team — Backend, Flutter, or QA — may deviate from this specification
  without a new, formally approved version of this document.
- This document is binding for all development, testing, and release
  activity referencing UI Version 1.0.
- Any change to any screen, component, workflow, or rule described herein
  constitutes a new UI version and requires a new Product Owner approval
  and a new version of this document.

This document is the single source of truth for the Deendoon Mobile
Application, Version 1.0.

========================================================

DOCUMENT STATUS

Status:
APPROVED

Approved By:
Product Owner

Document:
Mobile_UI_V1_Frozen.md

Version:
1.0

State:
FROZEN

Approval Date:
2026-07-27

Effective Date:
2026-07-27

--------------------------------------------------------

This document is the official UI Specification for the
Deendoon Mobile Application.

It is the Single Source of Truth for:

• Backend Development
• Flutter Mobile Development
• Quality Assurance (QA)
• Future Product Enhancements

Any modification to this document after approval
requires formal Product Owner approval.

========================================================
