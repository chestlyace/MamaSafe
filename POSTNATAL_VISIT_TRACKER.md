# MamaSafe — Postnatal Visit Tracker
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Postnatal Visit Tracker  
**Stack:** FastAPI · PostgreSQL · Baileys WhatsApp · React · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Clinical Context — The 3 WHO Postnatal Contacts](#2-clinical-context--the-3-who-postnatal-contacts)
3. [System Architecture](#3-system-architecture)
4. [How It Works](#4-how-it-works)
5. [Data Model](#5-data-model)
6. [PHQ-2 Mental Health Screening](#6-phq2-mental-health-screening)
7. [API Reference](#7-api-reference)
8. [Backend Implementation](#8-backend-implementation)
9. [Web Frontend Implementation](#9-web-frontend-implementation)
10. [Mobile Frontend Implementation (Expo)](#10-mobile-frontend-implementation-expo)
11. [WhatsApp Notifications](#11-whatsapp-notifications)
12. [Testing Guide](#12-testing-guide)
13. [Report Integration](#13-report-integration)
14. [Future Extensions](#14-future-extensions)

---

## 1. Overview and Purpose

The MamaSafe Postnatal Visit Tracker closes the final gap in the
maternal health care cycle. Every other MamaSafe module — risk
prediction, ANC scheduling, emergency referral, longitudinal
tracking — covers the period from first antenatal visit through
delivery. But the most dangerous period for both mother and newborn
is the 48 hours immediately after birth, and the six weeks that
follow. Without a structured postnatal tracking system, women
effectively disappear from the health system the moment they leave
the delivery facility.

The postnatal tracker does four things:

**1. Registers delivery outcomes** — When a pregnancy reaches its
end, the CHW records the delivery: date, location, mode (normal,
C-section, instrumental), outcome (live birth, stillbirth,
miscarriage), and the newborn's initial condition. This closes the
pregnancy record and opens the postnatal period.

**2. Schedules and tracks 3 WHO postnatal contacts** — The system
auto-schedules the three WHO-recommended postnatal visits (24 hours,
1 week, 6 weeks after delivery) and sends WhatsApp reminders to
the mother for each.

**3. Records mother and newborn status at each visit** — At every
postnatal visit the CHW records maternal indicators (blood pressure,
bleeding, wound healing) and newborn indicators (weight, feeding,
jaundice, breathing) in a structured digital form that replaces
paper records.

**4. Screens for postnatal depression** — The PHQ-2 mental health
screening tool is embedded in every postnatal visit form. If the
score reaches the clinical threshold, the CHW receives an immediate
alert and a referral prompt.

**What this replaces:** In Cameroon's current system, postnatal
follow-up is largely informal — the CHW may call the mother or
the mother may return to the clinic, but there is no structured
schedule, no digital record, and no mental health screening. Women
with postnatal complications go undetected until they present as
emergencies.

---

## 2. Clinical Context — The 3 WHO Postnatal Contacts

The WHO 2022 postnatal care guidelines recommend a minimum of
four postnatal contacts, with the most critical being within the
first 24 hours. For MamaSafe's context — community health worker
delivery — three contacts are implemented: 24 hours, 1 week, and
6 weeks.

### Postnatal contact schedule

| Contact | Timing | Key maternal checks | Key newborn checks |
|---------|--------|--------------------|--------------------|
| PNC 1 | 24 hours after delivery | Bleeding, BP, uterine involution, pain, wound site | Breathing, temperature, feeding initiated, cord |
| PNC 2 | 1 week (day 7) | Wound healing, BP, anaemia signs, feeding support | Weight, jaundice, cord healing, feeding pattern |
| PNC 3 | 6 weeks | BP, family planning, depression screen (PHQ-2), contraception | Weight-for-age, immunisation, feeding, development |

### Why the 24-hour visit is critical

Approximately 60% of maternal deaths from haemorrhage occur in
the first 24 hours after delivery. Uterine atony — failure of the
uterus to contract after delivery — is the leading cause and is
detectable by a CHW through fundal palpation and bleeding assessment.
The 24-hour postnatal visit is the single highest-value clinical
intervention in the postnatal period.

### Postnatal depression in Cameroon

Postnatal depression (PND) affects approximately 15-20% of women
globally and up to 35% in low-income countries according to WHO
estimates. It is almost entirely unrecognised in Cameroon due to
the absence of systematic screening. The PHQ-2, a validated
two-question screening tool, takes under 60 seconds to administer
and has a sensitivity of 83% for detecting major depression.
Including it in the 6-week postnatal visit costs nothing in
additional infrastructure but dramatically extends MamaSafe's
clinical reach into mental health.

---

## 3. System Architecture

### Component overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      MamaSafe Platform                          │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────────────────────────┐  │
│  │  React Web   │───▶│          FastAPI Backend             │  │
│  │  Expo Mobile │    │                                      │  │
│  └──────────────┘    │  /api/v1/deliveries                  │  │
│                      │  /api/v1/postnatal-visits            │  │
│                      │  /api/v1/postnatal-schedule          │  │
│                      │  /api/v1/mental-health               │  │
│                      │                                      │  │
│                      │  ┌─────────────────────────────┐    │  │
│                      │  │      APScheduler            │    │  │
│                      │  │  PNC reminder jobs          │    │  │
│                      │  │  (reuses scheduler from     │    │  │
│                      │  │   ANC visit module)         │    │  │
│                      │  └──────────┬──────────────────┘    │  │
│                      └────────────┼───────────────────────────┘  │
└───────────────────────────────────┼─────────────────────────────┘
                                    │ WhatsApp via Baileys
                         ┌──────────▼──────────┐
                         │  Patient's Phone    │
                         │  CHW's Phone        │
                         └─────────────────────┘
```

### Relationship to existing modules

The postnatal tracker sits at the end of the care chain and connects
to three existing modules:

- **ANC card** — the `Pregnancy` record is the entry point. Delivery
  is recorded against a pregnancy, which then closes the ANC period
  and opens the postnatal period.
- **Longitudinal risk tracking** — the last antenatal risk assessment
  is displayed on the postnatal profile as context for the CHW.
- **Referral system** — if postnatal complications or PHQ-2 scores
  indicate urgent need, the referral module is triggered directly
  from the postnatal visit screen.

---

## 4. How It Works

### Step 1 — CHW records delivery

When a patient delivers, the CHW opens the patient profile in
MamaSafe and taps **Record Delivery**. The delivery form captures:

- Delivery date and time
- Delivery location (home, health post, district hospital)
- Delivery mode: normal vaginal, assisted vaginal, caesarean
- Delivery outcome: live birth, stillbirth, miscarriage
- Newborn sex and birth weight
- Apgar score if available
- Any immediate complications

Submitting the delivery form:
1. Creates a `Delivery` record linked to the pregnancy
2. Sets `Pregnancy.is_active = false`
3. Creates `NewbornRecord` for the baby
4. Auto-schedules 3 `PostnatalScheduledVisit` records
5. Sends a WhatsApp congratulations and first PNC reminder to mother

### Step 2 — Auto-scheduled PNC visits

Three postnatal scheduled visits are created automatically:

```
PNC 1 date = delivery_date + 1 day
PNC 2 date = delivery_date + 7 days
PNC 3 date = delivery_date + 42 days
```

Each visit has its own reminder workflow using the existing
APScheduler infrastructure from the ANC visit module.

### Step 3 — CHW records postnatal visit

At each PNC visit, the CHW opens the postnatal visit form and records
maternal and newborn status. The form is structured by visit number
— PNC 1 shows the bleeding and uterine assessment fields prominently,
PNC 3 shows the PHQ-2 depression screening and family planning fields.

### Step 4 — PHQ-2 screening at PNC 3

At the 6-week visit, two PHQ-2 questions are embedded in the form:

1. Over the past 2 weeks, how often have you felt little interest
   or pleasure in doing things?
2. Over the past 2 weeks, how often have you felt down, depressed,
   or hopeless?

Each scored 0–3 (Not at all / Several days / More than half the days /
Nearly every day). Total score ≥ 3 triggers an alert.

### Step 5 — Alert if PHQ-2 positive

If PHQ-2 score ≥ 3, the system:
1. Flags the postnatal visit record
2. Sends immediate WhatsApp to the CHW with patient name and score
3. Displays a referral prompt on the visit result screen
4. Records the event in `MentalHealthScreening` table

### Step 6 — Newborn growth tracking

At PNC 2 and PNC 3, newborn weight is recorded. The system
calculates weight gain since the previous visit and flags:
- Weight loss > 10% from birth weight at PNC 2 → alert
- Weight below the 3rd percentile for age → alert
- Failure to regain birth weight by day 14 → alert

The infant growth tracker module (v2 feature rank 6) extends this
with WHO growth curves — but the weight recording and basic alerting
is included here as part of the postnatal tracker.

---

## 5. Data Model

### New tables

```
deliveries
  │ id
  │ pregnancy_id → pregnancies.id
  │ patient_id → patients.id
  │ chw_id → users.id
  │ delivery_date
  │ delivery_time
  │ delivery_location
  │ delivery_mode: normal | assisted | caesarean
  │ outcome: live_birth | stillbirth | miscarriage
  │ complications
  │ notes
  │ created_at
  └── newborn (1:1)

newborns
  │ id
  │ delivery_id → deliveries.id
  │ patient_id → patients.id (mother)
  │ sex: male | female | unknown
  │ birth_weight_kg
  │ apgar_1min
  │ apgar_5min
  │ cord_condition: normal | infected | dry
  │ breathing_normal
  │ breastfeeding_initiated
  │ notes
  │ created_at
  └── postnatal_visits (via newborn_id)

postnatal_scheduled_visits
  │ id
  │ delivery_id → deliveries.id
  │ patient_id → patients.id
  │ visit_number: 1 | 2 | 3
  │ scheduled_date
  │ status: scheduled | completed | missed | cancelled
  │ postnatal_visit_id → postnatal_visits.id
  │ reminder_sent
  │ created_at

postnatal_visits
  │ id
  │ delivery_id → deliveries.id
  │ patient_id → patients.id
  │ newborn_id → newborns.id
  │ scheduled_visit_id → postnatal_scheduled_visits.id
  │ visit_number: 1 | 2 | 3
  │ visit_date
  │ ── MATERNAL ──
  │ maternal_bp_systolic
  │ maternal_bp_diastolic
  │ maternal_temp
  │ bleeding_status: none | light | moderate | heavy
  │ uterine_involution: normal | subinvolution
  │ wound_healing: healing | infected | dehisced
  │ anaemia_signs
  │ breastfeeding_status: exclusive | mixed | none
  │ family_planning_counselled
  │ family_planning_method_chosen
  │ ── NEWBORN ──
  │ newborn_weight_kg
  │ weight_gain_status: gaining | static | losing
  │ jaundice: none | mild | severe
  │ cord_status: normal | dry | infected
  │ breathing_normal
  │ feeding_well
  │ immunisation_given
  │ ── MENTAL HEALTH ──
  │ phq2_q1: 0-3
  │ phq2_q2: 0-3
  │ phq2_score: 0-6
  │ phq2_positive (score >= 3)
  │ mental_health_referral_made
  │ ── META ──
  │ chw_id → users.id
  │ notes
  │ created_at
  └── mental_health_screening (1:0..1)

mental_health_screenings
  │ id
  │ postnatal_visit_id → postnatal_visits.id
  │ patient_id → patients.id
  │ phq2_score
  │ phq2_positive
  │ action_taken: none | counselled | referred
  │ referral_id → referrals.id
  │ whatsapp_alert_sent
  │ chw_id → users.id
  │ created_at
```

### Add to `database.py`

```python
class Delivery(Base):
    __tablename__ = "deliveries"

    id                  = Column(Integer, primary_key=True, index=True)
    pregnancy_id        = Column(Integer, ForeignKey("pregnancies.id"),
                                 nullable=False)
    patient_id          = Column(Integer, ForeignKey("patients.id"),
                                 nullable=False)
    chw_id              = Column(Integer, ForeignKey("users.id"),
                                 nullable=True)
    delivery_date       = Column(String, nullable=False)  # YYYY-MM-DD
    delivery_time       = Column(String, nullable=True)   # HH:MM
    delivery_location   = Column(String, nullable=True)
    # home | health_post | district_hospital | regional_hospital | other
    delivery_mode       = Column(String, nullable=False, default="normal")
    # normal | assisted | caesarean
    outcome             = Column(String, nullable=False, default="live_birth")
    # live_birth | stillbirth | miscarriage
    complications       = Column(String, nullable=True)
    notes               = Column(String, nullable=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    pregnancy           = relationship("Pregnancy")
    patient             = relationship("Patient")
    newborn             = relationship("Newborn", back_populates="delivery",
                                       uselist=False)
    postnatal_scheduled_visits = relationship(
        "PostnatalScheduledVisit",
        back_populates="delivery",
        cascade="all, delete-orphan"
    )
    postnatal_visits    = relationship("PostnatalVisit",
                                       back_populates="delivery",
                                       cascade="all, delete-orphan")


class Newborn(Base):
    __tablename__ = "newborns"

    id                       = Column(Integer, primary_key=True, index=True)
    delivery_id              = Column(Integer, ForeignKey("deliveries.id"),
                                      nullable=False)
    patient_id               = Column(Integer, ForeignKey("patients.id"),
                                      nullable=False)
    sex                      = Column(String, nullable=True)
    # male | female | unknown
    birth_weight_kg          = Column(Float, nullable=True)
    apgar_1min               = Column(Integer, nullable=True)
    apgar_5min               = Column(Integer, nullable=True)
    cord_condition           = Column(String, default="normal")
    # normal | infected | dry
    breathing_normal         = Column(Boolean, default=True)
    breastfeeding_initiated  = Column(Boolean, default=False)
    notes                    = Column(String, nullable=True)
    created_at               = Column(DateTime, default=datetime.utcnow)

    delivery                 = relationship("Delivery",
                                            back_populates="newborn")
    postnatal_visits         = relationship("PostnatalVisit",
                                            back_populates="newborn")


class PostnatalScheduledVisit(Base):
    __tablename__ = "postnatal_scheduled_visits"

    id                  = Column(Integer, primary_key=True, index=True)
    delivery_id         = Column(Integer, ForeignKey("deliveries.id"),
                                 nullable=False)
    patient_id          = Column(Integer, ForeignKey("patients.id"),
                                 nullable=False)
    visit_number        = Column(Integer, nullable=False)  # 1, 2, 3
    scheduled_date      = Column(String, nullable=False)   # YYYY-MM-DD
    status              = Column(String, default="scheduled")
    # scheduled | completed | missed | cancelled
    postnatal_visit_id  = Column(Integer, ForeignKey("postnatal_visits.id"),
                                 nullable=True)
    reminder_sent       = Column(Boolean, default=False)
    reminder_sent_at    = Column(DateTime, nullable=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    delivery            = relationship("Delivery",
                                       back_populates="postnatal_scheduled_visits")
    patient             = relationship("Patient")


class PostnatalVisit(Base):
    __tablename__ = "postnatal_visits"

    id                          = Column(Integer, primary_key=True, index=True)
    delivery_id                 = Column(Integer, ForeignKey("deliveries.id"),
                                         nullable=False)
    patient_id                  = Column(Integer, ForeignKey("patients.id"),
                                         nullable=False)
    newborn_id                  = Column(Integer, ForeignKey("newborns.id"),
                                         nullable=True)
    scheduled_visit_id          = Column(Integer,
                                         ForeignKey("postnatal_scheduled_visits.id"),
                                         nullable=True)
    chw_id                      = Column(Integer, ForeignKey("users.id"),
                                         nullable=True)
    visit_number                = Column(Integer, nullable=False)
    visit_date                  = Column(String, nullable=False)

    # ── MATERNAL ─────────────────────────────────────────
    maternal_bp_systolic        = Column(Float, nullable=True)
    maternal_bp_diastolic       = Column(Float, nullable=True)
    maternal_temp               = Column(Float, nullable=True)
    bleeding_status             = Column(String, nullable=True)
    # none | light | moderate | heavy
    uterine_involution          = Column(String, nullable=True)
    # normal | subinvolution
    wound_healing               = Column(String, nullable=True)
    # healing | infected | dehisced
    anaemia_signs               = Column(Boolean, default=False)
    breastfeeding_status        = Column(String, nullable=True)
    # exclusive | mixed | none
    family_planning_counselled  = Column(Boolean, default=False)
    family_planning_method      = Column(String, nullable=True)

    # ── NEWBORN ──────────────────────────────────────────
    newborn_weight_kg           = Column(Float, nullable=True)
    weight_gain_status          = Column(String, nullable=True)
    # gaining | static | losing
    jaundice                    = Column(String, nullable=True)
    # none | mild | severe
    cord_status                 = Column(String, nullable=True)
    # normal | dry | infected
    newborn_breathing_normal    = Column(Boolean, default=True)
    feeding_well                = Column(Boolean, default=True)
    immunisation_given          = Column(Boolean, default=False)

    # ── MENTAL HEALTH (PHQ-2) ────────────────────────────
    phq2_q1                     = Column(Integer, nullable=True)  # 0-3
    phq2_q2                     = Column(Integer, nullable=True)  # 0-3
    phq2_score                  = Column(Integer, nullable=True)  # 0-6
    phq2_positive               = Column(Boolean, default=False)
    mental_health_referral_made = Column(Boolean, default=False)

    notes                       = Column(String, nullable=True)
    created_at                  = Column(DateTime, default=datetime.utcnow)

    delivery                    = relationship("Delivery",
                                               back_populates="postnatal_visits")
    patient                     = relationship("Patient")
    newborn                     = relationship("Newborn",
                                               back_populates="postnatal_visits")
    mental_health_screening     = relationship("MentalHealthScreening",
                                               back_populates="postnatal_visit",
                                               uselist=False)


class MentalHealthScreening(Base):
    __tablename__ = "mental_health_screenings"

    id                   = Column(Integer, primary_key=True, index=True)
    postnatal_visit_id   = Column(Integer,
                                  ForeignKey("postnatal_visits.id"),
                                  nullable=False)
    patient_id           = Column(Integer, ForeignKey("patients.id"),
                                  nullable=False)
    phq2_score           = Column(Integer, nullable=False)
    phq2_positive        = Column(Boolean, nullable=False)
    action_taken         = Column(String, default="none")
    # none | counselled | referred
    referral_id          = Column(Integer, ForeignKey("referrals.id"),
                                  nullable=True)
    whatsapp_alert_sent  = Column(Boolean, default=False)
    chw_id               = Column(Integer, ForeignKey("users.id"),
                                  nullable=True)
    created_at           = Column(DateTime, default=datetime.utcnow)

    postnatal_visit      = relationship("PostnatalVisit",
                                        back_populates="mental_health_screening")
    patient              = relationship("Patient")
```

Run migration after adding all models:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('All postnatal tables created')
"
```

Verify:

```bash
python -c "
from sqlalchemy import inspect
from app.database import engine
tables = inspect(engine).get_table_names()
pnc_tables = [t for t in tables if 'postnatal' in t or
              'deliver' in t or 'newborn' in t or 'mental' in t]
print('PNC tables:', pnc_tables)
"
```

Expected output:
```
PNC tables: ['deliveries', 'newborns', 'postnatal_scheduled_visits',
             'postnatal_visits', 'mental_health_screenings']
```

---

## 6. PHQ-2 Mental Health Screening

### What is the PHQ-2

The Patient Health Questionnaire-2 (PHQ-2) is a validated two-item
depression screening tool derived from the full PHQ-9. It asks about
the two core symptoms of depression — anhedonia and depressed mood —
over the past two weeks.

### The two questions

Both questions must be asked and scored identically:

**Question 1 (Anhedonia):**
Over the past 2 weeks, how often have you had little interest or
pleasure in doing things?

**Question 2 (Depressed mood):**
Over the past 2 weeks, how often have you felt down, depressed,
or hopeless?

### Scoring

| Response | Score |
|----------|-------|
| Not at all | 0 |
| Several days | 1 |
| More than half the days | 2 |
| Nearly every day | 3 |

**Total score = Q1 + Q2 (range 0–6)**

**Threshold: Score ≥ 3 = positive screen** — requires follow-up.
The PHQ-2 at this threshold has sensitivity of 83% and specificity
of 90% for major depressive disorder (Kroenke et al., 2003).

### French translations for CHW use

**Question 1:**
Au cours des 2 dernières semaines, à quelle fréquence avez-vous
ressenti peu d'intérêt ou de plaisir à faire les choses ?

**Question 2:**
Au cours des 2 dernières semaines, à quelle fréquence vous êtes-vous
sentie triste, déprimée ou sans espoir ?

**Response options (FR):**
- Jamais (0)
- Plusieurs jours (1)
- Plus de la moitié des jours (2)
- Presque tous les jours (3)

### What happens when PHQ-2 is positive

1. `postnatal_visits.phq2_positive` set to `true`
2. `MentalHealthScreening` record created
3. WhatsApp alert sent to CHW immediately
4. CHW sees a referral prompt on the visit result screen
5. CHW selects action: counselled in place, referred for mental health
   support, or no action taken
6. If referred: creates a referral record linked to the mental health
   screening

### PHQ-2 scoring function

```python
def calculate_phq2(q1: int, q2: int) -> dict:
    """
    Calculate PHQ-2 score and determine clinical action.
    q1, q2 must be integers 0-3.
    """
    if not (0 <= q1 <= 3 and 0 <= q2 <= 3):
        raise ValueError("PHQ-2 responses must be 0-3")

    score    = q1 + q2
    positive = score >= 3

    if score <= 2:
        level = "low"
        action = "No immediate action required. Continue routine support."
    elif score <= 4:
        level = "moderate"
        action = ("Positive PHQ-2 screen. Counsel patient and schedule "
                  "follow-up in 2 weeks.")
    else:
        level = "high"
        action = ("High PHQ-2 score. Refer to mental health services "
                  "or district hospital counsellor immediately.")

    return {
        "q1":       q1,
        "q2":       q2,
        "score":    score,
        "positive": positive,
        "level":    level,
        "action":   action,
    }
```

---

## 7. API Reference

### Base URL
```
http://localhost:8000/api/v1
```

All endpoints require JWT authentication.

---

### Deliveries

#### `POST /deliveries`
Record a delivery. Automatically creates newborn record and schedules
3 postnatal visits.

**Request body:**
```json
{
  "pregnancy_id":      1,
  "patient_id":        1,
  "delivery_date":     "2025-10-17",
  "delivery_time":     "14:32",
  "delivery_location": "district_hospital",
  "delivery_mode":     "caesarean",
  "outcome":           "live_birth",
  "complications":     "Mild postpartum haemorrhage, managed with oxytocin",
  "notes":             "Healthy mother and baby at discharge",
  "newborn": {
    "sex":                      "female",
    "birth_weight_kg":          3.1,
    "apgar_1min":               8,
    "apgar_5min":               9,
    "cord_condition":           "normal",
    "breathing_normal":         true,
    "breastfeeding_initiated":  true
  }
}
```

**Response:** Full delivery object with newborn and 3 scheduled PNC
visit dates.

**Side effects:**
- Creates `Delivery` record
- Creates `Newborn` record
- Sets `Pregnancy.is_active = false`
- Creates 3 `PostnatalScheduledVisit` records
- Sends congratulations + PNC 1 reminder WhatsApp to patient

---

#### `GET /deliveries/{delivery_id}`
Get a delivery record with newborn and scheduled visits.

---

#### `GET /patients/{patient_id}/deliveries`
Get all delivery records for a patient.

---

### Postnatal Visits

#### `POST /postnatal-visits`
Record a postnatal visit. If PHQ-2 data is included, automatically
calculates score and triggers alert if positive.

**Request body:**
```json
{
  "delivery_id":              1,
  "patient_id":               1,
  "newborn_id":               1,
  "scheduled_visit_id":       1,
  "visit_number":             1,
  "visit_date":               "2025-10-18",
  "maternal_bp_systolic":     110,
  "maternal_bp_diastolic":    70,
  "maternal_temp":            98.2,
  "bleeding_status":          "light",
  "uterine_involution":       "normal",
  "wound_healing":            "healing",
  "anaemia_signs":            false,
  "breastfeeding_status":     "exclusive",
  "newborn_weight_kg":        3.1,
  "jaundice":                 "none",
  "cord_status":              "normal",
  "newborn_breathing_normal": true,
  "feeding_well":             true,
  "immunisation_given":       false,
  "notes":                    "Mother doing well. Baby feeding well."
}
```

**Request body for PNC 3 (includes PHQ-2):**
```json
{
  "delivery_id":                1,
  "patient_id":                 1,
  "newborn_id":                 1,
  "scheduled_visit_id":         3,
  "visit_number":               3,
  "visit_date":                 "2025-11-28",
  "maternal_bp_systolic":       118,
  "maternal_bp_diastolic":      75,
  "breastfeeding_status":       "exclusive",
  "family_planning_counselled": true,
  "family_planning_method":     "injectable",
  "newborn_weight_kg":          4.8,
  "feeding_well":               true,
  "immunisation_given":         true,
  "phq2_q1":                    2,
  "phq2_q2":                    2,
  "notes":                      "Mother reports feeling exhausted and low mood."
}
```

**Response:** Full `PostnatalVisitOut` with PHQ-2 result if applicable.

**Side effects:**
- Creates `PostnatalVisit` record
- Updates linked `PostnatalScheduledVisit.status = "completed"`
- If PHQ-2 score ≥ 3: creates `MentalHealthScreening`, sends WhatsApp to CHW

---

#### `GET /postnatal-visits/{visit_id}`
Get a single postnatal visit record.

---

#### `GET /deliveries/{delivery_id}/postnatal-visits`
Get all postnatal visits for a delivery, ordered by visit number.

---

#### `GET /postnatal-schedule/{delivery_id}`
Get the 3-visit postnatal schedule for a delivery with completion status.

**Response:**
```json
[
  {
    "id":             1,
    "visit_number":   1,
    "label":          "24-hour check",
    "scheduled_date": "2025-10-18",
    "status":         "completed",
    "postnatal_visit_id": 1
  },
  {
    "id":             2,
    "visit_number":   2,
    "label":          "1-week check",
    "scheduled_date": "2025-10-24",
    "status":         "scheduled",
    "postnatal_visit_id": null
  },
  {
    "id":             3,
    "visit_number":   3,
    "label":          "6-week check",
    "scheduled_date": "2025-11-28",
    "status":         "scheduled",
    "postnatal_visit_id": null
  }
]
```

---

### Mental Health

#### `GET /mental-health/screenings`
Get all PHQ-2 screenings for the CHW's patients.

**Query params:**
- `positive_only` (bool, default false) — filter to positive screens
- `days` (int, default 30) — lookback window

---

#### `PATCH /mental-health/screenings/{screening_id}/action`
Record action taken after a positive PHQ-2.

**Request body:**
```json
{
  "action_taken": "referred",
  "referral_id":  5
}
```

---

#### `GET /postnatal-visits/analytics/summary`
Summary statistics for postnatal care.

**Response:**
```json
{
  "total_deliveries":           12,
  "live_births":                11,
  "pnc1_completion_rate":       91.7,
  "pnc2_completion_rate":       75.0,
  "pnc3_completion_rate":       58.3,
  "phq2_screens_performed":     7,
  "phq2_positive_count":        2,
  "phq2_positive_rate":         28.6,
  "exclusive_breastfeeding_rate": 72.7,
  "newborn_weight_alerts":      1
}
```

---

## 8. Backend Implementation

### File structure additions

```
backend/
  app/
    database.py              ← Add 5 new models
    schemas_postnatal.py     ← Pydantic schemas
    utils/
      postnatal_jobs.py      ← PNC reminder scheduler jobs
      whatsapp.py            ← Add postnatal message templates
    routers/
      postnatal.py           ← All postnatal endpoints
    main.py                  ← Register postnatal router + jobs
```

### Step 1 — Schemas (`schemas_postnatal.py`)

```python
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class NewbornCreate(BaseModel):
    sex:                     Optional[str]   = None
    birth_weight_kg:         Optional[float] = None
    apgar_1min:              Optional[int]   = None
    apgar_5min:              Optional[int]   = None
    cord_condition:          str             = "normal"
    breathing_normal:        bool            = True
    breastfeeding_initiated: bool            = False
    notes:                   Optional[str]   = None


class NewbornOut(NewbornCreate):
    id:          int
    delivery_id: int
    patient_id:  int
    created_at:  datetime
    class Config:
        from_attributes = True


class DeliveryCreate(BaseModel):
    pregnancy_id:      int
    patient_id:        int
    delivery_date:     str
    delivery_time:     Optional[str]  = None
    delivery_location: Optional[str]  = None
    delivery_mode:     str            = "normal"
    outcome:           str            = "live_birth"
    complications:     Optional[str]  = None
    notes:             Optional[str]  = None
    newborn:           Optional[NewbornCreate] = None


class PostnatalScheduledVisitOut(BaseModel):
    id:                  int
    visit_number:        int
    label:               str
    scheduled_date:      str
    status:              str
    postnatal_visit_id:  Optional[int]
    reminder_sent:       bool
    created_at:          datetime
    class Config:
        from_attributes = True


class DeliveryOut(BaseModel):
    id:                int
    pregnancy_id:      int
    patient_id:        int
    chw_id:            Optional[int]
    delivery_date:     str
    delivery_time:     Optional[str]
    delivery_location: Optional[str]
    delivery_mode:     str
    outcome:           str
    complications:     Optional[str]
    notes:             Optional[str]
    created_at:        datetime
    newborn:           Optional[NewbornOut]
    postnatal_scheduled_visits: List[PostnatalScheduledVisitOut] = []
    class Config:
        from_attributes = True


class PostnatalVisitCreate(BaseModel):
    delivery_id:                int
    patient_id:                 int
    newborn_id:                 Optional[int]   = None
    scheduled_visit_id:         Optional[int]   = None
    visit_number:               int = Field(..., ge=1, le=3)
    visit_date:                 str

    # Maternal
    maternal_bp_systolic:       Optional[float] = None
    maternal_bp_diastolic:      Optional[float] = None
    maternal_temp:              Optional[float] = None
    bleeding_status:            Optional[str]   = None
    uterine_involution:         Optional[str]   = None
    wound_healing:              Optional[str]   = None
    anaemia_signs:              bool            = False
    breastfeeding_status:       Optional[str]   = None
    family_planning_counselled: bool            = False
    family_planning_method:     Optional[str]   = None

    # Newborn
    newborn_weight_kg:          Optional[float] = None
    weight_gain_status:         Optional[str]   = None
    jaundice:                   Optional[str]   = None
    cord_status:                Optional[str]   = None
    newborn_breathing_normal:   bool            = True
    feeding_well:               bool            = True
    immunisation_given:         bool            = False

    # PHQ-2 (PNC 3 only)
    phq2_q1:                    Optional[int]   = None
    phq2_q2:                    Optional[int]   = None

    notes:                      Optional[str]   = None


class PHQ2Result(BaseModel):
    score:    int
    positive: bool
    level:    str
    action:   str


class PostnatalVisitOut(PostnatalVisitCreate):
    id:                         int
    chw_id:                     Optional[int]
    phq2_score:                 Optional[int]
    phq2_positive:              bool
    mental_health_referral_made: bool
    phq2_result:                Optional[PHQ2Result] = None
    created_at:                 datetime
    class Config:
        from_attributes = True


class MentalHealthActionUpdate(BaseModel):
    action_taken: str   # none | counselled | referred
    referral_id:  Optional[int] = None
```

### Step 2 — Postnatal router (`routers/postnatal.py`)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date, timedelta

from app.database import (
    get_db, Delivery, Newborn, Patient, Pregnancy,
    PostnatalScheduledVisit, PostnatalVisit,
    MentalHealthScreening, User
)
from app.schemas_postnatal import (
    DeliveryCreate, DeliveryOut,
    PostnatalVisitCreate, PostnatalVisitOut,
    PostnatalScheduledVisitOut,
    MentalHealthActionUpdate,
)
from app.routers.auth import get_current_user
from app.utils.whatsapp import send_whatsapp
import asyncio
import logging

logger = logging.getLogger("mamasafe.postnatal")

router = APIRouter(prefix="/api/v1", tags=["postnatal"])

PNC_SCHEDULE = [
    {"visit_number": 1, "days_after": 1,  "label": "24-hour check"},
    {"visit_number": 2, "days_after": 7,  "label": "1-week check"},
    {"visit_number": 3, "days_after": 42, "label": "6-week check"},
]

def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def calculate_phq2(q1: int, q2: int) -> dict:
    score    = q1 + q2
    positive = score >= 3
    if score <= 2:
        level  = "low"
        action = "No immediate action required. Continue routine support."
    elif score <= 4:
        level  = "moderate"
        action = ("Positive PHQ-2 screen. Counsel patient and schedule "
                  "follow-up in 2 weeks.")
    else:
        level  = "high"
        action = ("High PHQ-2 score. Refer to mental health services "
                  "or district hospital counsellor immediately.")
    return {"q1": q1, "q2": q2, "score": score, "positive": positive,
            "level": level, "action": action}


def auto_schedule_pnc(db: Session, delivery_id: int,
                       patient_id: int, delivery_date_str: str):
    delivery_date = datetime.strptime(delivery_date_str, "%Y-%m-%d").date()
    for v in PNC_SCHEDULE:
        visit_date = delivery_date + timedelta(days=v["days_after"])
        sv = PostnatalScheduledVisit(
            delivery_id    = delivery_id,
            patient_id     = patient_id,
            visit_number   = v["visit_number"],
            scheduled_date = str(visit_date),
            status         = "scheduled",
        )
        db.add(sv)
    db.commit()


# ── DELIVERIES ────────────────────────────────────────────

@router.post("/deliveries", response_model=DeliveryOut)
async def record_delivery(
    data: DeliveryCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Create delivery record
    delivery = Delivery(
        pregnancy_id      = data.pregnancy_id,
        patient_id        = data.patient_id,
        chw_id            = current_user.id,
        delivery_date     = data.delivery_date,
        delivery_time     = data.delivery_time,
        delivery_location = data.delivery_location,
        delivery_mode     = data.delivery_mode,
        outcome           = data.outcome,
        complications     = data.complications,
        notes             = data.notes,
    )
    db.add(delivery)
    db.commit()
    db.refresh(delivery)

    # Create newborn record if live birth
    if data.outcome == "live_birth" and data.newborn:
        newborn = Newborn(
            delivery_id              = delivery.id,
            patient_id               = data.patient_id,
            sex                      = data.newborn.sex,
            birth_weight_kg          = data.newborn.birth_weight_kg,
            apgar_1min               = data.newborn.apgar_1min,
            apgar_5min               = data.newborn.apgar_5min,
            cord_condition           = data.newborn.cord_condition,
            breathing_normal         = data.newborn.breathing_normal,
            breastfeeding_initiated  = data.newborn.breastfeeding_initiated,
            notes                    = data.newborn.notes,
        )
        db.add(newborn)
        db.commit()

    # Close the pregnancy
    pregnancy = db.query(Pregnancy).filter(
        Pregnancy.id == data.pregnancy_id).first()
    if pregnancy:
        pregnancy.is_active       = False
        pregnancy.delivery_date   = data.delivery_date
        pregnancy.delivery_outcome = data.outcome
        db.commit()

    # Auto-schedule 3 PNC visits
    auto_schedule_pnc(db, delivery.id, data.patient_id, data.delivery_date)
    db.refresh(delivery)

    # Send congratulations + PNC1 reminder to patient
    patient = db.query(Patient).filter(
        Patient.id == data.patient_id).first()
    if patient and patient.phone and data.outcome == "live_birth":
        lang = getattr(patient, 'preferred_language', 'fr') or 'fr'
        pnc1_date = str(
            datetime.strptime(data.delivery_date, "%Y-%m-%d").date()
            + timedelta(days=1)
        )
        message = build_delivery_congratulations(
            patient_name=patient.full_name,
            delivery_date=data.delivery_date,
            pnc1_date=pnc1_date,
            facility=patient.facility or "votre centre de santé",
            lang=lang,
        )
        await send_whatsapp(patient.phone, message)

    return delivery


@router.get("/deliveries/{delivery_id}", response_model=DeliveryOut)
def get_delivery(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    d = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not d:
        raise HTTPException(status_code=404, detail="Delivery not found")
    return d


@router.get("/patients/{patient_id}/deliveries",
            response_model=List[DeliveryOut])
def patient_deliveries(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(Delivery)
              .filter(Delivery.patient_id == patient_id)
              .order_by(Delivery.delivery_date.desc())
              .all())


# ── POSTNATAL SCHEDULE ────────────────────────────────────

@router.get("/postnatal-schedule/{delivery_id}")
def get_pnc_schedule(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visits = (db.query(PostnatalScheduledVisit)
                .filter(PostnatalScheduledVisit.delivery_id == delivery_id)
                .order_by(PostnatalScheduledVisit.visit_number)
                .all())
    labels = {1: "24-hour check", 2: "1-week check", 3: "6-week check"}
    return [
        {
            "id":                 v.id,
            "visit_number":       v.visit_number,
            "label":              labels.get(v.visit_number, ""),
            "scheduled_date":     v.scheduled_date,
            "status":             v.status,
            "postnatal_visit_id": v.postnatal_visit_id,
            "reminder_sent":      v.reminder_sent,
            "created_at":         str(v.created_at),
        }
        for v in visits
    ]


# ── POSTNATAL VISITS ──────────────────────────────────────

@router.post("/postnatal-visits", response_model=PostnatalVisitOut)
async def record_postnatal_visit(
    data: PostnatalVisitCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Calculate PHQ-2 if provided
    phq2_result  = None
    phq2_score   = None
    phq2_positive = False

    if data.phq2_q1 is not None and data.phq2_q2 is not None:
        phq2_result   = calculate_phq2(data.phq2_q1, data.phq2_q2)
        phq2_score    = phq2_result["score"]
        phq2_positive = phq2_result["positive"]

    # Calculate newborn weight gain status
    weight_gain_status = None
    if data.newborn_weight_kg and data.visit_number > 1:
        prev_visit = (
            db.query(PostnatalVisit)
              .filter(PostnatalVisit.delivery_id == data.delivery_id,
                      PostnatalVisit.visit_number < data.visit_number)
              .order_by(PostnatalVisit.visit_number.desc())
              .first()
        )
        if prev_visit and prev_visit.newborn_weight_kg:
            if data.newborn_weight_kg > prev_visit.newborn_weight_kg:
                weight_gain_status = "gaining"
            elif data.newborn_weight_kg == prev_visit.newborn_weight_kg:
                weight_gain_status = "static"
            else:
                weight_gain_status = "losing"

    visit = PostnatalVisit(
        delivery_id                 = data.delivery_id,
        patient_id                  = data.patient_id,
        newborn_id                  = data.newborn_id,
        scheduled_visit_id          = data.scheduled_visit_id,
        chw_id                      = current_user.id,
        visit_number                = data.visit_number,
        visit_date                  = data.visit_date,
        maternal_bp_systolic        = data.maternal_bp_systolic,
        maternal_bp_diastolic       = data.maternal_bp_diastolic,
        maternal_temp               = data.maternal_temp,
        bleeding_status             = data.bleeding_status,
        uterine_involution          = data.uterine_involution,
        wound_healing               = data.wound_healing,
        anaemia_signs               = data.anaemia_signs,
        breastfeeding_status        = data.breastfeeding_status,
        family_planning_counselled  = data.family_planning_counselled,
        family_planning_method      = data.family_planning_method,
        newborn_weight_kg           = data.newborn_weight_kg,
        weight_gain_status          = weight_gain_status,
        jaundice                    = data.jaundice,
        cord_status                 = data.cord_status,
        newborn_breathing_normal    = data.newborn_breathing_normal,
        feeding_well                = data.feeding_well,
        immunisation_given          = data.immunisation_given,
        phq2_q1                     = data.phq2_q1,
        phq2_q2                     = data.phq2_q2,
        phq2_score                  = phq2_score,
        phq2_positive               = phq2_positive,
        notes                       = data.notes,
    )
    db.add(visit)
    db.commit()
    db.refresh(visit)

    # Mark scheduled visit as completed
    if data.scheduled_visit_id:
        sv = db.query(PostnatalScheduledVisit).filter(
            PostnatalScheduledVisit.id == data.scheduled_visit_id).first()
        if sv:
            sv.status              = "completed"
            sv.postnatal_visit_id  = visit.id
            db.commit()

    # Handle positive PHQ-2
    if phq2_positive:
        patient = db.query(Patient).filter(
            Patient.id == data.patient_id).first()
        screening = MentalHealthScreening(
            postnatal_visit_id  = visit.id,
            patient_id          = data.patient_id,
            phq2_score          = phq2_score,
            phq2_positive       = True,
            chw_id              = current_user.id,
        )
        db.add(screening)
        db.commit()

        # Alert CHW via WhatsApp
        chw_phone = getattr(current_user, 'whatsapp_number', None)
        if chw_phone and patient:
            lang    = getattr(patient, 'preferred_language', 'fr') or 'fr'
            message = build_phq2_alert(
                chw_name     = current_user.full_name or current_user.username,
                patient_name = patient.full_name,
                score        = phq2_score,
                action       = phq2_result["action"],
                lang         = lang,
            )
            result = await send_whatsapp(chw_phone, message)
            screening.whatsapp_alert_sent = result.get("success", False)
            db.commit()

        logger.warning(
            f"PHQ-2 positive: patient {data.patient_id}, "
            f"score {phq2_score}"
        )

    # Check for newborn alerts
    alerts = []
    if data.newborn_weight_kg:
        delivery = db.query(Delivery).filter(
            Delivery.id == data.delivery_id).first()
        if delivery and delivery.newborn and delivery.newborn.birth_weight_kg:
            bw = delivery.newborn.birth_weight_kg
            loss_pct = ((bw - data.newborn_weight_kg) / bw) * 100
            if loss_pct > 10 and data.visit_number <= 2:
                alerts.append(f"Weight loss > 10% from birth weight "
                               f"({loss_pct:.1f}%)")
        if weight_gain_status == "losing":
            alerts.append("Newborn losing weight since last visit")

    response_data = visit.__dict__.copy()
    response_data["phq2_result"] = phq2_result
    response_data["alerts"]      = alerts

    return visit


@router.get("/postnatal-visits/{visit_id}",
            response_model=PostnatalVisitOut)
def get_postnatal_visit(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    v = db.query(PostnatalVisit).filter(
        PostnatalVisit.id == visit_id).first()
    if not v:
        raise HTTPException(status_code=404, detail="Visit not found")
    return v


@router.get("/deliveries/{delivery_id}/postnatal-visits",
            response_model=List[PostnatalVisitOut])
def list_postnatal_visits(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(PostnatalVisit)
              .filter(PostnatalVisit.delivery_id == delivery_id)
              .order_by(PostnatalVisit.visit_number)
              .all())


# ── MENTAL HEALTH ─────────────────────────────────────────

@router.get("/mental-health/screenings")
def list_screenings(
    positive_only: bool = False,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    since = date.today() - timedelta(days=days)
    q = (db.query(MentalHealthScreening)
           .filter(MentalHealthScreening.created_at >= str(since))
           .filter(MentalHealthScreening.chw_id == current_user.id))
    if positive_only:
        q = q.filter(MentalHealthScreening.phq2_positive == True)
    screenings = q.order_by(MentalHealthScreening.created_at.desc()).all()
    result = []
    for s in screenings:
        patient = db.query(Patient).filter(
            Patient.id == s.patient_id).first()
        result.append({
            "id":                  s.id,
            "patient_name":        patient.full_name if patient else "Unknown",
            "phq2_score":          s.phq2_score,
            "phq2_positive":       s.phq2_positive,
            "action_taken":        s.action_taken,
            "whatsapp_alert_sent": s.whatsapp_alert_sent,
            "date":                str(s.created_at.date()),
        })
    return result


@router.patch("/mental-health/screenings/{screening_id}/action")
def update_screening_action(
    screening_id: int,
    data: MentalHealthActionUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    s = db.query(MentalHealthScreening).filter(
        MentalHealthScreening.id == screening_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Screening not found")
    s.action_taken = data.action_taken
    if data.referral_id:
        s.referral_id = data.referral_id
    db.commit()
    db.refresh(s)
    return {"message": "Action recorded", "action_taken": s.action_taken}


# ── ANALYTICS ─────────────────────────────────────────────

@router.get("/postnatal-visits/analytics/summary")
def postnatal_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    from sqlalchemy import func

    # Get deliveries for this CHW
    deliveries = (db.query(Delivery)
                    .filter(Delivery.chw_id == current_user.id)
                    .all())
    total       = len(deliveries)
    live_births = sum(1 for d in deliveries if d.outcome == "live_birth")

    if total == 0:
        return {
            "total_deliveries": 0,
            "live_births": 0,
            "pnc1_completion_rate": 0,
            "pnc2_completion_rate": 0,
            "pnc3_completion_rate": 0,
            "phq2_screens_performed": 0,
            "phq2_positive_count": 0,
            "phq2_positive_rate": 0,
            "exclusive_breastfeeding_rate": 0,
            "newborn_weight_alerts": 0,
        }

    delivery_ids = [d.id for d in deliveries]

    def pnc_rate(visit_num):
        total_sv = (db.query(PostnatalScheduledVisit)
                      .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                              PostnatalScheduledVisit.visit_number == visit_num)
                      .count())
        completed = (db.query(PostnatalScheduledVisit)
                       .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                               PostnatalScheduledVisit.visit_number == visit_num,
                               PostnatalScheduledVisit.status == "completed")
                       .count())
        return round(completed / total_sv * 100, 1) if total_sv else 0

    phq2_screens = (db.query(PostnatalVisit)
                      .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                              PostnatalVisit.phq2_score.isnot(None))
                      .count())
    phq2_positive = (db.query(PostnatalVisit)
                       .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                               PostnatalVisit.phq2_positive == True)
                       .count())

    bf_visits = (db.query(PostnatalVisit)
                   .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                           PostnatalVisit.breastfeeding_status.isnot(None))
                   .all())
    excl_bf = sum(1 for v in bf_visits
                  if v.breastfeeding_status == "exclusive")
    bf_rate = round(excl_bf / len(bf_visits) * 100, 1) if bf_visits else 0

    weight_alerts = (db.query(PostnatalVisit)
                       .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                               PostnatalVisit.weight_gain_status == "losing")
                       .count())

    return {
        "total_deliveries":           total,
        "live_births":                live_births,
        "pnc1_completion_rate":       pnc_rate(1),
        "pnc2_completion_rate":       pnc_rate(2),
        "pnc3_completion_rate":       pnc_rate(3),
        "phq2_screens_performed":     phq2_screens,
        "phq2_positive_count":        phq2_positive,
        "phq2_positive_rate":         round(phq2_positive / phq2_screens * 100, 1)
                                      if phq2_screens else 0,
        "exclusive_breastfeeding_rate": bf_rate,
        "newborn_weight_alerts":      weight_alerts,
    }
```

### Step 3 — WhatsApp templates (add to `utils/whatsapp.py`)

```python
def build_delivery_congratulations(patient_name: str,
                                    delivery_date: str,
                                    pnc1_date: str,
                                    facility: str,
                                    lang: str = "fr") -> str:
    if lang == "en":
        return (
            f"🎉 *MamaSafe — Congratulations!*\n\n"
            f"Dear {patient_name},\n\n"
            f"Congratulations on the birth of your baby on "
            f"*{delivery_date}*! 👶\n\n"
            f"Your next postnatal check is scheduled for:\n"
            f"📅 *{pnc1_date}* — 24-hour check\n"
            f"🏥 {facility}\n\n"
            f"Please attend even if you feel well — early checks "
            f"protect both you and your baby.\n\n"
            f"_MamaSafe is with you every step of the way._ 🤱"
        )
    return (
        f"🎉 *MamaSafe — Félicitations !*\n\n"
        f"Chère {patient_name},\n\n"
        f"Félicitations pour la naissance de votre bébé le "
        f"*{delivery_date}* ! 👶\n\n"
        f"Votre prochaine visite postnatale est prévue pour :\n"
        f"📅 *{pnc1_date}* — Contrôle à 24 heures\n"
        f"🏥 {facility}\n\n"
        f"Veuillez y assister même si vous vous sentez bien — les "
        f"contrôles précoces protègent vous et votre bébé.\n\n"
        f"_MamaSafe vous accompagne à chaque étape._ 🤱"
    )


def build_pnc_reminder(patient_name: str, visit_number: int,
                        visit_label: str, visit_date: str,
                        facility: str, chw_name: str,
                        lang: str = "fr") -> str:
    if lang == "en":
        return (
            f"🤱 *MamaSafe — Postnatal Visit Reminder*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your postnatal check is scheduled for:\n\n"
            f"📅 *{visit_date}*\n"
            f"🏥 *{facility}*\n"
            f"👩‍⚕️ *CHW: {chw_name}*\n\n"
            f"This is your *Visit {visit_number} — {visit_label}*.\n\n"
            f"Please bring your baby and health booklet. 📋\n\n"
            f"_MamaSafe_"
        )
    return (
        f"🤱 *MamaSafe — Rappel de visite postnatale*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite postnatale est prévue pour :\n\n"
        f"📅 *{visit_date}*\n"
        f"🏥 *{facility}*\n"
        f"👩‍⚕️ *Agent : {chw_name}*\n\n"
        f"Il s'agit de votre *visite n°{visit_number} — {visit_label}*.\n\n"
        f"Veuillez apporter votre bébé et votre carnet de santé. 📋\n\n"
        f"_MamaSafe_"
    )


def build_phq2_alert(chw_name: str, patient_name: str,
                      score: int, action: str,
                      lang: str = "fr") -> str:
    if lang == "en":
        return (
            f"🧠 *MamaSafe — Mental Health Alert*\n\n"
            f"Hello {chw_name},\n\n"
            f"Your patient *{patient_name}* has a *positive PHQ-2 "
            f"depression screen*.\n\n"
            f"📊 Score: *{score}/6*\n\n"
            f"Recommended action:\n{action}\n\n"
            f"Please follow up with the patient as soon as possible.\n\n"
            f"_MamaSafe_"
        )
    return (
        f"🧠 *MamaSafe — Alerte santé mentale*\n\n"
        f"Bonjour {chw_name},\n\n"
        f"Votre patiente *{patient_name}* a un *dépistage PHQ-2 "
        f"positif* pour la dépression postnatale.\n\n"
        f"📊 Score : *{score}/6*\n\n"
        f"Action recommandée :\n{action}\n\n"
        f"Veuillez faire un suivi avec la patiente dès que possible.\n\n"
        f"_MamaSafe_"
    )
```

### Step 4 — Register in `main.py`

```python
from app.routers import (predict, assessments, auth, dashboard,
                          anc, referral, schedule, risk_trend,
                          postnatal)

app.include_router(postnatal.router)
```

### Step 5 — PNC reminder jobs (`utils/postnatal_jobs.py`)

```python
from datetime import date, timedelta
from sqlalchemy.orm import Session
from app.database import (SessionLocal, PostnatalScheduledVisit,
                           Patient, Delivery, User)
from app.utils.whatsapp import send_whatsapp, build_pnc_reminder
import asyncio
import logging

logger = logging.getLogger("mamasafe.postnatal_jobs")

PNC_LABELS = {1: "24-hour check", 2: "1-week check", 3: "6-week check"}

def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def job_send_pnc_reminders():
    """
    Runs daily at 07:00.
    Sends WhatsApp reminders for PNC visits due in 24 hours.
    """
    logger.info("Running PNC reminder job...")
    db = SessionLocal()
    try:
        tomorrow = str(date.today() + timedelta(days=1))
        visits   = (db.query(PostnatalScheduledVisit)
                      .filter(PostnatalScheduledVisit.scheduled_date == tomorrow,
                              PostnatalScheduledVisit.status == "scheduled",
                              PostnatalScheduledVisit.reminder_sent == False)
                      .all())

        logger.info(f"Found {len(visits)} PNC visits for {tomorrow}")

        for sv in visits:
            patient = db.query(Patient).filter(
                Patient.id == sv.patient_id).first()
            if not patient or not patient.phone:
                continue

            delivery = db.query(Delivery).filter(
                Delivery.id == sv.delivery_id).first()
            chw = db.query(User).filter(
                User.id == delivery.chw_id).first() if delivery else None

            lang    = getattr(patient, 'preferred_language', 'fr') or 'fr'
            message = build_pnc_reminder(
                patient_name = patient.full_name,
                visit_number = sv.visit_number,
                visit_label  = PNC_LABELS.get(sv.visit_number, ""),
                visit_date   = sv.scheduled_date,
                facility     = patient.facility or "votre centre de santé",
                chw_name     = chw.full_name if chw else "votre agent de santé",
                lang         = lang,
            )

            result = run_async(send_whatsapp(patient.phone, message))
            from datetime import datetime
            sv.reminder_sent    = True
            sv.reminder_sent_at = datetime.utcnow()
            db.commit()

            logger.info(
                f"PNC reminder sent to {patient.full_name}: "
                f"{'ok' if result['success'] else 'failed'}"
            )

    except Exception as e:
        logger.error(f"PNC reminder job failed: {e}")
    finally:
        db.close()
```

Add the PNC job to APScheduler in `main.py` startup:

```python
from app.utils.postnatal_jobs import job_send_pnc_reminders

scheduler.add_job(
    job_send_pnc_reminders,
    CronTrigger(hour=7, minute=30),  # 07:30 daily
    id="pnc_reminders",
    replace_existing=True,
)
```

---

## 9. Web Frontend Implementation

### New pages and components

| Component / Page | Description |
|-----------------|-------------|
| `DeliveryForm.jsx` | Form to record a delivery and newborn |
| `PostnatalSchedule.jsx` | 3-visit PNC timeline on patient profile |
| `PostnatalVisitForm.jsx` | Form to record a postnatal visit |
| `PHQ2Widget.jsx` | Embedded PHQ-2 screening component |
| `PostnatalResult.jsx` | Visit result with alerts and PHQ-2 result |

### PHQ-2 widget (`PHQ2Widget.jsx`)

```jsx
const RESPONSES_FR = [
  { value: 0, label: 'Jamais' },
  { value: 1, label: 'Plusieurs jours' },
  { value: 2, label: 'Plus de la moitié des jours' },
  { value: 3, label: 'Presque tous les jours' },
];

const RESPONSES_EN = [
  { value: 0, label: 'Not at all' },
  { value: 1, label: 'Several days' },
  { value: 2, label: 'More than half the days' },
  { value: 3, label: 'Nearly every day' },
];

const QUESTIONS_FR = [
  "Au cours des 2 dernières semaines, à quelle fréquence avez-vous ressenti peu d'intérêt ou de plaisir à faire les choses ?",
  "Au cours des 2 dernières semaines, à quelle fréquence vous êtes-vous sentie triste, déprimée ou sans espoir ?",
];

const QUESTIONS_EN = [
  "Over the past 2 weeks, how often have you had little interest or pleasure in doing things?",
  "Over the past 2 weeks, how often have you felt down, depressed, or hopeless?",
];

export default function PHQ2Widget({ onChange, lang = 'fr' }) {
  const [q1, setQ1] = useState(null);
  const [q2, setQ2] = useState(null);

  const questions = lang === 'en' ? QUESTIONS_EN : QUESTIONS_FR;
  const responses = lang === 'en' ? RESPONSES_EN : RESPONSES_FR;

  useEffect(() => {
    if (q1 !== null && q2 !== null) {
      const score    = q1 + q2;
      const positive = score >= 3;
      onChange({ q1, q2, score, positive });
    }
  }, [q1, q2]);

  const score    = q1 !== null && q2 !== null ? q1 + q2 : null;
  const positive = score !== null && score >= 3;

  return (
    <div className="bg-blue-50 border border-blue-200 rounded-2xl p-5">
      <div className="flex items-center gap-2 mb-4">
        <span className="text-xl">🧠</span>
        <h3 className="font-bold text-blue-800 text-sm">
          PHQ-2 Depression Screen {lang === 'fr' ? '(6-week visit)' : '(visite 6 semaines)'}
        </h3>
      </div>

      {[{ q: questions[0], val: q1, set: setQ1 },
        { q: questions[1], val: q2, set: setQ2 }].map((item, qi) => (
        <div key={qi} className="mb-4">
          <p className="text-sm text-blue-900 font-medium mb-3 leading-relaxed">
            {qi + 1}. {item.q}
          </p>
          <div className="grid grid-cols-2 gap-2">
            {responses.map(r => (
              <button
                key={r.value}
                type="button"
                onClick={() => item.set(r.value)}
                className={`p-2.5 rounded-xl border text-xs font-medium
                            text-left transition-colors
                            ${item.val === r.value
                              ? 'bg-blue-600 text-white border-blue-600'
                              : 'bg-white text-blue-700 border-blue-200 hover:bg-blue-50'}`}
              >
                <span className="font-bold">{r.value}</span> — {r.label}
              </button>
            ))}
          </div>
        </div>
      ))}

      {score !== null && (
        <div className={`rounded-xl p-3 mt-2 border ${
          positive
            ? 'bg-red-50 border-red-300'
            : 'bg-green-50 border-green-300'
        }`}>
          <p className={`text-sm font-bold ${
            positive ? 'text-red-700' : 'text-green-700'
          }`}>
            Score: {score}/6 — {positive
              ? '⚠️ Positive screen — follow-up required'
              : '✓ Low risk'}
          </p>
        </div>
      )}
    </div>
  );
}
```

### Postnatal schedule component (`PostnatalSchedule.jsx`)

```jsx
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getPNCSchedule } from '../api/client';

const STATUS_CONFIG = {
  scheduled:  { color: 'indigo', label: 'Scheduled',  icon: '📅' },
  completed:  { color: 'green',  label: 'Completed',  icon: '✅' },
  missed:     { color: 'red',    label: 'Missed',     icon: '⚠️' },
  cancelled:  { color: 'gray',   label: 'Cancelled',  icon: '❌' },
};

const COLOR_CLASSES = {
  indigo: 'bg-indigo-50 border-indigo-200 text-indigo-700',
  green:  'bg-green-50  border-green-200  text-green-700',
  red:    'bg-red-50    border-red-200    text-red-700',
  gray:   'bg-gray-50   border-gray-200   text-gray-500',
};

export default function PostnatalSchedule({ deliveryId }) {
  const [schedule, setSchedule] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    if (deliveryId) getPNCSchedule(deliveryId).then(setSchedule);
  }, [deliveryId]);

  if (!schedule.length) return null;

  const completed = schedule.filter(v => v.status === 'completed').length;

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-gray-800">Postnatal Care</h3>
        <span className="text-sm text-gray-500">
          {completed}/{schedule.length} done
        </span>
      </div>

      <div className="space-y-2">
        {schedule.map(v => {
          const sc = STATUS_CONFIG[v.status] || STATUS_CONFIG.scheduled;
          const cc = COLOR_CLASSES[sc.color];
          const isNext = v.status === 'scheduled' &&
                         !schedule.find(s => s.visit_number < v.visit_number &&
                                             s.status === 'scheduled');
          return (
            <div key={v.id}
                 className={`flex items-center gap-3 p-3 rounded-xl
                             border ${cc}
                             ${isNext ? 'ring-2 ring-indigo-400' : ''}`}>
              <span className="text-xl">{sc.icon}</span>
              <div className="flex-1">
                <p className="text-sm font-semibold">
                  PNC {v.visit_number} — {v.label}
                </p>
                <p className="text-xs opacity-75">
                  {new Date(v.scheduled_date).toLocaleDateString('en-GB', {
                    day: 'numeric', month: 'short', year: 'numeric'
                  })}
                </p>
              </div>
              {v.status === 'scheduled' && (
                <button
                  onClick={() => navigate(
                    `/postnatal-visit/${deliveryId}/${v.visit_number}/${v.id}`
                  )}
                  className="text-xs bg-white border border-current
                             px-3 py-1.5 rounded-full font-medium"
                >
                  Record
                </button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

### API client additions

```javascript
// Deliveries
export const recordDelivery = async (data) => {
  const res = await client.post('/api/v1/deliveries', data);
  return res.data;
};

export const getDelivery = async (id) => {
  const res = await client.get(`/api/v1/deliveries/${id}`);
  return res.data;
};

export const getPatientDeliveries = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/deliveries`);
  return res.data;
};

// PNC schedule
export const getPNCSchedule = async (deliveryId) => {
  const res = await client.get(`/api/v1/postnatal-schedule/${deliveryId}`);
  return res.data;
};

// Postnatal visits
export const recordPostnatalVisit = async (data) => {
  const res = await client.post('/api/v1/postnatal-visits', data);
  return res.data;
};

export const getPostnatalVisits = async (deliveryId) => {
  const res = await client.get(
    `/api/v1/deliveries/${deliveryId}/postnatal-visits`);
  return res.data;
};

// Mental health
export const getMentalHealthScreenings = async (positiveOnly = false) => {
  const res = await client.get(
    `/api/v1/mental-health/screenings?positive_only=${positiveOnly}`);
  return res.data;
};

export const recordScreeningAction = async (screeningId, action, referralId) => {
  const res = await client.patch(
    `/api/v1/mental-health/screenings/${screeningId}/action`,
    { action_taken: action, referral_id: referralId }
  );
  return res.data;
};

// Analytics
export const getPostnatalAnalytics = async () => {
  const res = await client.get('/api/v1/postnatal-visits/analytics/summary');
  return res.data;
};
```

---

## 10. Mobile Frontend Implementation (Expo)

### New screens

```
src/screens/
  DeliveryFormScreen.js        ← Record delivery and newborn
  PostnatalVisitScreen.js      ← Record postnatal visit with PHQ-2
  PostnatalSummaryScreen.js    ← Patient postnatal overview
```

### Postnatal visit screen (`PostnatalVisitScreen.js`)

```jsx
import React, { useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  TextInput, Switch, StyleSheet, Alert
} from 'react-native';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { recordPostnatalVisit } from '../utils/api';

const BLEEDING_OPTIONS   = ['none', 'light', 'moderate', 'heavy'];
const JAUNDICE_OPTIONS   = ['none', 'mild', 'severe'];
const BF_OPTIONS         = ['exclusive', 'mixed', 'none'];
const PHQ2_RESPONSES     = [
  { value: 0, label: 'Jamais' },
  { value: 1, label: 'Plusieurs jours' },
  { value: 2, label: 'Plus de la moitié des jours' },
  { value: 3, label: 'Presque tous les jours' },
];

const PHQ2_QUESTIONS = [
  "Au cours des 2 dernières semaines, à quelle fréquence avez-vous ressenti peu d'intérêt ou de plaisir à faire les choses ?",
  "Au cours des 2 dernières semaines, à quelle fréquence vous êtes-vous sentie triste, déprimée ou sans espoir ?",
];

export default function PostnatalVisitScreen({ route, navigation }) {
  const { deliveryId, patientId, newbornId,
          scheduledVisitId, visitNumber } = route.params;

  const [form, setForm] = useState({
    maternal_bp_systolic:  '',
    maternal_bp_diastolic: '',
    bleeding_status:       'none',
    breastfeeding_status:  'exclusive',
    anaemia_signs:         false,
    wound_healing:         'healing',
    newborn_weight_kg:     '',
    jaundice:              'none',
    feeding_well:          true,
    cord_status:           'normal',
    immunisation_given:    false,
    phq2_q1:              null,
    phq2_q2:              null,
    notes:                '',
  });
  const [loading, setLoading] = useState(false);

  const phq2Score   = form.phq2_q1 !== null && form.phq2_q2 !== null
    ? form.phq2_q1 + form.phq2_q2 : null;
  const phq2Positive = phq2Score !== null && phq2Score >= 3;

  const handleSubmit = async () => {
    setLoading(true);
    try {
      const payload = {
        delivery_id:        deliveryId,
        patient_id:         patientId,
        newborn_id:         newbornId,
        scheduled_visit_id: scheduledVisitId,
        visit_number:       visitNumber,
        visit_date:         new Date().toISOString().split('T')[0],
        ...form,
        maternal_bp_systolic:  form.maternal_bp_systolic
                               ? parseFloat(form.maternal_bp_systolic) : null,
        maternal_bp_diastolic: form.maternal_bp_diastolic
                               ? parseFloat(form.maternal_bp_diastolic) : null,
        newborn_weight_kg:     form.newborn_weight_kg
                               ? parseFloat(form.newborn_weight_kg) : null,
      };
      const result = await recordPostnatalVisit(payload);
      navigation.replace('PostnatalResult', {
        visit: result,
        phq2Score,
        phq2Positive,
      });
    } catch (err) {
      Alert.alert('Error', 'Failed to record visit. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const Field = ({ label, children }) => (
    <View style={s.field}>
      <Text style={s.fieldLabel}>{label}</Text>
      {children}
    </View>
  );

  const OptionRow = ({ options, value, onSelect, colorMap }) => (
    <View style={s.optionRow}>
      {options.map(opt => (
        <TouchableOpacity
          key={opt}
          style={[s.optionBtn, value === opt && s.optionBtnActive]}
          onPress={() => onSelect(opt)}
        >
          <Text style={[s.optionText, value === opt && s.optionTextActive]}>
            {opt}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );

  return (
    <ScrollView style={s.root} contentContainerStyle={s.scroll}>
      <Text style={s.title}>PNC {visitNumber} Visit</Text>
      <Text style={s.subtitle}>
        {visitNumber === 1 ? '24-hour check'
         : visitNumber === 2 ? '1-week check'
         : '6-week check'}
      </Text>

      {/* Maternal section */}
      <View style={s.section}>
        <Text style={s.sectionTitle}>👩 Maternal Status</Text>

        <View style={s.bpRow}>
          <View style={{ flex: 1 }}>
            <Text style={s.fieldLabel}>Systolic BP</Text>
            <TextInput
              style={s.input}
              value={form.maternal_bp_systolic}
              onChangeText={v => setForm(f => ({
                ...f, maternal_bp_systolic: v
              }))}
              keyboardType="decimal-pad"
              placeholder="mmHg"
              placeholderTextColor={COLORS.textDim}
            />
          </View>
          <View style={s.bpSep} />
          <View style={{ flex: 1 }}>
            <Text style={s.fieldLabel}>Diastolic BP</Text>
            <TextInput
              style={s.input}
              value={form.maternal_bp_diastolic}
              onChangeText={v => setForm(f => ({
                ...f, maternal_bp_diastolic: v
              }))}
              keyboardType="decimal-pad"
              placeholder="mmHg"
              placeholderTextColor={COLORS.textDim}
            />
          </View>
        </View>

        <Field label="Bleeding">
          <OptionRow
            options={BLEEDING_OPTIONS}
            value={form.bleeding_status}
            onSelect={v => setForm(f => ({ ...f, bleeding_status: v }))}
          />
        </Field>

        <Field label="Breastfeeding">
          <OptionRow
            options={BF_OPTIONS}
            value={form.breastfeeding_status}
            onSelect={v => setForm(f => ({ ...f, breastfeeding_status: v }))}
          />
        </Field>

        <View style={s.switchRow}>
          <Text style={s.switchLabel}>Signs of anaemia</Text>
          <Switch
            value={form.anaemia_signs}
            onValueChange={v => setForm(f => ({ ...f, anaemia_signs: v }))}
            trackColor={{ false: COLORS.border, true: COLORS.warning }}
          />
        </View>
      </View>

      {/* Newborn section */}
      <View style={s.section}>
        <Text style={s.sectionTitle}>👶 Newborn Status</Text>

        <Field label="Weight (kg)">
          <TextInput
            style={s.input}
            value={form.newborn_weight_kg}
            onChangeText={v => setForm(f => ({
              ...f, newborn_weight_kg: v
            }))}
            keyboardType="decimal-pad"
            placeholder="e.g. 3.2"
            placeholderTextColor={COLORS.textDim}
          />
        </Field>

        <Field label="Jaundice">
          <OptionRow
            options={JAUNDICE_OPTIONS}
            value={form.jaundice}
            onSelect={v => setForm(f => ({ ...f, jaundice: v }))}
          />
        </Field>

        <View style={s.switchRow}>
          <Text style={s.switchLabel}>Feeding well</Text>
          <Switch
            value={form.feeding_well}
            onValueChange={v => setForm(f => ({ ...f, feeding_well: v }))}
            trackColor={{ false: COLORS.border, true: COLORS.success }}
          />
        </View>

        <View style={s.switchRow}>
          <Text style={s.switchLabel}>Immunisation given</Text>
          <Switch
            value={form.immunisation_given}
            onValueChange={v => setForm(f => ({
              ...f, immunisation_given: v
            }))}
            trackColor={{ false: COLORS.border, true: COLORS.success }}
          />
        </View>
      </View>

      {/* PHQ-2 section (visit 3 only) */}
      {visitNumber === 3 && (
        <View style={[s.section, s.phq2Section]}>
          <Text style={s.sectionTitle}>🧠 Depression Screening (PHQ-2)</Text>

          {PHQ2_QUESTIONS.map((q, qi) => (
            <View key={qi} style={s.phq2Question}>
              <Text style={s.phq2QuestionText}>{qi + 1}. {q}</Text>
              {PHQ2_RESPONSES.map(r => (
                <TouchableOpacity
                  key={r.value}
                  style={[s.phq2Option,
                    (qi === 0 ? form.phq2_q1 : form.phq2_q2) === r.value
                    && s.phq2OptionActive]}
                  onPress={() => {
                    if (qi === 0) setForm(f => ({ ...f, phq2_q1: r.value }));
                    else          setForm(f => ({ ...f, phq2_q2: r.value }));
                  }}
                >
                  <Text style={[s.phq2OptionText,
                    (qi === 0 ? form.phq2_q1 : form.phq2_q2) === r.value
                    && s.phq2OptionTextActive]}>
                    {r.value} — {r.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          ))}

          {phq2Score !== null && (
            <View style={[s.phq2Result,
              phq2Positive ? s.phq2ResultPositive : s.phq2ResultNegative]}>
              <Text style={[s.phq2ResultText,
                { color: phq2Positive ? '#991B1B' : '#065F46' }]}>
                Score: {phq2Score}/6 —{' '}
                {phq2Positive ? '⚠️ Positive — follow-up required'
                              : '✓ Low risk'}
              </Text>
            </View>
          )}
        </View>
      )}

      {/* Notes */}
      <View style={s.section}>
        <Text style={s.fieldLabel}>Notes (optional)</Text>
        <TextInput
          style={[s.input, s.notesInput]}
          value={form.notes}
          onChangeText={v => setForm(f => ({ ...f, notes: v }))}
          placeholder="Any additional observations..."
          placeholderTextColor={COLORS.textDim}
          multiline
          numberOfLines={3}
          textAlignVertical="top"
        />
      </View>

      <TouchableOpacity
        style={[s.submitBtn, loading && { opacity: 0.6 }]}
        onPress={handleSubmit}
        disabled={loading}
      >
        <Text style={s.submitBtnText}>
          {loading ? 'Recording...' : '✅ Record PNC Visit'}
        </Text>
      </TouchableOpacity>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:               { flex: 1, backgroundColor: COLORS.bg },
  scroll:             { padding: 16 },
  title:              { fontSize: FONT.xl, fontWeight: '700', color: COLORS.text },
  subtitle:           { fontSize: FONT.sm, color: COLORS.textMuted, marginBottom: 16 },
  section:            { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: 14, marginBottom: 12 },
  phq2Section:        { backgroundColor: '#EFF6FF', borderWidth: 1, borderColor: '#BFDBFE' },
  sectionTitle:       { fontSize: FONT.md, fontWeight: '600', color: COLORS.text, marginBottom: 12 },
  field:              { marginBottom: 12 },
  fieldLabel:         { fontSize: FONT.xs, fontWeight: '500', color: COLORS.textMuted, textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 6 },
  input:              { backgroundColor: COLORS.surface2, borderRadius: RADIUS.md, padding: 10, color: COLORS.text, fontSize: FONT.sm, borderWidth: 1, borderColor: COLORS.border },
  notesInput:         { minHeight: 70, textAlignVertical: 'top' },
  bpRow:              { flexDirection: 'row', alignItems: 'flex-end', marginBottom: 12 },
  bpSep:              { width: 12 },
  optionRow:          { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  optionBtn:          { paddingHorizontal: 12, paddingVertical: 7, borderRadius: RADIUS.full, borderWidth: 1, borderColor: COLORS.border, backgroundColor: COLORS.surface2 },
  optionBtnActive:    { backgroundColor: COLORS.primary, borderColor: COLORS.primary },
  optionText:         { fontSize: FONT.xs, color: COLORS.textMuted, fontWeight: '500' },
  optionTextActive:   { color: '#fff' },
  switchRow:          { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 0.5, borderBottomColor: COLORS.border },
  switchLabel:        { fontSize: FONT.sm, color: COLORS.text },
  phq2Question:       { marginBottom: 16 },
  phq2QuestionText:   { fontSize: FONT.sm, color: '#1E3A5F', lineHeight: 20, marginBottom: 8 },
  phq2Option:         { padding: 10, borderRadius: RADIUS.md, borderWidth: 1, borderColor: '#BFDBFE', backgroundColor: '#fff', marginBottom: 4 },
  phq2OptionActive:   { backgroundColor: '#2563EB', borderColor: '#2563EB' },
  phq2OptionText:     { fontSize: FONT.sm, color: '#1E40AF' },
  phq2OptionTextActive: { color: '#fff', fontWeight: '500' },
  phq2Result:         { borderRadius: RADIUS.md, padding: 10, marginTop: 8 },
  phq2ResultPositive: { backgroundColor: '#FEE2E2', borderWidth: 1, borderColor: '#FCA5A5' },
  phq2ResultNegative: { backgroundColor: '#D1FAE5', borderWidth: 1, borderColor: '#6EE7B7' },
  phq2ResultText:     { fontSize: FONT.sm, fontWeight: '600' },
  submitBtn:          { backgroundColor: COLORS.success, padding: 16, borderRadius: RADIUS.lg, alignItems: 'center', marginTop: 8 },
  submitBtnText:      { color: '#fff', fontSize: FONT.md, fontWeight: '700' },
});
```

---

## 11. WhatsApp Notifications

### Four notification types

| Type | Trigger | Recipient | Template function |
|------|---------|-----------|------------------|
| Delivery congratulations | Delivery recorded | Patient | `build_delivery_congratulations` |
| PNC reminder | 24hrs before visit | Patient | `build_pnc_reminder` |
| PHQ-2 alert | PHQ-2 score ≥ 3 | CHW | `build_phq2_alert` |
| Missed PNC alert | 18:00 same day | CHW | (extend `build_missed_visit_alert` from ANC module) |

All templates support French and English via the `lang` parameter.
The patient's `preferred_language` field determines which is used.

---

## 12. Testing Guide

### Postman test sequence

```
1.  POST /api/v1/deliveries          → creates delivery + newborn +
                                       3 PNC scheduled visits
2.  GET  /api/v1/postnatal-schedule/1
                                     → verify 3 visits with correct dates
                                       (D+1, D+7, D+42)
3.  POST /api/v1/postnatal-visits    → record PNC 1 (no PHQ-2)
                                     → scheduled visit 1 marked completed
4.  GET  /api/v1/postnatal-schedule/1
                                     → PNC 1 status = completed
5.  POST /api/v1/postnatal-visits    → record PNC 2 with newborn weight
6.  POST /api/v1/postnatal-visits    → record PNC 3 with PHQ-2 q1=2, q2=2
                                     → phq2_score = 4, phq2_positive = true
                                     → MentalHealthScreening created
                                     → WhatsApp alert to CHW
7.  GET  /api/v1/mental-health/screenings?positive_only=true
                                     → returns the PHQ-2 positive screen
8.  PATCH /api/v1/mental-health/screenings/1/action
          { "action_taken": "referred", "referral_id": 1 }
9.  GET  /api/v1/postnatal-visits/analytics/summary
                                     → pnc3_completion_rate: 33.3 (1/3 visit sets)
                                       phq2_positive_rate: 100.0 (1/1 screen)
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| PNC-01 | Record delivery — live birth | Delivery, newborn, 3 scheduled PNC visits created |
| PNC-02 | PNC 1 date = delivery + 1 day | Date calculation correct |
| PNC-03 | PNC 2 date = delivery + 7 days | Date calculation correct |
| PNC-04 | PNC 3 date = delivery + 42 days | Date calculation correct |
| PNC-05 | Record PNC 1 without PHQ-2 | Visit saved, no mental health record |
| PNC-06 | Record PNC 3 with PHQ-2 score 2 | `phq2_positive: false`, no alert |
| PNC-07 | Record PNC 3 with PHQ-2 score 4 | `phq2_positive: true`, alert created, WhatsApp sent |
| PNC-08 | Record PNC 3 with PHQ-2 score 6 | `phq2_positive: true`, high urgency action |
| PNC-09 | Newborn weight less than PNC 1 | `weight_gain_status: "losing"` |
| PNC-10 | Delivery with outcome stillbirth | No newborn record created |
| PNC-11 | Mental health action update | `action_taken` updated, referral linked |
| PNC-12 | Analytics after 2 PNC 1 visits out of 3 deliveries | `pnc1_completion_rate: 66.7` |
| PNC-13 | Congratulations WhatsApp sent on delivery | Baileys microservice called |
| PNC-14 | PNC reminder job — visit tomorrow | Reminder WhatsApp sent, `reminder_sent = true` |

---

## 13. Report Integration

### Section 1.1 — Background of the Study (add)

> The postnatal period — particularly the 48 hours following delivery
> — accounts for a disproportionate share of maternal deaths, with an
> estimated 60% of postpartum haemorrhage fatalities occurring within
> the first day. In Cameroon, postnatal follow-up is largely informal,
> with no structured digital tracking of the three WHO-recommended
> postnatal contacts. The MamaSafe postnatal tracker closes this gap
> by extending the platform's coverage through the full six weeks of
> the postnatal period.

### Section 1.4 — Research Objectives (add Specific Objective 10)

> To design and implement a postnatal visit tracker that records
> delivery outcomes, automatically schedules the three WHO-recommended
> postnatal contacts, captures structured maternal and newborn status
> data at each visit, and integrates the PHQ-2 postnatal depression
> screening tool with automated WhatsApp alerts to community health
> workers on positive screens.

### Section 2.3 — Empirical Framework (add sub-group)

**Postnatal care and mental health in sub-Saharan Africa:**
> Kroenke et al. (2003) validated the PHQ-2 as a reliable screening
> tool for major depressive disorder, demonstrating sensitivity of
> 83% and specificity of 90% at a threshold score of ≥ 3. Sawyer
> et al. (2010) documented elevated rates of postnatal depression
> in low-income countries (up to 35%), with Cameroon-specific
> evidence suggesting the condition is widespread but systematically
> undetected. No digital health tool deployed in Cameroon integrates
> PHQ-2 screening into routine postnatal care workflows.

### Section 4.2.5 — Extended System Discussion

> The postnatal tracker completes MamaSafe's coverage of the
> maternal health journey. By linking delivery recording to
> automatic scheduling of three WHO postnatal contacts, the system
> ensures that no woman delivered under MamaSafe's care disappears
> from follow-up after birth. The embedded PHQ-2 screening at the
> six-week visit addresses postnatal depression — a condition
> affecting up to 35% of postpartum women in low-income settings
> (Sawyer et al., 2010) yet almost entirely undetected in Cameroon
> due to the absence of systematic screening infrastructure. The
> automated WhatsApp alert to the CHW on a positive PHQ-2 screen
> transforms a passive recording tool into an active clinical
> safety mechanism.

### Section 5.4 — Limitations (add)

> The PHQ-2 depression screening tool included in the postnatal
> tracker has not been formally validated in a Cameroonian
> French-language clinical population. While the tool is widely
> used internationally and translation guidelines were followed,
> cross-cultural validation with Cameroonian women of diverse
> educational and linguistic backgrounds is recommended before
> interpreting PHQ-2 results as clinically definitive.

---

## 14. Future Extensions

| Feature | Description | Effort |
|---------|-------------|--------|
| Infant growth curves | Plot newborn weight against WHO percentile curves — extends the basic weight tracking in this module | Low (already in v2 rank 6) |
| Full PHQ-9 | Administer the complete 9-item PHQ for confirmed positive PHQ-2 cases | Low |
| Family planning registry | Track long-term contraception method uptake per CHW catchment area | Medium |
| Mother support groups | WhatsApp group creation for mothers who delivered in the same week, facilitated by CHW | Medium |
| Newborn hearing/vision screening | Structured prompt for CHW to flag developmental concerns at 6-week visit | Low |
| Cord blood banking referral | For facilities with cord blood banking capability — flag at delivery | Low |

---

*End of document.*

**MamaSafe Postnatal Visit Tracker Documentation v1.0**  
*Prepared for the MamaSafe Final Year Project — YIBS Software Engineering*
