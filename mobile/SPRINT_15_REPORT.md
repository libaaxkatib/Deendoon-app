# Sprint 15 — Documents Center

## Summary

Implemented the Documents Center module end-to-end against the real, tested Laravel backend, matching the approved Mobile UI Board (`Mobile_UI_V1_Frozen.md` §8) and the real capabilities exposed by `DocumentController`. The module covers Documents Home (tabs, search, Recent Documents, Storage Usage), a full paginated Document List ("View All"), a real in-app PDF Preview with Download and Share, and a Share flow with channel + template selection. Debt Detail's existing "Related Documents" section was rewired to open the new real Preview screen. A follow-up UI polish pass (requested after the first live review) enlarged the PDF preview viewport, confirmed/locked in Fit-Width as the default zoom state, fixed the Storage Usage unit display, added a proper icon-based empty state for the "Other" (statement) tab, and clarified the search field's placeholder text.

## Features Completed

- **Documents Home** (§8.1): type tabs (All/Invoices/Receipts/Letters/Other) backed by real `type` filtering, debounced server-side search by reference number, Recent Documents preview (first 5 of the shared list), "View All" link, and a Storage Usage card.
- **Document List ("View All")**: full paginated list sharing the same live provider/state as Home (tab/search stays in sync, no duplicate fetch), infinite scroll via `loadMore()`.
- **Document Preview** (§8.6–8.8): real PDF rendering via `pdfx`, Download action (saves bytes to device storage), Share action (routes to the Share screen). Bytes are fetched once per visit and reused for both viewing and downloading, avoiding a redundant server-side download record.
- **Document Share**: WhatsApp/SMS channel picker reusing the Reminders feature's real `messageTemplatesProvider`/`GET /message-templates` — no duplicate endpoint wrapper.
- **Storage Usage card**: real `usedBytes`/`totalBytes`/`usedPercentage` from the backend, rendered as a progress bar + human-readable label.
- **Debt Detail integration**: "Related Documents" section now opens the real Document Preview screen (previously a "coming soon" placeholder).
- **Cross-cutting model promotions**: `DocumentSummary` (was `DebtDocument`, Sprint 12) and `SentMessage` (was in `reminders/domain/`, Sprint 14) promoted to `core/models/` since both are now shared by two features — reuse, not duplication.
- **UI polish pass** (post-review): larger PDF viewport (redundant type/label header row removed from Preview), explicit Fit-Width builder with a wider pinch-zoom ceiling, GB-aware file-size formatting, icon-based empty state for the Other tab, clearer search placeholder.

## Files Created

**Domain / core models**
- `mobile/lib/core/models/document_summary.dart`
- `mobile/lib/core/models/sent_message.dart`
- `mobile/lib/features/documents/domain/document_page.dart`
- `mobile/lib/features/documents/domain/storage_usage.dart`
- `mobile/lib/features/documents/domain/document_event.dart`

**Data layer**
- `mobile/lib/features/documents/data/document_api.dart`
- `mobile/lib/features/documents/data/document_repository.dart`

**Providers**
- `mobile/lib/features/documents/presentation/providers/document_list_provider.dart`
- `mobile/lib/features/documents/presentation/providers/document_detail_providers.dart`
- `mobile/lib/features/documents/presentation/providers/document_actions.dart`

**Widgets**
- `mobile/lib/features/documents/presentation/widgets/document_type_icon.dart`
- `mobile/lib/features/documents/presentation/widgets/document_card.dart`
- `mobile/lib/features/documents/presentation/widgets/storage_usage_card.dart`

**Screens**
- `mobile/lib/features/documents/presentation/screens/documents_home_screen.dart`
- `mobile/lib/features/documents/presentation/screens/document_list_screen.dart`
- `mobile/lib/features/documents/presentation/screens/document_preview_screen.dart`
- `mobile/lib/features/documents/presentation/screens/document_share_screen.dart`

**Tests**
- `mobile/test/features/documents/domain/document_models_test.dart`
- `mobile/test/features/documents/data/document_repository_test.dart`
- `mobile/test/features/documents/presentation/providers/document_list_provider_test.dart`
- `mobile/test/features/documents/presentation/screens/documents_home_screen_test.dart`
- `mobile/test/features/documents/presentation/screens/document_list_screen_test.dart`

## Files Modified

