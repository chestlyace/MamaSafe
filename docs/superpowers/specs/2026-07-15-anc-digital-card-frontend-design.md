# ANC Digital Card — Frontend Design Spec

> **Goal:** Add a Digital ANC Card feature to the MamaSafe web frontend — a patient record that follows a pregnant woman across every antenatal visit, with Patient → Pregnancy → Visit hierarchy and integration with the existing risk assessment system.

**Architecture:** React SPA with local state (useState), Tailwind v4 design tokens, Material Symbols icons. Five new pages + one modified page (AssessmentPage). All under existing ProtectedRoute + Layout wrapper. API calls via existing Axios client with JWT interceptor.

**Tech Stack:** React 19, React Router v7, Tailwind CSS v4, Axios, i18next, Recharts (existing, unused for this feature)

---

## Navigation

**NavBar change:** Add "Patients" as a 4th top-level link with icon `people`, positioned between "Assess" and "History".

Desktop nav: Assess | **Patients** | History | Dashboard
Mobile drawer: Same order with icons.

**Active state:** `text-rose-500 font-semibold` when on any `/patients/*` route (use `location.pathname.startsWith('/patients')`).

---

## New Pages

| Route | Page | Purpose |
|-------|------|---------|
| `/patients` | PatientListPage | Search + list of all patients |
| `/patients/new` | PatientRegisterPage | Register a new patient |
| `/patients/:id` | PatientDetailPage | Full ANC card view (the centerpiece) |
| `/patients/:id/pregnancies/new` | PregnancyRegisterPage | Start a new pregnancy |
| `/patients/:id/pregnancies/:pregnancyId/visits/new` | VisitLogPage | Log an ANC visit with clinical readings |

**Route structure in App.jsx:**
```jsx
<Route path="/patients" element={<PatientListPage />} />
<Route path="/patients/new" element={<PatientRegisterPage />} />
<Route path="/patients/:id" element={<PatientDetailPage />} />
<Route path="/patients/:id/pregnancies/new" element={<PregnancyRegisterPage />} />
<Route path="/patients/:id/pregnancies/:pregnancyId/visits/new" element={<VisitLogPage />} />
```

All under existing `<Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>`.

---

## Modified Pages

### AssessmentPage — Patient Selector

Add an optional patient search/select field above the existing "Patient Reference" field.

- Search input queries `GET /api/v1/patients?search=...` as CHW types (debounced)
- Results appear in a dropdown list below the input
- CHW clicks a patient to select → patient name and ID populate the field
- If no patient found or CHW skips it → assessment saves without `patient_id` (standalone, same as today)
- If patient selected → assessment saves with `patient_id` linked
- Existing `patient_ref` text field stays for backward compatibility

### ResultPage — Patient Card Link

After assessment completes, if `patient_id` is set in the response, show a "View Patient Card" link alongside the existing links.

---

## Page Designs

### PatientListPage (`/patients`)

- **Header:** Title "Patients" + "+ Register Patient" button (top right, `bg-rose-500`)
- **Search bar:** Full-width input with search icon, filters patients by name via API `?search=` param
- **Patient cards:** List layout, each card shows: name (bold), DOB · Phone · Facility
- **Click card →** navigates to `/patients/:id`
- **Empty state:** Dashed border card, `people` icon, "No patients yet" message + Register button
- **Card style:** `bg-white rounded-2xl border border-border p-4 hover:border-rose-primary/40 transition-colors`

### PatientRegisterPage (`/patients/new`)

- **Back link:** "← Patients" at top
- **Full page form** following AssessmentPage pattern
- **Fields:**
  - Full name* (text)
  - Date of birth* (date)
  - Phone (tel)
  - Address (text)
  - Facility (text)
  - Blood group (select: A+, A-, B+, B-, AB+, AB-, O+, O-)
  - Allergies (text)
  - Emergency contact name (text)
  - Emergency contact phone (tel)
- **Required:** full_name, date_of_birth
- **On submit:** POST `/api/v1/patients` → navigate to `/patients/:id`

### PatientDetailPage (`/patients/:id`) — The ANC Card

Layout from top to bottom:

**1. Header area:**
- Back link: "← Patients"
- Patient name (large heading)
- DOB · Phone · Facility (subtitle)
- Info row: Blood group, Allergies, Emergency contact name, Emergency contact phone
- Action button: "+ Start New Pregnancy" (only shown if no active pregnancy)

**2. Pregnancy tabs:**
- Two tabs: "Current" (default active) and "Past"
- Current tab shows the active pregnancy section (or empty state: "No active pregnancy" + "Start New Pregnancy" prompt)
- Past tab shows completed pregnancies (delivery recorded, `is_active=False`)
- Past tab empty: "No past pregnancies"

**3. Pregnancy section (inside each tab):**
- Pregnancy header bar: LMP date, EDD date, Gravida/Parity, visit count badge
- If active: "+ Log Visit" button
- If completed: delivery outcome badge (live birth / stillbirth / miscarriage) + delivery date

**4. Visit timeline (inside pregnancy section):**
- Vertical line on the left with numbered circle markers (Visit 1, 2, ... 8)
- Each visit is a card to the right of the line
- Visit card content:
  - Header: "Visit N" + date
  - Compact grid of vitals: GA, weight, BP, Hb, fundal height, fetal HR, presentation, oedema
  - Treatment badges row: TT vaccine, malaria prophylaxis, iron supplements (colored pills)
  - "Assessment linked" badge if `risk_assessment_id` is set
  - Notes in italic if present
  - Next visit date at bottom if set

