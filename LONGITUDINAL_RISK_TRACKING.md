# MamaSafe — Longitudinal Risk Tracking
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Longitudinal Risk Tracking  
**Stack:** FastAPI · PostgreSQL · React · Recharts · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Clinical Context](#2-clinical-context)
3. [System Architecture](#3-system-architecture)
4. [How It Works](#4-how-it-works)
5. [Data Model](#5-data-model)
6. [Alert Logic](#6-alert-logic)
7. [API Reference](#7-api-reference)
8. [Backend Implementation](#8-backend-implementation)
9. [Web Frontend Implementation](#9-web-frontend-implementation)
10. [Mobile Frontend Implementation (Expo)](#10-mobile-frontend-implementation-expo)
11. [WhatsApp Risk Escalation Alerts](#11-whatsapp-risk-escalation-alerts)
12. [Testing Guide](#12-testing-guide)
13. [Report Integration](#13-report-integration)
14. [Future Extensions](#14-future-extensions)

---

## 1. Overview and Purpose

The MamaSafe Longitudinal Risk Tracking module transforms MamaSafe from a
point-in-time risk assessment tool into a continuous pregnancy monitoring
system. Without this module, every assessment is an island — the CHW sees
a risk result, acts on it, and the next visit starts from scratch with no
memory of what came before. A patient whose risk has been quietly escalating
across three visits may not trigger concern on any single visit, but the
trend tells a different story entirely.

Longitudinal risk tracking does three things:

**1. Plots risk scores across all ANC visits** — Every assessment linked to
a patient is displayed as a trend chart on the patient profile. The CHW sees
at a glance whether the patient is stable, improving, or deteriorating across
the pregnancy.

**2. Detects risk escalation automatically** — When a new assessment produces
a higher risk level than the previous one, the system fires an escalation
alert. A patient who was low risk at visit 2 and is now mid risk at visit 3
has her CHW notified immediately via WhatsApp.

**3. Surfaces the clinical drivers of change** — The trend view shows not
just the overall risk level over time but also how each individual clinical
feature (SystolicBP, Blood Sugar, Age) has changed between visits. This
gives the CHW a precise picture of what is worsening, not just that something
has worsened.

**What this replaces:** Paper-based ANC cards record measurements visit by
visit, but trend analysis — comparing readings across visits — requires
manual calculation by the CHW. In practice, this rarely happens. Longitudinal
tracking makes the trend automatic, visual, and alerting.

---

## 2. Clinical Context

### Why trends matter more than single readings

A single high blood pressure reading at one visit may be positional, stress
related, or instrument error. The same reading appearing at three consecutive
visits with an upward slope is gestational hypertension developing into
pre-eclampsia. The clinical significance lies in the pattern, not the
point.

The same principle applies to blood sugar: a reading of 9 mmol/L at 16
weeks is concerning. The same reading at 26 weeks following readings of
7, 7.5, and 8 at earlier visits reveals a progression toward gestational
diabetes that needs urgent intervention.

WHO ANC guidelines explicitly recommend tracking measurements across visits
precisely for this reason — to detect deteriorating conditions before they
become emergencies.

### Risk escalation as a clinical signal

MamaSafe classifies risk as low, mid, or high. The transition between these
levels across consecutive visits is the most actionable clinical signal the
system can produce:

| Transition | Clinical meaning | Required action |
|-----------|-----------------|-----------------|
| Low → Low | Stable, no concern | Routine monitoring |
| Low → Mid | Early deterioration | Increase visit frequency |
| Mid → Mid | Stable but elevated | Monitor closely |
| Mid → High | Active deterioration | Immediate referral |
| Low → High | Rapid deterioration | Emergency referral |
| High → Mid | Improving with intervention | Continue current care |
| High → Low | Resolved | Document and maintain |

Any upward transition (toward higher risk) triggers an automated alert.
Downward transitions (toward lower risk) are noted positively but do not
trigger alerts — they confirm that clinical interventions are working.

### The SHAP dimension

Each assessment already carries SHAP values showing which features drove
the prediction. Longitudinal tracking extends this to show how SHAP values
for each feature change between visits. If SystolicBP's SHAP contribution
increases from +0.5 at visit 2 to +2.3 at visit 4, blood pressure is not
just elevated — it is becoming increasingly dominant in driving the risk
classification. This is a level of clinical insight impossible to obtain
from paper records.

---

## 3. System Architecture

### Component overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      MamaSafe Platform                          │
│                                                                 │
│  ┌──────────────┐    ┌─────────────────────────────────────┐   │
│  │  React Web   │───▶│           FastAPI Backend            │   │
│  │  Expo Mobile │    │                                      │   │
│  └──────────────┘    │  /api/v1/patients/{id}/risk-trend   │   │
│                      │  /api/v1/patients/{id}/risk-summary  │   │
│                      │  /api/v1/assessments (existing)      │   │
│                      │                                      │   │
│                      │  ┌──────────────────────────────┐   │   │
│                      │  │    Escalation Detector       │   │   │
│                      │  │  (runs on every new          │   │   │
│                      │  │   assessment submission)     │   │   │
│                      │  └──────────┬───────────────────┘   │   │
│                      └────────────┼──────────────────────────┘  │
└───────────────────────────────────┼─────────────────────────────┘
                                    │ WhatsApp alert on escalation
                         ┌──────────▼──────────┐
                         │  Baileys WhatsApp   │
                         │  Microservice       │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   CHW's WhatsApp    │
                         └─────────────────────┘
```

### Key design decision — no new assessment model

Longitudinal tracking requires **zero changes to the existing Assessment
model**. All data needed already exists:

- `assessments.patient_id` — links assessment to patient
- `assessments.risk_level` — the classification result
- `assessments.prob_high / prob_low / prob_mid` — probability scores
- `assessments.systolic_bp, blood_sugar, age` etc — raw feature values
- `assessments.shap_bs, shap_systolic, shap_age` — SHAP contributions
- `assessments.created_at` — timestamp for ordering

The longitudinal view is a **query and aggregation** over existing data,
not a new data collection. This makes it the lowest-effort feature on the
v2 roadmap relative to its clinical value.

The only addition needed is a `patient_id` foreign key on the assessments
table — which was already added when building the ANC card module. If it
is present, this module is ready to build immediately.

---

## 4. How It Works

### Step 1 — Patient assessment is linked to patient record

When a CHW submits a new assessment from the patient profile screen
(rather than the standalone assessment form), the `patient_id` is
automatically included in the request body. The assessment is saved as
normal and also linked to the patient record.

### Step 2 — Escalation check runs automatically

Immediately after saving the new assessment, the backend calls
`check_risk_escalation(patient_id, new_assessment)`. This function:

1. Loads the previous assessment for this patient (ordered by `created_at`)
2. Compares `risk_level` of previous vs new assessment
3. If new risk level is higher — fires a WhatsApp alert to the CHW
4. Logs the escalation event

### Step 3 — CHW views the trend chart

On the patient profile page, a `RiskTrendChart` component fetches
`GET /api/v1/patients/{id}/risk-trend` and renders:

- A line chart with risk level plotted across visits (y-axis:
  high/mid/low, x-axis: visit date)
- A confidence score line overlaid on the same chart
- Below the chart: a feature trend table showing how BP, BS, and other
  key values changed between visits
- An escalation badge if the most recent assessment represents a
  risk increase

### Step 4 — CHW acts on the trend

If the trend shows escalation, the patient profile displays a prominent
action card:

- If mid risk is reached: "Consider increasing visit frequency"
- If high risk is reached: an Emergency Refer button linking directly
  to the referral module

This connects the longitudinal tracking module to the referral module
built previously — escalation detected → referral initiated, all within
the same patient profile view.

---

## 5. Data Model

### No new database tables required

Longitudinal risk tracking is entirely read-based. It queries the
existing `assessments` table using `patient_id` as the grouping key.

The only prerequisite is confirming that `patient_id` exists on the
`assessments` table. Verify with:

```bash
python -c "
from app.database import Assessment
print([c.name for c in Assessment.__table__.columns])
"
```

If `patient_id` is present, proceed. If not, add it:

```python
# In database.py, inside the Assessment class:
patient_id = Column(Integer, ForeignKey("patients.id"), nullable=True)
```

Then run:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('Done')
"
```

### New table — `risk_escalation_events`

This table logs every detected escalation for audit, analytics, and
future ML training purposes:

```python
class RiskEscalationEvent(Base):
    __tablename__ = "risk_escalation_events"

    id                  = Column(Integer, primary_key=True, index=True)
    patient_id          = Column(Integer, ForeignKey("patients.id"),
                                 nullable=False)
    previous_assessment_id = Column(Integer, ForeignKey("assessments.id"),
                                    nullable=True)
    new_assessment_id   = Column(Integer, ForeignKey("assessments.id"),
                                 nullable=False)
    previous_risk_level = Column(String, nullable=False)
    new_risk_level      = Column(String, nullable=False)
    escalation_type     = Column(String, nullable=False)
    # low_to_mid | mid_to_high | low_to_high
    whatsapp_sent       = Column(Boolean, default=False)
    chw_id              = Column(Integer, ForeignKey("users.id"),
                                 nullable=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    patient             = relationship("Patient")
```

Add to `database.py` after your existing models and run migration.

### Risk level numeric mapping

For trend charting, risk levels are mapped to numeric values:

```python
RISK_NUMERIC = {
    "low risk":  1,
    "mid risk":  2,
    "high risk": 3,
}
```

This allows the frontend to plot risk on a numeric y-axis where 1 = low,
2 = mid, 3 = high, making upward trends visually obvious.

### Escalation type classification

```python
ESCALATION_TYPES = {
    ("low risk",  "mid risk"):  "low_to_mid",
    ("mid risk",  "high risk"): "mid_to_high",
    ("low risk",  "high risk"): "low_to_high",   # most urgent
}

IMPROVEMENT_TYPES = {
    ("high risk", "mid risk"):  "high_to_mid",
    ("mid risk",  "low risk"):  "mid_to_low",
    ("high risk", "low risk"):  "high_to_low",
}
```

---

## 6. Alert Logic

### Escalation detection function

```python
def check_risk_escalation(db, patient_id, new_assessment, chw):
    """
    Called after every new assessment is saved.
    Compares with previous assessment for same patient.
    Fires WhatsApp alert to CHW if risk has escalated.
    """
    RISK_ORDER = {"low risk": 1, "mid risk": 2, "high risk": 3}

    # Load previous assessment for this patient
    previous = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id,
                  Assessment.id != new_assessment.id)
          .order_by(Assessment.created_at.desc())
          .first()
    )

    if not previous:
        # First assessment for this patient — no comparison possible
        return None

    prev_score = RISK_ORDER.get(previous.risk_level, 0)
    new_score  = RISK_ORDER.get(new_assessment.risk_level, 0)

    if new_score <= prev_score:
        # Same or lower risk — no escalation
        return None

    # Escalation detected
    escalation_type = f"{previous.risk_level.replace(' ', '_')}_to_" \
                      f"{new_assessment.risk_level.replace(' ', '_')}"

    patient = db.query(Patient).filter(Patient.id == patient_id).first()

    event = RiskEscalationEvent(
        patient_id             = patient_id,
        previous_assessment_id = previous.id,
        new_assessment_id      = new_assessment.id,
        previous_risk_level    = previous.risk_level,
        new_risk_level         = new_assessment.risk_level,
        escalation_type        = escalation_type,
        chw_id                 = chw.id if chw else None,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    return event
```

### Escalation WhatsApp alert

When escalation is detected, the CHW receives an immediate WhatsApp
alert with the patient name, the escalation type, the key driving signals
from SHAP, and a direct link to the patient profile to act.

```
⚠️ *MamaSafe — Escalade de risque détectée*

Bonjour [Nom du CHW],

Le risque de votre patiente *[Nom de la patiente]* vient
d'augmenter :

🔴 *[RISQUE FAIBLE → RISQUE ÉLEVÉ]*

📊 Principaux facteurs :
• Tension systolique : [SBP] mmHg (SHAP: +[value])
• Glycémie : [BS] mmol/L (SHAP: +[value])

⚡ Action requise : Référer immédiatement à un hôpital de
district.

Consultez le profil complet dans MamaSafe.
_MamaSafe_
```

---

## 7. API Reference

### Base URL
```
http://localhost:8000/api/v1
```

All endpoints require JWT authentication.

---

### `GET /patients/{patient_id}/risk-trend`

Returns all assessments for a patient, ordered chronologically, with
all data needed for trend charting.

**Response:**
```json
{
  "patient_id": 1,
  "patient_name": "Marie Ngono",
  "total_assessments": 4,
  "current_risk_level": "mid risk",
  "risk_trend": "escalating",
  "last_escalation": {
    "from": "low risk",
    "to": "mid risk",
    "date": "2025-05-02"
  },
  "assessments": [
    {
      "id": 1,
      "visit_number": 1,
      "date": "2025-03-07",
      "gestational_week": 8,
      "risk_level": "low risk",
      "risk_numeric": 1,
      "confidence": 0.92,
      "prob_high": 0.03,
      "prob_mid": 0.05,
      "prob_low": 0.92,
      "systolic_bp": 110,
      "diastolic_bp": 70,
      "blood_sugar": 6.5,
      "body_temp": 98.0,
      "heart_rate": 72,
      "age": 30,
      "shap_bs": -1.2,
      "shap_systolic": -0.8,
      "shap_age": 0.3
    },
    {
      "id": 3,
      "visit_number": 2,
      "date": "2025-05-02",
      "gestational_week": 16,
      "risk_level": "mid risk",
      "risk_numeric": 2,
      "confidence": 0.78,
      "prob_high": 0.12,
      "prob_mid": 0.78,
      "prob_low": 0.10,
      "systolic_bp": 125,
      "diastolic_bp": 82,
      "blood_sugar": 8.9,
      "shap_bs": 0.6,
      "shap_systolic": 0.4,
      "shap_age": 0.2
    }
  ],
  "feature_trends": {
    "systolic_bp":  [110, 125],
    "diastolic_bp": [70,  82],
    "blood_sugar":  [6.5, 8.9],
    "body_temp":    [98.0, 98.0],
    "heart_rate":   [72, 75],
    "shap_bs":      [-1.2, 0.6],
    "shap_systolic": [-0.8, 0.4]
  }
}
```

---

### `GET /patients/{patient_id}/risk-summary`

Lightweight summary for displaying on patient list cards — no full
assessment data, just the trend headline.

**Response:**
```json
{
  "patient_id": 1,
  "total_assessments": 4,
  "current_risk_level": "mid risk",
  "previous_risk_level": "low risk",
  "risk_trend": "escalating",
  "last_assessment_date": "2025-05-02",
  "escalation_count": 1
}
```

---

### `GET /patients/{patient_id}/escalations`

All escalation events for a patient.

**Response:** Array of escalation event objects ordered by date.

---

### `GET /risk-escalations/recent`

Recent escalation events across all of the CHW's patients. Used for
the dashboard alert feed.

**Query params:**
- `days` (optional, default 7) — lookback window
- `limit` (optional, default 10)

---

### `GET /risk-escalations/analytics`

Escalation statistics for the CHW's patient panel.

**Response:**
```json
{
  "total_escalations":     8,
  "low_to_mid":            5,
  "mid_to_high":           2,
  "low_to_high":           1,
  "patients_currently_high_risk": 3,
  "patients_escalated_this_week": 2
}
```

---

## 8. Backend Implementation

### File structure additions

```
backend/
  app/
    database.py              ← Add RiskEscalationEvent model
    utils/
      risk_tracking.py       ← Escalation detection + WhatsApp alert
    routers/
      risk_trend.py          ← All longitudinal tracking endpoints
    routers/
      predict.py             ← Update to trigger escalation check
    main.py                  ← Register risk_trend router
```

### Step 1 — Add `RiskEscalationEvent` to `database.py`

Add this class after your existing models:

```python
class RiskEscalationEvent(Base):
    __tablename__ = "risk_escalation_events"

    id                     = Column(Integer, primary_key=True, index=True)
    patient_id             = Column(Integer, ForeignKey("patients.id"),
                                    nullable=False)
    previous_assessment_id = Column(Integer, ForeignKey("assessments.id"),
                                    nullable=True)
    new_assessment_id      = Column(Integer, ForeignKey("assessments.id"),
                                    nullable=False)
    previous_risk_level    = Column(String, nullable=False)
    new_risk_level         = Column(String, nullable=False)
    escalation_type        = Column(String, nullable=False)
    whatsapp_sent          = Column(Boolean, default=False)
    chw_id                 = Column(Integer, ForeignKey("users.id"),
                                    nullable=True)
    created_at             = Column(DateTime, default=datetime.utcnow)

    patient                = relationship("Patient")
    chw                    = relationship("User",
                                          foreign_keys=[chw_id])
```

Run migration:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('Done')
"
```

### Step 2 — Risk tracking utility (`utils/risk_tracking.py`)

```python
from sqlalchemy.orm import Session
from datetime import datetime
from app.database import (Assessment, Patient, User,
                           RiskEscalationEvent)
from app.utils.whatsapp import send_whatsapp
import asyncio
import logging

logger = logging.getLogger("mamasafe.risk_tracking")

RISK_ORDER = {"low risk": 1, "mid risk": 2, "high risk": 3}

ESCALATION_MESSAGES_FR = {
    "low_to_mid": (
        "⚠️ *MamaSafe — Escalade de risque*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a augmenté :\n\n"
        "🟡 *RISQUE FAIBLE → RISQUE MOYEN*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "Action recommandée : Augmentez la fréquence des visites "
        "et surveillez de près.\n\n"
        "_MamaSafe_"
    ),
    "mid_to_high": (
        "🚨 *MamaSafe — ALERTE RISQUE ÉLEVÉ*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a fortement "
        "augmenté :\n\n"
        "🔴 *RISQUE MOYEN → RISQUE ÉLEVÉ*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "⚡ *Action requise : Référer immédiatement à un hôpital "
        "de district.*\n\n"
        "_MamaSafe_"
    ),
    "low_to_high": (
        "🚨 *MamaSafe — ALERTE URGENTE*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a augmenté "
        "de façon critique :\n\n"
        "🔴 *RISQUE FAIBLE → RISQUE ÉLEVÉ*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "⚡ *Action requise : RÉFÉRER EN URGENCE IMMÉDIATEMENT.*\n\n"
        "_MamaSafe_"
    ),
}

ESCALATION_MESSAGES_EN = {
    "low_to_mid": (
        "⚠️ *MamaSafe — Risk Escalation*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk level has increased:\n\n"
        "🟡 *LOW RISK → MID RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "Recommended action: Increase visit frequency and monitor "
        "closely.\n\n"
        "_MamaSafe_"
    ),
    "mid_to_high": (
        "🚨 *MamaSafe — HIGH RISK ALERT*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk level has escalated:\n\n"
        "🔴 *MID RISK → HIGH RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "⚡ *Action required: Refer to district hospital immediately.*"
        "\n\n_MamaSafe_"
    ),
    "low_to_high": (
        "🚨 *MamaSafe — URGENT ALERT*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk has jumped critically:\n\n"
        "🔴 *LOW RISK → HIGH RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "⚡ *Action required: EMERGENCY REFERRAL IMMEDIATELY.*\n\n"
        "_MamaSafe_"
    ),
}


def build_signal_lines(assessment) -> str:
    """Format top SHAP-driven signals for WhatsApp message."""
    signals = []
    if assessment.systolic_bp:
        signals.append(f"• Tension systolique : {assessment.systolic_bp} mmHg")
    if assessment.blood_sugar:
        signals.append(f"• Glycémie : {assessment.blood_sugar} mmol/L")
    if assessment.diastolic_bp:
        signals.append(f"• Tension diastolique : {assessment.diastolic_bp} mmHg")
    return "\n".join(signals[:3])


def get_escalation_type(prev_level: str, new_level: str) -> str:
    prev = prev_level.replace(" ", "_")
    new  = new_level.replace(" ", "_")
    return f"{prev}_to_{new}"


def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def check_and_handle_escalation(
    db: Session,
    patient_id: int,
    new_assessment,
    chw
):
    """
    Main function called after every new assessment.
    Detects escalation, logs event, sends WhatsApp alert.
    Returns the escalation event if one was detected, else None.
    """
    # Get previous assessment for this patient
    previous = (
        db.query(Assessment)
          .filter(
              Assessment.patient_id == patient_id,
              Assessment.id != new_assessment.id
          )
          .order_by(Assessment.created_at.desc())
          .first()
    )

    if not previous:
        logger.info(f"First assessment for patient {patient_id} — "
                    f"no comparison")
        return None

    prev_score = RISK_ORDER.get(previous.risk_level, 0)
    new_score  = RISK_ORDER.get(new_assessment.risk_level, 0)

    if new_score <= prev_score:
        direction = "stable" if new_score == prev_score else "improving"
        logger.info(
            f"Patient {patient_id}: {previous.risk_level} → "
            f"{new_assessment.risk_level} ({direction})"
        )
        return None

    # Escalation confirmed
    escalation_type = get_escalation_type(
        previous.risk_level, new_assessment.risk_level
    )
    logger.warning(
        f"ESCALATION: Patient {patient_id}: {previous.risk_level} → "
        f"{new_assessment.risk_level} ({escalation_type})"
    )

    # Log escalation event
    event = RiskEscalationEvent(
        patient_id             = patient_id,
        previous_assessment_id = previous.id,
        new_assessment_id      = new_assessment.id,
        previous_risk_level    = previous.risk_level,
        new_risk_level         = new_assessment.risk_level,
        escalation_type        = escalation_type,
        chw_id                 = chw.id if chw else None,
        whatsapp_sent          = False,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    # Send WhatsApp alert to CHW
    chw_phone = getattr(chw, 'whatsapp_number', None) if chw else None
    if chw_phone:
        patient = db.query(Patient).filter(
            Patient.id == patient_id).first()
        lang = getattr(patient, 'preferred_language', 'fr') or 'fr'

        templates = (ESCALATION_MESSAGES_FR
                     if lang == 'fr' else ESCALATION_MESSAGES_EN)
        template  = templates.get(escalation_type, templates["mid_to_high"])

        message = template.format(
            chw_name     = chw.full_name or chw.username,
            patient_name = patient.full_name if patient else f"Patient #{patient_id}",
            signals      = build_signal_lines(new_assessment),
        )

        result = run_async(send_whatsapp(chw_phone, message))
        event.whatsapp_sent = result.get("success", False)
        db.commit()

        logger.info(
            f"Escalation WhatsApp to CHW {chw.username}: "
            f"{'sent' if event.whatsapp_sent else 'failed'}"
        )

    return event
```

### Step 3 — Update the predict router

Open `app/routers/predict.py` and update `predict_risk` to trigger the
escalation check when `patient_id` is present:

```python
from app.utils.risk_tracking import check_and_handle_escalation

@router.post("/predict", response_model=PredictResponse)
def predict_risk(
    request: PredictRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    result = run_predict(request.dict())

    record = Assessment(
        patient_ref  = request.patient_ref,
        patient_id   = request.patient_id,   # include if present in schema
        age          = request.age,
        systolic_bp  = request.systolic_bp,
        diastolic_bp = request.diastolic_bp,
        blood_sugar  = request.blood_sugar,
        body_temp    = request.body_temp,
        heart_rate   = request.heart_rate,
        risk_level   = result["risk_level"],
        prob_high    = result["prob_high"],
        prob_low     = result["prob_low"],
        prob_mid     = result["prob_mid"],
        shap_bs      = next((s["shap_value"] for s in result["shap_values"]
                             if s["feature"] == "BS"), None),
        shap_systolic= next((s["shap_value"] for s in result["shap_values"]
                             if s["feature"] == "SystolicBP"), None),
        shap_age     = next((s["shap_value"] for s in result["shap_values"]
                             if s["feature"] == "Age"), None),
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    # Longitudinal risk tracking — check for escalation
    escalation = None
    if request.patient_id:
        escalation = check_and_handle_escalation(
            db          = db,
            patient_id  = request.patient_id,
            new_assessment = record,
            chw         = current_user,
        )

    response = {**result, "assessment_id": record.id}
    if escalation:
        response["escalation_detected"] = True
        response["escalation_type"]     = escalation.escalation_type
        response["previous_risk_level"] = escalation.previous_risk_level
    else:
        response["escalation_detected"] = False

    return response
```

Also update `PredictRequest` in `schemas.py` to accept `patient_id`:

```python
class PredictRequest(BaseModel):
    age:          float = Field(..., ge=10,  le=70)
    systolic_bp:  float = Field(..., ge=70,  le=180)
    diastolic_bp: float = Field(..., ge=40,  le=120)
    blood_sugar:  float = Field(..., ge=4,   le=25)
    body_temp:    float = Field(..., ge=95,  le=105)
    heart_rate:   float = Field(..., ge=40,  le=100)
    patient_ref:  Optional[str]  = None
    patient_id:   Optional[int]  = None   # add this line
    pregnancy_id: Optional[int]  = None   # add this line
```

And update `PredictResponse` to carry escalation info back to frontend:

```python
class PredictResponse(BaseModel):
    risk_level:           str
    confidence:           float
    prob_high:            float
    prob_low:             float
    prob_mid:             float
    recommendation:       str
    shap_values:          list[SHAPExplanation]
    assessment_id:        int
    escalation_detected:  bool = False         # add
    escalation_type:      Optional[str] = None # add
    previous_risk_level:  Optional[str] = None # add
```

### Step 4 — Risk trend router (`routers/risk_trend.py`)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, timedelta

from app.database import (get_db, Assessment, Patient,
                           RiskEscalationEvent)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["risk-trend"])

RISK_NUMERIC = {"low risk": 1, "mid risk": 2, "high risk": 3}
RISK_ORDER   = {"low risk": 1, "mid risk": 2, "high risk": 3}


def compute_trend(assessments: list) -> str:
    """
    Determine overall trend direction from a list of assessments
    ordered oldest to newest.
    """
    if len(assessments) < 2:
        return "insufficient_data"
    first_score = RISK_NUMERIC.get(assessments[0].risk_level, 0)
    last_score  = RISK_NUMERIC.get(assessments[-1].risk_level, 0)
    if last_score > first_score:
        return "escalating"
    if last_score < first_score:
        return "improving"
    return "stable"


@router.get("/patients/{patient_id}/risk-trend")
def get_risk_trend(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    assessments = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .order_by(Assessment.created_at.asc())
          .all()
    )

    if not assessments:
        return {
            "patient_id":          patient_id,
            "patient_name":        patient.full_name,
            "total_assessments":   0,
            "current_risk_level":  None,
            "risk_trend":          "no_data",
            "last_escalation":     None,
            "assessments":         [],
            "feature_trends":      {},
        }

    # Build assessment data list
    assessment_data = []
    for i, a in enumerate(assessments):
        assessment_data.append({
            "id":              a.id,
            "visit_number":    i + 1,
            "date":            str(a.created_at.date()),
            "risk_level":      a.risk_level,
            "risk_numeric":    RISK_NUMERIC.get(a.risk_level, 0),
            "confidence":      round(max(a.prob_high or 0,
                                         a.prob_low  or 0,
                                         a.prob_mid  or 0), 4),
            "prob_high":       a.prob_high,
            "prob_low":        a.prob_low,
            "prob_mid":        a.prob_mid,
            "systolic_bp":     a.systolic_bp,
            "diastolic_bp":    a.diastolic_bp,
            "blood_sugar":     a.blood_sugar,
            "body_temp":       a.body_temp,
            "heart_rate":      a.heart_rate,
            "age":             a.age,
            "shap_bs":         a.shap_bs,
            "shap_systolic":   a.shap_systolic,
            "shap_age":        a.shap_age,
        })

    # Feature trends — list of values per feature across visits
    feature_trends = {
        "systolic_bp":   [a.systolic_bp  for a in assessments if a.systolic_bp],
        "diastolic_bp":  [a.diastolic_bp for a in assessments if a.diastolic_bp],
        "blood_sugar":   [a.blood_sugar  for a in assessments if a.blood_sugar],
        "body_temp":     [a.body_temp    for a in assessments if a.body_temp],
        "heart_rate":    [a.heart_rate   for a in assessments if a.heart_rate],
        "shap_bs":       [a.shap_bs      for a in assessments if a.shap_bs is not None],
        "shap_systolic": [a.shap_systolic for a in assessments if a.shap_systolic is not None],
        "shap_age":      [a.shap_age     for a in assessments if a.shap_age is not None],
    }

    # Most recent escalation event
    last_escalation = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .order_by(RiskEscalationEvent.created_at.desc())
          .first()
    )

    escalation_data = None
    if last_escalation:
        escalation_data = {
            "from": last_escalation.previous_risk_level,
            "to":   last_escalation.new_risk_level,
            "date": str(last_escalation.created_at.date()),
            "type": last_escalation.escalation_type,
        }

    return {
        "patient_id":         patient_id,
        "patient_name":       patient.full_name,
        "total_assessments":  len(assessments),
        "current_risk_level": assessments[-1].risk_level,
        "risk_trend":         compute_trend(assessments),
        "last_escalation":    escalation_data,
        "assessments":        assessment_data,
        "feature_trends":     feature_trends,
    }


@router.get("/patients/{patient_id}/risk-summary")
def get_risk_summary(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Lightweight summary for patient list cards."""
    assessments = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .order_by(Assessment.created_at.desc())
          .limit(2)
          .all()
    )

    if not assessments:
        return {"patient_id": patient_id, "total_assessments": 0,
                "current_risk_level": None, "risk_trend": "no_data",
                "escalation_count": 0}

    current  = assessments[0]
    previous = assessments[1] if len(assessments) > 1 else None

    trend = "stable"
    if previous:
        cs = RISK_ORDER.get(current.risk_level, 0)
        ps = RISK_ORDER.get(previous.risk_level, 0)
        if cs > ps:
            trend = "escalating"
        elif cs < ps:
            trend = "improving"

    escalation_count = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .count()
    )

    total = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .count()
    )

    return {
        "patient_id":            patient_id,
        "total_assessments":     total,
        "current_risk_level":    current.risk_level,
        "previous_risk_level":   previous.risk_level if previous else None,
        "last_assessment_date":  str(current.created_at.date()),
        "risk_trend":            trend,
        "escalation_count":      escalation_count,
    }


@router.get("/patients/{patient_id}/escalations")
def get_patient_escalations(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    events = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .order_by(RiskEscalationEvent.created_at.desc())
          .all()
    )
    return [
        {
            "id":                     e.id,
            "from":                   e.previous_risk_level,
            "to":                     e.new_risk_level,
            "escalation_type":        e.escalation_type,
            "date":                   str(e.created_at.date()),
            "whatsapp_sent":          e.whatsapp_sent,
            "previous_assessment_id": e.previous_assessment_id,
            "new_assessment_id":      e.new_assessment_id,
        }
        for e in events
    ]


@router.get("/risk-escalations/recent")
def recent_escalations(
    days: int = 7,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Recent escalations across CHW's patients for dashboard feed."""
    since = date.today() - timedelta(days=days)
    q = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.created_at >= str(since))
          .order_by(RiskEscalationEvent.created_at.desc())
    )
    if current_user.role != "admin":
        q = q.filter(RiskEscalationEvent.chw_id == current_user.id)

    events = q.limit(limit).all()

    result = []
    for e in events:
        patient = db.query(Patient).filter(Patient.id == e.patient_id).first()
        result.append({
            "patient_id":      e.patient_id,
            "patient_name":    patient.full_name if patient else "Unknown",
            "from":            e.previous_risk_level,
            "to":              e.new_risk_level,
            "escalation_type": e.escalation_type,
            "date":            str(e.created_at.date()),
            "whatsapp_sent":   e.whatsapp_sent,
        })
    return result


@router.get("/risk-escalations/analytics")
def escalation_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = db.query(RiskEscalationEvent)
    if current_user.role != "admin":
        q = q.filter(RiskEscalationEvent.chw_id == current_user.id)

    total        = q.count()
    low_to_mid   = q.filter(RiskEscalationEvent.escalation_type
                              == "low_risk_to_mid_risk").count()
    mid_to_high  = q.filter(RiskEscalationEvent.escalation_type
                              == "mid_risk_to_high_risk").count()
    low_to_high  = q.filter(RiskEscalationEvent.escalation_type
                              == "low_risk_to_high_risk").count()

    # Patients currently high risk
    from app.database import Patient
    from sqlalchemy import func
    subq = (
        db.query(Assessment.patient_id,
                 func.max(Assessment.created_at).label("latest"))
          .filter(Assessment.patient_id.isnot(None))
          .group_by(Assessment.patient_id)
          .subquery()
    )
    latest_assessments = (
        db.query(Assessment)
          .join(subq, (Assessment.patient_id == subq.c.patient_id) &
                      (Assessment.created_at  == subq.c.latest))
          .filter(Assessment.risk_level == "high risk")
          .count()
    )

    one_week_ago = date.today() - timedelta(days=7)
    this_week = q.filter(
        RiskEscalationEvent.created_at >= str(one_week_ago)
    ).count()

    return {
        "total_escalations":              total,
        "low_to_mid":                     low_to_mid,
        "mid_to_high":                    mid_to_high,
        "low_to_high":                    low_to_high,
        "patients_currently_high_risk":   latest_assessments,
        "patients_escalated_this_week":   this_week,
    }
```

### Step 5 — Register router in `main.py`

```python
from app.routers import (predict, assessments, auth, dashboard,
                          anc, referral, schedule, risk_trend)

app.include_router(risk_trend.router)
```

---

## 9. Web Frontend Implementation

### New components

| Component | Description |
|-----------|-------------|
| `RiskTrendChart.jsx` | Line chart of risk level over visits |
| `FeatureTrendTable.jsx` | Table showing BP, BS, SHAP changes across visits |
| `EscalationBadge.jsx` | Prominent alert badge when risk has escalated |
| `EscalationFeed.jsx` | Dashboard widget listing recent escalations |

### Risk trend chart (`RiskTrendChart.jsx`)

```jsx
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ReferenceLine, ResponsiveContainer, Legend
} from 'recharts';

const RISK_LABELS = { 1: 'Low risk', 2: 'Mid risk', 3: 'High risk' };
const RISK_COLORS = { 1: '#22C55E', 2: '#F59E0B', 3: '#EF4444' };

const CustomDot = ({ cx, cy, payload }) => {
  const color = RISK_COLORS[payload.risk_numeric] || '#6366F1';
  return (
    <circle cx={cx} cy={cy} r={6} fill={color}
            stroke="white" strokeWidth={2} />
  );
};

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;
  return (
    <div className="bg-white border border-gray-200 rounded-xl
                    p-3 shadow-lg text-sm">
      <p className="font-bold text-gray-800 mb-1">{d.date}</p>
      <p className="font-semibold" style={{
        color: RISK_COLORS[d.risk_numeric]
      }}>
        {d.risk_level?.toUpperCase()}
      </p>
      <p className="text-gray-500 text-xs">
        Confidence: {Math.round(d.confidence * 100)}%
      </p>
      {d.systolic_bp && (
        <p className="text-gray-500 text-xs">SBP: {d.systolic_bp} mmHg</p>
      )}
      {d.blood_sugar && (
        <p className="text-gray-500 text-xs">BS: {d.blood_sugar} mmol/L</p>
      )}
    </div>
  );
};

export default function RiskTrendChart({ assessments, trend }) {
  if (!assessments || assessments.length === 0) {
    return (
      <div className="bg-white rounded-2xl border border-gray-200
                      p-6 text-center">
        <p className="text-4xl mb-2">📊</p>
        <p className="text-gray-500 text-sm">
          No assessments yet. Run the first assessment to begin
          tracking this patient's risk trend.
        </p>
      </div>
    );
  }

  const trendColor = trend === 'escalating' ? '#EF4444'
                   : trend === 'improving'  ? '#22C55E'
                   : '#6366F1';

  const trendLabel = trend === 'escalating' ? '↑ Escalating'
                   : trend === 'improving'  ? '↓ Improving'
                   : trend === 'stable'     ? '→ Stable'
                   : 'Insufficient data';

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-gray-800">Risk Trend</h3>
        <span className="text-sm font-semibold px-3 py-1 rounded-full"
              style={{ color: trendColor,
                       background: trendColor + '18' }}>
          {trendLabel}
        </span>
      </div>

      <ResponsiveContainer width="100%" height={220}>
        <LineChart data={assessments}
                   margin={{ top: 8, right: 16, left: 0, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false}
                         stroke="#F1F5F9" />
          <XAxis dataKey="date" tick={{ fontSize: 11 }}
                 tickFormatter={d => {
                   const date = new Date(d);
                   return `${date.getDate()}/${date.getMonth() + 1}`;
                 }} />
          <YAxis
            domain={[0.5, 3.5]}
            ticks={[1, 2, 3]}
            tickFormatter={v => RISK_LABELS[v] || ''}
            tick={{ fontSize: 10 }}
            width={60}
          />
          <Tooltip content={<CustomTooltip />} />
          <ReferenceLine y={2} stroke="#F59E0B" strokeDasharray="4 4"
                         strokeOpacity={0.5} />
          <ReferenceLine y={3} stroke="#EF4444" strokeDasharray="4 4"
                         strokeOpacity={0.5} />
          <Line
            type="monotone"
            dataKey="risk_numeric"
            stroke="#6366F1"
            strokeWidth={2.5}
            dot={<CustomDot />}
            activeDot={{ r: 8 }}
            name="Risk level"
          />
          <Line
            type="monotone"
            dataKey="confidence"
            stroke="#94A3B8"
            strokeWidth={1.5}
            strokeDasharray="4 4"
            dot={false}
            name="Confidence"
            yAxisId={0}
          />
        </LineChart>
      </ResponsiveContainer>

      <p className="text-xs text-gray-400 mt-2 text-center">
        {assessments.length} assessment{assessments.length !== 1 ? 's' : ''}
        · Dashed line = confidence score
      </p>
    </div>
  );
}
```

### Feature trend table (`FeatureTrendTable.jsx`)

```jsx
const FEATURES = [
  { key: 'systolic_bp',  label: 'Systolic BP',  unit: 'mmHg',   danger: v => v >= 140 },
  { key: 'diastolic_bp', label: 'Diastolic BP', unit: 'mmHg',   danger: v => v >= 90  },
  { key: 'blood_sugar',  label: 'Blood Sugar',  unit: 'mmol/L', danger: v => v >= 11  },
  { key: 'body_temp',    label: 'Body Temp',    unit: '°F',     danger: v => v >= 101 },
  { key: 'heart_rate',   label: 'Heart Rate',   unit: 'bpm',    danger: v => v >= 90  },
];

export default function FeatureTrendTable({ assessments }) {
  if (!assessments || assessments.length < 2) return null;

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <h3 className="font-bold text-gray-800 mb-4">
        Clinical Feature Trends
      </h3>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="text-left text-xs text-gray-500 font-medium
                             pb-2 pr-4">
                Feature
              </th>
              {assessments.map((a, i) => (
                <th key={a.id}
                    className="text-center text-xs text-gray-500
                               font-medium pb-2 px-2">
                  Visit {i + 1}
                  <br />
                  <span className="text-gray-300 font-normal">
                    {a.date}
                  </span>
                </th>
              ))}
              <th className="text-center text-xs text-gray-500
                             font-medium pb-2 px-2">
                Change
              </th>
            </tr>
          </thead>
          <tbody>
            {FEATURES.map(feat => {
              const values = assessments.map(a => a[feat.key]);
              const first  = values[0];
              const last   = values[values.length - 1];
              const change = last !== null && first !== null
                ? (last - first).toFixed(1) : null;
              const isRising = change > 0;
              const isDanger = last !== null && feat.danger(last);

              return (
                <tr key={feat.key}
                    className="border-b border-gray-50 last:border-0">
                  <td className="py-2 pr-4 font-medium text-gray-700
                                 text-xs whitespace-nowrap">
                    {feat.label}
                    <span className="text-gray-400 ml-1">({feat.unit})</span>
                  </td>
                  {assessments.map((a, i) => {
                    const val = a[feat.key];
                    const danger = val !== null && feat.danger(val);
                    return (
                      <td key={i}
                          className="text-center py-2 px-2 text-xs">
                        <span className={`font-medium ${
                          danger ? 'text-red-600' : 'text-gray-800'
                        }`}>
                          {val !== null ? val : '—'}
                        </span>
                      </td>
                    );
                  })}
                  <td className="text-center py-2 px-2">
                    {change !== null ? (
                      <span className={`text-xs font-bold ${
                        isRising
                          ? isDanger ? 'text-red-600' : 'text-amber-600'
                          : 'text-green-600'
                      }`}>
                        {isRising ? '↑' : '↓'} {Math.abs(change)}
                      </span>
                    ) : '—'}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

### Escalation badge (`EscalationBadge.jsx`)

```jsx
const ESCALATION_CONFIG = {
  low_risk_to_mid_risk: {
    bg: 'bg-amber-50', border: 'border-amber-300',
    text: 'text-amber-700', icon: '⚠️',
    label: 'Risk escalated: LOW → MID',
    action: 'Increase visit frequency and monitor closely.',
  },
  mid_risk_to_high_risk: {
    bg: 'bg-red-50', border: 'border-red-300',
    text: 'text-red-700', icon: '🚨',
    label: 'Risk escalated: MID → HIGH',
    action: 'Refer to district hospital immediately.',
  },
  low_risk_to_high_risk: {
    bg: 'bg-red-50', border: 'border-red-400',
    text: 'text-red-800', icon: '🚨',
    label: 'CRITICAL: Risk jumped LOW → HIGH',
    action: 'EMERGENCY REFERRAL required immediately.',
  },
};

export default function EscalationBadge({ escalation, onRefer }) {
  if (!escalation) return null;
  const cfg = ESCALATION_CONFIG[escalation.type];
  if (!cfg) return null;

  return (
    <div className={`rounded-2xl border-2 p-4 ${cfg.bg} ${cfg.border}`}>
      <div className="flex items-start gap-3">
        <span className="text-2xl">{cfg.icon}</span>
        <div className="flex-1">
          <p className={`font-black text-sm ${cfg.text}`}>{cfg.label}</p>
          <p className={`text-xs mt-1 ${cfg.text} opacity-80`}>
            Detected on {escalation.date}
          </p>
          <p className={`text-sm font-medium mt-2 ${cfg.text}`}>
            {cfg.action}
          </p>
        </div>
      </div>
      {(escalation.type === 'mid_risk_to_high_risk' ||
        escalation.type === 'low_risk_to_high_risk') && onRefer && (
        <button
          onClick={onRefer}
          className="mt-3 w-full py-2.5 bg-red-600 hover:bg-red-700
                     text-white font-bold rounded-xl text-sm transition"
        >
          🚨 Emergency Refer Patient
        </button>
      )}
    </div>
  );
}
```

### API client additions

```javascript
// Risk trend
export const getRiskTrend = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/risk-trend`);
  return res.data;
};

export const getRiskSummary = async (patientId) => {
  const res = await client.get(
    `/api/v1/patients/${patientId}/risk-summary`);
  return res.data;
};

export const getPatientEscalations = async (patientId) => {
  const res = await client.get(
    `/api/v1/patients/${patientId}/escalations`);
  return res.data;
};

export const getRecentEscalations = async (days = 7) => {
  const res = await client.get(
    `/api/v1/risk-escalations/recent?days=${days}`);
  return res.data;
};

export const getEscalationAnalytics = async () => {
  const res = await client.get('/api/v1/risk-escalations/analytics');
  return res.data;
};
```

### Integration into patient profile page

On the patient profile page, import and render the three new components
below the patient identity card:

```jsx
import RiskTrendChart    from '../components/RiskTrendChart';
import FeatureTrendTable from '../components/FeatureTrendTable';
import EscalationBadge  from '../components/EscalationBadge';

// Inside PatientProfilePage:
const [trendData, setTrendData] = useState(null);

useEffect(() => {
  if (patientId) {
    getRiskTrend(patientId).then(setTrendData);
  }
}, [patientId]);

// In JSX:
{trendData && (
  <div className="space-y-4 mt-4">
    {trendData.last_escalation && (
      <EscalationBadge
        escalation={trendData.last_escalation}
        onRefer={() => navigate(
          `/refer/${trendData.assessments.at(-1)?.id}`
        )}
      />
    )}
    <RiskTrendChart
      assessments={trendData.assessments}
      trend={trendData.risk_trend}
    />
    <FeatureTrendTable assessments={trendData.assessments} />
  </div>
)}
```

---

## 10. Mobile Frontend Implementation (Expo)

### New screens

```
src/screens/
  RiskTrendScreen.js    ← Full trend view for a patient
```

### Risk trend screen (`RiskTrendScreen.js`)

```jsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, StyleSheet
} from 'react-native';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { getRiskTrend } from '../utils/api';

const RISK_COLORS = {
  'low risk':  COLORS.success,
  'mid risk':  COLORS.warning,
  'high risk': COLORS.danger,
};

const RISK_NUMERIC = { 'low risk': 1, 'mid risk': 2, 'high risk': 3 };

export default function RiskTrendScreen({ route }) {
  const { patientId, patientName } = route.params;
  const [trendData, setTrendData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getRiskTrend(patientId)
      .then(setTrendData)
      .finally(() => setLoading(false));
  }, [patientId]);

  if (loading || !trendData) {
    return (
      <View style={s.center}>
        <Text style={s.loadingText}>Loading trend data...</Text>
      </View>
    );
  }

  const { assessments, risk_trend, last_escalation } = trendData;
  const trendColor = risk_trend === 'escalating' ? COLORS.danger
                   : risk_trend === 'improving'  ? COLORS.success
                   : COLORS.primary;

  return (
    <ScrollView style={s.root} contentContainerStyle={s.scroll}>
      <Text style={s.title}>{patientName}</Text>
      <Text style={s.subtitle}>Risk trend across {assessments.length} assessment(s)</Text>

      {/* Trend indicator */}
      <View style={[s.trendBadge, { backgroundColor: trendColor + '18',
                                    borderColor: trendColor }]}>
        <Text style={[s.trendText, { color: trendColor }]}>
          {risk_trend === 'escalating' ? '↑ Escalating'
           : risk_trend === 'improving' ? '↓ Improving'
           : '→ Stable'}
        </Text>
      </View>

      {/* Escalation alert */}
      {last_escalation && (
        <View style={s.escalationCard}>
          <Text style={s.escalationIcon}>⚠️</Text>
          <View style={s.escalationBody}>
            <Text style={s.escalationTitle}>
              Risk escalated: {last_escalation.from?.toUpperCase()} → {last_escalation.to?.toUpperCase()}
            </Text>
            <Text style={s.escalationDate}>
              Detected {last_escalation.date}
            </Text>
          </View>
        </View>
      )}

      {/* Assessment timeline */}
      <Text style={s.sectionTitle}>Assessment History</Text>
      {assessments.map((a, i) => {
        const color = RISK_COLORS[a.risk_level] || COLORS.primary;
        const prev  = i > 0 ? assessments[i - 1] : null;
        const prevScore = prev ? RISK_NUMERIC[prev.risk_level] : null;
        const currScore = RISK_NUMERIC[a.risk_level];
        const arrow = prevScore
          ? currScore > prevScore ? '↑' : currScore < prevScore ? '↓' : '→'
          : null;

        return (
          <View key={a.id} style={s.assessmentCard}>
            <View style={[s.visitBubble, { backgroundColor: color }]}>
              <Text style={s.visitNum}>{i + 1}</Text>
            </View>
            <View style={s.assessmentInfo}>
              <View style={s.assessmentRow}>
                <Text style={[s.riskLabel, { color }]}>
                  {a.risk_level?.toUpperCase()}
                </Text>
                {arrow && (
                  <Text style={[s.arrow, {
                    color: arrow === '↑' ? COLORS.danger
                           : arrow === '↓' ? COLORS.success
                           : COLORS.textMuted
                  }]}>
                    {arrow}
                  </Text>
                )}
                <Text style={s.confidence}>
                  {Math.round(a.confidence * 100)}%
                </Text>
              </View>
              <Text style={s.visitDate}>{a.date}</Text>
              <View style={s.miniStats}>
                {a.systolic_bp && (
                  <Text style={s.miniStat}>SBP {a.systolic_bp}</Text>
                )}
                {a.blood_sugar && (
                  <Text style={s.miniStat}>BS {a.blood_sugar}</Text>
                )}
              </View>
            </View>
          </View>
        );
      })}

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:             { flex: 1, backgroundColor: COLORS.bg },
  scroll:           { padding: 16 },
  center:           { flex: 1, alignItems: 'center', justifyContent: 'center' },
  loadingText:      { color: COLORS.textMuted, fontSize: FONT.sm },
  title:            { fontSize: FONT.xl, fontWeight: '700', color: COLORS.text },
  subtitle:         { fontSize: FONT.xs, color: COLORS.textMuted, marginBottom: 16 },
  trendBadge:       { alignSelf: 'flex-start', paddingHorizontal: 12, paddingVertical: 6, borderRadius: RADIUS.full, borderWidth: 1, marginBottom: 12 },
  trendText:        { fontSize: FONT.sm, fontWeight: '700' },
  escalationCard:   { backgroundColor: '#FEF3C7', borderRadius: RADIUS.md, padding: 12, flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 16, borderWidth: 1, borderColor: '#F59E0B' },
  escalationIcon:   { fontSize: 20 },
  escalationBody:   { flex: 1 },
  escalationTitle:  { fontSize: FONT.sm, fontWeight: '600', color: '#92400E' },
  escalationDate:   { fontSize: FONT.xs, color: '#B45309', marginTop: 2 },
  sectionTitle:     { fontSize: FONT.md, fontWeight: '600', color: COLORS.text, marginBottom: 10 },
  assessmentCard:   { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 12, flexDirection: 'row', alignItems: 'flex-start', gap: 10, marginBottom: 8 },
  visitBubble:      { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center', flexShrink: 0 },
  visitNum:         { color: '#fff', fontSize: FONT.xs, fontWeight: '700' },
  assessmentInfo:   { flex: 1 },
  assessmentRow:    { flexDirection: 'row', alignItems: 'center', gap: 8 },
  riskLabel:        { fontSize: FONT.sm, fontWeight: '700' },
  arrow:            { fontSize: FONT.md, fontWeight: '700' },
  confidence:       { fontSize: FONT.xs, color: COLORS.textMuted },
  visitDate:        { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  miniStats:        { flexDirection: 'row', gap: 10, marginTop: 4 },
  miniStat:         { fontSize: FONT.xs, color: COLORS.textDim },
});
```

---

## 11. WhatsApp Risk Escalation Alerts

All escalation alert templates live in `utils/risk_tracking.py` inside
`ESCALATION_MESSAGES_FR` and `ESCALATION_MESSAGES_EN` dictionaries.

### Alert triggering rules

| Escalation type | Message urgency | CHW action recommended |
|----------------|-----------------|----------------------|
| `low_to_mid` | Warning ⚠️ | Increase visit frequency |
| `mid_to_high` | Alert 🚨 | Refer to district hospital |
| `low_to_high` | Critical 🚨 | Emergency referral immediately |

### No alert for improvements

Downward risk transitions (high→mid, mid→low, high→low) do not trigger
alerts. They are silently recorded in the `risk_escalation_events` table
as reference data. The CHW sees them in the trend chart as a visual signal
that treatment is working.

### Alert deduplication

If multiple assessments are submitted in quick succession and all show
escalation, only the first triggers a WhatsApp alert. This is enforced
by checking whether an escalation event for this patient already exists
today before sending:

```python
# In check_and_handle_escalation, before sending WhatsApp:
today = str(date.today())
already_alerted_today = (
    db.query(RiskEscalationEvent)
      .filter(
          RiskEscalationEvent.patient_id == patient_id,
          RiskEscalationEvent.whatsapp_sent == True,
          RiskEscalationEvent.created_at >= today
      )
      .first()
)
if already_alerted_today:
    logger.info(f"CHW already alerted for patient {patient_id} today "
                f"— skipping duplicate")
    return event
```

---

## 12. Testing Guide

### Postman test sequence

```
1.  POST /api/v1/predict  (patient_id=1, low-risk values)
    → First assessment, no comparison, no escalation

2.  POST /api/v1/predict  (patient_id=1, mid-risk values)
    → escalation_detected: true, escalation_type: low_to_mid

3.  GET  /api/v1/patients/1/risk-trend
    → 2 assessments, risk_trend: "escalating"

4.  GET  /api/v1/patients/1/risk-summary
    → current: "mid risk", previous: "low risk", trend: "escalating"

5.  GET  /api/v1/patients/1/escalations
    → 1 event: low_risk_to_mid_risk

6.  POST /api/v1/predict  (patient_id=1, high-risk values)
    → escalation_detected: true, escalation_type: mid_to_high
    → WhatsApp alert sent to CHW

7.  GET  /api/v1/patients/1/risk-trend
    → 3 assessments, risk_trend: "escalating",
      last_escalation: {from: mid, to: high}

8.  POST /api/v1/predict  (patient_id=1, low-risk values again)
    → escalation_detected: false  (improvement, not escalation)

9.  GET  /api/v1/patients/1/risk-trend
    → 4 assessments, risk_trend: "improving"

10. GET  /api/v1/risk-escalations/analytics
    → total: 2, low_to_mid: 1, mid_to_high: 1
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| LRT-01 | First assessment for patient — no previous data | `escalation_detected: false`, no escalation event created |
| LRT-02 | Second assessment with same risk level | `escalation_detected: false` |
| LRT-03 | Assessment with higher risk than previous | `escalation_detected: true`, escalation event logged |
| LRT-04 | Low → high risk jump | `escalation_type: low_risk_to_high_risk`, urgent WhatsApp sent |
| LRT-05 | Risk improves (high → mid) | `escalation_detected: false`, no WhatsApp sent |
| LRT-06 | Risk trend endpoint with 1 assessment | `risk_trend: insufficient_data` |
| LRT-07 | Risk trend endpoint with 3 escalating assessments | `risk_trend: escalating` |
| LRT-08 | Risk trend endpoint with 3 improving assessments | `risk_trend: improving` |
| LRT-09 | Feature trends returned correctly | `feature_trends.systolic_bp` array matches assessment values |
| LRT-10 | Risk summary lightweight endpoint | Correct `current_risk_level` and `previous_risk_level` |
| LRT-11 | Escalation analytics after 2 events | `total: 2`, correct type counts |
| LRT-12 | Duplicate escalation same day | Second WhatsApp not sent, only one event logged |

---

## 13. Report Integration

### Section 1.2 — Statement of the Problem (add bullet)

> Existing antenatal risk assessment tools produce point-in-time
> classifications that are immediately discarded after the visit —
> no mechanism exists to compare risk across visits, detect gradual
> deterioration, or alert CHWs when a patient's clinical trajectory
> is worsening. A patient transitioning from low to high risk across
> three visits may not appear alarming on any single assessment
> read in isolation.

### Section 1.4 — Research Objectives (add Specific Objective 9)

> To implement a longitudinal risk tracking module that aggregates
> assessment data across antenatal visits, detects risk escalation
> events automatically, visualises risk and clinical feature trends
> on the patient profile, and delivers immediate WhatsApp escalation
> alerts to community health workers.

### Section 3.6 — Model Specification

Add `RiskEscalationEvent` to the data model table. Add all risk trend
endpoints to Table 3.2.

### Section 4.2.5 — Extended System Discussion

> The longitudinal risk tracking module fundamentally changes the
> nature of MamaSafe's clinical contribution. In isolation, each
> assessment answers the question: "what is this patient's risk level
> right now?" Longitudinal tracking answers the more clinically
> relevant question: "is this patient getting better or worse?"
> The automated escalation detection converts passive data into an
> active safety net — the system does not wait for a CHW to notice
> a trend; it detects deterioration and alerts the responsible CHW
> immediately. The feature trend table extends this by showing the
> CHW not just that risk has increased, but precisely which clinical
> indicator is driving the increase — enabling targeted clinical
> intervention rather than generalised heightened surveillance.

### Section 5.4 — Limitations (add)

> The longitudinal risk tracking module depends on consistent
> patient identification across visits — assessments are linked
> to patients via `patient_id`. If a CHW submits an assessment
> without linking it to a patient record (using the standalone
> assessment form rather than the patient profile flow), that
> assessment does not contribute to the longitudinal trend.
> Training CHWs to always initiate assessments from the patient
> profile is therefore a deployment priority.

---

## 14. Future Extensions

| Feature | Description | Effort |
|---------|-------------|--------|
| Trend-based ML model | Train a secondary model on sequences of assessments (not just single visits) — RNN or LSTM on the time series of risk scores and feature values | High |
| Gestational-age normalised trends | Adjust expected feature ranges by gestational week — a BP of 130 at 36 weeks has different clinical significance than at 8 weeks | Medium |
| Population trend dashboard | District-level heatmap showing which areas have the highest proportion of escalating patients — for health system resource allocation | Medium |
| Trend-based referral auto-suggestion | Automatically suggest emergency referral when 2+ consecutive assessments show escalation, without waiting for a single high-risk result | Low |
| CHW alert digest | Instead of immediate per-patient alerts, send the CHW a daily digest of all patients who escalated in the last 24 hours — reduces alert fatigue | Low |

---

*End of document.*

**MamaSafe Longitudinal Risk Tracking Documentation v1.0**  
*Prepared for the MamaSafe Final Year Project — YIBS Software Engineering*