- `mobile/lib/app/router/app_router.dart` — added Documents routes (`/documents/list`, `/documents/:id`, `/documents/:id/share`), replaced the Documents tab placeholder with `DocumentsHomeScreen`.
- `mobile/lib/features/debts/presentation/widgets/debt_documents_section.dart` — "Related Documents" now navigates to the real Preview screen instead of a "coming soon" placeholder.
- `mobile/lib/features/debts/data/debt_api.dart`, `mobile/lib/features/debts/data/debt_repository.dart`, `mobile/lib/features/debts/presentation/providers/debt_detail_providers.dart` — updated for the `DebtDocument` → `DocumentSummary` promotion (renamed type, updated import path).
- `mobile/lib/features/reminders/data/reminder_api.dart`, `mobile/lib/features/reminders/data/reminder_repository.dart`, `mobile/lib/features/reminders/presentation/providers/reminder_actions.dart` — updated `SentMessage` import path after promotion to `core/models/`.
- `mobile/test/features/debts/domain/debt_models_test.dart`, `mobile/test/features/debts/presentation/screens/debt_detail_screen_test.dart`, `mobile/test/features/reminders/data/reminder_repository_test.dart`, `mobile/test/features/reminders/domain/reminder_models_test.dart` — import path fixes for the two model promotions.
- `mobile/lib/features/documents/presentation/widgets/document_type_icon.dart` — `formatFileSize()` extended to format GB (was capped at MB).
- `mobile/lib/features/documents/presentation/screens/documents_home_screen.dart` — search hint changed to "Search documents...", added `_StatementsEmptyState` (icon + heading + caption) for the Other tab.
- `mobile/lib/features/documents/presentation/screens/document_preview_screen.dart` — removed the type-icon/label header row to enlarge the PDF viewport; added an explicit `PdfViewBuilders` pinning Fit-Width as the default/minimum scale with a wider pinch-zoom ceiling (`contained` → `contained * 4.0`).
- `mobile/pubspec.yaml` / `mobile/pubspec.lock` — see Dependencies below.
- `mobile/macos/Flutter/GeneratedPluginRegistrant.swift`, `mobile/windows/flutter/generated_plugin_registrant.cc`, `mobile/windows/flutter/generated_plugins.cmake` — auto-regenerated by `flutter pub get` after adding `path_provider`/`pdfx`; no manual edits (these targets are not built or shipped by this project, Android-only).

## Dependencies Added / Removed

- **Added `pdfx: ^2.9.2`** — a viewer-only, PDFium-based PDF rendering package. Required because the approved Preview screen (§8.6) needs to render real PDF bytes returned by `GET /documents/{id}/download`, and no PDF-viewing capability existed anywhere in the project before this sprint.
- **Added `path_provider: ^2.1.6`** (promoted from an existing transitive dependency via `flutter_secure_storage` to an explicit direct one) — needed to resolve a real on-device directory for the Download action (`getApplicationDocumentsDirectory()`).
- **`printing` was evaluated, added, then removed** during this sprint. It was the first candidate for PDF rendering but was rejected in favor of `pdfx` after an explicit dependency review (triggered by your correction mid-sprint): `printing` is built for *generating/printing* PDFs and pulls in unused transitive dependencies (`pdf`, `image`, `archive`, `barcode`, `qr` — 13 total transitive packages) for that purpose. This screen only needs to *view* bytes that already exist server-side, so `pdfx` (7 transitive packages: `pdfx`, `synchronized`, `universal_platform`, `uuid` + platform interfaces) is the smaller-footprint, purpose-matched choice. Net dependency state: `printing` is not present in the final `pubspec.yaml`.

## APIs Used

