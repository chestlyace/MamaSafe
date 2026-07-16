# Emergency Referral System — Design Spec

**Date:** 2026-07-16
**Status:** Approved

## Overview

A one-tap emergency referral system that sends a pre-populated patient summary to a receiving facility when a community health worker identifies a high-risk maternal case. Supports three delivery channels (SMS, WhatsApp, in-app), offline-first operation, and three-state status tracking (SENT → RECEIVED → PATIENT_ARRIVED).

## Context

MamaSafe is an AI-powered maternal health risk assessment tool for community health workers in Cameroon. Cameroon has a ~596-782/100,000 live births maternal mortality ratio, and 75% of referral-related maternal deaths are from late referrals. The current system has no digital referral capability — referrals are paper-based or ad-hoc phone calls with no tracking.

## Scope

- One-tap referral from assessment results (pre-filled)
- Dedicated referral screen for manual entry (with or without assessment)
- Facility directory with admin approval workflow
- Three delivery channels: SMS, WhatsApp, in-app
- Three-state status tracking with timestamps
- Offline queue (same pattern as existing assessment queue)
- Dashboard analytics for referral completion rates

## Data Model

### `facilities` table

| Field | Type | Notes |
|-------|------|-------|
| id | SERIAL PK | |
| name | VARCHAR NOT NULL | |
| level | ENUM: health_post, health_center, district_hospital, regional_hospital, central_hospital | |
| phone | VARCHAR, nullable | For SMS delivery |
| whatsapp | VARCHAR, nullable | For WhatsApp delivery |
| address | VARCHAR, nullable | |
| region | VARCHAR, nullable | |
| is_active | BOOLEAN | default true |
| suggested_by | FK -> users.id, nullable | |
| approved | BOOLEAN | default false |
| created_at | TIMESTAMP | |

### `referrals` table

| Field | Type | Notes |
|-------|------|-------|
| id | SERIAL PK | |
| patient_id | FK -> patients.id | |
| assessment_id | FK -> assessments.id, nullable | Optional link to assessment |
| facility_id | FK -> facilities.id | |
| facility_name | VARCHAR | Snapshot of facility name |
| status | ENUM: SENT, RECEIVED, PATIENT_ARRIVED | |
| patient_name | VARCHAR | Snapshot |
| patient_age | INTEGER | Snapshot |
| patient_phone | VARCHAR, nullable | Snapshot |
| patient_blood_group | VARCHAR, nullable | Snapshot |
| patient_allergies | VARCHAR, nullable | Snapshot |
| emergency_contact_name | VARCHAR, nullable | Snapshot |
| emergency_contact_phone | VARCHAR, nullable | Snapshot |
| gravida | INTEGER, nullable | Snapshot |
| parity | INTEGER, nullable | Snapshot |
| edd_date | VARCHAR, nullable | Snapshot |
| gestational_age | INTEGER, nullable | Snapshot |
| systolic_bp | FLOAT, nullable | Snapshot |
| diastolic_bp | FLOAT, nullable | Snapshot |
| heart_rate | INTEGER, nullable | Snapshot |
| body_temp | FLOAT, nullable | Snapshot |
| blood_sugar | FLOAT, nullable | Snapshot |
| risk_level | VARCHAR, nullable | Snapshot |
| risk_probability | FLOAT, nullable | Snapshot |
| complication_type | VARCHAR, nullable | Free-text |
| chw_notes | TEXT, nullable | |
| chw_id | FK -> users.id | |
| sent_at | TIMESTAMP | |
| received_at | TIMESTAMP, nullable | |
| patient_arrived_at | TIMESTAMP, nullable | |
| created_at | TIMESTAMP | |

### Key data model decisions

- `facility_name` is a snapshot — if the facility record changes later, the referral record is unaffected
- Patient/pregnancy/clinical data are all copied into the referral — self-contained, no live joins needed
- `assessment_id` is nullable so referrals can be created standalone (not just from assessments)
- `complication_type` is a free-text field (e.g., "Eclampsia", "PPH", "Obstructed labor") — simple and flexible
- Three status timestamps instead of just a status enum — gives you duration analytics (time from SENT to RECEIVED, time from SENT to PATIENT_ARRIVED)

## API Endpoints

All endpoints prefixed with `/api/v1`, require JWT auth.

### Facility Directory

