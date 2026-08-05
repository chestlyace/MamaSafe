# Design: Supervisor Facility Approvals (Web) + Facilities on Mobile

Date: 2026-08-05
Status: Approved and implemented (incl. mobile Approvals nested under Facilities; supervisor "Add Facility" is immediate — no approval step)

## Problem

Supervisor feature parity gaps between the web and mobile apps:

1. **Web lacks facility-suggestion approval.** Facility approval (`POST /facilities/{id}/approve`) and the pending list (`GET /api/v1/admin/facilities`) are admin-only. Supervisors can suggest facilities but cannot review or act on pending suggestions.
2. **Mobile lacks a facilities entry point for supervisors.** A facilities feature already exists on mobile for CHWs (`/home/facilities`, `FacilitiesScreen`, `FacilityFormScreen`, offline-cached `FacilityRepository`), but supervisors have no route or link to it. Mobile admins are not in scope — they use the embedded webview of the web admin panel (`/admin-browser`).
3. **Supervisor "suggest" should be "add".** A supervisor-created facility is added by staff, not proposed by a CHW, so it must be **approved immediately** — no pending/approval step. Approvals exist only for facilities suggested by CHWs.

## Decisions (confirmed)

- **Web approvals UI:** Add an **Approved / Pending tab** structure inside the existing `FacilitiesPage` (supervisor). Pending suggestions get inline **Approve / Reject** actions.
- **Mobile scope:** Supervisors only. Add a "Facilities" quick action + routes reusing the existing CHW facilities screens. Admins keep the webview.
- **Reject capability:** Supervisors (and admins) can both approve and reject pending suggestions.
- **Add vs. suggest:** `POST /api/v1/facilities` is role-aware — supervisors/admins create a facility with `approved=True` (no `suggested_by`); CHWs still create a pending suggestion (`approved=False`, `suggested_by=current_user.id`). Both web and mobile call this same endpoint, so the role check is the single source of truth.
- **Mobile wording:** The facility form title is role-aware — supervisor/admin = "Add Facility", CHW = "Suggest Facility" (new `facility.suggest` l10n key).
- **Mobile payload fix:** `CreateFacilityData.toJson()` previously sent `location`/`contact_phone`/`latitude`/`longitude`, which the backend `FacilityCreate` schema rejects (it requires `name` + `level`), so **every mobile facility creation failed online with 422** and only queued an unsyncable offline op. The payload now maps to the backend schema (`level` defaults to `health_center`, `location` → `address`, `contact_phone` → `phone`, lat/lng dropped — the backend `Facility` model has no coordinate columns). This makes supervisor adds (and CHW suggestions) actually reach the backend.
- **Missing ORM column (pre-existing 500):** the web form POSTs `district` (a column present in the `facilities` table via `_migrate_columns` and in `FacilityCreate`), but the `Facility` ORM model lacked the `district` attribute — so `Facility(**data.dict(), ...)` raised `TypeError` and `POST /facilities` returned 500 for every create. Added `district = Column(String, nullable=True)` to `app/database.py`'s `Facility` model. Without this, neither web adds nor the new mobile payload could be persisted.

## Backend changes — `backend/app/routers/facilities.py`

Use the existing `require_supervisor` dependency (already defined in `admin.py:30`, allows roles `supervisor` and `admin`) — import it from `app.routers.admin`.

1. **`GET /api/v1/facilities/pending`** (response `List[FacilityOut]`)
   - Allowed: `require_supervisor`.
   - Returns facilities where `approved == False` and `is_active == True`, ordered by `created_at` (oldest first). `FacilityOut` already exposes `suggested_by`, `approved`, `is_active`, `created_at`.
   - Must be defined before the `/facilities/{facility_id}` routes (no GET `/{id}` exists, so no actual conflict, but keep ordering clean).

2. **`POST /api/v1/facilities/{facility_id}/approve`** — relax guard.
   - Change `if current_user.role != "admin"` → use `current_user = Depends(require_supervisor)` and drop the manual check. Existing behavior (404 if missing, set `approved = True`) unchanged.

3. **`POST /api/v1/facilities/{facility_id}/reject`** (response `FacilityOut`) — new.
   - Allowed: `require_supervisor`.
   - 404 if facility not found; sets `is_active = False` (soft-delete, same semantics as existing `delete_facility`) and `approved = False`. Returns the updated facility.

