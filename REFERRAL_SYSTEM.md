# MamaSafe — Emergency Referral System
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Emergency Referral  
**Stack:** FastAPI · PostgreSQL · Africa's Talking SMS · React · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Clinical Context](#2-clinical-context)
3. [System Architecture](#3-system-architecture)
4. [Data Model](#4-data-model)
5. [Status Machine](#5-status-machine)
6. [API Reference](#6-api-reference)
7. [SMS Integration — Africa's Talking](#7-sms-integration--africas-talking)
8. [Clinical Packet — What Gets Sent](#8-clinical-packet--what-gets-sent)
9. [Backend Implementation](#9-backend-implementation)
10. [Web Frontend Implementation](#10-web-frontend-implementation)
11. [Mobile Frontend Implementation (Expo)](#11-mobile-frontend-implementation-expo)
12. [Webhook — Facility Reply Handling](#12-webhook--facility-reply-handling)
13. [Testing Guide](#13-testing-guide)
14. [Report Integration](#14-report-integration)
15. [Future Extensions](#15-future-extensions)

---

## 1. Overview and Purpose

The MamaSafe Emergency Referral System transforms a risk prediction result into a tracked clinical action. When a community health worker (CHW) receives a high-risk prediction from the MamaSafe AI engine, the app provides a recommendation — *"IMMEDIATE REFERRAL REQUIRED"* — but without a structured referral mechanism, that recommendation remains text on a screen. The patient disappears into the system, the CHW has no confirmation she arrived, and the receiving facility has no advance warning to prepare.

The referral module closes this gap by doing four things:

**1. Packaging the clinical handoff** — When a CHW initiates a referral, the system automatically compiles everything the receiving facility needs: patient identity, ANC history, risk level, confidence score, and the specific clinical signals (SystolicBP, blood sugar, etc.) that drove the prediction. This is called the **clinical packet**.

**2. Notifying the facility by SMS** — The clinical packet is sent as an SMS to the receiving facility's phone number via Africa's Talking. This works on any basic phone, requires no internet, and arrives within seconds. The facility doctor knows the patient is coming before she arrives.

**3. Tracking the referral through completion** — The referral passes through a five-state machine: `sent → received → patient_arrived → completed → cancelled`. Each state transition is timestamped. This produces a referral completion rate — a metric that no paper-based system can generate.

**4. Closing the outcome loop** — After delivery or discharge, the outcome is recorded against the referral: delivered, discharged, died, or transferred. This data feeds the district analytics dashboard and, over time, enables Ministry of Health reporting on referral effectiveness.

---

## 2. Clinical Context

### The Three Delays Framework

The referral system is designed around the Three Delays Model (Thaddeus & Maine, 1994), which identifies three points where preventable maternal deaths occur:

| Delay | Description | % of Deaths | How referral addresses it |
|-------|-------------|-------------|--------------------------|
| Delay 1 | Decision to seek care | 13% | Risk prediction triggers urgency awareness |
| Delay 2 | Reaching the facility | 25.8% | Referral routes patient to correct facility with advance notice |
| Delay 3 | Receiving adequate care | 50% | Clinical packet ensures facility prepares before patient arrives |

The referral system is MamaSafe's primary intervention against Delay 2. By routing the patient to the nearest facility with obstetric capacity — not just the nearest facility — and by sending her clinical history ahead of her, it reduces both the time to appropriate care and the quality gap on arrival.

### Why SMS, not the app

Receiving facilities in rural and peri-urban Cameroon typically have one shared smartphone or a tablet — and internet connectivity is intermittent. An in-app notification would be missed during outages. SMS, by contrast:

- Works on any phone including a basic Nokia feature phone
- Delivers within seconds on MTN, Orange, and Nexttel Cameroon
- Does not require an internet connection at the receiving end
- Is free to receive for the facility
- Produces a delivery receipt on the Africa's Talking dashboard

This is why Africa's Talking was chosen over WhatsApp Business API, email, or push notifications. Africa's Talking has direct carrier partnerships with all three major Cameroonian networks.

### Referral urgency levels

| Urgency | Definition | Expected response |
|---------|-----------|-------------------|
| `routine` | Non-urgent referral for further investigation | Within 72 hours |
| `urgent` | High-risk case requiring facility care within 24 hours | Within 24 hours |
| `emergency` | Immediate life-threatening risk | Within 2 hours |

In practice, any high-risk prediction from MamaSafe should trigger at minimum an `urgent` referral. The `emergency` level is reserved for cases where the CHW observes additional clinical signs beyond the prediction — severe bleeding, unconsciousness, active convulsions.

---

## 3. System Architecture

### Component overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MamaSafe Platform                        │
│                                                                 │
│  ┌──────────────┐     ┌──────────────────┐     ┌────────────┐  │
│  │  React Web   │────▶│   FastAPI        │────▶│ PostgreSQL │  │
│  │  Expo Mobile │     │   Backend        │     │ Database   │  │
│  └──────────────┘     │                  │     └────────────┘  │
│                       │  /api/v1/        │                     │
│                       │  referrals       │                     │
│                       │  /api/v1/        │                     │
│                       │  facilities      │                     │
│                       └────────┬─────────┘                     │
└────────────────────────────────┼────────────────────────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │   Africa's Talking API    │
                    │   SMS Gateway             │
                    └────────────┬─────────────┘
                                 │ SMS delivery
                    ┌────────────▼─────────────┐
                    │   Receiving Facility      │
                    │   (any phone)             │
                    └────────────┬─────────────┘
                                 │ Reply "RECEIVED"
                    ┌────────────▼─────────────┐
                    │   AT Webhook → FastAPI    │
                    │   /referrals/webhook/sms  │
                    └──────────────────────────┘
```

### Request lifecycle

When a CHW submits a referral, the following sequence occurs in a single POST request:

1. FastAPI validates the request body against `ReferralCreate` schema
2. Patient record is loaded from PostgreSQL
3. Linked assessment record is loaded to extract risk data
4. `build_clinical_summary()` generates the human-readable clinical packet
5. `Referral` database record is created with `status = "sent"`
6. Database commit persists the record
7. If the receiving facility has a phone number, `send_referral_sms()` is called
8. Africa's Talking sends SMS to the facility phone
9. SMS result (success, message_id) is written back to the referral record
10. Final referral record is returned to the frontend
11. Frontend displays confirmation with referral ID

Total time: typically under 2 seconds end to end.

---

## 4. Data Model

### Entity Relationship

```
users
  │
  ├── (chw_id) ──────────────────────────┐
  │                                       │
patients                                  │
  │ id                                    │
  │ full_name                             │
  │ date_of_birth                         │
  │ phone                                 │
  │ facility                              │
  │ chw_id → users.id                    │
  │                                       │
  ├── pregnancies                         │
  │     │ patient_id → patients.id        │
  │     └── anc_visits                    │
  │                                       │
  └── referrals ◀─────────────────────────┘
        │ patient_id → patients.id
        │ pregnancy_id → pregnancies.id
        │ assessment_id → assessments.id
        │ chw_id → users.id
        │ receiving_facility_id → facilities.id
        │
        status: sent | received | patient_arrived | completed | cancelled
        outcome: delivered | discharged | died | transferred

facilities
  │ id
  │ name
  │ type: health_post | district_hospital | regional_hospital
  │ phone  ← SMS target
  │ has_obstetric_care
  │ has_blood_bank
  │ has_operating_theatre
  └── referrals_received (back-ref)

assessments (existing)
  │ risk_level
  │ prob_high / prob_low / prob_mid
  │ shap_bs / shap_systolic / shap_age
  └── (linked to referral via assessment_id)
```

### `facilities` table — full schema

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer PK | Auto-generated |
| `name` | String | Full facility name |
| `type` | String | `health_post`, `district_hospital`, `regional_hospital` |
| `district` | String | Administrative district |
| `region` | String | One of Cameroon's 10 regions |
| `phone` | String | Phone number for SMS referral alerts |
| `latitude` | Float | GPS latitude for future map routing |
| `longitude` | Float | GPS longitude |
| `has_obstetric_care` | Boolean | Can handle obstetric emergencies |
| `has_blood_bank` | Boolean | Has blood products available |
| `has_operating_theatre` | Boolean | Can perform C-sections |
| `is_active` | Boolean | Whether facility is currently active |
| `created_at` | DateTime | Record creation timestamp |

### `referrals` table — full schema

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer PK | Auto-generated |
| `patient_id` | Integer FK | References `patients.id` |
| `pregnancy_id` | Integer FK | References `pregnancies.id` (nullable) |
| `assessment_id` | Integer FK | References `assessments.id` (nullable) |
| `chw_id` | Integer FK | References `users.id` — the CHW who created referral |
| `sending_facility` | String | Name of CHW's facility |
| `receiving_facility_id` | Integer FK | References `facilities.id` (nullable) |
| `receiving_facility_name` | String | Fallback name if no facility record |
| `urgency` | String | `routine`, `urgent`, `emergency` |
| `risk_level` | String | Copied from assessment: `high risk`, `mid risk`, `low risk` |
| `clinical_summary` | Text | Auto-generated summary from assessment data |
| `chw_notes` | Text | Free text notes from CHW |
| `status` | String | Current state in status machine |
| `outcome` | String | Final outcome after completion |
| `outcome_notes` | Text | Clinical notes on outcome |
| `outcome_recorded_at` | DateTime | When outcome was recorded |
| `sms_sent` | Boolean | Whether SMS was successfully sent |
| `sms_message_id` | String | Africa's Talking message ID for tracking |
| `created_at` | DateTime | When referral was submitted |
| `received_at` | DateTime | When facility confirmed receipt |
| `arrived_at` | DateTime | When patient confirmed arrived |

---

## 5. Status Machine

The referral moves through five states. Each transition is triggered by a specific actor and produces a timestamp.

```
                    ┌─────────┐
                    │  SENT   │ ← CHW submits referral
                    └────┬────┘
                         │ Facility replies "RECEIVED" via SMS
                         │ OR facility user updates via API
                         ▼
                    ┌──────────┐
                    │ RECEIVED │ ← received_at timestamped
                    └────┬─────┘
                         │ Patient physically arrives at facility
                         ▼
                  ┌───────────────┐
                  │ PATIENT_ARRI  │ ← arrived_at timestamped
                  │     VED       │
                  └───────┬───────┘
                          │ Outcome recorded (delivery/discharge)
                          ▼
                    ┌───────────┐
                    │ COMPLETED │ ← outcome_recorded_at timestamped
                    └───────────┘

    At any point before COMPLETED:
                         ▼
                    ┌───────────┐
                    │ CANCELLED │ ← patient refused, transported elsewhere
                    └───────────┘
```

### State transition rules

| From | To | Triggered by | Endpoint |
|------|----|-------------|----------|
| `sent` | `received` | Facility SMS reply "RECEIVED" | `POST /referrals/webhook/sms` |
| `sent` | `received` | Manual facility confirmation | `PATCH /referrals/{id}/status` |
| `received` | `patient_arrived` | CHW or facility confirms arrival | `PATCH /referrals/{id}/status` |
| `patient_arrived` | `completed` | Outcome recorded | `PATCH /referrals/{id}/outcome` |
| `sent/received/patient_arrived` | `cancelled` | Manual cancellation | `PATCH /referrals/{id}/status` |

### Business rules

- A referral cannot move backward through the status machine (e.g., from `received` back to `sent`). This is enforced at the API level.
- A referral in `completed` or `cancelled` status cannot have its status updated — only outcome notes can be amended.
- Only admins can view referrals from all CHWs. CHWs see only referrals they created.
- A patient can have multiple referrals (e.g., one per pregnancy, or one per ANC visit where risk escalates). All are tracked independently.

---

## 6. API Reference

### Base URL
```
http://localhost:8000/api/v1
```

All endpoints require JWT authentication unless marked otherwise. Include the token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

### Facilities

#### `POST /facilities`
Create a new facility. **Admin only.**

**Request body:**
```json
{
  "name": "Hôpital de District de Yaoundé Centre",
  "type": "district_hospital",
  "district": "Yaoundé",
  "region": "Centre",
  "phone": "+237699000001",
  "has_obstetric_care": true,
  "has_blood_bank": true,
  "has_operating_theatre": true
}
```

**Response:** `FacilityOut` with `id` assigned.

---

#### `GET /facilities`
List all active facilities. Used by frontend to populate the facility selector dropdown.

**Response:** `Array<FacilityOut>` ordered by name.

---

### Referrals

#### `POST /referrals`
Create a new referral. Triggers SMS automatically if the facility has a phone number.

**Request body:**
```json
{
  "patient_id": 1,
  "pregnancy_id": 1,
  "assessment_id": 1,
  "receiving_facility_id": 1,
  "receiving_facility_name": "Hôpital de District de Yaoundé Centre",
  "urgency": "emergency",
  "sending_facility": "Centre de Santé de Melen",
  "chw_notes": "Severe hypertension observed. Immediate review required."
}
```

**Response:** Full `ReferralOut` object including auto-generated `clinical_summary` and `sms_sent` status.

**Side effects:**
- Creates `Referral` record in database
- Sends SMS to receiving facility (if phone available)
- Records SMS message ID for tracking

---

#### `GET /referrals`
List referrals for the current CHW (or all referrals for admin).

**Query parameters:**
- `status` (optional) — filter by status: `sent`, `received`, `patient_arrived`, `completed`, `cancelled`
- `skip` (optional, default 0) — pagination offset
- `limit` (optional, default 30) — page size

**Response:** `Array<ReferralOut>`

---

#### `GET /referrals/{referral_id}`
Get a single referral by ID.

**Response:** `ReferralOut`

---

#### `PATCH /referrals/{referral_id}/status`
Update the referral status.

**Request body:**
```json
{
  "status": "received"
}
```

Valid values: `received`, `patient_arrived`, `completed`, `cancelled`

**Response:** Updated `ReferralOut`

**Side effects:** Sends SMS notification to patient phone (if available) when status changes to `received` or `patient_arrived`.

---

#### `PATCH /referrals/{referral_id}/outcome`
Record the final outcome. Automatically sets status to `completed`.

**Request body:**
```json
{
  "outcome": "delivered",
  "outcome_notes": "Caesarean section performed. Mother and baby stable."
}
```

Valid outcome values: `delivered`, `discharged`, `died`, `transferred`

**Response:** Updated `ReferralOut`

---

#### `GET /patients/{patient_id}/referrals`
Get all referrals for a specific patient.

**Response:** `Array<ReferralOut>` ordered by creation date descending.

---

#### `GET /referrals/analytics/summary`
Referral analytics summary for the current CHW or all CHWs (admin).

**Response:**
```json
{
  "total": 24,
  "sent": 2,
  "received": 1,
  "patient_arrived": 3,
  "completed": 17,
  "cancelled": 1,
  "high_risk": 19,
  "completion_rate": 70.8
}
```

---

#### `POST /referrals/webhook/sms` *(no auth required)*
Africa's Talking incoming SMS webhook. Called automatically when a facility replies to a referral SMS.

**Request:** form-encoded POST from Africa's Talking
```
from=+237699000001
to=MamaSafe
text=RECEIVED
date=2025-07-14 10:45:23
```

**Behaviour:** If the text contains "RECEIVED", finds the most recent `sent` referral from that facility phone number and updates it to `received`.

**Response:**
```json
{"message": "Status updated to received"}
```

---

## 7. SMS Integration — Africa's Talking

### Account setup

1. Register at [africastalking.com](https://africastalking.com)
2. Go to **Settings → API Key** — copy your API key
3. Add to your `.env` file:

```env
AT_USERNAME=sandbox        # use "sandbox" for testing, your username for production
AT_API_KEY=your_key_here
AT_SENDER_ID=MamaSafe
```

4. In production, register your sender ID ("MamaSafe") with Africa's Talking — this can take 1–3 business days for Cameroonian carrier approval.

### Sandbox testing

The sandbox environment simulates SMS delivery without sending real messages. All sandbox messages appear in your Africa's Talking dashboard under **Sandbox → SMS**.

To test the incoming SMS webhook locally, use ngrok:

```bash
# Install ngrok, then:
ngrok http 8000

# Copy the HTTPS forwarding URL, e.g.:
# https://abc123.ngrok.io

# Set this as your webhook in Africa's Talking dashboard:
# SMS → Incoming Messages → Callback URL:
# https://abc123.ngrok.io/api/v1/referrals/webhook/sms
```

Then simulate a facility reply in the Africa's Talking sandbox dashboard to trigger the webhook.

### SMS format

The referral alert SMS sent to the receiving facility:

```
MAMASAFE REFERRAL #0001
Patient: Marie Ngono | Age: 30
Risk: HIGH RISK (94%)
Key signals: SBP 140mmHg | BS 15.0mmol/L
CHW: Pauline Mba | From: CS de Melen
Reply RECEIVED to confirm.
```

Character count: approximately 160 characters (1 SMS unit). Designed to fit within a single SMS to minimise cost.

### SMS costs (Africa's Talking — Cameroon)

| Network | Cost per SMS |
|---------|-------------|
| MTN Cameroon | ~$0.013 USD |
| Orange Cameroon | ~$0.013 USD |
| Nexttel Cameroon | ~$0.013 USD |

For a district with 200 referrals per month, monthly SMS cost is approximately $2.60 USD — negligible compared to the clinical value.

### Error handling

The SMS utility (`app/utils/sms.py`) wraps the Africa's Talking call in a try-except block. If SMS delivery fails:

- The referral record is still saved successfully — the referral is not blocked by SMS failure
- `sms_sent` is set to `False` and `sms_message_id` records the error string
- The CHW sees a warning on the frontend: *"Referral saved. SMS delivery could not be confirmed."*
- The CHW can still communicate the referral by phone call as a fallback

This design principle — **SMS is a notification layer, not a dependency** — ensures the referral system works even in areas with poor AT connectivity.

---

## 8. Clinical Packet — What Gets Sent

The clinical packet is the set of patient information bundled into the SMS and stored in the `clinical_summary` field of the referral record.

### Auto-generation logic (`build_clinical_summary`)

```python
def build_clinical_summary(assessment, patient) -> str:
    signals = []
    if assessment.systolic_bp:
        signals.append(f"SBP {assessment.systolic_bp}mmHg")
    if assessment.blood_sugar:
        signals.append(f"BS {assessment.blood_sugar}mmol/L")
    if assessment.diastolic_bp:
        signals.append(f"DBP {assessment.diastolic_bp}mmHg")
    top = ", ".join(signals[:3])
    return (
        f"Patient {patient.full_name}, age {int(assessment.age)}. "
        f"Risk: {assessment.risk_level.upper()} "
        f"({int(max(assessment.prob_high, assessment.prob_low, assessment.prob_mid) * 100)}%). "
        f"Key signals: {top}."
    )
```

### Example output

```
Patient Marie Ngono, age 30. Risk: HIGH RISK (94%).
Key signals: SBP 140mmHg, BS 15.0mmol/L, DBP 100mmHg.
```

### What the facility can access

In addition to the SMS summary, when MamaSafe has internet connectivity, the SMS includes a reference link (e.g., `mamasafe.app/ref/001`) that takes the facility directly to the full patient ANC card in the system. This requires the receiving facility to have the MamaSafe web app — a future deployment consideration.

---

## 9. Backend Implementation

### File structure

```
backend/
  app/
    database.py           ← Add Facility and Referral models
    schemas_referral.py   ← Pydantic schemas for referral module
    utils/
      __init__.py
      sms.py              ← Africa's Talking SMS wrapper
    routers/
      referral.py         ← All referral and facility endpoints
    main.py               ← Register referral router
  requirements.txt        ← Add africastalking==1.2.5
  .env                    ← Add AT_USERNAME, AT_API_KEY, AT_SENDER_ID
```

### Database models (`database.py`)

Two new models are added: `Facility` and `Referral`. Key design decisions:

**`receiving_facility_name` is stored as a plain string** even when `receiving_facility_id` is present. This is a denormalisation that protects historical accuracy — if a facility is later renamed or deleted, the referral record still shows the correct name at time of referral.

**`risk_level` is copied** from the assessment at time of referral creation. It does not reference the assessment record dynamically. This ensures the referral record is self-contained and readable even if the assessment record changes.

**`clinical_summary` is pre-generated** at creation time, not on-the-fly. This means the SMS can be sent immediately without a second database query.

### Router logic (`routers/referral.py`)

The `create_referral` endpoint follows this exact sequence:

```python
# 1. Validate patient exists
# 2. Load assessment (if provided)
# 3. Auto-generate clinical_summary
# 4. Extract risk_level from assessment
# 5. Create Referral object
# 6. db.add() and db.commit()
# 7. db.refresh() to get generated id
# 8. Query facility phone number
# 9. Call send_referral_sms() if phone available
# 10. Update referral.sms_sent and sms_message_id
# 11. db.commit() again
# 12. Return referral
```

Steps 9–11 happen after the initial commit. This means even if SMS fails, the referral record is permanently saved. The two-commit pattern is intentional.

### Adding to `main.py`

```python
from app.routers import predict, assessments, auth, dashboard, anc, referral

app.include_router(referral.router)
```

---

## 10. Web Frontend Implementation

### New pages required

| Page | Route | Description |
|------|-------|-------------|
| Facility selector | (component, not page) | Dropdown inside referral form |
| Create referral | `/refer/:assessmentId` | Form to submit a new referral |
| Referral list | `/referrals` | CHW's referral history with status badges |
| Referral detail | `/referrals/:id` | Full referral with status tracker |

### Connecting referral to risk result

The primary entry point is the result page after a risk prediction. Add an **Emergency Refer** button beneath the risk result card — visible and prominent when `risk_level === "high risk"`, available but secondary when `risk_level === "mid risk"`:

```jsx
// In ResultPage.jsx — add below the recommendation card
{(result.risk_level === 'high risk' || result.risk_level === 'mid risk') && (
  <button
    onClick={() => navigate(`/refer/${result.assessment_id}`)}
    className={`w-full py-4 font-black rounded-2xl text-white transition-colors
      ${result.risk_level === 'high risk'
        ? 'bg-red-600 hover:bg-red-700 animate-pulse'
        : 'bg-amber-500 hover:bg-amber-600'}`}
  >
    🚨 Emergency Refer Patient
  </button>
)}
```

### Referral form page (`ReferralPage.jsx`)

```jsx
import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Layout from '../components/Layout';
import { getFacilities, createReferral, getAssessment } from '../api/client';

const URGENCY_OPTIONS = [
  { value: 'emergency', label: 'Emergency — immediate life risk', color: 'red' },
  { value: 'urgent',    label: 'Urgent — within 24 hours',       color: 'amber' },
  { value: 'routine',   label: 'Routine — within 72 hours',      color: 'green' },
];

export default function ReferralPage() {
  const { assessmentId } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const [facilities, setFacilities] = useState([]);
  const [assessment, setAssessment] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [referralResult, setReferralResult] = useState(null);
  const [error, setError] = useState('');

  const [form, setForm] = useState({
    patient_id:              '',
    pregnancy_id:            '',
    assessment_id:           assessmentId || '',
    receiving_facility_id:   '',
    receiving_facility_name: '',
    urgency:                 'urgent',
    sending_facility:        '',
    chw_notes:               '',
  });

  useEffect(() => {
    getFacilities().then(setFacilities);
    if (assessmentId) {
      getAssessment(assessmentId).then(a => {
        setAssessment(a);
        setForm(f => ({
          ...f,
          patient_id:    a.patient_id || '',
          assessment_id: assessmentId,
          urgency: a.risk_level === 'high risk' ? 'emergency' : 'urgent',
        }));
      });
    }
  }, [assessmentId]);

  const handleFacilityChange = (facilityId) => {
    const fac = facilities.find(f => f.id === parseInt(facilityId));
    setForm(f => ({
      ...f,
      receiving_facility_id:   facilityId,
      receiving_facility_name: fac ? fac.name : '',
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.receiving_facility_name) {
      setError('Please select or enter a receiving facility.');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const payload = {
        ...form,
        patient_id:            parseInt(form.patient_id),
        pregnancy_id:          form.pregnancy_id ? parseInt(form.pregnancy_id) : null,
        assessment_id:         form.assessment_id ? parseInt(form.assessment_id) : null,
        receiving_facility_id: form.receiving_facility_id
                                 ? parseInt(form.receiving_facility_id) : null,
      };
      const result = await createReferral(payload);
      setReferralResult(result);
      setSubmitted(true);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to submit referral.');
    } finally {
      setLoading(false);
    }
  };

  // Success screen
  if (submitted && referralResult) {
    return (
      <Layout>
        <div className="max-w-lg mx-auto text-center py-12">
          <div className="text-6xl mb-4">✅</div>
          <h1 className="text-2xl font-black text-gray-900 mb-2">
            Referral Submitted
          </h1>
          <p className="text-gray-500 mb-6">
            Referral #{String(referralResult.id).padStart(4, '0')} has been created.
          </p>

          <div className="bg-green-50 border border-green-200 rounded-2xl p-4 mb-6 text-left">
            <p className="text-sm font-bold text-green-700 mb-1">
              {referralResult.sms_sent
                ? '📱 SMS alert sent to facility'
                : '⚠️ SMS could not be sent — contact facility by phone'}
            </p>
            <p className="text-sm text-green-600">
              To: {referralResult.receiving_facility_name}
            </p>
          </div>

          <div className="bg-gray-50 rounded-2xl p-4 mb-6 text-left text-sm">
            <p className="font-bold text-gray-700 mb-1">Clinical summary sent:</p>
            <p className="text-gray-600">{referralResult.clinical_summary}</p>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => navigate('/referrals')}
              className="py-3 border-2 border-indigo-600 text-indigo-600
                         font-bold rounded-xl hover:bg-indigo-50"
            >
              View all referrals
            </button>
            <button
              onClick={() => navigate('/assess')}
              className="py-3 bg-indigo-600 text-white font-bold
                         rounded-xl hover:bg-indigo-700"
            >
              New assessment
            </button>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-lg mx-auto">
        <div className="mb-6">
          <h1 className="text-2xl font-black text-gray-900">Emergency Referral</h1>
          <p className="text-gray-500 text-sm mt-1">
            Patient will be referred to a receiving facility with a full clinical summary.
          </p>
        </div>

        {assessment && (
          <div className="bg-red-50 border border-red-200 rounded-2xl p-4 mb-4">
            <p className="text-sm font-bold text-red-700">
              🔴 Assessment result: {assessment.risk_level?.toUpperCase()}
            </p>
            <p className="text-xs text-red-600 mt-0.5">
              Confidence: {Math.round(Math.max(
                assessment.prob_high,
                assessment.prob_low,
                assessment.prob_mid) * 100)}%
            </p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">

          {/* Urgency */}
          <div className="bg-white rounded-2xl border border-gray-200 p-4">
            <label className="block text-xs font-semibold text-gray-500
                              uppercase tracking-wider mb-3">
              Urgency level
            </label>
            <div className="space-y-2">
              {URGENCY_OPTIONS.map(opt => (
                <label key={opt.value}
                       className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="radio"
                    name="urgency"
                    value={opt.value}
                    checked={form.urgency === opt.value}
                    onChange={e => setForm(f => ({...f, urgency: e.target.value}))}
                    className="accent-indigo-600"
                  />
                  <span className="text-sm font-medium text-gray-700">
                    {opt.label}
                  </span>
                </label>
              ))}
            </div>
          </div>

          {/* Receiving facility */}
          <div className="bg-white rounded-2xl border border-gray-200 p-4">
            <label className="block text-xs font-semibold text-gray-500
                              uppercase tracking-wider mb-2">
              Receiving facility
            </label>
            <select
              className="w-full px-4 py-3 rounded-xl border border-gray-200
                         focus:ring-2 focus:ring-indigo-500 outline-none text-sm"
              value={form.receiving_facility_id}
              onChange={e => handleFacilityChange(e.target.value)}
            >
              <option value="">Select a facility...</option>
              {facilities.map(fac => (
                <option key={fac.id} value={fac.id}>
                  {fac.name} — {fac.district}
                  {fac.has_blood_bank ? ' 🩸' : ''}
                  {fac.has_operating_theatre ? ' 🏥' : ''}
                </option>
              ))}
            </select>
            <p className="text-xs text-gray-400 mt-1">
              🩸 = blood bank available · 🏥 = operating theatre available
            </p>
          </div>

          {/* CHW notes */}
          <div className="bg-white rounded-2xl border border-gray-200 p-4">
            <label className="block text-xs font-semibold text-gray-500
                              uppercase tracking-wider mb-2">
              Additional notes (optional)
            </label>
            <textarea
              rows={3}
              value={form.chw_notes}
              onChange={e => setForm(f => ({...f, chw_notes: e.target.value}))}
              placeholder="Any additional clinical observations not captured by the assessment..."
              className="w-full px-4 py-3 rounded-xl border border-gray-200
                         focus:ring-2 focus:ring-indigo-500 outline-none text-sm
                         resize-none"
            />
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-xl px-4
                            py-3 text-sm text-red-600">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 bg-red-600 hover:bg-red-700 disabled:opacity-60
                       text-white font-black rounded-2xl transition-colors text-base"
          >
            {loading ? 'Submitting referral...' : '🚨 Submit Emergency Referral'}
          </button>
        </form>
      </div>
    </Layout>
  );
}
```

### Referral list page (`ReferralListPage.jsx`)

```jsx
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../components/Layout';
import { getReferrals } from '../api/client';

const STATUS_CONFIG = {
  sent:            { label: 'Sent',           color: 'amber',  icon: '📤' },
  received:        { label: 'Received',        color: 'blue',   icon: '📥' },
  patient_arrived: { label: 'Patient arrived', color: 'purple', icon: '🏥' },
  completed:       { label: 'Completed',       color: 'green',  icon: '✅' },
  cancelled:       { label: 'Cancelled',       color: 'gray',   icon: '❌' },
};

const COLOR_CLASSES = {
  amber:  'bg-amber-100 text-amber-700 border-amber-200',
  blue:   'bg-blue-100 text-blue-700 border-blue-200',
  purple: 'bg-purple-100 text-purple-700 border-purple-200',
  green:  'bg-green-100 text-green-700 border-green-200',
  gray:   'bg-gray-100 text-gray-600 border-gray-200',
};

export default function ReferralListPage() {
  const navigate = useNavigate();
  const [referrals, setReferrals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const status = filter === 'all' ? null : filter;
    getReferrals(status)
      .then(setReferrals)
      .finally(() => setLoading(false));
  }, [filter]);

  const filters = ['all', 'sent', 'received', 'patient_arrived', 'completed'];

  return (
    <Layout>
      <div className="max-w-2xl mx-auto">
        <h1 className="text-2xl font-black text-gray-900 mb-4">Referrals</h1>

        {/* Filter pills */}
        <div className="flex gap-2 flex-wrap mb-4">
          {filters.map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-full text-xs font-semibold
                          border transition-colors capitalize
                          ${filter === f
                            ? 'bg-indigo-600 text-white border-indigo-600'
                            : 'bg-white text-gray-600 border-gray-200'}`}
            >
              {f === 'all' ? 'All' : STATUS_CONFIG[f]?.label}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="text-center py-12 text-gray-400">Loading...</div>
        ) : referrals.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-3">📋</div>
            <p className="text-gray-500">No referrals found.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {referrals.map(ref => {
              const sc = STATUS_CONFIG[ref.status] || STATUS_CONFIG.sent;
              return (
                <div
                  key={ref.id}
                  onClick={() => navigate(`/referrals/${ref.id}`)}
                  className="bg-white rounded-2xl border border-gray-200 p-4
                             cursor-pointer hover:border-indigo-300
                             hover:shadow-sm transition-all"
                >
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <p className="font-bold text-gray-900 text-sm">
                        Referral #{String(ref.id).padStart(4, '0')}
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5">
                        → {ref.receiving_facility_name}
                      </p>
                    </div>
                    <span className={`text-xs font-semibold px-2.5 py-1
                                     rounded-full border ${COLOR_CLASSES[sc.color]}`}>
                      {sc.icon} {sc.label}
                    </span>
                  </div>

                  <p className="text-xs text-gray-500 mb-2 line-clamp-2">
                    {ref.clinical_summary}
                  </p>

                  <div className="flex items-center justify-between text-xs text-gray-400">
                    <span className={`font-semibold uppercase
                      ${ref.urgency === 'emergency' ? 'text-red-600' :
                        ref.urgency === 'urgent' ? 'text-amber-600' :
                        'text-green-600'}`}>
                      {ref.urgency}
                    </span>
                    <span>
                      {new Date(ref.created_at).toLocaleDateString('en-GB', {
                        day: 'numeric', month: 'short', year: 'numeric'
                      })}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </Layout>
  );
}
```

### API client additions (`api/client.js`)

Add these functions to your existing `client.js`:

```javascript
// Facilities
export const getFacilities = async () => {
  const res = await client.get('/api/v1/facilities');
  return res.data;
};

// Referrals
export const createReferral = async (data) => {
  const res = await client.post('/api/v1/referrals', data);
  return res.data;
};

export const getReferrals = async (status = null) => {
  const url = status
    ? `/api/v1/referrals?status=${status}`
    : '/api/v1/referrals';
  const res = await client.get(url);
  return res.data;
};

export const getReferral = async (id) => {
  const res = await client.get(`/api/v1/referrals/${id}`);
  return res.data;
};

export const updateReferralStatus = async (id, status) => {
  const res = await client.patch(`/api/v1/referrals/${id}/status`, { status });
  return res.data;
};

export const recordOutcome = async (id, outcome, notes) => {
  const res = await client.patch(`/api/v1/referrals/${id}/outcome`, {
    outcome,
    outcome_notes: notes
  });
  return res.data;
};

export const getReferralAnalytics = async () => {
  const res = await client.get('/api/v1/referrals/analytics/summary');
  return res.data;
};
```

### Route registration (`App.jsx`)

Add these imports and routes:

```jsx
import ReferralPage     from './pages/ReferralPage';
import ReferralListPage from './pages/ReferralListPage';

// Inside <Routes>:
<Route path="/refer/:assessmentId" element={
  <ProtectedRoute><ReferralPage /></ProtectedRoute>
} />
<Route path="/referrals" element={
  <ProtectedRoute><ReferralListPage /></ProtectedRoute>
} />
<Route path="/referrals/:id" element={
  <ProtectedRoute><ReferralDetailPage /></ProtectedRoute>
} />
```

---

## 11. Mobile Frontend Implementation (Expo)

### Screen structure

The Expo mobile app has the same screens as the web app but adapted for touch navigation. Add the following screens to your Expo project:

```
src/screens/
  ReferralScreen.js       ← Create referral form (entry from result screen)
  ReferralListScreen.js   ← CHW's referral history
  ReferralDetailScreen.js ← Single referral with status tracker
```

### Bottom tab navigator update

Add a Referrals tab to your existing tab navigator in `App.js`:

```jsx
<Tab.Screen
  name="Referrals"
  component={ReferralListScreen}
  options={{
    title: "Referrals",
    tabBarIcon: ({ focused }) => (
      <TabIcon emoji="🚨" label="Referrals" focused={focused} />
    ),
  }}
/>
```

### Referral screen (`ReferralScreen.js`)

```jsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  TextInput, StyleSheet, Alert, ActivityIndicator
} from 'react-native';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { getFacilities, createReferral } from '../utils/api';

const URGENCY = [
  { value: 'emergency', label: 'Emergency — immediate life risk', color: COLORS.danger },
  { value: 'urgent',    label: 'Urgent — within 24 hours',       color: COLORS.warning },
  { value: 'routine',   label: 'Routine — within 72 hours',      color: COLORS.success },
];

export default function ReferralScreen({ route, navigation }) {
  const { assessmentId, patientId, pregnancyId, riskLevel } = route.params || {};

  const [facilities, setFacilities] = useState([]);
  const [selectedFacility, setSelectedFacility] = useState(null);
  const [urgency, setUrgency] = useState(
    riskLevel === 'high risk' ? 'emergency' : 'urgent'
  );
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [showFacilityPicker, setShowFacilityPicker] = useState(false);

  useEffect(() => {
    getFacilities().then(setFacilities);
  }, []);

  const handleSubmit = async () => {
    if (!selectedFacility) {
      Alert.alert('Required', 'Please select a receiving facility.');
      return;
    }
    setLoading(true);
    try {
      const result = await createReferral({
        patient_id:              patientId,
        pregnancy_id:            pregnancyId || null,
        assessment_id:           assessmentId || null,
        receiving_facility_id:   selectedFacility.id,
        receiving_facility_name: selectedFacility.name,
        urgency,
        chw_notes: notes || null,
      });
      navigation.replace('ReferralSuccess', { referral: result });
    } catch (err) {
      Alert.alert('Error', 'Failed to submit referral. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={s.root} contentContainerStyle={s.scroll}>
      <Text style={s.title}>Emergency Referral</Text>

      {riskLevel === 'high risk' && (
        <View style={s.riskBanner}>
          <Text style={s.riskBannerText}>🔴 HIGH RISK patient — immediate action required</Text>
        </View>
      )}

      {/* Urgency */}
      <View style={s.card}>
        <Text style={s.cardLabel}>Urgency level</Text>
        {URGENCY.map(opt => (
          <TouchableOpacity
            key={opt.value}
            style={[s.urgencyRow, urgency === opt.value && { borderColor: opt.color }]}
            onPress={() => setUrgency(opt.value)}
          >
            <View style={[s.radio, urgency === opt.value && { backgroundColor: opt.color, borderColor: opt.color }]}>
              {urgency === opt.value && <View style={s.radioDot} />}
            </View>
            <Text style={[s.urgencyLabel, urgency === opt.value && { color: opt.color }]}>
              {opt.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Facility picker */}
      <View style={s.card}>
        <Text style={s.cardLabel}>Receiving facility</Text>
        <TouchableOpacity
          style={s.facilityPicker}
          onPress={() => setShowFacilityPicker(true)}
        >
          <Text style={selectedFacility ? s.facilitySelected : s.facilityPlaceholder}>
            {selectedFacility ? selectedFacility.name : 'Select a facility...'}
          </Text>
          <Text style={s.chevron}>›</Text>
        </TouchableOpacity>

        {showFacilityPicker && (
          <View style={s.facilityList}>
            {facilities.map(fac => (
              <TouchableOpacity
                key={fac.id}
                style={s.facilityOption}
                onPress={() => {
                  setSelectedFacility(fac);
                  setShowFacilityPicker(false);
                }}
              >
                <Text style={s.facilityOptionName}>{fac.name}</Text>
                <Text style={s.facilityOptionSub}>
                  {fac.district}
                  {fac.has_blood_bank ? ' · Blood bank' : ''}
                  {fac.has_operating_theatre ? ' · Theatre' : ''}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </View>

      {/* Notes */}
      <View style={s.card}>
        <Text style={s.cardLabel}>Additional notes (optional)</Text>
        <TextInput
          style={s.notesInput}
          value={notes}
          onChangeText={setNotes}
          placeholder="Any additional clinical observations..."
          placeholderTextColor={COLORS.textDim}
          multiline
          numberOfLines={3}
          textAlignVertical="top"
        />
      </View>

      <TouchableOpacity
        style={[s.submitBtn, loading && s.submitBtnDisabled]}
        onPress={handleSubmit}
        disabled={loading}
      >
        {loading
          ? <ActivityIndicator color="#fff" />
          : <Text style={s.submitBtnText}>🚨 Submit Emergency Referral</Text>
        }
      </TouchableOpacity>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:               { flex: 1, backgroundColor: COLORS.bg },
  scroll:             { padding: 16 },
  title:              { fontSize: FONT.xl, fontWeight: '700', color: COLORS.text, marginBottom: 16 },
  riskBanner:         { backgroundColor: '#FEE2E2', borderRadius: RADIUS.md, padding: 12, marginBottom: 12, borderWidth: 1, borderColor: '#FCA5A5' },
  riskBannerText:     { fontSize: FONT.sm, color: '#991B1B', fontWeight: '500' },
  card:               { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: 14, marginBottom: 12 },
  cardLabel:          { fontSize: FONT.xs, fontWeight: '500', color: COLORS.textMuted, textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 10 },
  urgencyRow:         { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 10, borderRadius: RADIUS.md, borderWidth: 1, borderColor: COLORS.border, marginBottom: 6 },
  radio:              { width: 18, height: 18, borderRadius: 9, borderWidth: 2, borderColor: COLORS.border, alignItems: 'center', justifyContent: 'center' },
  radioDot:           { width: 8, height: 8, borderRadius: 4, backgroundColor: '#fff' },
  urgencyLabel:       { fontSize: FONT.sm, color: COLORS.textMuted, flex: 1 },
  facilityPicker:     { flexDirection: 'row', alignItems: 'center', backgroundColor: COLORS.surface2, borderRadius: RADIUS.md, padding: 12, borderWidth: 1, borderColor: COLORS.border },
  facilitySelected:   { flex: 1, fontSize: FONT.sm, color: COLORS.text },
  facilityPlaceholder:{ flex: 1, fontSize: FONT.sm, color: COLORS.textDim },
  chevron:            { fontSize: 18, color: COLORS.textDim },
  facilityList:       { marginTop: 8, borderRadius: RADIUS.md, overflow: 'hidden', borderWidth: 1, borderColor: COLORS.border },
  facilityOption:     { padding: 12, borderBottomWidth: 0.5, borderBottomColor: COLORS.border, backgroundColor: COLORS.surface2 },
  facilityOptionName: { fontSize: FONT.sm, color: COLORS.text, fontWeight: '500' },
  facilityOptionSub:  { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  notesInput:         { backgroundColor: COLORS.surface2, borderRadius: RADIUS.md, padding: 12, color: COLORS.text, fontSize: FONT.sm, minHeight: 80, borderWidth: 1, borderColor: COLORS.border },
  submitBtn:          { backgroundColor: '#DC2626', padding: 16, borderRadius: RADIUS.lg, alignItems: 'center', marginTop: 8 },
  submitBtnDisabled:  { opacity: 0.6 },
  submitBtnText:      { color: '#fff', fontSize: FONT.md, fontWeight: '700' },
});
```

### Navigation from result screen (Expo)

In your existing `ResultScreen.js`, add the referral button after the risk result display:

```jsx
{(result.risk_level === 'high risk' || result.risk_level === 'mid risk') && (
  <TouchableOpacity
    style={[sr.referralBtn,
      result.risk_level === 'high risk' ? sr.btnHighRisk : sr.btnMidRisk]}
    onPress={() => navigation.navigate('Referral', {
      assessmentId: result.assessment_id,
      patientId:    result.patient_id,
      riskLevel:    result.risk_level,
    })}
  >
    <Text style={sr.referralBtnText}>🚨 Emergency Refer Patient</Text>
  </TouchableOpacity>
)}
```

---

## 12. Webhook — Facility Reply Handling

### How it works

When Africa's Talking delivers an SMS and the recipient replies, AT sends an HTTP POST to your registered callback URL. The webhook endpoint at `/api/v1/referrals/webhook/sms` receives this POST, parses the sender's phone number and message text, and updates the referral status accordingly.

### Setting up the callback URL

1. In the Africa's Talking dashboard, go to **SMS → Incoming Messages**
2. Set the callback URL to `https://your-domain.com/api/v1/referrals/webhook/sms`
3. For local development, use ngrok: `ngrok http 8000` and use the HTTPS URL

### Matching logic

The webhook matches incoming replies to referrals by:
1. Finding the `Facility` record whose `phone` matches the SMS sender number
2. Finding the most recent `sent` referral from that facility
3. Updating its status to `received`

### Webhook payload (from Africa's Talking)

```
POST /api/v1/referrals/webhook/sms
Content-Type: application/x-www-form-urlencoded

from=%2B237699000001&to=MamaSafe&text=RECEIVED&date=2025-07-14+10%3A45%3A23&id=ATXid_abc123
```

### Security note

The webhook endpoint has no JWT auth — this is required because Africa's Talking does not support custom auth headers. To secure it in production:

1. Verify the request comes from Africa's Talking IP ranges (documented in AT docs)
2. Add a shared secret parameter: `?secret=your_webhook_secret` and validate it
3. Or whitelist AT IP addresses at the nginx/firewall level

---

## 13. Testing Guide

### Postman test sequence

Run in order, using the JWT token from your CHW login:

```
1. POST /api/v1/facilities        → seed a facility, save id
2. POST /api/v1/referrals         → create referral, save id
3. GET  /api/v1/referrals         → list all referrals (expect 1)
4. PATCH /api/v1/referrals/1/status { "status": "received" }
5. PATCH /api/v1/referrals/1/status { "status": "patient_arrived" }
6. PATCH /api/v1/referrals/1/outcome { "outcome": "delivered", "outcome_notes": "C-section. Both stable." }
7. GET  /api/v1/referrals/1       → verify status is "completed"
8. GET  /api/v1/referrals/analytics/summary → verify completion_rate: 100.0
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| REF-01 | Create referral with valid patient and assessment | `201` response, `status: "sent"`, `clinical_summary` populated |
| REF-02 | Create referral without facility phone | `201` response, `sms_sent: false` |
| REF-03 | Create referral with valid facility phone (sandbox) | `201` response, `sms_sent: true` |
| REF-04 | Update status to `received` | `200`, `received_at` timestamped |
| REF-05 | Update status to `patient_arrived` | `200`, `arrived_at` timestamped |
| REF-06 | Record outcome `delivered` | `200`, `status: "completed"`, `outcome_recorded_at` set |
| REF-07 | Attempt invalid status value | `400` Bad Request |
| REF-08 | Get referrals as CHW | Only own referrals returned |
| REF-09 | Get referrals as admin | All CHW referrals returned |
| REF-10 | Analytics summary after 1 completed referral | `total: 1`, `completion_rate: 100.0` |
| REF-11 | Webhook POST with text "RECEIVED" | Referral status updated to `received` |
| REF-12 | List referrals filtered by status `sent` | Only `sent` referrals returned |

---

## 14. Report Integration

### Where to add referral content in your YIBS report

**Section 1.2 — Statement of the Problem (add bullet 5):**
> The absence of a structured referral mechanism means that high-risk predictions generated by antenatal risk assessment tools do not translate into tracked clinical actions — patients are verbally directed to facilities with no confirmation of arrival, no advance clinical handoff, and no outcome data.

**Section 1.4 — Research Objectives (add Specific Objective 7):**
> To design and implement an emergency referral management module that converts AI risk predictions into tracked clinical referrals, including automated SMS notification to receiving facilities via Africa's Talking and a five-state referral tracking machine.

**Section 2.4 — Literature Gap (add Gap 5):**
> No existing maternal health application for the Cameroonian context integrates AI-powered risk prediction with a structured referral tracking system, facility capacity visibility, and SMS-based clinical handoff — leaving the gap between prediction and action unaddressed.

**Section 3.6 — Model Specification (update API endpoint table):**
> Add all referral endpoints to Table 3.2. Update Figure 3.1 to include the Referral module alongside the ANC, Prediction, and Postnatal modules.

**Section 4.2.5 — Extended System Discussion:**
> The emergency referral module directly addresses Delay 2 of the Three Delays framework. By routing high-risk patients to facilities with confirmed obstetric capacity and sending the clinical packet ahead of the patient, the module reduces both the time to appropriate care and the quality gap on arrival. The referral completion rate metric — unavailable in paper-based systems — enables, for the first time, quantitative measurement of referral effectiveness at district level.

**Section 5.3 — Recommendations (update Recommendation 1):**
> It is recommended that the MamaSafe platform, including the emergency referral module, be piloted in a district health area in collaboration with the Cameroon Ministry of Public Health, with Africa's Talking SMS configured for MTN and Orange Cameroon carrier routes.

---

## 15. Future Extensions

### v3 features not included in current implementation

| Feature | Description | Effort |
|---------|-------------|--------|
| Facility capacity dashboard | Real-time bed and blood supply visibility | Medium |
| GPS-based facility routing | Route to nearest facility with required capacity using Haversine distance | Low |
| Referral map view | Visual map of referral routes in the district | Medium |
| Two-way SMS conversation | Facility can reply with estimated readiness time, not just "RECEIVED" | Low |
| Ambulance tracking | Integration with district ambulance dispatch system | High |
| Referral outcome ML model | Predict likelihood of referral completion based on facility, urgency, time of day | High |

### GPS-based facility routing (quick implementation)

If you add `latitude` and `longitude` to both your patient records and facility records, you can implement nearest-facility routing using the Haversine formula — no external API required:

```python
import math

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat/2)**2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(dlon/2)**2)
    return R * 2 * math.asin(math.sqrt(a))

def nearest_facility_with_obstetric_care(patient_lat, patient_lon, facilities):
    capable = [f for f in facilities if f.has_obstetric_care and f.latitude]
    return min(capable,
               key=lambda f: haversine_km(patient_lat, patient_lon,
                                          f.latitude, f.longitude),
               default=None)
```

This function can be called during referral creation to auto-suggest the nearest capable facility, then let the CHW confirm or override.

---

*End of document.*

**MamaSafe Referral System Documentation v1.0**  
*Prepared for the MamaSafe Final Year Project — YIBS Software Engineering*