| Method | Path | Description |
|--------|------|-------------|
| GET | `/facilities` | List approved facilities (CHW: approved only; admin: all + pending) |
| POST | `/facilities` | CHW suggests new facility (auto-approved=false) |
| POST | `/facilities/{id}/approve` | Admin approves suggested facility |
| PATCH | `/facilities/{id}` | Admin edits facility |
| DELETE | `/facilities/{id}` | Admin soft-deletes (is_active=false) |

### Referrals

| Method | Path | Description |
|--------|------|-------------|
| POST | `/referrals` | Create manual referral (CHW edits fields) |
| POST | `/referrals/quick` | One-tap from assessment (takes assessment_id + facility_id, auto-builds snapshot) |
| GET | `/referrals` | List referrals (CHW: own; admin: all). Filterable by status, facility, patient |
| GET | `/referrals/{id}` | Get single referral |
| PATCH | `/referrals/{id}/status` | Update status (RECEIVED or PATIENT_ARRIVED) |
| GET | `/referrals/stats` | Aggregate stats: counts, completion rate, avg response time |

## UI Flows

### Flow A: One-Tap from Assessment

1. CHW completes assessment, sees high-risk result
2. Taps "Emergency Referral" button (red-outlined, prominent)
3. Quick referral modal/sheet opens with all fields pre-filled from assessment + patient data
4. CHW reviews, optionally edits vitals/notes, picks receiving facility from dropdown
5. Taps "Send Referral", confirmation toast, referral saved + delivery triggered

### Flow B: Dedicated Referral Screen

1. CHW navigates to "Refer" tab (mobile) or "Emergency Referral" page (web)
2. Selects patient (if not already on a patient page)
3. System pre-fills available data; CHW enters/edits remaining fields
4. Picks receiving facility, adds complication type + notes
5. Taps "Send Referral"

### Flow C: Referral History and Tracking

1. CHW opens "Referrals" tab, sees list with status badges + time elapsed
2. Filters by status, facility, or patient name
3. Taps referral card for full details view
4. Dashboard shows referral stats + stale referral alerts (>2 hours without RECEIVED)

## Delivery Channels

| Channel | Trigger | Content |
|---------|---------|---------|
| In-app | Always | Full referral record appears in facility's referral list |
| SMS | Always (if facility has phone) | Condensed summary with key vitals, ≤160 chars per segment |
| WhatsApp | Always (if facility has WhatsApp) | Rich-formatted full referral summary |

SMS and WhatsApp are sent by the backend, not the mobile app. The app posts referral data, backend handles delivery.

### SMS message format

```
[MamaSafe URGENT REFERRAL]
Patient: Marie N., 28y
BP: 180/110 | HR: 110
Risk: HIGH
Complication: Eclampsia
Notes: Seizure x2, refer immediately
```

### WhatsApp message format

```
MAMASAFE URGENT REFERRAL

Patient: Marie Nkongho, 28 years
Phone: +237 6XX XXX XXX
Blood Group: O+
Allergies: Penicillin

Pregnancy: G3P2, EDD: 2026-08-15
Gestational Age: 32 weeks

Vitals:
  BP: 180/110 mmHg
  HR: 110 bpm
  Temp: 37.2 C
  Blood Sugar: 5.2 mmol/L

Risk Level: HIGH (87% confidence)
Complication: Eclampsia

CHW Notes: Seizure x2 today, referred from Health Post Mankon

Referred to: District Hospital Buea
Sent: 16 Jul 2026, 14:32
```

## Offline Behavior

1. CHW sends referral while offline, saved to AsyncStorage with status=SENT
2. Patient snapshot built from local data (no network needed)
3. Appears in local list with "pending sync" indicator
4. On connectivity return, POST to backend, backend triggers SMS/WhatsApp delivery
5. On failure, retry with exponential backoff

## Facility Directory Management

- CHWs suggest facilities via a form in the facility picker
- Admin approves/rejects from a "Facilities" admin page
- Only approved facilities appear in CHW dropdowns

## Analytics Integration

Dashboard additions:

- Referrals this week: sent / received / arrived counts
- Completion rate: arrived / sent %
- Avg response time: SENT to RECEIVED
- Stale referral alerts: SENT > 2 hours with no RECEIVED
- Referrals by facility, complication type, CHW

## Implementation Areas

1. **Backend:** Facility model + CRUD, Referral model + CRUD + quick endpoint, delivery service (SMS/WhatsApp)
2. **Frontend (web):** Facility admin page, referral page, referral modal on assessment results, dashboard referral card, patient detail referral tab, navbar update
3. **Mobile:** Referral tab, referral form, quick referral from result screen, referral history, offline queue integration, i18n keys
