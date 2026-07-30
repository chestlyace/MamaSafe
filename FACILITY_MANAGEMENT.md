
# MamaSafe — Facility Management Dashboard
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Facility Management & CHW Performance Analytics  
**Stack:** FastAPI · PostgreSQL · React · Recharts · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [User Roles and Access Control](#2-user-roles-and-access-control)
3. [System Architecture](#3-system-architecture)
4. [What the Dashboard Shows](#4-what-the-dashboard-shows)
5. [Data Model](#5-data-model)
6. [API Reference](#6-api-reference)
7. [Backend Implementation](#7-backend-implementation)
8. [Web Frontend Implementation](#8-web-frontend-implementation)
9. [Mobile Frontend Implementation (Expo)](#9-mobile-frontend-implementation-expo)
10. [WhatsApp Supervisor Digest](#10-whatsapp-supervisor-digest)
11. [Testing Guide](#11-testing-guide)
12. [Report Integration](#12-report-integration)
13. [Future Extensions](#13-future-extensions)

---

## 1. Overview and Purpose

Every other MamaSafe module is designed for the community health
worker — the person in the field conducting antenatal visits,
recording deliveries, and submitting referrals. The Facility
Management Dashboard is designed for the person above them: the
district health supervisor, the facility in-charge, or the
regional health system planner who is responsible for the
performance of multiple CHWs across a district or health area.

Without a management layer, MamaSafe generates enormous amounts
of clinical and operational data with no way for supervisors to
see it in aggregate. A supervisor currently has to physically
visit each CHW, collect paper registers, and manually compile
statistics — a process that happens monthly at best and produces
data that is already weeks old by the time it reaches decision
makers.

The Facility Management Dashboard does five things:

**1. District-level patient and activity overview** — The
supervisor sees the total patient count, total assessments,
deliveries, and referrals across all CHWs in their district,
broken down by week and month.

**2. CHW performance monitoring** — Each CHW's activity is
summarised: how many patients registered, how many assessments
submitted, how many referrals made, when they last used the
system, and whether their referral completion rates are adequate.

**3. High-risk patient panel** — A cross-CHW list of all
patients currently classified as high risk, with their last
assessment date and the CHW responsible. This allows the
supervisor to follow up directly on cases that have not
been actioned.

**4. Facility and referral analytics** — Referral completion
rates by receiving facility, average time from referral to
patient arrival, and facilities with the highest referral loads.

**5. Ministry of Health reporting** — A one-tap export of
district-level maternal health indicators formatted for
monthly Ministry of Public Health reporting — eliminating
the manual paper reporting that currently consumes 4-8
hours of CHW and supervisor time per month.

---

## 2. User Roles and Access Control

### Three-tier role hierarchy

```
National Admin
  ↓ can see all districts
District Supervisor  (role: "supervisor")
  ↓ can see all CHWs in their district
Community Health Worker  (role: "chw")
  ↓ can see only their own patients
```

### Role definitions

| Role | Who | What they see |
|------|-----|---------------|
| `admin` | System administrator | All data, all districts, all CHWs |
| `supervisor` | District health supervisor | All CHWs and patients in their `district` |
| `chw` | Community health worker | Only their own patients and assessments |

### District assignment

Each user record has a `district` field. Supervisors see all
patients and CHWs where `User.district == supervisor.district`.
This means a supervisor in the Mfoundi district sees only Mfoundi
CHWs and their patients — never data from another district.

### Existing User model update

Add these fields to your User model in `database.py`:

```python
# Add to User class:
role             = Column(String, default="chw")
# chw | supervisor | admin
district         = Column(String, nullable=True)
region           = Column(String, nullable=True)
whatsapp_number  = Column(String, nullable=True)
full_name        = Column(String, nullable=True)
facility         = Column(String, nullable=True)
is_active        = Column(Boolean, default=True)
last_active      = Column(DateTime, nullable=True)
```

Run migration after adding fields:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('User fields updated')
"
```

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MamaSafe Platform                           │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────────────────────────┐  │
│  │  React Web   │───▶│          FastAPI Backend             │  │
│  │  Expo Mobile │    │                                      │  │
│  └──────────────┘    │  /api/v1/admin/dashboard             │  │
│       ↑              │  /api/v1/admin/chws                  │  │
│   Supervisor         │  /api/v1/admin/chws/{id}/stats       │  │
│   only UI            │  /api/v1/admin/high-risk-patients    │  │
│                      │  /api/v1/admin/referral-analytics    │  │
│                      │  /api/v1/admin/report/monthly        │  │
│                      │  /api/v1/admin/users (CRUD)          │  │
│                      │                                      │  │
│                      │  All endpoints gated by:             │  │
│                      │  role == "supervisor" OR "admin"     │  │
│                      └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data sources

The facility management dashboard is a **read-only aggregation
layer** — it does not create new data. It queries existing tables:

| Data | Source table |
|------|-------------|
| Patient counts | `patients` |
| Assessment counts and risk | `assessments` |
| ANC visit completion | `scheduled_visits` |
| Delivery and newborn data | `deliveries`, `newborns` |
| Referral tracking | `referrals` |
| PNC completion | `postnatal_scheduled_visits` |
| Growth alerts | `growth_alerts` |
| CHW activity | `users`, `assessments.created_at` |
| Mental health screens | `mental_health_screenings` |

---

## 4. What the Dashboard Shows

### Supervisor home screen

```
┌────────────────────────────────────────────────────┐
│  Mfoundi District Overview · July 2025             │
├──────────┬──────────┬──────────┬───────────────────┤
│ Patients │Assessments│Referrals │  High-risk active │
│    48    │    127   │    23    │        7          │
├──────────┴──────────┴──────────┴───────────────────┤
│  Weekly activity trend (bar chart)                 │
│  ████░░░░ This week vs last week                   │
├────────────────────────────────────────────────────┤
│  CHW Performance                                   │
│  ● Pauline Mba      12 patients  Last active: Today│
│  ● Jean Mballa       9 patients  Last active: 2d ago│
│  ● Marie Fotso       6 patients  Last active: 5d ago│
│    ⚠️ Inactive > 3 days                            │
├────────────────────────────────────────────────────┤
│  High-risk patients needing attention              │
│  🔴 Marie Ngono   SBP 140 / BS 15  CHW: Pauline   │
│  🔴 Anne Biya     SBP 135 / BS 12  CHW: Jean      │
├────────────────────────────────────────────────────┤
│  [Export Monthly Report]                           │
└────────────────────────────────────────────────────┘
```

### CHW detail screen (drilldown)

```
┌────────────────────────────────────────────────────┐
│  Pauline Mba · CS de Melen                        │
│  Last active: Today 08:42                         │
├──────────┬──────────┬──────────┬───────────────────┤
│ Patients │Assessments│Referrals │  Completion rate  │
│    12    │    34    │     8    │      87.5%        │
├────────────────────────────────────────────────────┤
│  Risk distribution                                 │
│  🟢 Low: 6    🟡 Mid: 4    🔴 High: 2            │
├────────────────────────────────────────────────────┤
│  ANC visit completion                              │
│  PNC1: 91%   PNC2: 75%   PNC3: 58%               │
├────────────────────────────────────────────────────┤
│  Weekly assessment trend (7 days chart)            │
├────────────────────────────────────────────────────┤
│  Patient list (tap to view)                        │
│  Marie Ngono  ●HIGH RISK  Last: 2 Jul              │
│  Rose Fonkam  ●LOW RISK   Last: 5 Jul              │
└────────────────────────────────────────────────────┘
```

---

## 5. Data Model

### No new tables required

The facility management dashboard requires zero new database
tables. It is a pure aggregation layer over existing data.
The only change is adding fields to the `User` model (done
in Section 2) and one small helper table for audit logging.

### Optional — `audit_logs` table

```python
class AuditLog(Base):
    __tablename__ = "audit_logs"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"), nullable=False)
    action      = Column(String, nullable=False)
    # user_created | user_deactivated | report_exported | chw_login
    target_type = Column(String, nullable=True)
    # user | patient | assessment
    target_id   = Column(Integer, nullable=True)
    ip_address  = Column(String, nullable=True)
    created_at  = Column(DateTime, default=datetime.utcnow)

    user        = relationship("User")
```

Add to `database.py` and run migration.

---

## 6. API Reference

### Base URL
```
http://localhost:8000/api/v1/admin
```

All endpoints in this section require role `supervisor` or `admin`.
Any CHW attempting to access these endpoints receives HTTP 403.

---

### `GET /admin/dashboard`

District-level summary for the supervisor's district.

**Response:**
```json
{
  "district":              "Mfoundi",
  "region":                "Centre",
  "total_chws":            5,
  "active_chws_today":     3,
  "total_patients":        48,
  "total_assessments":     127,
  "total_deliveries":      12,
  "total_referrals":       23,
  "referral_completion_rate": 78.3,
  "high_risk_active":      7,
  "mid_risk_active":       14,
  "low_risk_active":       27,
  "pnc1_completion_rate":  83.3,
  "phq2_positive_this_month": 2,
  "growth_alerts_active":  1,
  "this_week": {
    "assessments":  18,
    "referrals":     4,
    "deliveries":    2,
    "new_patients":  3
  },
  "last_week": {
    "assessments":  22,
    "referrals":     5,
    "deliveries":    1,
    "new_patients":  5
  }
}
```

---

### `GET /admin/chws`

List all CHWs in the supervisor's district with summary stats.

**Response:**
```json
[
  {
    "id":                1,
    "full_name":         "Pauline Mba",
    "username":          "pauline_mba",
    "facility":          "Centre de Santé de Melen",
    "district":          "Mfoundi",
    "is_active":         true,
    "last_active":       "2025-07-14T08:42:11",
    "days_since_active": 0,
    "patient_count":     12,
    "assessment_count":  34,
    "referral_count":    8,
    "high_risk_count":   2,
    "referral_completion_rate": 87.5,
    "status":            "active"
  },
  {
    "id":                2,
    "full_name":         "Jean Mballa",
    "days_since_active": 2,
    "patient_count":     9,
    "status":            "active"
  },
  {
    "id":                3,
    "full_name":         "Marie Fotso",
    "days_since_active": 5,
    "patient_count":     6,
    "status":            "inactive_warning"
  }
]
```

CHW status values:
- `active` — last active within 3 days
- `inactive_warning` — last active 3–7 days ago
- `inactive` — last active more than 7 days ago
- `never_active` — never logged in

---

### `GET /admin/chws/{chw_id}/stats`

Detailed performance statistics for a single CHW.

**Response:**
```json
{
  "chw_id":             1,
  "full_name":          "Pauline Mba",
  "facility":           "Centre de Santé de Melen",
  "last_active":        "2025-07-14T08:42:11",
  "patient_count":      12,
  "assessment_count":   34,
  "referral_count":     8,
  "referral_completion_rate": 87.5,
  "risk_distribution": {
    "low":  6,
    "mid":  4,
    "high": 2
  },
  "anc_completion": {
    "visit_1": 91.7,
    "visit_2": 75.0,
    "visit_3": 66.7,
    "visit_4": 50.0,
    "visit_5": 41.7,
    "visit_6": 25.0,
    "visit_7": 16.7,
    "visit_8": 8.3
  },
  "pnc_completion": {
    "pnc_1": 83.3,
    "pnc_2": 66.7,
    "pnc_3": 50.0
  },
  "weekly_activity": [
    {"week": "2025-07-07", "assessments": 5, "referrals": 1},
    {"week": "2025-06-30", "assessments": 8, "referrals": 2},
    {"week": "2025-06-23", "assessments": 6, "referrals": 1},
    {"week": "2025-06-16", "assessments": 4, "referrals": 0}
  ],
  "patients": [
    {
      "id":           1,
      "full_name":    "Marie Ngono",
      "risk_level":   "high risk",
      "last_assessment": "2025-07-02",
      "gestational_week": 28
    }
  ]
}
```

---

### `GET /admin/high-risk-patients`

All currently high-risk patients across the district, regardless
of which CHW they belong to.

**Query params:**
- `days_since_assessment` (int, default 7) — flag patients not
  assessed in this many days

**Response:**
```json
[
  {
    "patient_id":       1,
    "full_name":        "Marie Ngono",
    "age":              30,
    "facility":         "CS de Melen",
    "chw_name":         "Pauline Mba",
    "chw_id":           1,
    "risk_level":       "high risk",
    "confidence":       0.94,
    "last_assessment_date": "2025-07-02",
    "days_since_assessment": 12,
    "flagged":          true,
    "systolic_bp":      140,
    "blood_sugar":      15.0,
    "referral_made":    false
  }
]
```

---

### `GET /admin/referral-analytics`

District-level referral performance.

**Response:**
```json
{
  "total_referrals":          23,
  "sent":                      2,
  "received":                  3,
  "patient_arrived":           5,
  "completed":                18,
  "cancelled":                 1,
  "completion_rate":          78.3,
  "avg_hours_to_receipt":     2.4,
  "avg_hours_to_arrival":     5.1,
  "high_risk_referrals":      19,
  "by_facility": [
    {
      "facility_name": "Hôpital de District de Yaoundé Centre",
      "total":          12,
      "completed":       9,
      "completion_rate": 75.0
    }
  ],
  "by_chw": [
    {
      "chw_name":       "Pauline Mba",
      "total":           8,
      "completed":       7,
      "completion_rate": 87.5
    }
  ]
}
```

---

### `GET /admin/report/monthly`

Generate the monthly Ministry of Health report data.

**Query params:**
- `year` (int) — e.g., 2025
- `month` (int) — e.g., 7

**Response:** Full structured report object (see Section 7
for structure). Also available as CSV download via
`GET /admin/report/monthly/csv`.

---

### User Management

#### `GET /admin/users`
List all CHWs in the district.

#### `POST /admin/users`
Create a new CHW account. Admin/supervisor only.

#### `PATCH /admin/users/{user_id}`
Update a user's details (name, facility, district, phone,
WhatsApp number).

#### `PATCH /admin/users/{user_id}/deactivate`
Deactivate a CHW account without deleting their data.

#### `PATCH /admin/users/{user_id}/activate`
Reactivate a deactivated CHW account.

#### `POST /admin/users/{user_id}/reset-password`
Generate a temporary password for a CHW who has forgotten
their credentials. Admin/supervisor only.

---

## 7. Backend Implementation

### File structure additions

```
backend/
  app/
    database.py              ← Add AuditLog model, update User
    schemas_admin.py         ← Pydantic schemas for admin module
    routers/
      admin.py               ← All facility management endpoints
    main.py                  ← Register admin router
```

### Step 1 — Supervisor role guard (dependency)

Add this dependency function to use across all admin endpoints:

```python
# In routers/admin.py or a shared utils/auth.py

from fastapi import HTTPException, Depends
from app.routers.auth import get_current_user

def require_supervisor(current_user = Depends(get_current_user)):
    """Dependency — requires role supervisor or admin."""
    if current_user.role not in ("supervisor", "admin"):
        raise HTTPException(
            status_code=403,
            detail="Supervisor or admin access required"
        )
    return current_user
```

### Step 2 — Schemas (`schemas_admin.py`)

```python
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class CHWSummary(BaseModel):
    id:                       int
    full_name:                Optional[str]
    username:                 str
    facility:                 Optional[str]
    district:                 Optional[str]
    is_active:                bool
    last_active:              Optional[datetime]
    days_since_active:        Optional[int]
    patient_count:            int
    assessment_count:         int
    referral_count:           int
    high_risk_count:          int
    referral_completion_rate: float
    status:                   str
    class Config:
        from_attributes = True


class HighRiskPatient(BaseModel):
    patient_id:             int
    full_name:              str
    age:                    Optional[float]
    facility:               Optional[str]
    chw_name:               Optional[str]
    chw_id:                 Optional[int]
    risk_level:             str
    confidence:             Optional[float]
    last_assessment_date:   Optional[str]
    days_since_assessment:  Optional[int]
    flagged:                bool
    systolic_bp:            Optional[float]
    blood_sugar:            Optional[float]
    referral_made:          bool


class UserCreate(BaseModel):
    username:         str
    password:         str
    full_name:        Optional[str] = None
    facility:         Optional[str] = None
    district:         Optional[str] = None
    region:           Optional[str] = None
    whatsapp_number:  Optional[str] = None
    role:             str = "chw"


class UserUpdate(BaseModel):
    full_name:        Optional[str] = None
    facility:         Optional[str] = None
    district:         Optional[str] = None
    whatsapp_number:  Optional[str] = None
    is_active:        Optional[bool] = None


class MonthlyReport(BaseModel):
    district:                     str
    region:                       Optional[str]
    year:                         int
    month:                        int
    reporting_period:             str
    total_chws:                   int
    active_chws:                  int
    total_patients_registered:    int
    new_patients_this_month:      int
    total_assessments:            int
    high_risk_detected:           int
    mid_risk_detected:            int
    low_risk_detected:            int
    total_referrals:              int
    referral_completion_rate:     float
    total_deliveries:             int
    live_births:                  int
    stillbirths:                  int
    pnc1_completion_rate:         float
    pnc2_completion_rate:         float
    pnc3_completion_rate:         float
    phq2_screens_performed:       int
    phq2_positive_count:          int
    growth_alerts_generated:      int
    exclusive_breastfeeding_rate: float
    generated_at:                 datetime
```

### Step 3 — Admin router (`routers/admin.py`)

```python
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime, date, timedelta
import io
import csv

from app.database import (
    get_db, User, Patient, Assessment, Referral,
    Delivery, PostnatalScheduledVisit, ScheduledVisit,
    GrowthAlert, MentalHealthScreening, AuditLog
)
from app.schemas_admin import (
    CHWSummary, HighRiskPatient, UserCreate,
    UserUpdate, MonthlyReport
)
from app.routers.auth import get_current_user, hash_password
from app.utils.whatsapp import send_whatsapp

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def require_supervisor(current_user = Depends(get_current_user)):
    if current_user.role not in ("supervisor", "admin"):
        raise HTTPException(status_code=403,
                            detail="Supervisor or admin access required")
    return current_user


def get_district_chw_ids(db: Session, supervisor) -> List[int]:
    """Return IDs of all CHWs in the supervisor's district."""
    if supervisor.role == "admin":
        return [u.id for u in db.query(User.id)
                .filter(User.role == "chw").all()]
    return [u.id for u in db.query(User.id)
            .filter(User.role == "chw",
                    User.district == supervisor.district).all()]


def get_district_patient_ids(db: Session, chw_ids: List[int]) -> List[int]:
    return [p.id for p in db.query(Patient.id)
            .filter(Patient.chw_id.in_(chw_ids)).all()]


def chw_status(days_since: Optional[int]) -> str:
    if days_since is None: return "never_active"
    if days_since == 0:    return "active"
    if days_since <= 3:    return "active"
    if days_since <= 7:    return "inactive_warning"
    return "inactive"


# ── DASHBOARD ─────────────────────────────────────────────

@router.get("/dashboard")
def get_dashboard(
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)

    today      = date.today()
    week_start = today - timedelta(days=7)
    last_week  = today - timedelta(days=14)

    # Core counts
    total_patients    = len(patient_ids)
    total_assessments = (db.query(Assessment)
                           .filter(Assessment.patient_id.in_(patient_ids))
                           .count())
    total_deliveries  = (db.query(Delivery)
                           .filter(Delivery.patient_id.in_(patient_ids))
                           .count())
    total_referrals   = (db.query(Referral)
                           .filter(Referral.chw_id.in_(chw_ids))
                           .count())
    completed_refs    = (db.query(Referral)
                           .filter(Referral.chw_id.in_(chw_ids),
                                   Referral.status == "completed")
                           .count())

    # Risk distribution (latest assessment per patient)
    risk_counts = {"low risk": 0, "mid risk": 0, "high risk": 0}
    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc())
                    .first())
        if latest:
            risk_counts[latest.risk_level] = risk_counts.get(
                latest.risk_level, 0) + 1

    # Active CHWs today
    active_today = (db.query(User)
                      .filter(User.id.in_(chw_ids),
                              func.date(User.last_active) == today)
                      .count())

    # This week / last week comparison
    def week_stats(start, end):
        return {
            "assessments": (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids),
                                      func.date(Assessment.created_at) >= start,
                                      func.date(Assessment.created_at) <  end)
                              .count()),
            "referrals":   (db.query(Referral)
                              .filter(Referral.chw_id.in_(chw_ids),
                                      func.date(Referral.created_at) >= start,
                                      func.date(Referral.created_at) <  end)
                              .count()),
            "deliveries":  (db.query(Delivery)
                              .filter(Delivery.patient_id.in_(patient_ids),
                                      Delivery.delivery_date >= str(start),
                                      Delivery.delivery_date <  str(end))
                              .count()),
            "new_patients": (db.query(Patient)
                               .filter(Patient.chw_id.in_(chw_ids),
                                       func.date(Patient.created_at) >= start,
                                       func.date(Patient.created_at) <  end)
                               .count()),
        }

    # PNC completion
    delivery_ids = [d.id for d in db.query(Delivery.id)
                    .filter(Delivery.patient_id.in_(patient_ids)).all()]

    def pnc_rate(visit_num):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == visit_num)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == visit_num,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        return round(done / total * 100, 1) if total else 0

    phq2_positive = (db.query(MentalHealthScreening)
                       .filter(MentalHealthScreening.chw_id.in_(chw_ids),
                               func.date(MentalHealthScreening.created_at) >=
                               date(today.year, today.month, 1))
                       .count())

    growth_alerts = (db.query(GrowthAlert)
                       .filter(GrowthAlert.chw_id.in_(chw_ids),
                               GrowthAlert.resolved == False)
                       .count())

    return {
        "district":               supervisor.district or "All districts",
        "region":                 supervisor.region,
        "total_chws":             len(chw_ids),
        "active_chws_today":      active_today,
        "total_patients":         total_patients,
        "total_assessments":      total_assessments,
        "total_deliveries":       total_deliveries,
        "total_referrals":        total_referrals,
        "referral_completion_rate": round(
            completed_refs / total_referrals * 100, 1)
            if total_referrals else 0,
        "high_risk_active":       risk_counts.get("high risk", 0),
        "mid_risk_active":        risk_counts.get("mid risk", 0),
        "low_risk_active":        risk_counts.get("low risk", 0),
        "pnc1_completion_rate":   pnc_rate(1),
        "phq2_positive_this_month": phq2_positive,
        "growth_alerts_active":   growth_alerts,
        "this_week":              week_stats(week_start, today),
        "last_week":              week_stats(last_week, week_start),
    }


# ── CHW LIST ──────────────────────────────────────────────

@router.get("/chws")
def list_chws(
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    chws    = db.query(User).filter(User.id.in_(chw_ids)).all()
    result  = []

    for chw in chws:
        patient_ids = [p.id for p in db.query(Patient.id)
                       .filter(Patient.chw_id == chw.id).all()]

        days_since = None
        if chw.last_active:
            days_since = (date.today() - chw.last_active.date()).days

        assessment_count = (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids))
                              .count())
        referral_count   = (db.query(Referral)
                              .filter(Referral.chw_id == chw.id)
                              .count())
        completed_refs   = (db.query(Referral)
                              .filter(Referral.chw_id == chw.id,
                                      Referral.status == "completed")
                              .count())
        high_risk = 0
        for pid in patient_ids:
            latest = (db.query(Assessment)
                        .filter(Assessment.patient_id == pid)
                        .order_by(Assessment.created_at.desc())
                        .first())
            if latest and latest.risk_level == "high risk":
                high_risk += 1

        result.append({
            "id":                       chw.id,
            "full_name":                chw.full_name,
            "username":                 chw.username,
            "facility":                 chw.facility,
            "district":                 chw.district,
            "is_active":                chw.is_active,
            "last_active":              chw.last_active,
            "days_since_active":        days_since,
            "patient_count":            len(patient_ids),
            "assessment_count":         assessment_count,
            "referral_count":           referral_count,
            "high_risk_count":          high_risk,
            "referral_completion_rate": round(
                completed_refs / referral_count * 100, 1)
                if referral_count else 0,
            "status":                   chw_status(days_since),
        })

    result.sort(key=lambda x: x["days_since_active"] or 9999)
    return result


# ── CHW DETAIL STATS ──────────────────────────────────────

@router.get("/chws/{chw_id}/stats")
def chw_detail_stats(
    chw_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw = db.query(User).filter(User.id == chw_id).first()
    if not chw:
        raise HTTPException(status_code=404, detail="CHW not found")

    patient_ids  = [p.id for p in db.query(Patient.id)
                    .filter(Patient.chw_id == chw_id).all()]
    delivery_ids = [d.id for d in db.query(Delivery.id)
                    .filter(Delivery.patient_id.in_(patient_ids)).all()]

    # Risk distribution
    risk_dist = {"low": 0, "mid": 0, "high": 0}
    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc()).first())
        if latest:
            key = latest.risk_level.replace(" risk", "")
            risk_dist[key] = risk_dist.get(key, 0) + 1

    # ANC completion per visit number
    anc_completion = {}
    for vn in range(1, 9):
        total = (db.query(ScheduledVisit)
                   .join(Patient,
                         Patient.id == ScheduledVisit.pregnancy_id)
                   .filter(Patient.chw_id == chw_id,
                           ScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(ScheduledVisit)
                   .join(Patient,
                         Patient.id == ScheduledVisit.pregnancy_id)
                   .filter(Patient.chw_id == chw_id,
                           ScheduledVisit.visit_number == vn,
                           ScheduledVisit.status == "completed")
                   .count())
        anc_completion[f"visit_{vn}"] = round(
            done / total * 100, 1) if total else 0

    # PNC completion
    pnc_completion = {}
    for vn in range(1, 4):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        pnc_completion[f"pnc_{vn}"] = round(
            done / total * 100, 1) if total else 0

    # Weekly activity (last 4 weeks)
    weekly_activity = []
    for w in range(3, -1, -1):
        week_start = date.today() - timedelta(weeks=w+1)
        week_end   = date.today() - timedelta(weeks=w)
        weekly_activity.append({
            "week":        str(week_start),
            "assessments": (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids),
                                      func.date(Assessment.created_at) >= week_start,
                                      func.date(Assessment.created_at) <  week_end)
                              .count()),
            "referrals":   (db.query(Referral)
                              .filter(Referral.chw_id == chw_id,
                                      func.date(Referral.created_at) >= week_start,
                                      func.date(Referral.created_at) <  week_end)
                              .count()),
        })

    # Patient list
    patients = db.query(Patient).filter(Patient.chw_id == chw_id).all()
    patient_list = []
    for p in patients:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == p.id)
                    .order_by(Assessment.created_at.desc()).first())
        patient_list.append({
            "id":               p.id,
            "full_name":        p.full_name,
            "risk_level":       latest.risk_level if latest else None,
            "last_assessment":  str(latest.created_at.date()) if latest else None,
        })

    ref_count   = (db.query(Referral)
                     .filter(Referral.chw_id == chw_id).count())
    comp_refs   = (db.query(Referral)
                     .filter(Referral.chw_id == chw_id,
                             Referral.status == "completed").count())

    return {
        "chw_id":                     chw_id,
        "full_name":                  chw.full_name,
        "username":                   chw.username,
        "facility":                   chw.facility,
        "last_active":                chw.last_active,
        "patient_count":              len(patient_ids),
        "assessment_count":           (db.query(Assessment)
                                         .filter(Assessment.patient_id
                                                 .in_(patient_ids)).count()),
        "referral_count":             ref_count,
        "referral_completion_rate":   round(comp_refs / ref_count * 100, 1)
                                      if ref_count else 0,
        "risk_distribution":          risk_dist,
        "anc_completion":             anc_completion,
        "pnc_completion":             pnc_completion,
        "weekly_activity":            weekly_activity,
        "patients":                   patient_list,
    }


# ── HIGH-RISK PATIENTS ────────────────────────────────────

@router.get("/high-risk-patients")
def get_high_risk_patients(
    days_since_assessment: int = 7,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)
    result      = []

    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc()).first())
        if not latest or latest.risk_level != "high risk":
            continue

        patient = db.query(Patient).filter(Patient.id == pid).first()
        chw     = db.query(User).filter(
            User.id == patient.chw_id).first() if patient else None

        days_since = (date.today() - latest.created_at.date()).days

        referral_made = (db.query(Referral)
                           .filter(Referral.patient_id == pid,
                                   Referral.risk_level == "high risk")
                           .first()) is not None

        result.append({
            "patient_id":             pid,
            "full_name":              patient.full_name if patient else "Unknown",
            "age":                    latest.age,
            "facility":               patient.facility if patient else None,
            "chw_name":               chw.full_name if chw else None,
            "chw_id":                 patient.chw_id if patient else None,
            "risk_level":             "high risk",
            "confidence":             round(latest.prob_high or 0, 3),
            "last_assessment_date":   str(latest.created_at.date()),
            "days_since_assessment":  days_since,
            "flagged":                days_since >= days_since_assessment,
            "systolic_bp":            latest.systolic_bp,
            "blood_sugar":            latest.blood_sugar,
            "referral_made":          referral_made,
        })

    result.sort(key=lambda x: x["days_since_assessment"], reverse=True)
    return result