**Timeline visual structure:**
```
  ● ── Visit 1  ─────────────  Jan 15, 2026
  │    GA: 12w | Wt: 62kg | BP: 110/70 | Hb: 11.2
  │    [TT] [Malaria prophylaxis]
  │
  ● ── Visit 2  ─────────────  Feb 12, 2026
  │    GA: 16w | Wt: 64kg | BP: 118/72 | Hb: 11.0
  │    [TT] [Iron]
  │
  ○ ── Visit 3  ─────────────  (not yet)
```

### PregnancyRegisterPage (`/patients/:id/pregnancies/new`)

- **Back link:** "← Patient Card"
- **Simple form:**
  - LMP date* (date picker)
  - Gravida (number, default 1)
  - Parity (number, default 0)
- **On submit:** POST `/api/v1/pregnancies` → navigate to `/patients/:id`
- EDD auto-calculated by backend (Naegele's rule)

### VisitLogPage (`/patients/:id/pregnancies/:pregnancyId/visits/new`)

- **Back link:** "← Patient Card"
- **Two-column grid layout** (same pattern as AssessmentPage)
- **Clinical readings section:**
  - Visit number* (1-8)
  - Visit date*
  - Gestational age (weeks)
  - Weight (kg)
  - Systolic BP
  - Diastolic BP
  - Fundal height (cm)
  - Fetal HR (bpm)
  - Presentation (select: cephalic / breech / transverse)
  - Oedema (checkbox)
- **Lab results section:**
  - Urinalysis protein (select: negative / trace / +1 / +2 / +3)
  - Urinalysis glucose (same)
  - Haemoglobin (g/dL)
- **Treatments section:**
  - TT vaccine (checkbox)
  - Malaria prophylaxis (checkbox)
  - Iron supplements (checkbox)
- **Free text:** Notes (textarea)
- **Scheduling:** Next visit date (date picker)
- **On submit:** POST `/api/v1/anc-visits` → navigate to `/patients/:id`
- **Error handling:** Backend returns 400 if visit number already exists for this pregnancy → show error banner

---

## API Client Updates

New functions in `api/client.js`:

```js
// Patients
export const getPatients = async (search = '', skip = 0, limit = 50) => { ... }
export const getPatient = async (id) => { ... }
export const getPatientCard = async (id) => { ... }

// Pregnancies
export const registerPregnancy = async (data) => { ... }
export const recordDelivery = async (pregnancyId, data) => { ... }

// ANC Visits
export const recordVisit = async (data) => { ... }
export const getVisit = async (id) => { ... }
export const listVisits = async (pregnancyId) => { ... }
```

**State management:** Local state only (useState) per page — same pattern as existing pages. No new global state.

---

## Empty States & Edge Cases

| Scenario | What shows |
|----------|------------|
| No patients yet | Dashed border card, `people` icon, "No patients yet" + Register button |
| Patient has no active pregnancy | Message: "No active pregnancy" + "Start New Pregnancy" link |
| Pregnancy has no visits yet | Message: "No visits recorded" + "Log Visit" button |
| Past pregnancies tab is empty | Message: "No past pregnancies" |
| Visit number already exists | Backend returns 400, form shows error banner |
| Patient not found (404) | "Patient not found" message with back link |
| Assessment with no patient selected | Works exactly as today — no change |
| Search returns no results | "No patients found" message in the list |

---

## i18n Translation Keys

New keys for EN and FR:

**EN additions:** patients, register_patient, patient_list, patient_detail, full_name, date_of_birth, phone, address, blood_group, allergies, emergency_contact, emergency_contact_name, emergency_contact_phone, search_patients, no_patients_found, start_pregnancy, lmp_date, edd_date, gravida, parity, active_pregnancy, past_pregnancies, no_active_pregnancy, log_visit, visit_number, visit_date, gestational_age, weight_kg, fundal_height_cm, foetal_hr, presentation, oedema, urinalysis_protein, urinalysis_glucose, haemoglobin, tt_vaccine, malaria_prophylaxis, iron_supplements, notes, next_visit_date, cephalic, breech, transverse, negative, trace, delivery_outcome, delivery_date, delivery_location, live_birth, stillbirth, miscarriage, visit_count, back_to_patients, no_visits_recorded, no_past_pregnancies

**FR additions:** Mirror of EN with French translations (same key names).

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `frontend/src/App.jsx` | Add 5 new routes |
| Modify | `frontend/src/components/NavBar.jsx` | Add "Patients" nav link (desktop + mobile) |
| Create | `frontend/src/pages/PatientListPage.jsx` | Patient search + list |
| Create | `frontend/src/pages/PatientRegisterPage.jsx` | Register new patient form |
| Create | `frontend/src/pages/PatientDetailPage.jsx` | Full ANC card view |
| Create | `frontend/src/pages/PregnancyRegisterPage.jsx` | Start new pregnancy form |
| Create | `frontend/src/pages/VisitLogPage.jsx` | Log ANC visit form |
| Modify | `frontend/src/pages/AssessmentPage.jsx` | Add patient selector field |
| Modify | `frontend/src/pages/ResultPage.jsx` | Add patient card link |
| Modify | `frontend/src/api/client.js` | Add patient/pregnancy/visit API functions |
| Modify | `frontend/src/i18n/en.json` | Add translation keys |
| Modify | `frontend/src/i18n/fr.json` | Add translation keys |

---

## Design Tokens (used consistently)

All new pages use the existing design system:
- Cards: `bg-white rounded-2xl border border-border`
- Inputs: `bg-surface border border-border rounded-xl px-4 py-2.5 text-sm`
- Primary button: `bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600`
- Secondary link: `text-rose-500 text-sm font-semibold hover:underline`
- Error: `bg-red-50 border border-red-200 text-red-700 rounded-xl`
- Success badge: `bg-green-100 text-green-700 text-xs rounded-full`
- Icons: Material Symbols Outlined
- Typography: Inter font, `text-text-heading` for titles, `text-text-muted` for labels