- `GET /documents` — list, params `type`, `search`, `page` (Documents Home + View All)
- `GET /documents/storage-usage` — Storage Usage card
- `GET /documents/{id}` — Document detail (Preview screen header/type)
- `GET /documents/{id}/download` — real PDF bytes (Preview render + Download action; also the backend's own audit-recording call)
- `POST /documents/{id}/share` — Share action (channel + template)
- `GET /message-templates?channel=` — reused from the Reminders feature for the Share screen's template list
- `GET /debts/{debt}/documents` — Debt Detail's "Related Documents" section (pre-existing from Sprint 12, now routes into the real Preview)

## Database / Backend Endpoints Used

All of the above are backed by `App\Http\Controllers\DocumentController` (`index`, `storageUsage`, `show`, `download`, `share`) plus `App\Http\Controllers\ReminderController`-adjacent `message-templates` endpoint (pre-existing, Sprint 14). No backend code was modified this sprint — read-only integration against the frozen, already-tested backend.

## Backend Blockers

- **Invoice excluded from storage-usage sum**: `DocumentService::storageUsage()` sums `Receipt` + `DemandLetter` + `Statement` file sizes only, not `Invoice`. Surfaced honestly — the app displays whatever the backend returns rather than compensating client-side.
- **`total_bytes` is not a real quota**: it's a single hardcoded env-configurable default (10 GiB), not a per-tenant limit. Displayed as-is.
- **No `filename` field on any Document Resource** — `reference_number` is used as the display filename (`"{reference_number}.pdf"`), matching exactly what the backend itself names the file in `DocumentController::download()`.
- **No separate preview-content endpoint** — `GET /documents/{id}/download` is the only source of document bytes, and it doubles as the audit-recording call server-side (records a `downloaded` `DocumentEvent`). Handled by fetching bytes exactly once per screen visit and reusing them for both the viewer and the Download button.
- **`document_events` never contains a `shared` event** — the `DocumentEventType` enum only has `generated`/`downloaded`/`regenerated`; sharing a document is not recorded as a document event.
- **No per-document/per-customer share-history endpoint** — the Share screen is send-only; there's nothing to list past shares against.

None of these are blockers to the approved scope — each was resolved by following real backend behavior rather than fabricating data or a control that doesn't work.

## flutter analyze Result

```
Analyzing mobile...
No issues found! (ran in 63.3s)
```

## flutter test Result

```
00:38 +181: All tests passed!
```
181/181 tests passing, 0 failures.

## Manual Verification Summary

Verified live in a windowed Android emulator (visible, per your request) against the real backend, logged in with the seeded dev account (`test@example.com`):

- **Documents Home**: all 5 tabs (All/Invoices/Receipts/Letters/Other) each trigger a correctly filtered, real `GET /documents` call; the Other tab's new empty state (icon + "No statements yet" + supporting caption) renders correctly since no statement documents are seeded.
- **Search**: typing filters the list server-side by reference number; placeholder now reads "Search documents...".
- **Recent Documents + View All**: share the same live provider/state; both render identical real data; the full list screen works correctly.
- **Storage Usage**: renders real usage data, now formatted as "7.2 KB of 10.0 GB used" (previously "10240.0 MB").
- **Document Preview**: `pdfx` renders actual PDF content (verified against a real receipt with real customer/debt/payment data); the type/label header row is gone so the PDF now occupies the full body area under the AppBar; the page renders Fit-Width by default (confirmed: content spans edge-to-edge with only the PDF's own internal body margin, not app letterboxing) with pinch-to-zoom available via `pdfx`'s built-in PhotoView gallery.
- **Download**: saves real PDF bytes to device storage, confirmed via snackbar with the save path.
- **Share**: channel picker (WhatsApp/SMS) correctly shows "No templates available for this channel" (honest empty state, no templates seeded for this tenant) and correctly disables the Send button.
- **Debt Detail → Related Documents → Preview integration**: tapping a related document opens the same real Preview screen.

No bugs found in either verification pass (initial pass + post-polish re-verification). All screens, buttons, and navigation flows introduced this sprint behave correctly against the real backend.

## Architecture Notes

- Standard per-module layering preserved: `domain/` (plain models), `data/` (`DocumentApi` + `DocumentRepository` with `_guard`-wrapped Dio exceptions), `presentation/providers/`, `presentation/screens/`, `presentation/widgets/` — no deviation from the pattern used in every prior module.
- `documentListProvider` is shared between Documents Home and the "View All" screen (same `AsyncNotifier`/state), avoiding a duplicate fetch and keeping tab/search selection in sync across both screens.
- Cross-feature reuse continued from prior sprints: `messageTemplatesProvider` (Reminders) is imported directly into Documents' Share screen rather than re-implemented, consistent with the Cases module reusing Debt/Customer repositories in Sprint 13.
- Two model promotions to `core/models/` (`DocumentSummary`, `SentMessage`) — both driven by genuine 2+-feature reuse, not speculative refactoring.
- The Preview screen's PDF builder customization (`PdfViewBuilders` with an explicit `pageBuilder`) is additive configuration on top of `pdfx`'s existing default behavior, not a new architectural layer — no new state management pattern, no new module structure.

## Known Limitations

- Storage Usage figures inherit the two backend caveats listed under Backend Blockers (Invoice excluded from the sum; total is a configured default, not a real quota) — these are backend characteristics, not app bugs, and are surfaced as-is.
- The Share screen cannot show share history (no backend endpoint exists for it) and document-sharing is not recorded in the timeline/event log (no `shared` event type exists server-side).
- "Fit Width" as the Preview's default zoom relies on this app's real document set always being portrait-oriented DomPDF pages (Invoice/Receipt/Demand Letter/Statement) narrower-than-tall relative to the preview viewport — true for every real document type in this system, not a generic assumption for arbitrary PDFs.

## Next Sprint Recommendation

With Documents Center complete, all five frozen bottom-tab modules (Home/Dashboard, Analytics — pending, Cases, Reminders, Documents) plus Customers/Debts have real backend integration except **Analytics**, which remains a placeholder tab. Recommend Sprint 16 scope this against the real Analytics/reporting endpoints, following the same audit-first process (read the real controllers/resources before planning screens) used in every prior module sprint.