# ── REFERRAL ANALYTICS ────────────────────────────────────

@router.get("/referral-analytics")
def referral_analytics(
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    refs    = db.query(Referral).filter(Referral.chw_id.in_(chw_ids)).all()

    total     = len(refs)
    by_status = {}
    for r in refs:
        by_status[r.status] = by_status.get(r.status, 0) + 1

    # Average hours to receipt and arrival
    receipt_times = []
    arrival_times = []
    for r in refs:
        if r.received_at and r.created_at:
            receipt_times.append(
                (r.received_at - r.created_at).total_seconds() / 3600)
        if r.arrived_at and r.created_at:
            arrival_times.append(
                (r.arrived_at - r.created_at).total_seconds() / 3600)

    # By facility
    facility_map = {}
    for r in refs:
        fn = r.receiving_facility_name or "Unknown"
        if fn not in facility_map:
            facility_map[fn] = {"total": 0, "completed": 0}
        facility_map[fn]["total"] += 1
        if r.status == "completed":
            facility_map[fn]["completed"] += 1

    by_facility = [
        {
            "facility_name":    fn,
            "total":            d["total"],
            "completed":        d["completed"],
            "completion_rate":  round(d["completed"] / d["total"] * 100, 1)
                                if d["total"] else 0,
        }
        for fn, d in facility_map.items()
    ]
    by_facility.sort(key=lambda x: x["total"], reverse=True)

    # By CHW
    chw_map = {}
    for r in refs:
        if r.chw_id not in chw_map:
            chw_map[r.chw_id] = {"total": 0, "completed": 0}
        chw_map[r.chw_id]["total"] += 1
        if r.status == "completed":
            chw_map[r.chw_id]["completed"] += 1

    by_chw = []
    for chw_id, d in chw_map.items():
        chw = db.query(User).filter(User.id == chw_id).first()
        by_chw.append({
            "chw_name":       chw.full_name if chw else f"CHW #{chw_id}",
            "total":          d["total"],
            "completed":      d["completed"],
            "completion_rate": round(d["completed"] / d["total"] * 100, 1)
                               if d["total"] else 0,
        })
    by_chw.sort(key=lambda x: x["total"], reverse=True)

    completed = by_status.get("completed", 0)

    return {
        "total_referrals":       total,
        "sent":                  by_status.get("sent", 0),
        "received":              by_status.get("received", 0),
        "patient_arrived":       by_status.get("patient_arrived", 0),
        "completed":             completed,
        "cancelled":             by_status.get("cancelled", 0),
        "completion_rate":       round(completed / total * 100, 1)
                                 if total else 0,
        "avg_hours_to_receipt":  round(sum(receipt_times) /
                                       len(receipt_times), 1)
                                 if receipt_times else None,
        "avg_hours_to_arrival":  round(sum(arrival_times) /
                                       len(arrival_times), 1)
                                 if arrival_times else None,
        "high_risk_referrals":   sum(1 for r in refs
                                     if r.risk_level == "high risk"),
        "by_facility":           by_facility,
        "by_chw":                by_chw,
    }


# ── MONTHLY REPORT ────────────────────────────────────────

@router.get("/report/monthly")
def monthly_report(
    year:  int = Query(...),
    month: int = Query(...),
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    from calendar import monthrange
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)

    month_start = date(year, month, 1)
    month_end   = date(year, month, monthrange(year, month)[1])

    def in_month(col):
        return and_(func.date(col) >= month_start,
                    func.date(col) <= month_end)

    total_assessments = (db.query(Assessment)
                           .filter(Assessment.patient_id.in_(patient_ids),
                                   in_month(Assessment.created_at))
                           .count())

    risk_in_month = {"high risk": 0, "mid risk": 0, "low risk": 0}
    for a in (db.query(Assessment)
                .filter(Assessment.patient_id.in_(patient_ids),
                        in_month(Assessment.created_at)).all()):
        risk_in_month[a.risk_level] = risk_in_month.get(a.risk_level, 0) + 1

    total_referrals = (db.query(Referral)
                         .filter(Referral.chw_id.in_(chw_ids),
                                 in_month(Referral.created_at))
                         .count())
    completed_refs  = (db.query(Referral)
                         .filter(Referral.chw_id.in_(chw_ids),
                                 in_month(Referral.created_at),
                                 Referral.status == "completed")
                         .count())

    deliveries = (db.query(Delivery)
                    .filter(Delivery.patient_id.in_(patient_ids),
                            Delivery.delivery_date >= str(month_start),
                            Delivery.delivery_date <= str(month_end))
                    .all())
    live_births = sum(1 for d in deliveries if d.outcome == "live_birth")
    stillbirths = sum(1 for d in deliveries if d.outcome == "stillbirth")

    delivery_ids = [d.id for d in deliveries]

    def pnc_rate(vn):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        return round(done / total * 100, 1) if total else 0

    phq2_screens  = (db.query(MentalHealthScreening)
                       .filter(MentalHealthScreening.chw_id.in_(chw_ids),
                               in_month(MentalHealthScreening.created_at))
                       .count())
    phq2_positive = (db.query(MentalHealthScreening)
                       .filter(MentalHealthScreening.chw_id.in_(chw_ids),
                               in_month(MentalHealthScreening.created_at),
                               MentalHealthScreening.phq2_positive == True)
                       .count())

    growth_alerts = (db.query(GrowthAlert)
                       .filter(GrowthAlert.chw_id.in_(chw_ids),
                               in_month(GrowthAlert.created_at))
                       .count())

    # Exclusive breastfeeding
    from app.database import PostnatalVisit
    bf_visits = (db.query(PostnatalVisit)
                   .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                           PostnatalVisit.breastfeeding_status.isnot(None))
                   .all())
    excl_bf   = sum(1 for v in bf_visits
                    if v.breastfeeding_status == "exclusive")
    bf_rate   = round(excl_bf / len(bf_visits) * 100, 1) if bf_visits else 0

    new_patients = (db.query(Patient)
                      .filter(Patient.chw_id.in_(chw_ids),
                              in_month(Patient.created_at))
                      .count())

    active_chws = (db.query(User)
                     .filter(User.id.in_(chw_ids),
                             User.last_active >= datetime(year, month, 1))
                     .count())

    import calendar
    month_name = calendar.month_name[month]

    return {
        "district":                     supervisor.district or "All",
        "region":                       supervisor.region,
        "year":                         year,
        "month":                        month,
        "reporting_period":             f"{month_name} {year}",
        "total_chws":                   len(chw_ids),
        "active_chws":                  active_chws,
        "total_patients_registered":    len(patient_ids),
        "new_patients_this_month":      new_patients,
        "total_assessments":            total_assessments,
        "high_risk_detected":           risk_in_month.get("high risk", 0),
        "mid_risk_detected":            risk_in_month.get("mid risk", 0),
        "low_risk_detected":            risk_in_month.get("low risk", 0),
        "total_referrals":              total_referrals,
        "referral_completion_rate":     round(completed_refs /
                                              total_referrals * 100, 1)
                                        if total_referrals else 0,
        "total_deliveries":             len(deliveries),
        "live_births":                  live_births,
        "stillbirths":                  stillbirths,
        "pnc1_completion_rate":         pnc_rate(1),
        "pnc2_completion_rate":         pnc_rate(2),
        "pnc3_completion_rate":         pnc_rate(3),
        "phq2_screens_performed":       phq2_screens,
        "phq2_positive_count":          phq2_positive,
        "growth_alerts_generated":      growth_alerts,
        "exclusive_breastfeeding_rate": bf_rate,
        "generated_at":                 datetime.utcnow(),
    }


