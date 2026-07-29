# MamaSafe — Infant Growth Tracker
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Infant Growth Tracker  
**Stack:** FastAPI · PostgreSQL · React · Recharts · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Clinical Context — WHO Growth Standards](#2-clinical-context--who-growth-standards)
3. [System Architecture](#3-system-architecture)
4. [How It Works](#4-how-it-works)
5. [Data Model](#5-data-model)
6. [WHO Growth Reference Data](#6-who-growth-reference-data)
7. [Alert Logic and Thresholds](#7-alert-logic-and-thresholds)
8. [API Reference](#8-api-reference)
9. [Backend Implementation](#9-backend-implementation)
10. [Web Frontend Implementation](#10-web-frontend-implementation)
11. [Mobile Frontend Implementation (Expo)](#11-mobile-frontend-implementation-expo)
12. [WhatsApp Growth Alerts](#12-whatsapp-growth-alerts)
13. [Testing Guide](#13-testing-guide)
14. [Report Integration](#14-report-integration)
15. [Future Extensions](#15-future-extensions)

---

## 1. Overview and Purpose

The MamaSafe Infant Growth Tracker extends the postnatal visit module
by adding WHO-standardised growth monitoring for every newborn
registered in the system. The basic weight recording built into the
postnatal visit tracker captures a number — the infant growth tracker
transforms that number into a clinical interpretation by comparing it
against the WHO Child Growth Standards percentile curves.

Without standardised growth monitoring, a CHW recording a weight of
4.2 kg at the 6-week visit has no way of knowing whether that is
healthy for this baby's age and sex without consulting a paper growth
chart — which may not be available, may have been left at the
facility, or may be misread. The infant growth tracker makes the
interpretation automatic, visual, and alerting.

The module does four things:

**1. Plots weight-for-age against WHO percentile curves** — Every
weight measurement recorded at postnatal visits is plotted on a
growth chart showing the WHO 3rd, 15th, 50th, 85th, and 97th
percentiles for the baby's sex and age in weeks. The CHW sees at
a glance whether the baby is growing normally or diverging from
the expected trajectory.

**2. Classifies nutritional status** — Each weight measurement is
classified using the WHO weight-for-age Z-score:

- **Normal**: weight between 3rd and 97th percentile
- **Underweight**: weight below the 15th percentile — monitor closely
- **Severely underweight**: weight below the 3rd percentile — alert
- **Overweight**: weight above the 97th percentile — flag for review

**3. Detects growth faltering automatically** — If a baby's weight
crosses downward across two major percentile lines between visits
(e.g., from the 50th to below the 15th), the system flags growth
faltering and alerts the CHW regardless of the absolute weight.

**4. Tracks feeding and immunisation alongside weight** — Growth is
not just a weight number. The tracker records exclusive breastfeeding
status and immunisation completion at each visit alongside weight,
enabling the CHW to identify correlations — a baby losing weight
who is not exclusively breastfed, or a baby with delayed immunisation
who is also showing growth faltering.

**What this replaces:** The paper Road-to-Health card used in
many African health systems is the closest equivalent — a card
with printed growth curves on which the CHW plots weight by hand.
In Cameroon this card is frequently lost, damaged, or unavailable
at community level. MamaSafe's digital growth tracker is always
available on the CHW's phone or tablet, auto-calculates percentiles,
and alerts — capabilities a paper card cannot provide.

---

## 2. Clinical Context — WHO Growth Standards

### The WHO 2006 Child Growth Standards

The WHO Child Growth Standards, published in 2006, describe how
children should grow under optimal conditions — adequate nutrition,
no disease, non-smoking environment. They are based on a multinational
study (the Multicentre Growth Reference Study) that included children
from Brazil, Ghana, India, Norway, Oman, and the United States.

These standards are the global reference for child growth monitoring
and are used by the Cameroon Ministry of Public Health in all national
nutrition programmes.

For the postnatal period covered by MamaSafe (0–12 weeks), the
relevant indicator is **weight-for-age**, expressed in either
percentiles or Z-scores.

### Weight-for-age in the postnatal period

| Age | Expected weight range (3rd–97th percentile) |
|-----|---------------------------------------------|
| Birth | 2.5 kg – 4.3 kg (girls) / 2.5 kg – 4.5 kg (boys) |
| 4 weeks | 3.2 kg – 5.6 kg (girls) / 3.4 kg – 5.7 kg (boys) |
| 6 weeks | 3.6 kg – 6.4 kg (girls) / 3.8 kg – 6.5 kg (boys) |
| 8 weeks | 4.0 kg – 7.1 kg (girls) / 4.3 kg – 7.3 kg (boys) |
| 12 weeks | 4.8 kg – 8.3 kg (girls) / 5.1 kg – 8.7 kg (boys) |

### Key clinical rules for newborn weight monitoring

**Rule 1 — Initial weight loss is normal:**
All newborns lose weight in the first 3–5 days of life due to fluid
loss. A loss of up to 7-10% of birth weight is physiologically
normal. Weight should return to birth weight by day 10–14.

**Rule 2 — Normal weight gain:**
After the initial loss, healthy infants gain approximately 150–200g
per week in the first three months (roughly 25–30g per day).

**Rule 3 — Growth faltering:**
Growth faltering is defined as a sustained failure to gain weight
appropriately, or actual weight loss beyond the initial postnatal
period. It is a clinical emergency requiring investigation.

**Rule 4 — The 3rd percentile threshold:**
Weight below the 3rd percentile for age and sex (approximately
2 standard deviations below the mean) indicates severe
underweight — a WHO-defined threshold for acute malnutrition
in infants that requires immediate nutritional intervention and
medical review.

### The Cameroon context

Cameroon's national stunting rate is 29%, rising to 40% in the
northern regions. Child wasting (acute undernutrition) affects
6% of children under five. Stunting begins in the first 1,000
days of life — the period from conception to the child's second
birthday — with the postnatal period being the most critical
intervention window. Early detection of growth faltering through
systematic growth monitoring is one of the highest-impact
nutritional interventions available at community level.

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
│  └──────────────┘    │  /api/v1/growth/{newborn_id}         │  │
│                      │  /api/v1/growth/{newborn_id}/chart   │  │
│                      │  /api/v1/growth/alerts               │  │
│                      │  /api/v1/growth/analytics            │  │
│                      │                                      │  │
│                      │  WHO Growth Data (JSON embedded)     │  │
│                      │  ┌──────────────────────────────┐   │  │
│                      │  │  who_growth_data.py           │   │  │
│                      │  │  Percentile tables for        │   │  │
│                      │  │  boys and girls, 0-52 weeks   │   │  │
│                      │  └──────────────────────────────┘   │  │
│                      └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Relationship to postnatal module

The infant growth tracker is a read-and-enrich layer on top of
data that already exists. Weight measurements are recorded in
`postnatal_visits.newborn_weight_kg` (from the postnatal tracker
module). The growth tracker:

1. Reads weight measurements from `postnatal_visits`
2. Reads birth weight from `newborns.birth_weight_kg`
3. Calculates age in weeks at each measurement from the
   delivery date and measurement date
4. Looks up the WHO percentile for that age, sex, and weight
5. Returns the enriched data with percentile classification
6. Stores growth alerts in `growth_alerts` table

**No duplicate weight storage** — weight is recorded once in
`postnatal_visits` and the growth tracker queries it. This follows
the single-source-of-truth principle.

---

## 4. How It Works

### Step 1 — Weight is recorded at postnatal visit

When a CHW records a postnatal visit in the postnatal tracker
module, they enter `newborn_weight_kg`. This is the data source
for the growth tracker — no additional data entry is required.

### Step 2 — Growth chart is generated on demand

When the CHW opens the infant profile or the growth chart screen,
the frontend calls `GET /api/v1/growth/{newborn_id}/chart`. The
backend:

1. Loads all postnatal visits for this newborn
2. Calculates age in weeks at each visit
3. Looks up WHO percentile values for each age point
4. Returns both the actual weight trajectory and the WHO
   reference curves (3rd, 15th, 50th, 85th, 97th percentiles)
5. The frontend plots both on the same chart

### Step 3 — Percentile classification at each visit

For each weight measurement, the backend calculates:

- **Percentile rank**: where the baby's weight sits on the
  WHO distribution (e.g., 23rd percentile)
- **Z-score**: how many standard deviations from the WHO mean
- **Classification**: normal / underweight / severely underweight /
  overweight

### Step 4 — Growth faltering detection

After each new weight measurement, the backend checks for
growth faltering by comparing the current percentile to the
previous measurement's percentile. If the percentile has dropped
by more than 2 major lines (across the 97th, 85th, 50th, 15th,
or 3rd thresholds), a growth faltering event is logged and a
WhatsApp alert sent to the CHW.

### Step 5 — Alert if below 3rd percentile

If the current weight is below the 3rd percentile for the baby's
age and sex, a `GrowthAlert` record is created with severity
`severe` and a WhatsApp sent immediately to the CHW.

---

## 5. Data Model

### New table — `growth_alerts`

Weight measurements are already in `postnatal_visits`. The only
new table is `growth_alerts` for logging detected growth issues:

```python
class GrowthAlert(Base):
    __tablename__ = "growth_alerts"

    id                  = Column(Integer, primary_key=True, index=True)
    newborn_id          = Column(Integer, ForeignKey("newborns.id"),
                                 nullable=False)
    patient_id          = Column(Integer, ForeignKey("patients.id"),
                                 nullable=False)
    postnatal_visit_id  = Column(Integer,
                                 ForeignKey("postnatal_visits.id"),
                                 nullable=True)
    chw_id              = Column(Integer, ForeignKey("users.id"),
                                 nullable=True)
    alert_type          = Column(String, nullable=False)
    # below_3rd_percentile | growth_faltering |
    # weight_loss_excessive | failed_to_regain_birth_weight
    severity            = Column(String, nullable=False)
    # mild | moderate | severe
    age_weeks           = Column(Float, nullable=True)
    weight_kg           = Column(Float, nullable=True)
    percentile          = Column(Float, nullable=True)
    z_score             = Column(Float, nullable=True)
    message             = Column(String, nullable=True)
    whatsapp_sent       = Column(Boolean, default=False)
    resolved            = Column(Boolean, default=False)
    resolved_at         = Column(DateTime, nullable=True)
    created_at          = Column(DateTime, default=datetime.utcnow)

    newborn             = relationship("Newborn")
    patient             = relationship("Patient")
```

Add to `database.py` after the `MentalHealthScreening` model and
run migration:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('growth_alerts table created')
"
```

---

## 6. WHO Growth Reference Data

### Embedding the reference data

The WHO weight-for-age reference data is embedded directly in the
backend as a Python module — no external API call, no file read at
runtime, works fully offline. Create
`app/utils/who_growth_data.py`:

```python
"""
WHO Child Growth Standards — Weight-for-age
Source: WHO Multicentre Growth Reference Study (2006)
https://www.who.int/tools/child-growth-standards

Values represent weight in kg at each percentile for
each week of age (0-52 weeks).

Format:
BOYS_WFA[week] = {
    "P3": float,   # 3rd percentile
    "P15": float,  # 15th percentile
    "P50": float,  # 50th percentile (median)
    "P85": float,  # 85th percentile
    "P97": float,  # 97th percentile
    "SD0": float,  # mean (same as P50)
    "SD1": float,  # +1 SD
    "SD2": float,  # +2 SD (approximately P97.7)
    "SD_neg1": float,  # -1 SD
    "SD_neg2": float,  # -2 SD (approximately P2.3)
}
"""

# ── BOYS weight-for-age (kg), weeks 0-12 ──────────────────
BOYS_WFA = {
    0:  {"P3": 2.5,  "P15": 2.9,  "P50": 3.3,  "P85": 3.9,  "P97": 4.4},
    1:  {"P3": 2.9,  "P15": 3.3,  "P50": 3.9,  "P85": 4.5,  "P97": 5.1},
    2:  {"P3": 3.4,  "P15": 3.9,  "P50": 4.5,  "P85": 5.1,  "P97": 5.8},
    3:  {"P3": 3.7,  "P15": 4.2,  "P50": 4.9,  "P85": 5.6,  "P97": 6.3},
    4:  {"P3": 4.0,  "P15": 4.5,  "P50": 5.2,  "P85": 5.9,  "P97": 6.7},
    5:  {"P3": 4.2,  "P15": 4.8,  "P50": 5.5,  "P85": 6.3,  "P97": 7.1},
    6:  {"P3": 4.4,  "P15": 5.0,  "P50": 5.8,  "P85": 6.6,  "P97": 7.4},
    7:  {"P3": 4.6,  "P15": 5.2,  "P50": 6.0,  "P85": 6.8,  "P97": 7.7},
    8:  {"P3": 4.8,  "P15": 5.4,  "P50": 6.2,  "P85": 7.1,  "P97": 7.9},
    9:  {"P3": 4.9,  "P15": 5.5,  "P50": 6.4,  "P85": 7.3,  "P97": 8.2},
    10: {"P3": 5.0,  "P15": 5.7,  "P50": 6.5,  "P85": 7.5,  "P97": 8.4},
    11: {"P3": 5.1,  "P15": 5.8,  "P50": 6.7,  "P85": 7.6,  "P97": 8.6},
    12: {"P3": 5.3,  "P15": 6.0,  "P50": 6.9,  "P85": 7.8,  "P97": 8.8},
    13: {"P3": 5.4,  "P15": 6.1,  "P50": 7.0,  "P85": 8.0,  "P97": 9.0},
    14: {"P3": 5.5,  "P15": 6.2,  "P50": 7.2,  "P85": 8.1,  "P97": 9.2},
    15: {"P3": 5.6,  "P15": 6.3,  "P50": 7.3,  "P85": 8.3,  "P97": 9.3},
    16: {"P3": 5.7,  "P15": 6.4,  "P50": 7.4,  "P85": 8.4,  "P97": 9.5},
    17: {"P3": 5.8,  "P15": 6.5,  "P50": 7.5,  "P85": 8.6,  "P97": 9.6},
    18: {"P3": 5.8,  "P15": 6.6,  "P50": 7.6,  "P85": 8.7,  "P97": 9.8},
    19: {"P3": 5.9,  "P15": 6.7,  "P50": 7.7,  "P85": 8.8,  "P97": 9.9},
    20: {"P3": 6.0,  "P15": 6.8,  "P50": 7.8,  "P85": 8.9,  "P97": 10.0},
    21: {"P3": 6.1,  "P15": 6.9,  "P50": 7.9,  "P85": 9.0,  "P97": 10.1},
    22: {"P3": 6.1,  "P15": 6.9,  "P50": 8.0,  "P85": 9.1,  "P97": 10.2},
    23: {"P3": 6.2,  "P15": 7.0,  "P50": 8.1,  "P85": 9.2,  "P97": 10.3},
    24: {"P3": 6.3,  "P15": 7.1,  "P50": 8.1,  "P85": 9.3,  "P97": 10.4},
    26: {"P3": 6.4,  "P15": 7.2,  "P50": 8.3,  "P85": 9.4,  "P97": 10.6},
    28: {"P3": 6.6,  "P15": 7.4,  "P50": 8.5,  "P85": 9.6,  "P97": 10.8},
    30: {"P3": 6.7,  "P15": 7.5,  "P50": 8.7,  "P85": 9.8,  "P97": 11.0},
    32: {"P3": 6.8,  "P15": 7.7,  "P50": 8.8,  "P85": 10.0, "P97": 11.2},
    34: {"P3": 7.0,  "P15": 7.8,  "P50": 9.0,  "P85": 10.2, "P97": 11.4},
    36: {"P3": 7.1,  "P15": 8.0,  "P50": 9.2,  "P85": 10.4, "P97": 11.7},
    38: {"P3": 7.2,  "P15": 8.1,  "P50": 9.3,  "P85": 10.5, "P97": 11.8},
    40: {"P3": 7.4,  "P15": 8.2,  "P50": 9.5,  "P85": 10.7, "P97": 12.0},
    42: {"P3": 7.5,  "P15": 8.4,  "P50": 9.6,  "P85": 10.9, "P97": 12.2},
    44: {"P3": 7.6,  "P15": 8.5,  "P50": 9.7,  "P85": 11.0, "P97": 12.3},
    46: {"P3": 7.7,  "P15": 8.6,  "P50": 9.9,  "P85": 11.2, "P97": 12.5},
    48: {"P3": 7.8,  "P15": 8.7,  "P50": 10.0, "P85": 11.3, "P97": 12.6},
    50: {"P3": 7.9,  "P15": 8.9,  "P50": 10.1, "P85": 11.5, "P97": 12.8},
    52: {"P3": 8.1,  "P15": 9.0,  "P50": 10.2, "P85": 11.6, "P97": 13.0},
}

# ── GIRLS weight-for-age (kg), weeks 0-52 ─────────────────
GIRLS_WFA = {
    0:  {"P3": 2.4,  "P15": 2.8,  "P50": 3.2,  "P85": 3.7,  "P97": 4.2},
    1:  {"P3": 2.7,  "P15": 3.1,  "P50": 3.6,  "P85": 4.2,  "P97": 4.8},
    2:  {"P3": 3.2,  "P15": 3.6,  "P50": 4.2,  "P85": 4.8,  "P97": 5.5},
    3:  {"P3": 3.5,  "P15": 3.9,  "P50": 4.5,  "P85": 5.2,  "P97": 5.9},
    4:  {"P3": 3.7,  "P15": 4.2,  "P50": 4.8,  "P85": 5.6,  "P97": 6.4},
    5:  {"P3": 3.9,  "P15": 4.4,  "P50": 5.1,  "P85": 5.9,  "P97": 6.7},
    6:  {"P3": 4.1,  "P15": 4.7,  "P50": 5.4,  "P85": 6.2,  "P97": 7.1},
    7:  {"P3": 4.3,  "P15": 4.9,  "P50": 5.6,  "P85": 6.5,  "P97": 7.4},
    8:  {"P3": 4.5,  "P15": 5.1,  "P50": 5.8,  "P85": 6.7,  "P97": 7.7},
    9:  {"P3": 4.6,  "P15": 5.2,  "P50": 6.0,  "P85": 6.9,  "P97": 7.9},
    10: {"P3": 4.7,  "P15": 5.4,  "P50": 6.2,  "P85": 7.1,  "P97": 8.1},
    11: {"P3": 4.9,  "P15": 5.5,  "P50": 6.3,  "P85": 7.3,  "P97": 8.3},
    12: {"P3": 5.0,  "P15": 5.6,  "P50": 6.5,  "P85": 7.4,  "P97": 8.5},
    13: {"P3": 5.1,  "P15": 5.7,  "P50": 6.6,  "P85": 7.6,  "P97": 8.7},
    14: {"P3": 5.2,  "P15": 5.8,  "P50": 6.7,  "P85": 7.7,  "P97": 8.8},
    15: {"P3": 5.2,  "P15": 5.9,  "P50": 6.8,  "P85": 7.8,  "P97": 9.0},
    16: {"P3": 5.3,  "P15": 6.0,  "P50": 6.9,  "P85": 7.9,  "P97": 9.1},
    17: {"P3": 5.4,  "P15": 6.1,  "P50": 7.0,  "P85": 8.0,  "P97": 9.2},
    18: {"P3": 5.5,  "P15": 6.2,  "P50": 7.1,  "P85": 8.2,  "P97": 9.4},
    19: {"P3": 5.5,  "P15": 6.2,  "P50": 7.2,  "P85": 8.3,  "P97": 9.5},
    20: {"P3": 5.6,  "P15": 6.3,  "P50": 7.3,  "P85": 8.4,  "P97": 9.6},
    21: {"P3": 5.7,  "P15": 6.4,  "P50": 7.4,  "P85": 8.5,  "P97": 9.7},
    22: {"P3": 5.7,  "P15": 6.5,  "P50": 7.5,  "P85": 8.5,  "P97": 9.8},
    23: {"P3": 5.8,  "P15": 6.5,  "P50": 7.5,  "P85": 8.6,  "P97": 9.9},
    24: {"P3": 5.8,  "P15": 6.6,  "P50": 7.6,  "P85": 8.7,  "P97": 10.0},
    26: {"P3": 5.9,  "P15": 6.7,  "P50": 7.7,  "P85": 8.9,  "P97": 10.1},
    28: {"P3": 6.1,  "P15": 6.9,  "P50": 7.9,  "P85": 9.1,  "P97": 10.4},
    30: {"P3": 6.2,  "P15": 7.0,  "P50": 8.1,  "P85": 9.3,  "P97": 10.6},
    32: {"P3": 6.4,  "P15": 7.2,  "P50": 8.2,  "P85": 9.5,  "P97": 10.8},
    34: {"P3": 6.5,  "P15": 7.3,  "P50": 8.4,  "P85": 9.6,  "P97": 11.0},
    36: {"P3": 6.6,  "P15": 7.4,  "P50": 8.5,  "P85": 9.8,  "P97": 11.2},
    38: {"P3": 6.7,  "P15": 7.6,  "P50": 8.7,  "P85": 10.0, "P97": 11.4},
    40: {"P3": 6.9,  "P15": 7.7,  "P50": 8.9,  "P85": 10.2, "P97": 11.6},
    42: {"P3": 7.0,  "P15": 7.9,  "P50": 9.0,  "P85": 10.3, "P97": 11.8},
    44: {"P3": 7.1,  "P15": 8.0,  "P50": 9.2,  "P85": 10.5, "P97": 12.0},
    46: {"P3": 7.2,  "P15": 8.1,  "P50": 9.3,  "P85": 10.6, "P97": 12.1},
    48: {"P3": 7.3,  "P15": 8.2,  "P50": 9.4,  "P85": 10.8, "P97": 12.3},
    50: {"P3": 7.4,  "P15": 8.4,  "P50": 9.5,  "P85": 10.9, "P97": 12.4},
    52: {"P3": 7.5,  "P15": 8.5,  "P50": 9.7,  "P85": 11.0, "P97": 12.6},
}


def get_percentiles_for_age_sex(age_weeks: float, sex: str) -> dict:
    """
    Returns WHO percentile values for a given age (weeks) and sex.
    Interpolates linearly between available data points.
    sex: 'male' or 'female'
    """
    table = BOYS_WFA if sex == "male" else GIRLS_WFA
    age   = round(age_weeks)

    # Clamp to available range
    age = max(0, min(52, age))

    # Direct lookup
    if age in table:
        return table[age]

    # Linear interpolation between nearest available points
    lower_age = max(k for k in table.keys() if k <= age)
    upper_age = min(k for k in table.keys() if k >= age)

    if lower_age == upper_age:
        return table[lower_age]

    ratio  = (age - lower_age) / (upper_age - lower_age)
    lower  = table[lower_age]
    upper  = table[upper_age]

    return {
        p: round(lower[p] + ratio * (upper[p] - lower[p]), 2)
        for p in lower
    }


def classify_weight(weight_kg: float, age_weeks: float,
                    sex: str) -> dict:
    """
    Classify a weight measurement against WHO percentiles.
    Returns percentile estimate, classification, and z-score approximation.
    """
    percentiles = get_percentiles_for_age_sex(age_weeks, sex)

    p3   = percentiles["P3"]
    p15  = percentiles["P15"]
    p50  = percentiles["P50"]
    p85  = percentiles["P85"]
    p97  = percentiles["P97"]

    # Estimate approximate percentile rank
    if weight_kg < p3:
        pct_rank = round((weight_kg / p3) * 3, 1)
        classification = "severely_underweight"
        severity       = "severe"
    elif weight_kg < p15:
        pct_rank       = round(3 + ((weight_kg - p3) / (p15 - p3)) * 12, 1)
        classification = "underweight"
        severity       = "moderate"
    elif weight_kg <= p85:
        pct_rank       = round(15 + ((weight_kg - p15) / (p85 - p15)) * 70, 1)
        classification = "normal"
        severity       = "none"
    elif weight_kg <= p97:
        pct_rank       = round(85 + ((weight_kg - p85) / (p97 - p85)) * 12, 1)
        classification = "overweight"
        severity       = "mild"
    else:
        pct_rank       = min(99.9, round(97 + ((weight_kg - p97) / p97) * 2, 1))
        classification = "obese"
        severity       = "mild"

    # Approximate Z-score using P50 and P15/P85 as SD proxies
    sd_approx  = (p85 - p15) / 2.0
    z_score    = round((weight_kg - p50) / sd_approx, 2) if sd_approx else 0

    return {
        "weight_kg":      weight_kg,
        "age_weeks":      age_weeks,
        "sex":            sex,
        "percentile":     min(99.9, max(0.1, pct_rank)),
        "z_score":        z_score,
        "classification": classification,
        "severity":       severity,
        "p3":             p3,
        "p15":            p15,
        "p50":            p50,
        "p85":            p85,
        "p97":            p97,
        "needs_alert":    classification == "severely_underweight",
        "needs_monitoring": classification in ("underweight", "overweight"),
    }


def get_chart_reference_curves(sex: str,
                                max_weeks: int = 12) -> dict:
    """
    Returns WHO reference curves for plotting on a growth chart.
    Returns a dict of percentile name → list of (week, weight) points.
    """
    table = BOYS_WFA if sex == "male" else GIRLS_WFA
    weeks = sorted(k for k in table.keys() if k <= max_weeks)

    return {
        "P3":  [(w, table[w]["P3"])  for w in weeks],
        "P15": [(w, table[w]["P15"]) for w in weeks],
        "P50": [(w, table[w]["P50"]) for w in weeks],
        "P85": [(w, table[w]["P85"]) for w in weeks],
        "P97": [(w, table[w]["P97"]) for w in weeks],
    }
```

---

## 7. Alert Logic and Thresholds

### Alert types

| Alert type | Trigger condition | Severity | Action |
|-----------|------------------|----------|--------|
| `below_3rd_percentile` | Weight < P3 for age/sex | Severe | Immediate referral |
| `growth_faltering` | Percentile drop across 2 major lines | Moderate | Increase visit frequency |
| `weight_loss_excessive` | Loss > 10% from birth weight after day 14 | Moderate | Review feeding |
| `failed_to_regain_birth_weight` | Below birth weight at day 14+ | Moderate | Medical review |

### Major percentile lines

For growth faltering detection, the five major percentile lines are:
P97, P85, P50, P15, P3. A drop across two or more of these lines
between consecutive visits constitutes growth faltering.

```python
MAJOR_PERCENTILE_LINES = [3, 15, 50, 85, 97]

def count_percentile_lines_crossed(prev_pct: float,
                                    curr_pct: float) -> int:
    """
    Count how many major percentile lines were crossed downward
    between two measurements.
    """
    if curr_pct >= prev_pct:
        return 0  # Not a downward crossing
    count = 0
    for line in MAJOR_PERCENTILE_LINES:
        if prev_pct >= line > curr_pct:
            count += 1
    return count
```

### Alert deduplication

Only one alert per type per newborn per week is created. This
prevents the system from flooding the CHW with repeated alerts
for the same issue if multiple postnatal visits are recorded close
together.

---

## 8. API Reference

### Base URL
```
http://localhost:8000/api/v1
```

All endpoints require JWT authentication.

---

### `GET /growth/{newborn_id}`

Get all growth measurements for a newborn with WHO percentile
classifications.

**Response:**
```json
{
  "newborn_id":    1,
  "sex":           "female",
  "birth_weight":  3.1,
  "measurements": [
    {
      "visit_number":    1,
      "visit_date":      "2025-10-18",
      "age_weeks":       0.14,
      "weight_kg":       3.0,
      "percentile":      42.3,
      "z_score":         -0.19,
      "classification":  "normal",
      "severity":        "none",
      "weight_change_kg": -0.1,
      "is_initial_loss": true
    },
    {
      "visit_number":    2,
      "visit_date":      "2025-10-24",
      "age_weeks":       1.0,
      "weight_kg":       3.4,
      "percentile":      38.1,
      "z_score":         -0.30,
      "classification":  "normal",
      "severity":        "none",
      "weight_change_kg": 0.4
    },
    {
      "visit_number":    3,
      "visit_date":      "2025-11-28",
      "age_weeks":       6.0,
      "weight_kg":       4.8,
      "percentile":      31.2,
      "z_score":         -0.51,
      "classification":  "normal",
      "severity":        "none",
      "weight_change_kg": 1.4
    }
  ],
  "current_classification": "normal",
  "alerts":                 []
}
```

---

### `GET /growth/{newborn_id}/chart`

Returns data formatted for the growth chart — baby's actual
trajectory and WHO reference curves on the same axis.

**Response:**
```json
{
  "newborn_id":  1,
  "sex":         "female",
  "birth_weight": 3.1,
  "actual_data": [
    {"week": 0.14, "weight": 3.0, "classification": "normal"},
    {"week": 1.0,  "weight": 3.4, "classification": "normal"},
    {"week": 6.0,  "weight": 4.8, "classification": "normal"}
  ],
  "reference_curves": {
    "P3":  [[0, 2.4], [1, 2.7], [2, 3.2], [3, 3.5], [4, 3.7],
            [5, 3.9], [6, 4.1], [7, 4.3], [8, 4.5], [9, 4.6],
            [10, 4.7], [11, 4.9], [12, 5.0]],
    "P15": [[0, 2.8], [1, 3.1], ...],
    "P50": [[0, 3.2], [1, 3.6], ...],
    "P85": [[0, 3.7], [1, 4.2], ...],
    "P97": [[0, 4.2], [1, 4.8], ...]
  }
}
```

---

### `GET /growth/alerts`

Get all active growth alerts for the CHW's patients.

**Query params:**
- `resolved` (bool, default false) — include resolved alerts
- `severity` (string, optional) — filter by `mild`, `moderate`, `severe`

---

### `PATCH /growth/alerts/{alert_id}/resolve`

Mark a growth alert as resolved.

**Request body:**
```json
{
  "resolution_notes": "Patient referred to nutrition programme. Weight gaining."
}
```

---

### `GET /growth/analytics`

Growth monitoring statistics across the CHW's patient panel.

**Response:**
```json
{
  "total_newborns_monitored":    8,
  "currently_normal":            6,
  "currently_underweight":       1,
  "currently_severely_underweight": 1,
  "active_growth_alerts":        2,
  "exclusive_breastfeeding_rate": 72.5,
  "avg_weight_gain_per_week_g":  187.3
}
```

---

## 9. Backend Implementation

### File structure additions

```
backend/
  app/
    database.py              ← Add GrowthAlert model
    utils/
      who_growth_data.py     ← WHO percentile tables and functions
      growth_tracker.py      ← Alert detection and WhatsApp logic
    routers/
      growth.py              ← All growth tracking endpoints
    main.py                  ← Register growth router
```

### Step 1 — Growth tracker utility (`utils/growth_tracker.py`)

```python
from sqlalchemy.orm import Session
from datetime import datetime, date
from app.database import (PostnatalVisit, Newborn, Delivery,
                           Patient, User, GrowthAlert)
from app.utils.who_growth_data import classify_weight, count_percentile_lines_crossed
from app.utils.whatsapp import send_whatsapp
import asyncio
import logging

logger = logging.getLogger("mamasafe.growth")

def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def calculate_age_weeks(delivery_date_str: str,
                         visit_date_str: str) -> float:
    """Calculate age in weeks at time of visit."""
    delivery = datetime.strptime(delivery_date_str, "%Y-%m-%d").date()
    visit    = datetime.strptime(visit_date_str,    "%Y-%m-%d").date()
    days     = (visit - delivery).days
    return round(days / 7, 2)


def get_growth_measurements(db: Session, newborn_id: int) -> list:
    """
    Load all weight measurements for a newborn from postnatal visits.
    Returns list of dicts with weight, date, age, and WHO classification.
    """
    newborn = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    if not newborn:
        return []

    delivery = db.query(Delivery).filter(
        Delivery.id == newborn.delivery_id).first()
    if not delivery:
        return []

    visits = (
        db.query(PostnatalVisit)
          .filter(PostnatalVisit.newborn_id == newborn_id,
                  PostnatalVisit.newborn_weight_kg.isnot(None))
          .order_by(PostnatalVisit.visit_date.asc())
          .all()
    )

    measurements = []
    prev_weight    = newborn.birth_weight_kg
    prev_percentile = None

    for i, v in enumerate(visits):
        age_weeks    = calculate_age_weeks(delivery.delivery_date, v.visit_date)
        sex          = newborn.sex or "male"
        classification = classify_weight(v.newborn_weight_kg, age_weeks, sex)

        weight_change = round(v.newborn_weight_kg - prev_weight, 3) \
                        if prev_weight else None
        is_initial_loss = (age_weeks <= 2 and
                           weight_change is not None and
                           weight_change < 0)

        lines_crossed = 0
        if prev_percentile is not None:
            lines_crossed = count_percentile_lines_crossed(
                prev_percentile, classification["percentile"]
            )

        measurements.append({
            "visit_id":        v.id,
            "visit_number":    v.visit_number,
            "visit_date":      v.visit_date,
            "age_weeks":       age_weeks,
            "weight_kg":       v.newborn_weight_kg,
            "percentile":      classification["percentile"],
            "z_score":         classification["z_score"],
            "classification":  classification["classification"],
            "severity":        classification["severity"],
            "p3":              classification["p3"],
            "p15":             classification["p15"],
            "p50":             classification["p50"],
            "p85":             classification["p85"],
            "p97":             classification["p97"],
            "weight_change_kg": weight_change,
            "is_initial_loss": is_initial_loss,
            "lines_crossed":   lines_crossed,
            "needs_alert":     classification["needs_alert"],
        })

        prev_weight     = v.newborn_weight_kg
        prev_percentile = classification["percentile"]

    return measurements


def check_and_create_growth_alerts(
    db: Session,
    newborn_id: int,
    measurements: list,
    chw
):
    """
    After weight is recorded, check all alert conditions.
    Creates GrowthAlert records and sends WhatsApp to CHW.
    """
    if not measurements:
        return []

    newborn  = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    patient  = db.query(Patient).filter(
        Patient.id == newborn.patient_id).first() if newborn else None
    delivery = db.query(Delivery).filter(
        Delivery.id == newborn.delivery_id).first() if newborn else None

    latest     = measurements[-1]
    alerts_created = []

    # Alert 1 — Below 3rd percentile
    if latest["classification"] == "severely_underweight":
        existing = (
            db.query(GrowthAlert)
              .filter(GrowthAlert.newborn_id  == newborn_id,
                      GrowthAlert.alert_type  == "below_3rd_percentile",
                      GrowthAlert.resolved    == False)
              .first()
        )
        if not existing:
            alert = GrowthAlert(
                newborn_id         = newborn_id,
                patient_id         = newborn.patient_id,
                postnatal_visit_id = latest["visit_id"],
                chw_id             = chw.id if chw else None,
                alert_type         = "below_3rd_percentile",
                severity           = "severe",
                age_weeks          = latest["age_weeks"],
                weight_kg          = latest["weight_kg"],
                percentile         = latest["percentile"],
                z_score            = latest["z_score"],
                message            = (
                    f"Newborn weight {latest['weight_kg']}kg at "
                    f"{latest['age_weeks']:.1f} weeks is below the 3rd "
                    f"percentile ({latest['p3']}kg). Severe underweight. "
                    f"Immediate nutritional assessment required."
                ),
            )
            db.add(alert)
            db.commit()
            db.refresh(alert)
            alerts_created.append(alert)

            # Send WhatsApp
            _send_growth_alert_whatsapp(db, alert, patient, chw)

    # Alert 2 — Growth faltering (2+ percentile lines crossed down)
    if latest.get("lines_crossed", 0) >= 2:
        alert = GrowthAlert(
            newborn_id         = newborn_id,
            patient_id         = newborn.patient_id,
            postnatal_visit_id = latest["visit_id"],
            chw_id             = chw.id if chw else None,
            alert_type         = "growth_faltering",
            severity           = "moderate",
            age_weeks          = latest["age_weeks"],
            weight_kg          = latest["weight_kg"],
            percentile         = latest["percentile"],
            z_score            = latest["z_score"],
            message            = (
                f"Growth faltering detected: newborn crossed "
                f"{latest['lines_crossed']} WHO percentile lines "
                f"downward between visits. Current percentile: "
                f"{latest['percentile']:.1f}. Review feeding immediately."
            ),
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        alerts_created.append(alert)
        _send_growth_alert_whatsapp(db, alert, patient, chw)

    # Alert 3 — Failed to regain birth weight after 2 weeks
    if (delivery and newborn.birth_weight_kg and
            latest["age_weeks"] >= 2 and
            latest["weight_kg"] < newborn.birth_weight_kg and
            not latest["is_initial_loss"]):
        existing = (
            db.query(GrowthAlert)
              .filter(GrowthAlert.newborn_id == newborn_id,
                      GrowthAlert.alert_type == "failed_to_regain_birth_weight",
                      GrowthAlert.resolved   == False)
              .first()
        )
        if not existing:
            deficit = round(newborn.birth_weight_kg - latest["weight_kg"], 3)
            alert   = GrowthAlert(
                newborn_id         = newborn_id,
                patient_id         = newborn.patient_id,
                postnatal_visit_id = latest["visit_id"],
                chw_id             = chw.id if chw else None,
                alert_type         = "failed_to_regain_birth_weight",
                severity           = "moderate",
                age_weeks          = latest["age_weeks"],
                weight_kg          = latest["weight_kg"],
                message            = (
                    f"Newborn has not regained birth weight at "
                    f"{latest['age_weeks']:.1f} weeks. "
                    f"Current: {latest['weight_kg']}kg, "
                    f"birth: {newborn.birth_weight_kg}kg "
                    f"(deficit: {deficit}kg). Medical review required."
                ),
            )
            db.add(alert)
            db.commit()
            db.refresh(alert)
            alerts_created.append(alert)
            _send_growth_alert_whatsapp(db, alert, patient, chw)

    return alerts_created


def _send_growth_alert_whatsapp(db, alert, patient, chw):
    """Send WhatsApp alert to CHW for a growth alert."""
    chw_phone = getattr(chw, 'whatsapp_number', None) if chw else None
    if not chw_phone:
        return

    lang = getattr(patient, 'preferred_language', 'fr') or 'fr' \
           if patient else 'fr'

    from app.utils.whatsapp import build_growth_alert
    message = build_growth_alert(
        chw_name     = chw.full_name or chw.username if chw else "CHW",
        patient_name = patient.full_name if patient else "Patient",
        alert_type   = alert.alert_type,
        weight_kg    = alert.weight_kg,
        age_weeks    = alert.age_weeks,
        percentile   = alert.percentile,
        action       = alert.message,
        lang         = lang,
    )

    result = run_async(send_whatsapp(chw_phone, message))
    alert.whatsapp_sent = result.get("success", False)
    db.commit()
    logger.warning(
        f"Growth alert WhatsApp to CHW: "
        f"{'sent' if alert.whatsapp_sent else 'failed'} — "
        f"{alert.alert_type}"
    )
```

### Step 2 — Growth router (`routers/growth.py`)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date, timedelta

from app.database import (get_db, Newborn, Delivery, Patient,
                           PostnatalVisit, GrowthAlert)
from app.routers.auth import get_current_user
from app.utils.who_growth_data import (classify_weight,
                                        get_chart_reference_curves)
from app.utils.growth_tracker import (get_growth_measurements,
                                       check_and_create_growth_alerts,
                                       calculate_age_weeks)

router = APIRouter(prefix="/api/v1/growth", tags=["growth"])


@router.get("/{newborn_id}")
def get_growth_data(
    newborn_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    newborn = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    if not newborn:
        raise HTTPException(status_code=404, detail="Newborn not found")

    measurements = get_growth_measurements(db, newborn_id)
    active_alerts = (
        db.query(GrowthAlert)
          .filter(GrowthAlert.newborn_id == newborn_id,
                  GrowthAlert.resolved   == False)
          .all()
    )

    current_classification = (
        measurements[-1]["classification"]
        if measurements else "no_data"
    )

    return {
        "newborn_id":             newborn_id,
        "sex":                    newborn.sex,
        "birth_weight":           newborn.birth_weight_kg,
        "measurements":           measurements,
        "current_classification": current_classification,
        "alerts": [
            {
                "id":         a.id,
                "alert_type": a.alert_type,
                "severity":   a.severity,
                "message":    a.message,
                "date":       str(a.created_at.date()),
            }
            for a in active_alerts
        ],
    }


@router.get("/{newborn_id}/chart")
def get_growth_chart(
    newborn_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    newborn = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    if not newborn:
        raise HTTPException(status_code=404, detail="Newborn not found")

    measurements = get_growth_measurements(db, newborn_id)
    sex          = newborn.sex or "male"

    max_weeks = 12
    if measurements:
        max_weeks = max(12, int(measurements[-1]["age_weeks"]) + 2)

    reference_curves = get_chart_reference_curves(sex, max_weeks)

    actual_data = [
        {
            "week":           m["age_weeks"],
            "weight":         m["weight_kg"],
            "classification": m["classification"],
            "percentile":     m["percentile"],
        }
        for m in measurements
    ]

    return {
        "newborn_id":       newborn_id,
        "sex":              sex,
        "birth_weight":     newborn.birth_weight_kg,
        "actual_data":      actual_data,
        "reference_curves": reference_curves,
    }


@router.get("/alerts/list")
def get_growth_alerts(
    resolved: bool = False,
    severity: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = (db.query(GrowthAlert)
           .filter(GrowthAlert.chw_id   == current_user.id,
                   GrowthAlert.resolved == resolved))
    if severity:
        q = q.filter(GrowthAlert.severity == severity)

    alerts = q.order_by(GrowthAlert.created_at.desc()).all()
    result = []
    for a in alerts:
        patient = db.query(Patient).filter(
            Patient.id == a.patient_id).first()
        result.append({
            "id":           a.id,
            "patient_name": patient.full_name if patient else "Unknown",
            "alert_type":   a.alert_type,
            "severity":     a.severity,
            "age_weeks":    a.age_weeks,
            "weight_kg":    a.weight_kg,
            "percentile":   a.percentile,
            "message":      a.message,
            "whatsapp_sent": a.whatsapp_sent,
            "resolved":     a.resolved,
            "date":         str(a.created_at.date()),
        })
    return result


@router.patch("/alerts/{alert_id}/resolve")
def resolve_alert(
    alert_id: int,
    resolution_notes: str = "",
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    from datetime import datetime
    alert = db.query(GrowthAlert).filter(
        GrowthAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert.resolved    = True
    alert.resolved_at = datetime.utcnow()
    if resolution_notes:
        alert.message = f"{alert.message} | Resolution: {resolution_notes}"
    db.commit()
    return {"message": "Alert resolved", "alert_id": alert_id}


@router.get("/analytics/summary")
def growth_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    from app.database import User
    patient_ids = [
        p.id for p in db.query(Patient).filter(
            Patient.chw_id == current_user.id).all()
    ]

    newborns = (db.query(Newborn)
                  .filter(Newborn.patient_id.in_(patient_ids))
                  .all())
    total = len(newborns)

    if total == 0:
        return {
            "total_newborns_monitored":       0,
            "currently_normal":               0,
            "currently_underweight":          0,
            "currently_severely_underweight": 0,
            "active_growth_alerts":           0,
            "avg_weight_gain_per_week_g":     0,
            "exclusive_breastfeeding_rate":   0,
        }

    classifications = {
        "normal": 0, "underweight": 0,
        "severely_underweight": 0, "overweight": 0
    }
    weight_gains = []

    for nb in newborns:
        measurements = get_growth_measurements(db, nb.id)
        if measurements:
            cls = measurements[-1]["classification"]
            classifications[cls] = classifications.get(cls, 0) + 1
            if len(measurements) >= 2:
                for i in range(1, len(measurements)):
                    if (measurements[i]["weight_change_kg"] and
                            not measurements[i]["is_initial_loss"]):
                        weeks_between = (
                            measurements[i]["age_weeks"] -
                            measurements[i-1]["age_weeks"]
                        )
                        if weeks_between > 0:
                            gain_per_week = (
                                measurements[i]["weight_change_kg"] /
                                weeks_between * 1000  # to grams
                            )
                            weight_gains.append(gain_per_week)

    active_alerts = (
        db.query(GrowthAlert)
          .filter(GrowthAlert.chw_id  == current_user.id,
                  GrowthAlert.resolved == False)
          .count()
    )

    # Breastfeeding rate from latest postnatal visits
    newborn_ids = [nb.id for nb in newborns]
    bf_visits = (
        db.query(PostnatalVisit)
          .filter(PostnatalVisit.newborn_id.in_(newborn_ids),
                  PostnatalVisit.breastfeeding_status.isnot(None))
          .order_by(PostnatalVisit.visit_date.desc())
          .all()
    )
    seen = set()
    excl_bf = 0
    total_bf = 0
    for v in bf_visits:
        if v.newborn_id not in seen:
            seen.add(v.newborn_id)
            total_bf += 1
            if v.breastfeeding_status == "exclusive":
                excl_bf += 1

    return {
        "total_newborns_monitored":
            total,
        "currently_normal":
            classifications.get("normal", 0),
        "currently_underweight":
            classifications.get("underweight", 0),
        "currently_severely_underweight":
            classifications.get("severely_underweight", 0),
        "active_growth_alerts":
            active_alerts,
        "avg_weight_gain_per_week_g":
            round(sum(weight_gains) / len(weight_gains), 1)
            if weight_gains else 0,
        "exclusive_breastfeeding_rate":
            round(excl_bf / total_bf * 100, 1) if total_bf else 0,
    }
```

### Step 3 — WhatsApp template (add to `utils/whatsapp.py`)

```python
def build_growth_alert(chw_name: str, patient_name: str,
                        alert_type: str, weight_kg: float,
                        age_weeks: float, percentile: float,
                        action: str, lang: str = "fr") -> str:
    type_labels_fr = {
        "below_3rd_percentile":          "🔴 Poids sous le 3ème percentile",
        "growth_faltering":              "⚠️ Ralentissement de croissance",
        "failed_to_regain_birth_weight": "⚠️ Poids de naissance non récupéré",
        "weight_loss_excessive":         "⚠️ Perte de poids excessive",
    }
    type_labels_en = {
        "below_3rd_percentile":          "🔴 Weight below 3rd percentile",
        "growth_faltering":              "⚠️ Growth faltering detected",
        "failed_to_regain_birth_weight": "⚠️ Failed to regain birth weight",
        "weight_loss_excessive":         "⚠️ Excessive weight loss",
    }
    labels = type_labels_en if lang == "en" else type_labels_fr
    label  = labels.get(alert_type, "⚠️ Growth alert")

    if lang == "en":
        return (
            f"📊 *MamaSafe — Newborn Growth Alert*\n\n"
            f"Hello {chw_name},\n\n"
            f"*{label}*\n\n"
            f"Patient: *{patient_name}*\n"
            f"Age: {age_weeks:.1f} weeks\n"
            f"Weight: *{weight_kg} kg*\n"
            f"Percentile: {percentile:.1f}th\n\n"
            f"Action required:\n{action}\n\n"
            f"_MamaSafe_"
        )
    return (
        f"📊 *MamaSafe — Alerte croissance nourrisson*\n\n"
        f"Bonjour {chw_name},\n\n"
        f"*{label}*\n\n"
        f"Patiente : *{patient_name}*\n"
        f"Âge : {age_weeks:.1f} semaines\n"
        f"Poids : *{weight_kg} kg*\n"
        f"Percentile : {percentile:.1f}e\n\n"
        f"Action requise :\n{action}\n\n"
        f"_MamaSafe_"
    )
```

### Step 4 — Hook into postnatal visit recording

In `routers/postnatal.py`, after saving a postnatal visit with
weight data, trigger the growth alert check:

```python
# After visit is saved and committed, add:
if data.newborn_id and data.newborn_weight_kg:
    from app.utils.growth_tracker import (get_growth_measurements,
                                           check_and_create_growth_alerts)
    measurements = get_growth_measurements(db, data.newborn_id)
    growth_alerts = check_and_create_growth_alerts(
        db           = db,
        newborn_id   = data.newborn_id,
        measurements = measurements,
        chw          = current_user,
    )
    if growth_alerts:
        logger.warning(
            f"Growth alerts created for newborn {data.newborn_id}: "
            f"{[a.alert_type for a in growth_alerts]}"
        )
```

### Step 5 — Register in `main.py`

```python
from app.routers import (predict, assessments, auth, dashboard,
                          anc, referral, schedule, risk_trend,
                          postnatal, growth)

app.include_router(growth.router)
```

---

## 10. Web Frontend Implementation

### New components

| Component | Description |
|-----------|-------------|
| `GrowthChart.jsx` | Recharts line chart with actual trajectory + WHO curves |
| `GrowthStatus.jsx` | Current classification badge and measurement summary |
| `GrowthAlertCard.jsx` | Alert card for active growth concerns |

### Growth chart component (`GrowthChart.jsx`)

```jsx
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  Legend, ReferenceLine, ResponsiveContainer, Area, AreaChart
} from 'recharts';
import { useEffect, useState } from 'react';
import { getGrowthChart } from '../api/client';

const PERCENTILE_COLORS = {
  P3:  { stroke: '#EF4444', dash: '4 4',  label: '3rd percentile' },
  P15: { stroke: '#F59E0B', dash: '4 2',  label: '15th percentile' },
  P50: { stroke: '#22C55E', dash: '0',    label: '50th percentile (median)' },
  P85: { stroke: '#F59E0B', dash: '4 2',  label: '85th percentile' },
  P97: { stroke: '#EF4444', dash: '4 4',  label: '97th percentile' },
};

const CLASSIFICATION_COLORS = {
  normal:               '#22C55E',
  underweight:          '#F59E0B',
  severely_underweight: '#EF4444',
  overweight:           '#8B5CF6',
};

const CustomTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0]?.payload;
  if (!d) return null;
  return (
    <div className="bg-white border border-gray-200 rounded-xl
                    p-3 shadow-lg text-xs">
      <p className="font-bold text-gray-800 mb-1">
        Week {d.week?.toFixed(1)}
      </p>
      {payload.map((p, i) => (
        <p key={i} style={{ color: p.color }}>
          {p.name}: {typeof p.value === 'number' ? p.value.toFixed(2) : p.value} kg
        </p>
      ))}
      {d.classification && (
        <p className="mt-1 font-semibold"
           style={{ color: CLASSIFICATION_COLORS[d.classification] }}>
          {d.classification.replace(/_/g, ' ')}
        </p>
      )}
    </div>
  );
};

export default function GrowthChart({ newbornId, sex }) {
  const [chartData, setChartData] = useState(null);
  const [loading,   setLoading]   = useState(true);

  useEffect(() => {
    if (newbornId) {
      getGrowthChart(newbornId).then(setChartData).finally(
        () => setLoading(false));
    }
  }, [newbornId]);

  if (loading) return (
    <div className="bg-white rounded-2xl border border-gray-200
                    p-6 text-center text-gray-400 text-sm">
      Loading growth chart...
    </div>
  );

  if (!chartData) return null;

  // Build combined dataset for chart
  // Merge reference curves and actual data on week axis
  const allWeeks = new Set();
  Object.values(chartData.reference_curves).forEach(
    curve => curve.forEach(([w]) => allWeeks.add(w))
  );
  chartData.actual_data.forEach(d => allWeeks.add(d.week));

  const sortedWeeks = [...allWeeks].sort((a, b) => a - b);

  const refMap = {};
  Object.entries(chartData.reference_curves).forEach(([key, curve]) => {
    curve.forEach(([week, weight]) => {
      if (!refMap[week]) refMap[week] = { week };
      refMap[week][key] = weight;
    });
  });

  const actualMap = {};
  chartData.actual_data.forEach(d => {
    actualMap[d.week] = {
      baby_weight:    d.weight,
      classification: d.classification,
      percentile:     d.percentile,
    };
  });

  const combined = sortedWeeks.map(w => ({
    week: w,
    ...refMap[w],
    ...actualMap[w],
  }));

  const currentClassification = chartData.actual_data.at(-1)?.classification;
  const currentColor = CLASSIFICATION_COLORS[currentClassification] || '#6366F1';

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <div className="flex items-center justify-between mb-1">
        <h3 className="font-bold text-gray-800">Growth Chart</h3>
        <span className="text-xs text-gray-400">
          {sex === 'female' ? '♀ Girls' : '♂ Boys'} · WHO 2006
        </span>
      </div>

      {currentClassification && (
        <div className="mb-4">
          <span className="text-xs font-semibold px-2.5 py-1 rounded-full"
                style={{ color: currentColor,
                         background: currentColor + '18' }}>
            Current: {currentClassification.replace(/_/g, ' ')}
          </span>
        </div>
      )}

      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={combined}
                   margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
          <XAxis
            dataKey="week"
            label={{ value: 'Age (weeks)', position: 'insideBottom',
                     offset: -2, fontSize: 11 }}
            tick={{ fontSize: 10 }}
          />
          <YAxis
            label={{ value: 'Weight (kg)', angle: -90,
                     position: 'insideLeft', fontSize: 11 }}
            tick={{ fontSize: 10 }}
            domain={['auto', 'auto']}
          />
          <Tooltip content={<CustomTooltip />} />

          {/* WHO reference curves */}
          {Object.entries(PERCENTILE_COLORS).map(([key, cfg]) => (
            <Line
              key={key}
              type="monotone"
              dataKey={key}
              stroke={cfg.stroke}
              strokeWidth={1}
              strokeDasharray={cfg.dash}
              dot={false}
              name={cfg.label}
              connectNulls
              strokeOpacity={0.6}
            />
          ))}

          {/* Actual baby weight */}
          <Line
            type="monotone"
            dataKey="baby_weight"
            stroke="#6366F1"
            strokeWidth={2.5}
            dot={{ fill: '#6366F1', r: 5, strokeWidth: 2,
                   stroke: 'white' }}
            activeDot={{ r: 7 }}
            name="Baby weight"
            connectNulls
          />
        </LineChart>
      </ResponsiveContainer>

      <div className="mt-3 flex flex-wrap gap-3">
        {Object.entries(PERCENTILE_COLORS).map(([key, cfg]) => (
          <span key={key} className="flex items-center gap-1.5 text-xs text-gray-500">
            <span className="w-4 h-0.5 inline-block"
                  style={{ background: cfg.stroke,
                           borderTop: `2px dashed ${cfg.stroke}` }} />
            {key}
          </span>
        ))}
        <span className="flex items-center gap-1.5 text-xs text-gray-500">
          <span className="w-4 h-0.5 bg-indigo-500 inline-block" />
          Baby
        </span>
      </div>
    </div>
  );
}
```

### Growth status card (`GrowthStatus.jsx`)

```jsx
const CONFIG = {
  normal: {
    bg: 'bg-green-50', border: 'border-green-200',
    text: 'text-green-700', icon: '✅',
    label: 'Normal growth',
    desc: 'Weight is within the healthy WHO range for age.'
  },
  underweight: {
    bg: 'bg-amber-50', border: 'border-amber-200',
    text: 'text-amber-700', icon: '⚠️',
    label: 'Underweight',
    desc: 'Weight is below the 15th percentile. Monitor closely and review feeding.'
  },
  severely_underweight: {
    bg: 'bg-red-50', border: 'border-red-300',
    text: 'text-red-700', icon: '🚨',
    label: 'Severely underweight',
    desc: 'Weight is below the 3rd percentile. Immediate nutritional assessment required.'
  },
  overweight: {
    bg: 'bg-purple-50', border: 'border-purple-200',
    text: 'text-purple-700', icon: '📊',
    label: 'Overweight',
    desc: 'Weight is above the 97th percentile. Flag for clinical review.'
  },
  no_data: {
    bg: 'bg-gray-50', border: 'border-gray-200',
    text: 'text-gray-500', icon: '📋',
    label: 'No measurements yet',
    desc: 'Record the first postnatal visit to begin growth tracking.'
  },
};

export default function GrowthStatus({ classification, latestMeasurement,
                                        birthWeight }) {
  const cfg = CONFIG[classification] || CONFIG.no_data;

  return (
    <div className={`rounded-2xl border-2 p-4 ${cfg.bg} ${cfg.border}`}>
      <div className="flex items-start gap-3">
        <span className="text-2xl">{cfg.icon}</span>
        <div className="flex-1">
          <p className={`font-black text-sm ${cfg.text}`}>{cfg.label}</p>
          <p className={`text-xs mt-1 ${cfg.text} opacity-80`}>{cfg.desc}</p>
        </div>
      </div>
      {latestMeasurement && (
        <div className="mt-3 grid grid-cols-3 gap-2">
          <div className="bg-white bg-opacity-60 rounded-lg p-2 text-center">
            <p className="text-lg font-black text-gray-800">
              {latestMeasurement.weight_kg}kg
            </p>
            <p className="text-xs text-gray-500">Current</p>
          </div>
          <div className="bg-white bg-opacity-60 rounded-lg p-2 text-center">
            <p className="text-lg font-black text-gray-800">
              {latestMeasurement.percentile?.toFixed(1)}
            </p>
            <p className="text-xs text-gray-500">Percentile</p>
          </div>
          <div className="bg-white bg-opacity-60 rounded-lg p-2 text-center">
            <p className="text-lg font-black text-gray-800">
              {latestMeasurement.age_weeks?.toFixed(1)}w
            </p>
            <p className="text-xs text-gray-500">Age</p>
          </div>
        </div>
      )}
    </div>
  );
}
```

### API client additions

```javascript
// Growth tracker
export const getGrowthData = async (newbornId) => {
  const res = await client.get(`/api/v1/growth/${newbornId}`);
  return res.data;
};

export const getGrowthChart = async (newbornId) => {
  const res = await client.get(`/api/v1/growth/${newbornId}/chart`);
  return res.data;
};

export const getGrowthAlerts = async (resolved = false) => {
  const res = await client.get(
    `/api/v1/growth/alerts/list?resolved=${resolved}`);
  return res.data;
};

export const resolveGrowthAlert = async (alertId, notes) => {
  const res = await client.patch(
    `/api/v1/growth/alerts/${alertId}/resolve`,
    null,
    { params: { resolution_notes: notes } }
  );
  return res.data;
};

export const getGrowthAnalytics = async () => {
  const res = await client.get('/api/v1/growth/analytics/summary');
  return res.data;
};
```

---

## 11. Mobile Frontend Implementation (Expo)

### New screens

```
src/screens/
  GrowthChartScreen.js    ← Growth chart + WHO curves
  GrowthAlertsScreen.js   ← Active growth alerts list
```

### Growth chart screen (`GrowthChartScreen.js`)

```jsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, StyleSheet,
  TouchableOpacity, Dimensions
} from 'react-native';
import Svg, { Polyline, Circle, Line, Text as SvgText } from 'react-native-svg';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { getGrowthChart, getGrowthData } from '../utils/api';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const CHART_WIDTH  = SCREEN_WIDTH - 48;
const CHART_HEIGHT = 220;
const PAD          = { top: 10, right: 10, bottom: 30, left: 36 };

const PLOT_W = CHART_WIDTH  - PAD.left - PAD.right;
const PLOT_H = CHART_HEIGHT - PAD.top  - PAD.bottom;

const P_COLORS = {
  P3: '#EF4444', P15: '#F59E0B',
  P50: '#22C55E', P85: '#F59E0B', P97: '#EF4444'
};

const CLASSIFICATION_COLORS = {
  normal:               COLORS.success,
  underweight:          COLORS.warning,
  severely_underweight: COLORS.danger,
  overweight:           '#8B5CF6',
};

export default function GrowthChartScreen({ route }) {
  const { newbornId, patientName } = route.params;
  const [chartData,  setChartData]  = useState(null);
  const [growthData, setGrowthData] = useState(null);
  const [loading,    setLoading]    = useState(true);

  useEffect(() => {
    Promise.all([
      getGrowthChart(newbornId),
      getGrowthData(newbornId),
    ]).then(([chart, growth]) => {
      setChartData(chart);
      setGrowthData(growth);
    }).finally(() => setLoading(false));
  }, [newbornId]);

  if (loading || !chartData) {
    return (
      <View style={s.center}>
        <Text style={s.loadingText}>Loading growth data...</Text>
      </View>
    );
  }

  // Determine x/y scale from reference curves
  const allWeeks = chartData.reference_curves.P50.map(([w]) => w);
  const allWeights = [
    ...chartData.reference_curves.P97.map(([, w]) => w),
    ...chartData.actual_data.map(d => d.weight),
  ];

  const minWeek   = 0;
  const maxWeek   = Math.max(...allWeeks);
  const minWeight = Math.max(0, Math.min(...allWeights) - 0.5);
  const maxWeight = Math.max(...allWeights) + 0.5;

  const toX = (week)   =>
    PAD.left + ((week - minWeek) / (maxWeek - minWeek)) * PLOT_W;
  const toY = (weight) =>
    PAD.top  + PLOT_H - ((weight - minWeight) / (maxWeight - minWeight)) * PLOT_H;

  const curvePoints = (curveData) =>
    curveData.map(([w, wt]) => `${toX(w)},${toY(wt)}`).join(' ');

  const actualPoints = chartData.actual_data
    .map(d => `${toX(d.week)},${toY(d.weight)}`).join(' ');

  const classification = growthData?.current_classification || 'no_data';
  const statusColor    = CLASSIFICATION_COLORS[classification] || COLORS.textDim;

  return (
    <ScrollView style={s.root} contentContainerStyle={s.scroll}>
      <Text style={s.title}>{patientName}</Text>
      <Text style={s.subtitle}>Infant Growth Chart</Text>

      {/* Status badge */}
      <View style={[s.statusBadge, { backgroundColor: statusColor + '18',
                                      borderColor: statusColor }]}>
        <Text style={[s.statusText, { color: statusColor }]}>
          {classification.replace(/_/g, ' ').toUpperCase()}
        </Text>
      </View>

      {/* SVG Growth chart */}
      <View style={s.chartCard}>
        <Text style={s.chartTitle}>
          Weight-for-age · {chartData.sex === 'female' ? '♀ Girls' : '♂ Boys'}
          · WHO 2006
        </Text>
        <Svg width={CHART_WIDTH} height={CHART_HEIGHT}>
          {/* WHO reference curves */}
          {Object.entries(P_COLORS).map(([key, color]) => {
            const curve = chartData.reference_curves[key];
            if (!curve) return null;
            return (
              <Polyline
                key={key}
                points={curvePoints(curve)}
                fill="none"
                stroke={color}
                strokeWidth={1}
                strokeDasharray={key === 'P50' ? '' : '4 3'}
                strokeOpacity={0.7}
              />
            );
          })}

          {/* Actual baby weight line */}
          {chartData.actual_data.length > 1 && (
            <Polyline
              points={actualPoints}
              fill="none"
              stroke={COLORS.primary}
              strokeWidth={2.5}
            />
          )}

          {/* Actual data points */}
          {chartData.actual_data.map((d, i) => (
            <Circle
              key={i}
              cx={toX(d.week)}
              cy={toY(d.weight)}
              r={5}
              fill={CLASSIFICATION_COLORS[d.classification] || COLORS.primary}
              stroke="white"
              strokeWidth={1.5}
            />
          ))}

          {/* Y-axis labels */}
          {[minWeight, (minWeight + maxWeight) / 2, maxWeight].map((w, i) => (
            <SvgText
              key={i}
              x={PAD.left - 4}
              y={toY(w) + 4}
              fontSize="9"
              fill={COLORS.textMuted}
              textAnchor="end"
            >
              {w.toFixed(1)}
            </SvgText>
          ))}

          {/* X-axis labels */}
          {[0, 4, 8, 12].filter(w => w <= maxWeek).map((w, i) => (
            <SvgText
              key={i}
              x={toX(w)}
              y={CHART_HEIGHT - 6}
              fontSize="9"
              fill={COLORS.textMuted}
              textAnchor="middle"
            >
              {w}w
            </SvgText>
          ))}
        </Svg>

        {/* Legend */}
        <View style={s.legendRow}>
          {[['P3/P97', '#EF4444'], ['P15/P85', '#F59E0B'],
            ['P50', '#22C55E'], ['Baby', COLORS.primary]].map(([label, color]) => (
            <View key={label} style={s.legendItem}>
              <View style={[s.legendDot, { backgroundColor: color }]} />
              <Text style={s.legendText}>{label}</Text>
            </View>
          ))}
        </View>
      </View>

      {/* Measurements table */}
      {growthData?.measurements?.length > 0 && (
        <View style={s.tableCard}>
          <Text style={s.tableTitle}>Measurements</Text>
          <View style={s.tableHeader}>
            <Text style={[s.tableCell, s.tableHead]}>Visit</Text>
            <Text style={[s.tableCell, s.tableHead]}>Age</Text>
            <Text style={[s.tableCell, s.tableHead]}>Weight</Text>
            <Text style={[s.tableCell, s.tableHead]}>Percentile</Text>
          </View>
          {growthData.measurements.map((m, i) => {
            const clsColor = CLASSIFICATION_COLORS[m.classification]
                             || COLORS.textMuted;
            return (
              <View key={i} style={[s.tableRow,
                i % 2 === 0 && { backgroundColor: COLORS.surface2 }]}>
                <Text style={s.tableCell}>PNC {m.visit_number}</Text>
                <Text style={s.tableCell}>{m.age_weeks?.toFixed(1)}w</Text>
                <Text style={s.tableCell}>{m.weight_kg}kg</Text>
                <Text style={[s.tableCell, { color: clsColor, fontWeight: '700' }]}>
                  {m.percentile?.toFixed(1)}th
                </Text>
              </View>
            );
          })}
        </View>
      )}

      {/* Active alerts */}
      {growthData?.alerts?.length > 0 && (
        <View style={s.alertSection}>
          <Text style={s.tableTitle}>Active Alerts</Text>
          {growthData.alerts.map((a, i) => (
            <View key={i} style={[s.alertCard,
              a.severity === 'severe' ? s.alertSevere : s.alertModerate]}>
              <Text style={[s.alertTitle,
                { color: a.severity === 'severe'
                  ? '#991B1B' : '#92400E' }]}>
                {a.severity === 'severe' ? '🚨' : '⚠️'}{' '}
                {a.alert_type.replace(/_/g, ' ')}
              </Text>
              <Text style={s.alertMessage}>{a.message}</Text>
            </View>
          ))}
        </View>
      )}

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:          { flex: 1, backgroundColor: COLORS.bg },
  scroll:        { padding: 16 },
  center:        { flex: 1, alignItems: 'center', justifyContent: 'center' },
  loadingText:   { color: COLORS.textMuted, fontSize: FONT.sm },
  title:         { fontSize: FONT.xl, fontWeight: '700', color: COLORS.text },
  subtitle:      { fontSize: FONT.xs, color: COLORS.textMuted, marginBottom: 12 },
  statusBadge:   { alignSelf: 'flex-start', paddingHorizontal: 12, paddingVertical: 5, borderRadius: RADIUS.full, borderWidth: 1, marginBottom: 14 },
  statusText:    { fontSize: FONT.xs, fontWeight: '700' },
  chartCard:     { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: 12, marginBottom: 12 },
  chartTitle:    { fontSize: FONT.xs, color: COLORS.textMuted, marginBottom: 8 },
  legendRow:     { flexDirection: 'row', gap: 12, marginTop: 8, flexWrap: 'wrap' },
  legendItem:    { flexDirection: 'row', alignItems: 'center', gap: 4 },
  legendDot:     { width: 8, height: 8, borderRadius: 4 },
  legendText:    { fontSize: 10, color: COLORS.textMuted },
  tableCard:     { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, overflow: 'hidden', marginBottom: 12 },
  tableTitle:    { fontSize: FONT.md, fontWeight: '600', color: COLORS.text, padding: 12, paddingBottom: 8 },
  tableHeader:   { flexDirection: 'row', backgroundColor: COLORS.surface2, paddingVertical: 6, paddingHorizontal: 12 },
  tableRow:      { flexDirection: 'row', paddingVertical: 8, paddingHorizontal: 12 },
  tableCell:     { flex: 1, fontSize: FONT.xs, color: COLORS.text },
  tableHead:     { color: COLORS.textMuted, fontWeight: '600', textTransform: 'uppercase', fontSize: 10 },
  alertSection:  { marginBottom: 12 },
  alertCard:     { borderRadius: RADIUS.md, padding: 12, marginBottom: 8, borderWidth: 1 },
  alertSevere:   { backgroundColor: '#FEE2E2', borderColor: '#FCA5A5' },
  alertModerate: { backgroundColor: '#FEF3C7', borderColor: '#FCD34D' },
  alertTitle:    { fontSize: FONT.sm, fontWeight: '700', marginBottom: 4 },
  alertMessage:  { fontSize: FONT.xs, color: '#374151', lineHeight: 16 },
});
```

---

## 12. WhatsApp Growth Alerts

### When alerts fire

| Condition | Alert fires | Severity |
|-----------|------------|---------|
| Weight below P3 for age/sex | Immediately after postnatal visit saved | Severe |
| 2+ percentile lines crossed down | Immediately after postnatal visit saved | Moderate |
| Failed to regain birth weight at 2+ weeks | Immediately after postnatal visit saved | Moderate |

### Alert frequency control

Alerts of the same type for the same newborn are deduplicated —
if an active unresolved alert of type `below_3rd_percentile`
already exists for this newborn, no new alert is created until
the CHW marks the existing one as resolved. This prevents alert
fatigue while ensuring important signals are never missed.

### Alert resolution flow

1. CHW receives WhatsApp alert
2. CHW takes clinical action (refers patient, counsels on feeding, etc.)
3. CHW opens MamaSafe → Growth Alerts → finds the active alert
4. CHW taps "Mark resolved" and adds resolution notes
5. Alert is archived — visible in history but no longer active
6. If the same condition recurs at the next visit, a new alert fires

---

## 13. Testing Guide

### Postman test sequence

```
1.  POST /api/v1/deliveries             → creates delivery + newborn (birth_weight: 3.1, sex: female)
2.  POST /api/v1/postnatal-visits       → PNC 1, newborn_weight_kg: 2.9 (normal loss)
3.  GET  /api/v1/growth/1              → 1 measurement, classification: normal, percentile ~35
4.  POST /api/v1/postnatal-visits       → PNC 2, newborn_weight_kg: 3.5 (week 1 — good gain)
5.  GET  /api/v1/growth/1/chart        → actual_data has 2 points, reference curves present
6.  POST /api/v1/postnatal-visits       → PNC 3, newborn_weight_kg: 2.8 (severely underweight at 6 weeks)
    → GrowthAlert created: below_3rd_percentile
    → WhatsApp sent to CHW
7.  GET  /api/v1/growth/alerts/list    → 1 active alert, severity: severe
8.  PATCH /api/v1/growth/alerts/1/resolve?resolution_notes=Referred to nutrition centre
    → alert.resolved = true
9.  GET  /api/v1/growth/analytics/summary → total: 1, severe: 1, avg_gain: x g/week
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| GWT-01 | Record weight at PNC 1 — within normal range | `classification: normal`, no alert |
| GWT-02 | Record weight below P3 for age and sex | `classification: severely_underweight`, alert created, WhatsApp sent |
| GWT-03 | Weight below P3 alert already exists — record another below P3 visit | No duplicate alert created (deduplication) |
| GWT-04 | Percentile drops 2 major lines between PNC 2 and PNC 3 | `growth_faltering` alert created |
| GWT-05 | Weight below birth weight at 2+ weeks | `failed_to_regain_birth_weight` alert created |
| GWT-06 | Initial weight loss at day 1 (<10%) | No alert — classified as `is_initial_loss: true` |
| GWT-07 | Growth chart endpoint returns WHO reference curves | `reference_curves` has P3, P15, P50, P85, P97 arrays |
| GWT-08 | Growth chart for female newborn | Reference curves use `GIRLS_WFA` table |
| GWT-09 | Resolve a growth alert | `alert.resolved = true`, `resolved_at` timestamped |
| GWT-10 | Analytics after 1 severe + 1 normal newborn | `currently_severely_underweight: 1`, `currently_normal: 1` |
| GWT-11 | Average weight gain calculation | Returns value in g/week from measurements |
| GWT-12 | WHO interpolation at week 3 (between data points) | Returns interpolated values between week 2 and week 4 |

---

## 14. Report Integration

### Section 1.1 — Background (add)

> Cameroon's national stunting rate of 29% — rising to 40% in the
> northern regions — reflects a failure to detect and address growth
> faltering during the critical first 1,000 days of life. Community
> health workers conducting postnatal visits currently have no
> standardised growth monitoring tool, relying on paper charts that
> may be unavailable or misread. The MamaSafe infant growth tracker
> provides automated WHO-standardised growth assessment at every
> postnatal visit, detecting faltering before it becomes
> irreversible stunting.

### Section 1.4 — Research Objectives (add Specific Objective 11)

> To implement an infant growth tracking module that classifies
> newborn weight measurements against WHO 2006 Child Growth
> Standards weight-for-age percentiles, detects growth faltering
> and severe underweight automatically, generates visual growth
> charts for community health workers, and delivers immediate
> WhatsApp alerts when clinical thresholds are crossed.

### Section 2.3 — Empirical Framework (add sub-group)

**WHO Child Growth Standards and community growth monitoring:**
> The WHO 2006 Multicentre Growth Reference Study established
> weight-for-age standards based on a longitudinal cohort of
> children raised under optimal conditions across six countries.
> Black et al. (2013) demonstrated that stunting is largely
> irreversible after 24 months and that the postnatal period
> represents the highest-yield window for growth monitoring
> interventions. Victora et al. (2010) showed that exclusive
> breastfeeding in the first six months is the single most
> impactful protective factor against growth faltering in
> low-income settings. No digital health tool deployed in
> Cameroon integrates WHO growth monitoring with automated
> alerting at the community health worker level.

### Section 4.2.5 — Extended System Discussion

> The infant growth tracker represents the final module in
> MamaSafe's postnatal care chain. By embedding WHO 2006
> Child Growth Standards directly in the backend — eliminating
> any dependency on paper charts or internet connectivity —
> the system enables automated percentile classification at the
> point of care. The growth faltering detection algorithm, which
> monitors percentile crossing across consecutive visits rather
> than absolute weight thresholds alone, reflects current WHO
> guidance on growth monitoring methodology. The automatic
> WhatsApp alert on crossing below the 3rd percentile converts
> a passive recording system into an active safety net, ensuring
> that severe underweight cases identified in the community
> receive the same urgency as a high-risk antenatal prediction.

### Section 5.4 — Limitations (add)

> The WHO 2006 growth reference data embedded in the infant
> growth tracker covers weight-for-age for children aged 0-52
> weeks. The module does not include length-for-age or
> weight-for-length indicators — both of which are required
> for a full nutritional assessment — as these require
> measurement equipment (length boards) not universally
> available at community level in Cameroon.

### Section 5.5 — Suggestions for Further Research (add)

> Integration of length-for-age and weight-for-length indicators
> from the WHO 2006 standards into the growth tracker would
> enable full stunting and wasting classification at community
> level. A training programme equipping CHWs with lightweight
> length boards — combined with the MamaSafe growth tracker —
> would constitute a complete community-level nutrition
> surveillance system aligned with Cameroon's SND30 nutrition
> targets.

---

## 15. Future Extensions

| Feature | Description | Effort |
|---------|-------------|--------|
| Length-for-age charts | Add height/length measurement and stunting classification using WHO LAZ standards | Medium |
| Weight-for-length (wasting) | Full MUAC-equivalent classification for acute malnutrition | Medium |
| Nutrition programme integration | Automatically enroll severely underweight infants into therapeutic feeding programmes via referral | Medium |
| Growth velocity charts | Plot rate of weight gain per week rather than absolute weight — more sensitive early indicator | Low |
| Sibling growth comparison | Where a patient has multiple infants in the system, compare growth trajectories across siblings | Low |
| Community nutrition dashboard | District-level stunting and wasting prevalence map from aggregated anonymised growth data | High |

---

*End of document.*

**MamaSafe Infant Growth Tracker Documentation v1.0**  
*Prepared for the MamaSafe Final Year Project — YIBS Software Engineering*