4. **`POST /api/v1/facilities` (create) — role-aware approval.**
   - Keep `get_current_user` (CHWs must be able to suggest).
   - `approved = current_user.role in ("supervisor", "admin")`. When approved, `suggested_by=None`; otherwise `suggested_by=current_user.id`. (Implemented in `suggest_facility`.)

No schema changes needed (`FacilityOut` already has all fields).

## Web changes

### `frontend/src/api/client.js`
- `getPendingFacilities()` → `GET /api/v1/facilities/pending`
- `rejectFacility(id)` → `POST /api/v1/facilities/{id}/reject`
- `suggestFacility(data)` renamed to `addFacility(data)` → `POST /api/v1/facilities`.
- Keep existing `getFacilities`, `approveFacility`.

### `frontend/src/pages/FacilitiesPage.jsx`
- Add tab state: `tab` ∈ `'approved' | 'pending'` (segmented control under the header; default `'approved'`).
- Load `facilities` (approved) as today; additionally load `pending` via `getPendingFacilities()`.
- **Approved tab:** existing table (unchanged).
- **Pending tab:** table of pending suggestions with columns: Name, Level, District, Suggested by (look up suggested-by username via existing admin/CHW lists if cheap, else show id — prefer showing the user's name; if not available, fall back to `-`), Date suggested, Actions.
  - Actions: **Approve** and **Reject** buttons per row with per-row loading state; on success refetch both lists and show success banner (`facility_approved` / `facility_rejected`); on failure show error banner.
  - Empty state: `no_pending_facilities` (key already exists in `en.json`; add to `fr.json` if missing).
- Header button + form submit button: **"Add Facility"** (`add_facility`), replacing the old `suggest_facility` / `submit_suggestion` labels.
- After a successful add (`addFacility`): show green `facility_added` banner, close + reset the form, `load()` the approved list, and switch to the **Approved tab** (the facility is approved immediately — it must not appear under Pending). The Pending tab is only for CHW-suggested facilities.
- Banner/error state reuse the existing `banner`/`error` pattern (the old `suggested` state and `facility_suggested` banner were removed).

### `frontend/src/i18n/en.json` + `fr.json` (flat keys)
Add: `facilities_approved_tab` / `facilities_pending_tab` (tab labels — the `_tab` suffix avoids colliding with `facilities_pending` used by `AdminFacilitiesPage`), `approve`, `reject`, `approving`, `rejecting`, `facility_approved`, `facility_rejected`, `suggested_by`, `approve_failed`, `reject_failed`.
Replace the suggest wording with `add_facility` ("Add Facility" / "Ajouter un établissement") and `facility_added` ("Facility added successfully." / "Établissement ajouté avec succès."); remove the now-unused `suggest_facility`, `facility_suggested`, `submit_suggestion`.
Verify `no_pending_facilities` and `pending_approvals` exist in both locales.

## Mobile changes

### `mobile/lib/core/router/app_router.dart`
- Under the `/supervisor` branch add:
  - `path: 'facilities'` → `SupervisorFacilitiesScreen` (tabbed Facilities / Approvals)
  - `path: 'facilities/new'` → `FacilityFormScreen`
- Add a top-level route `path: '/facilities/new'` → `FacilityFormScreen` to fix the existing `FacilitiesScreen` FAB, which pushes `/facilities/new` (currently unmatched — only `/home/facilities/new` is registered; the CHW FAB is likely broken).
- The standalone `path: 'approvals'` route and `path: 'supervisor/approvals'` route stay registered (`ApprovalsScreen` is kept as a thin wrapper) but are no longer linked from the dashboard.

### `mobile/lib/features/supervisor/screens/supervisor_facilities_screen.dart` (new)
- `SupervisorFacilitiesScreen`: a `ConsumerStatefulWidget` with a 2-tab `TabController` (Facilities / Approvals).
  - AppBar title + bottom `TabBar` (dark theme, matches other supervisor screens): tabs labelled `supervisor.facilities` and `approval.title`.
  - `TabBarView` children: `FacilitiesTabView` (the list extracted from `FacilitiesScreen`) and `ApprovalsBody(darkTabBar: false)`.
  - FAB (→ `/facilities/new`) shown only while on the Facilities tab; hidden on the Approvals tab.

### `mobile/lib/features/facilities/screens/facilities_screen.dart`
- Extract the list/empty/loading/error body into a public `FacilitiesTabView` so it can be embedded without a `Scaffold`. `FacilitiesScreen` (used by CHW `/home/facilities`) keeps its `Scaffold` + AppBar + FAB unchanged.

### `mobile/lib/features/supervisor/screens/approvals_screen.dart`
- Extract the offline-data approvals UI into an embeddable `ApprovalsBody` (its own 3-tab controller: pending/approved/rejected; approve/reject dialogs and snackbars unchanged). `darkTabBar` flag switches the inner TabBar between dark (standalone, primary background) and light (embedded) styling.
- `ApprovalsScreen` is now a thin `ConsumerWidget` wrapper (`Scaffold` + AppBar + `ApprovalsBody(darkTabBar: true)`) so the existing standalone routes still work.

### `mobile/lib/features/supervisor/screens/supervisor_dashboard_screen.dart`
- Add `_QuickLink(label: tr(ref, 'supervisor.facilities'), icon: Icons.local_hospital_outlined, onTap: () => context.push('/supervisor/facilities'))` after CHW management.
- Remove the standalone Approvals `_QuickLink` (approvals is now reached via the Facilities tab).

### `mobile/lib/features/facilities/screens/facility_form_screen.dart`
- AppBar title is role-aware: supervisor/admin → `facility.new` ("Add Facility"), CHW → `facility.suggest` ("Suggest Facility"). Role read from `authStateProvider.user.role`.
- After a successful `createFacility`, call `ref.invalidate(facilitiesProvider)` before popping, so the list (Facilities tab / CHW screen) refreshes and shows the newly created facility immediately.

### `mobile/lib/features/facilities/facility_repository.dart`
- `CreateFacilityData.toJson()` now produces a backend-valid payload: `name`, `level` (defaults to `health_center`), `district`, `address` (from the form's `location` field), and `phone` (from `contactPhone`). `latitude`/`longitude` are kept in `CreateFacilityData` (still stored in the local drift `Facilities` table and sent by the offline `create_facility` pending op) but no longer sent in the create payload — the backend `Facility` model has no coordinate columns.
- Offline fallback (DioException → local insert + `pendingOps.create_facility`) is unchanged.

### `mobile/lib/l10n/app_en.dart` + `app_fr.dart`
- Add `"supervisor.facilities"` ("Facilities" / "Établissements").
- Add `"facility.suggest"` ("Suggest Facility" / "Proposer un établissement").

### Reuse
- `FacilitiesScreen` (list + FAB to suggest) and `FacilityFormScreen` (district pre-fill already implemented) are reused; `FacilityRepository` already does offline cache + `POST /facilities`. Supervisors only ever see approved facilities via `GET /facilities` — correct, since `GET /facilities/pending` is web-only for now. Supervisor-created facilities are approved immediately by the backend (see Backend change #4), so they appear in the Facilities list right away.

## Out of scope / notes
- Web has no mobile-offline-data approvals — that feature is mobile-only; on mobile it is now nested under Facilities (Facilities / Approvals tabs). Web's `FacilitiesPage` covers facility approval only.
- Mobile facility creation does not collect a facility level; the create payload defaults to `health_center`. Adding a level selector to the mobile form is future work.
- Mobile coordinates (`latitude`/`longitude`) are stored locally but the backend `Facility` model has no coordinate columns — adding them server-side is future work.
- Admin facility management on mobile stays in the webview (`/admin-browser`).

## Verification
- Backend: `uvicorn` boots; manual curl — supervisor token → `GET /facilities/pending` returns unapproved list; `POST /facilities/{id}/approve|reject` succeed; CHW token gets 403; after reject, facility no longer appears in pending or approved lists. `POST /facilities` with a supervisor token returns `approved=true` (and `suggested_by=null`); with a CHW token returns `approved=false` and `suggested_by` set.
- Web: `npm run build`; manually exercise tabs, approve, reject; the header/form buttons read "Add Facility"; adding a facility shows the green "Facility added" banner, refreshes the Approved tab, and does NOT land in Pending.
- Mobile: `flutter analyze`; manually verify supervisor dashboard Facilities link opens the tabbed screen, Facilities/Approvals tabs render, FAB→form with "Add Facility" title (CHW form shows "Suggest Facility"), add a facility and confirm it appears in the list immediately (list refresh after create), district pre-fill, approvals approve/reject flow, and that the standalone Approvals quick action is gone.