@router.get("/report/monthly/csv")
def monthly_report_csv(
    year:  int = Query(...),
    month: int = Query(...),
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    """Download monthly report as CSV."""
    report = monthly_report(year, month, db, supervisor)
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Indicator", "Value"])
    for key, value in report.items():
        if key != "generated_at":
            writer.writerow([
                key.replace("_", " ").title(),
                value
            ])
    output.seek(0)
    filename = f"MamaSafe_Report_{report['district']}_{year}_{month:02d}.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# ── USER MANAGEMENT ───────────────────────────────────────

@router.get("/users")
def list_users(
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    return db.query(User).filter(User.id.in_(chw_ids)).all()


@router.post("/users")
def create_chw(
    data: UserCreate,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    existing = db.query(User).filter(User.username == data.username).first()
    if existing:
        raise HTTPException(status_code=400,
                            detail="Username already exists")
    user = User(
        username        = data.username,
        hashed_password = hash_password(data.password),
        full_name       = data.full_name,
        facility        = data.facility,
        district        = data.district or supervisor.district,
        region          = data.region or supervisor.region,
        whatsapp_number = data.whatsapp_number,
        role            = "chw",
        must_change_password = True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    log = AuditLog(user_id=supervisor.id, action="user_created",
                   target_type="user", target_id=user.id)
    db.add(log)
    db.commit()

    return {"message": "CHW account created",
            "user_id": user.id,
            "username": user.username,
            "temporary_password": data.password}


@router.patch("/users/{user_id}")
def update_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    for field, value in data.dict(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    return {"message": "User updated"}


@router.patch("/users/{user_id}/deactivate")
def deactivate_user(
    user_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    log = AuditLog(user_id=supervisor.id, action="user_deactivated",
                   target_type="user", target_id=user_id)
    db.add(log)
    db.commit()
    return {"message": f"User {user.username} deactivated"}


@router.patch("/users/{user_id}/activate")
def activate_user(
    user_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = True
    db.commit()
    return {"message": f"User {user.username} activated"}
```

### Step 4 — Update `last_active` on login

In `routers/auth.py`, update the login endpoint to record the
timestamp:

```python
@router.post("/auth/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.username == form_data.username).first()
    if not user or not verify_password(
            form_data.password, user.hashed_password):
        raise HTTPException(status_code=401,
                            detail="Incorrect username or password")

    # Update last_active timestamp
    user.last_active = datetime.utcnow()
    db.commit()

    token = create_token({"sub": user.username, "role": user.role})
    return {"access_token": token, "token_type": "bearer"}
```

### Step 5 — Register in `main.py`

```python
from app.routers import (predict, assessments, auth, dashboard,
                          anc, referral, schedule, risk_trend,
                          postnatal, growth, admin)

app.include_router(admin.router)
```

---

## 8. Web Frontend Implementation

### New pages (supervisor only)

| Page | Route | Description |
|------|-------|-------------|
| Facility Dashboard | `/supervisor` | District overview with CHW list |
| CHW Detail | `/supervisor/chw/:id` | Single CHW performance drilldown |
| High-Risk Panel | `/supervisor/high-risk` | All high-risk patients across district |
| Referral Analytics | `/supervisor/referrals` | Referral performance charts |
| User Management | `/supervisor/users` | Create and manage CHW accounts |
| Monthly Report | `/supervisor/report` | Generate and download MoH report |

### Route guard (`SupervisorRoute.jsx`)

```jsx
import { Navigate } from 'react-router-dom';

export default function SupervisorRoute({ children }) {
  const token = localStorage.getItem('token');
  if (!token) return <Navigate to="/login" replace />;

  // Decode role from JWT payload
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    if (!['supervisor', 'admin'].includes(payload.role)) {
      return <Navigate to="/assess" replace />;
    }
  } catch {
    return <Navigate to="/login" replace />;
  }

  return children;
}
```

### Supervisor dashboard page (`SupervisorDashboard.jsx`)

```jsx
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts';
import Layout from '../components/Layout';
import {
  getAdminDashboard, getCHWList, getHighRiskPatients
} from '../api/client';

const STATUS_COLORS = {
  active:           'text-green-600  bg-green-50  border-green-200',
  inactive_warning: 'text-amber-600  bg-amber-50  border-amber-200',
  inactive:         'text-red-600    bg-red-50    border-red-200',
  never_active:     'text-gray-500   bg-gray-50   border-gray-200',
};

const RISK_COLORS = ['#EF4444', '#F59E0B', '#22C55E'];

export default function SupervisorDashboard() {
  const navigate  = useNavigate();
  const [dash,    setDash]    = useState(null);
  const [chws,    setCHWs]    = useState([]);
  const [hiRisk,  setHiRisk]  = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      getAdminDashboard(),
      getCHWList(),
      getHighRiskPatients(),
    ]).then(([d, c, h]) => {
      setDash(d); setCHWs(c); setHiRisk(h);
    }).finally(() => setLoading(false));
  }, []);

  if (loading || !dash) {
    return (
      <Layout>
        <div className="text-center py-20 text-gray-400">
          Loading district data...
        </div>
      </Layout>
    );
  }

  const statCards = [
    { label: 'Patients', value: dash.total_patients, icon: '👩' },
    { label: 'Assessments', value: dash.total_assessments, icon: '📋' },
    { label: 'Referrals', value: dash.total_referrals, icon: '🚑' },
    { label: 'High risk active', value: dash.high_risk_active, icon: '🔴' },
  ];

  const riskPie = [
    { name: 'High risk', value: dash.high_risk_active },
    { name: 'Mid risk',  value: dash.mid_risk_active  },
    { name: 'Low risk',  value: dash.low_risk_active  },
  ];

  const weeklyChart = [
    { name: 'Last week', ...dash.last_week },
    { name: 'This week', ...dash.this_week },
  ];

  return (
    <Layout>
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-2xl font-black text-gray-900">
            {dash.district} District
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            {dash.total_chws} CHWs · {dash.active_chws_today} active today
          </p>
        </div>

        {/* Stat cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
          {statCards.map(c => (
            <div key={c.label}
                 className="bg-white rounded-2xl border border-gray-200 p-4">
              <div className="text-2xl mb-1">{c.icon}</div>
              <div className="text-2xl font-black text-gray-900">
                {c.value}
              </div>
              <div className="text-xs text-gray-500 mt-0.5">{c.label}</div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          {/* Weekly comparison */}
          <div className="bg-white rounded-2xl border border-gray-200 p-5">
            <h3 className="font-bold text-gray-800 mb-4">
              This week vs last week
            </h3>
            <ResponsiveContainer width="100%" height={180}>
              <BarChart data={weeklyChart} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="assessments" fill="#6366F1" name="Assessments"
                     radius={[4,4,0,0]} />
                <Bar dataKey="referrals" fill="#F59E0B" name="Referrals"
                     radius={[4,4,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Risk distribution */}
          <div className="bg-white rounded-2xl border border-gray-200 p-5">
            <h3 className="font-bold text-gray-800 mb-4">Risk distribution</h3>
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
                <Pie data={riskPie} cx="50%" cy="50%"
                     innerRadius={50} outerRadius={80}
                     paddingAngle={3} dataKey="value">
                  {riskPie.map((_, i) => (
                    <Cell key={i} fill={RISK_COLORS[i]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* CHW list */}
        <div className="bg-white rounded-2xl border border-gray-200 p-5 mb-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-gray-800">CHW Performance</h3>
            <button
              onClick={() => navigate('/supervisor/users')}
              className="text-xs text-indigo-600 font-semibold
                         hover:underline"
            >
              Manage users →
            </button>
          </div>
          <div className="space-y-2">
            {chws.map(chw => {
              const sc = STATUS_COLORS[chw.status] || STATUS_COLORS.active;
              return (
                <div
                  key={chw.id}
                  onClick={() =>
                    navigate(`/supervisor/chw/${chw.id}`)
                  }
                  className="flex items-center gap-3 p-3 rounded-xl
                             hover:bg-gray-50 cursor-pointer border
                             border-transparent hover:border-gray-200
                             transition-all"
                >
                  <div className="w-9 h-9 rounded-full bg-indigo-100
                                  flex items-center justify-center
                                  text-indigo-600 font-bold text-sm
                                  flex-shrink-0">
                    {chw.full_name?.[0] || chw.username[0].toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-sm text-gray-800 truncate">
                      {chw.full_name || chw.username}
                    </p>
                    <p className="text-xs text-gray-400 truncate">
                      {chw.facility} · {chw.patient_count} patients
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <span className={`text-xs font-semibold px-2 py-0.5
                                     rounded-full border ${sc}`}>
                      {chw.status.replace('_', ' ')}
                    </span>
                    <p className="text-xs text-gray-400 mt-1">
                      {chw.referral_completion_rate}% refs
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* High-risk patients needing attention */}
        {hiRisk.filter(p => p.flagged).length > 0 && (
          <div className="bg-red-50 border border-red-200 rounded-2xl p-5 mb-4">
            <h3 className="font-bold text-red-700 mb-3">
              ⚠️ High-risk patients not assessed in {7}+ days
            </h3>
            <div className="space-y-2">
              {hiRisk.filter(p => p.flagged).slice(0, 5).map(p => (
                <div key={p.patient_id}
                     className="flex items-center justify-between
                                bg-white rounded-xl px-4 py-3 border
                                border-red-100">
                  <div>
                    <p className="font-semibold text-sm text-gray-900">
                      {p.full_name}
                    </p>
                    <p className="text-xs text-gray-500">
                      CHW: {p.chw_name} · Last assessed: {p.days_since_assessment}d ago
                    </p>
                  </div>
                  <div className="text-right text-xs text-red-600">
                    {p.systolic_bp && <p>SBP {p.systolic_bp}</p>}
                    {p.blood_sugar && <p>BS {p.blood_sugar}</p>}
                  </div>
                </div>
              ))}
            </div>
            <button
              onClick={() => navigate('/supervisor/high-risk')}
              className="mt-3 text-xs text-red-600 font-semibold
                         hover:underline"
            >
              View all high-risk patients →
            </button>
          </div>
        )}

        {/* Quick actions */}
        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={() => navigate('/supervisor/report')}
            className="bg-white border-2 border-indigo-200 rounded-2xl
                       p-4 text-left hover:border-indigo-400 transition"
          >
            <div className="text-2xl mb-1">📊</div>
            <p className="font-bold text-sm text-gray-800">Monthly Report</p>
            <p className="text-xs text-gray-500">
              Export MoH indicators
            </p>
          </button>
          <button
            onClick={() => navigate('/supervisor/referrals')}
            className="bg-white border-2 border-amber-200 rounded-2xl
                       p-4 text-left hover:border-amber-400 transition"
          >
            <div className="text-2xl mb-1">🚑</div>
            <p className="font-bold text-sm text-gray-800">
              Referral Analytics
            </p>
            <p className="text-xs text-gray-500">
              {dash.referral_completion_rate}% completion rate
            </p>
          </button>
        </div>
      </div>
    </Layout>
  );
}
```

### API client additions

```javascript
// Admin / Supervisor endpoints
export const getAdminDashboard = async () => {
  const res = await client.get('/api/v1/admin/dashboard');
  return res.data;
};

export const getCHWList = async () => {
  const res = await client.get('/api/v1/admin/chws');
  return res.data;
};

export const getCHWStats = async (chwId) => {
  const res = await client.get(`/api/v1/admin/chws/${chwId}/stats`);
  return res.data;
};

export const getHighRiskPatients = async (daysSince = 7) => {
  const res = await client.get(
    `/api/v1/admin/high-risk-patients?days_since_assessment=${daysSince}`);
  return res.data;
};

export const getAdminReferralAnalytics = async () => {
  const res = await client.get('/api/v1/admin/referral-analytics');
  return res.data;
};

export const getMonthlyReport = async (year, month) => {
  const res = await client.get(
    `/api/v1/admin/report/monthly?year=${year}&month=${month}`);
  return res.data;
};

export const downloadMonthlyReportCSV = (year, month) => {
  window.open(
    `${BASE_URL}/api/v1/admin/report/monthly/csv?year=${year}&month=${month}`,
    '_blank'
  );
};

export const createCHWUser = async (data) => {
  const res = await client.post('/api/v1/admin/users', data);
  return res.data;
};

export const deactivateCHW = async (userId) => {
  const res = await client.patch(`/api/v1/admin/users/${userId}/deactivate`);
  return res.data;
};
```

### Route registration

```jsx
import SupervisorRoute     from './components/SupervisorRoute';
import SupervisorDashboard from './pages/SupervisorDashboard';
import CHWDetailPage       from './pages/CHWDetailPage';
import HighRiskPage        from './pages/HighRiskPage';
import UserManagementPage  from './pages/UserManagementPage';
import MonthlyReportPage   from './pages/MonthlyReportPage';

// In <Routes>:
<Route path="/supervisor" element={
  <SupervisorRoute><SupervisorDashboard /></SupervisorRoute>
} />
<Route path="/supervisor/chw/:id" element={
  <SupervisorRoute><CHWDetailPage /></SupervisorRoute>
} />
<Route path="/supervisor/high-risk" element={
  <SupervisorRoute><HighRiskPage /></SupervisorRoute>
} />
<Route path="/supervisor/users" element={
  <SupervisorRoute><UserManagementPage /></SupervisorRoute>
} />
<Route path="/supervisor/report" element={
  <SupervisorRoute><MonthlyReportPage /></SupervisorRoute>
} />
```

---

## 9. Mobile Frontend Implementation (Expo)

### Supervisor tab (conditional on role)

The Expo app shows a **Supervisor** tab only when the logged-in
user has role `supervisor` or `admin`. Add role detection to
`App.js`:

```jsx
// Decode role from stored token
function getUserRole() {
  const token = AsyncStorage.getItem('token');
  if (!token) return null;
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.role;
  } catch { return 'chw'; }
}
```

```jsx
// In Tab.Navigator:
{['supervisor','admin'].includes(userRole) && (
  <Tab.Screen
    name="Supervisor"
    component={SupervisorScreen}
    options={{
      title: "District",
      tabBarIcon: ({ focused }) => (
        <TabIcon emoji="🏥" label="District" focused={focused} />
      ),
    }}
  />
)}
```

### Supervisor screen (`SupervisorScreen.js`)

```jsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  StyleSheet, RefreshControl
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { getAdminDashboard, getCHWList } from '../utils/api';

export default function SupervisorScreen() {
  const navigation = useNavigation();
  const [dash,      setDash]      = useState(null);
  const [chws,      setCHWs]      = useState([]);
  const [refreshing,setRefreshing] = useState(false);

  const load = async () => {
    const [d, c] = await Promise.all([getAdminDashboard(), getCHWList()]);
    setDash(d); setCHWs(c);
  };

  useEffect(() => { load(); }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  };

  if (!dash) return (
    <View style={s.center}>
      <Text style={s.loadingText}>Loading district data...</Text>
    </View>
  );

  const summaryStats = [
    { label: 'Patients',    value: dash.total_patients    },
    { label: 'Assessments', value: dash.total_assessments },
    { label: 'High risk',   value: dash.high_risk_active  },
    { label: 'Referrals',   value: dash.total_referrals   },
  ];

  return (
    <ScrollView
      style={s.root}
      contentContainerStyle={s.scroll}
      refreshControl={<RefreshControl refreshing={refreshing}
                                       onRefresh={onRefresh} />}
    >
      <Text style={s.title}>{dash.district}</Text>
      <Text style={s.subtitle}>
        {dash.total_chws} CHWs · {dash.active_chws_today} active today
      </Text>

      {/* Summary stats grid */}
      <View style={s.statsGrid}>
        {summaryStats.map(stat => (
          <View key={stat.label} style={s.statCard}>
            <Text style={s.statValue}>{stat.value}</Text>
            <Text style={s.statLabel}>{stat.label}</Text>
          </View>
        ))}
      </View>

      {/* Referral rate */}
      <View style={s.metricCard}>
        <Text style={s.metricLabel}>Referral completion rate</Text>
        <View style={s.progressRow}>
          <View style={s.progressBar}>
            <View style={[s.progressFill, {
              width: `${dash.referral_completion_rate}%`
            }]} />
          </View>
          <Text style={s.progressPct}>
            {dash.referral_completion_rate}%
          </Text>
        </View>
      </View>

      {/* CHW list */}
      <Text style={s.sectionTitle}>CHW Performance</Text>
      {chws.map(chw => {
        const isWarning = chw.status === 'inactive_warning';
        const isInactive = chw.status === 'inactive' ||
                           chw.status === 'never_active';
        return (
          <TouchableOpacity
            key={chw.id}
            style={s.chwCard}
            onPress={() =>
              navigation.navigate('CHWDetail', { chwId: chw.id,
                                                 chwName: chw.full_name })
            }
          >
            <View style={[s.chwAvatar,
              isInactive ? { backgroundColor: '#FEE2E2' }
              : isWarning ? { backgroundColor: '#FEF3C7' }
              : { backgroundColor: '#EEF2FF' }]}>
              <Text style={[s.chwAvatarText,
                isInactive ? { color: '#991B1B' }
                : isWarning ? { color: '#92400E' }
                : { color: '#4F46E5' }]}>
                {(chw.full_name || chw.username)[0].toUpperCase()}
              </Text>
            </View>
            <View style={s.chwInfo}>
              <Text style={s.chwName}>
                {chw.full_name || chw.username}
              </Text>
              <Text style={s.chwSub}>
                {chw.patient_count} patients ·{' '}
                {chw.days_since_active === 0
                  ? 'Active today'
                  : `${chw.days_since_active}d ago`}
              </Text>
            </View>
            <View style={s.chwStats}>
              {chw.high_risk_count > 0 && (
                <Text style={s.chwHighRisk}>
                  🔴 {chw.high_risk_count}
                </Text>
              )}
              <Text style={s.chwChevron}>›</Text>
            </View>
          </TouchableOpacity>
        );
      })}

      {/* Quick actions */}
      <Text style={[s.sectionTitle, { marginTop: 8 }]}>Quick Actions</Text>
      <View style={s.actionsGrid}>
        <TouchableOpacity
          style={s.actionCard}
          onPress={() => navigation.navigate('MonthlyReport')}
        >
          <Text style={s.actionIcon}>📊</Text>
          <Text style={s.actionLabel}>Monthly Report</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={s.actionCard}
          onPress={() => navigation.navigate('HighRiskPanel')}
        >
          <Text style={s.actionIcon}>🔴</Text>
          <Text style={s.actionLabel}>High-Risk Panel</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={s.actionCard}
          onPress={() => navigation.navigate('UserManagement')}
        >
          <Text style={s.actionIcon}>👥</Text>
          <Text style={s.actionLabel}>Manage CHWs</Text>
        </TouchableOpacity>
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:          { flex: 1, backgroundColor: COLORS.bg },
  scroll:        { padding: 16 },
  center:        { flex: 1, alignItems: 'center', justifyContent: 'center' },
  loadingText:   { color: COLORS.textMuted, fontSize: FONT.sm },
  title:         { fontSize: FONT.xxl, fontWeight: '700', color: COLORS.text },
  subtitle:      { fontSize: FONT.xs, color: COLORS.textMuted, marginBottom: 16 },
  statsGrid:     { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 12 },
  statCard:      { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 12, flex: 1, minWidth: '45%', alignItems: 'center' },
  statValue:     { fontSize: FONT.xxl, fontWeight: '800', color: COLORS.text },
  statLabel:     { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  metricCard:    { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 14, marginBottom: 16 },
  metricLabel:   { fontSize: FONT.sm, color: COLORS.textMuted, marginBottom: 8 },
  progressRow:   { flexDirection: 'row', alignItems: 'center', gap: 10 },
  progressBar:   { flex: 1, height: 8, backgroundColor: COLORS.surface2, borderRadius: 4, overflow: 'hidden' },
  progressFill:  { height: '100%', backgroundColor: COLORS.primary, borderRadius: 4 },
  progressPct:   { fontSize: FONT.sm, fontWeight: '700', color: COLORS.primary },
  sectionTitle:  { fontSize: FONT.md, fontWeight: '600', color: COLORS.text, marginBottom: 10 },
  chwCard:       { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 12, flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 8 },
  chwAvatar:     { width: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center', flexShrink: 0 },
  chwAvatarText: { fontSize: FONT.md, fontWeight: '700' },
  chwInfo:       { flex: 1 },
  chwName:       { fontSize: FONT.sm, fontWeight: '600', color: COLORS.text },
  chwSub:        { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  chwStats:      { flexDirection: 'row', alignItems: 'center', gap: 6 },
  chwHighRisk:   { fontSize: FONT.xs, fontWeight: '700', color: '#EF4444' },
  chwChevron:    { fontSize: 18, color: COLORS.textDim },
  actionsGrid:   { flexDirection: 'row', gap: 10 },
  actionCard:    { flex: 1, backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 14, alignItems: 'center' },
  actionIcon:    { fontSize: 24, marginBottom: 6 },
  actionLabel:   { fontSize: FONT.xs, color: COLORS.textMuted, textAlign: 'center', fontWeight: '500' },
});
```

---

## 10. WhatsApp Supervisor Digest

A weekly summary WhatsApp is sent to the district supervisor
every Monday at 08:00. Add this to the APScheduler setup in
`main.py`:

```python
from app.utils.supervisor_digest import job_send_supervisor_digest

scheduler.add_job(
    job_send_supervisor_digest,
    CronTrigger(day_of_week="mon", hour=8, minute=0),
    id="supervisor_digest",
    replace_existing=True,
)
```

Create `utils/supervisor_digest.py`:

```python
from sqlalchemy.orm import Session
from app.database import SessionLocal, User
from app.utils.whatsapp import send_whatsapp
import asyncio, logging
from datetime import date, timedelta

logger = logging.getLogger("mamasafe.supervisor_digest")

def run_async(coro):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try: return loop.run_until_complete(coro)
    finally: loop.close()

def job_send_supervisor_digest():
    db = SessionLocal()
    try:
        supervisors = db.query(User).filter(
            User.role == "supervisor",
            User.is_active == True,
            User.whatsapp_number.isnot(None)
        ).all()

        for supervisor in supervisors:
            # Import here to avoid circular imports
            from app.routers.admin import (get_district_chw_ids,
                                            get_district_patient_ids)
            chw_ids     = get_district_chw_ids(db, supervisor)
            patient_ids = get_district_patient_ids(db, chw_ids)

            from app.database import Assessment, Referral, GrowthAlert
            from sqlalchemy import func
            today      = date.today()
            week_ago   = today - timedelta(days=7)

            assessments_week = (db.query(Assessment)
                                  .filter(Assessment.patient_id.in_(patient_ids),
                                          func.date(Assessment.created_at) >= week_ago)
                                  .count())
            referrals_week   = (db.query(Referral)
                                  .filter(Referral.chw_id.in_(chw_ids),
                                          func.date(Referral.created_at) >= week_ago)
                                  .count())
            active_alerts    = (db.query(GrowthAlert)
                                  .filter(GrowthAlert.chw_id.in_(chw_ids),
                                          GrowthAlert.resolved == False)
                                  .count())

            # Count high-risk patients
            high_risk = 0
            for pid in patient_ids:
                latest = (db.query(Assessment)
                            .filter(Assessment.patient_id == pid)
                            .order_by(Assessment.created_at.desc()).first())
                if latest and latest.risk_level == "high risk":
                    high_risk += 1

            message = (
                f"📋 *MamaSafe — Weekly District Summary*\n"
                f"{supervisor.district} · {today.strftime('%d %B %Y')}\n\n"
                f"Last 7 days:\n"
                f"• Assessments: *{assessments_week}*\n"
                f"• Referrals:   *{referrals_week}*\n"
                f"• CHWs active: *{len(chw_ids)}*\n\n"
                f"Current status:\n"
                f"• High-risk patients: *{high_risk}*\n"
                f"• Growth alerts open: *{active_alerts}*\n\n"
                f"_Log in to MamaSafe for full details._"
            )

            result = run_async(send_whatsapp(supervisor.whatsapp_number,
                                              message))
            logger.info(
                f"Weekly digest to supervisor {supervisor.username}: "
                f"{'sent' if result['success'] else 'failed'}"
            )
    except Exception as e:
        logger.error(f"Supervisor digest job failed: {e}")
    finally:
        db.close()
```

---

## 11. Testing Guide

### Postman test sequence

```
1.  POST /api/v1/auth/register  (admin creates supervisor account, role: supervisor)
2.  POST /api/v1/auth/login     (login as supervisor)
3.  GET  /api/v1/admin/dashboard
    → district stats, CHW count, patient count, risk distribution
4.  GET  /api/v1/admin/chws
    → list of CHWs with patient counts and status
5.  GET  /api/v1/admin/chws/1/stats
    → full detail for CHW 1: risk dist, ANC completion, weekly chart
6.  GET  /api/v1/admin/high-risk-patients
    → all high-risk patients across district
7.  GET  /api/v1/admin/referral-analytics
    → completion rate, by facility, by CHW
8.  GET  /api/v1/admin/report/monthly?year=2025&month=7
    → full MoH report structure
9.  GET  /api/v1/admin/report/monthly/csv?year=2025&month=7
    → CSV download response
10. POST /api/v1/admin/users    (create new CHW account)
11. PATCH /api/v1/admin/users/2/deactivate
12. PATCH /api/v1/admin/users/2/activate
13. GET  /api/v1/admin/chws    (CHW 2 should show is_active: false then true)

--- CHW tries supervisor endpoint ---
14. GET  /api/v1/admin/dashboard (logged in as CHW)
    → HTTP 403 Forbidden
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| FM-01 | Supervisor accesses dashboard | `200` with district stats |
| FM-02 | CHW accesses admin dashboard | `403 Forbidden` |
| FM-03 | Supervisor sees only own district CHWs | CHWs from other districts not returned |
| FM-04 | CHW with no recent login appears as `inactive_warning` | `days_since_active >= 3`, `status: inactive_warning` |
| FM-05 | High-risk patient not assessed in 7+ days | `flagged: true` in high-risk patients list |
| FM-06 | Monthly report generates correct assessment count | Count matches assessments submitted in that month |
| FM-07 | CSV report download | Response has `Content-Disposition: attachment` header |
| FM-08 | Create new CHW account as supervisor | New user created with `role: chw`, `must_change_password: true` |
| FM-09 | Deactivate CHW | `is_active: false`, audit log created |
| FM-10 | Reactivate CHW | `is_active: true` |
| FM-11 | Referral analytics by facility | Correct completion rate per facility |
| FM-12 | Weekly digest job (manual trigger) | WhatsApp sent to supervisor |

---

## 12. Report Integration

### Section 1.4 — Research Objectives (add Specific Objective 12)

> To design and implement a facility management dashboard providing
> district health supervisors with real-time visibility into CHW
> performance, high-risk patient panels, referral completion analytics,
> and automated Ministry of Health monthly reporting — extending
> MamaSafe's value beyond individual CHWs to the health system
> planning level.

### Section 2.4 — Literature Gap (update Gap 5)

> The facility management dashboard addresses a governance gap
> absent from all existing maternal health technology reviewed:
> the need for a supervisor-facing analytics layer that aggregates
> CHW activity into district-level indicators compatible with
> national health information system reporting requirements.

### Section 3.6 — Model Specification (update architecture)

Add the three-tier role hierarchy diagram to Figure 3.1. Add all
`/api/v1/admin/*` endpoints to Table 3.2 with their role
restriction noted.

### Section 4.2.5 — Extended System Discussion

> The facility management dashboard elevates MamaSafe from a CHW
> tool to a health system tool. By providing district supervisors
> with real-time visibility into CHW activity, high-risk patient
> status, and referral completion rates, the dashboard addresses
> a critical accountability gap in Cameroon's community health
> worker supervision model. The one-tap CSV export of monthly
> Ministry of Health indicators represents a concrete reduction
> in administrative burden — eliminating the 4-8 hours per month
> currently spent on manual register compilation — and directly
> supports Cameroon's SND30 health information system objectives.

### Section 1.6 — Significance (update policy paragraph)

> The facility management dashboard and its monthly reporting
> export directly support Cameroon's National Development Strategy
> 2030 health sector goal of strengthening district-level health
> management information systems. The structured data produced
> aligns with Cameroon Ministry of Public Health reporting formats,
> making MamaSafe immediately compatible with existing health
> information workflows rather than requiring parallel reporting
> structures.

---

## 13. Future Extensions

| Feature | Description | Effort |
|---------|-------------|--------|
| DHIS2 integration | Auto-push monthly report data to Cameroon's national DHIS2 instance via API | High |
| Supervisor mobile alerts | Push notification to supervisor when a CHW has been inactive 5+ days | Low |
| Inter-district comparison | Regional dashboard comparing district performance (for regional health delegates) | Medium |
| CHW certification tracking | Track training dates, recertification requirements, and certification expiry | Low |
| Supply request management | CHW requests medical supplies (oxytocin, iron tablets) via MamaSafe; supervisor approves | Medium |
| Budget allocation support | District-level cost reporting for maternal health interventions to support MoH budgeting | High |
| National admin panel | Ministry-level view aggregating all districts with regional drill-down | High |

---

*End of document.*

