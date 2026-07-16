# Emergency Referral System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-tap emergency referral system that sends pre-populated patient summaries to receiving facilities via SMS, WhatsApp, and in-app notifications, with three-state status tracking.

**Architecture:** Lightweight referral entity (Option C) — new `referrals` and `facilities` tables that optionally link to existing assessments. Referral records are self-contained snapshots. Backend handles delivery via SMS/WhatsApp gateways. Mobile uses existing offline queue pattern.

**Tech Stack:** FastAPI + SQLAlchemy (backend), React + Tailwind (web), React Native + Expo + NativeWind (mobile), Zustand (state), i18next (i18n)

---

## File Structure

### Backend (new/modified)
| File | Action | Responsibility |
|------|--------|---------------|
| `backend/app/database.py` | Modify | Add Facility, Referral models |
| `backend/app/schemas_referral.py` | Create | Pydantic schemas for facilities + referrals |
| `backend/app/routers/facilities.py` | Create | Facility CRUD + approval endpoints |
| `backend/app/routers/referrals.py` | Create | Referral CRUD + quick endpoint + stats |
| `backend/app/services/delivery.py` | Create | SMS + WhatsApp delivery service |
| `backend/app/main.py` | Modify | Register new routers |

### Frontend (new/modified)
| File | Action | Responsibility |
|------|--------|---------------|
| `frontend/src/api/client.js` | Modify | Add facility + referral API functions |
| `frontend/src/components/FacilityPicker.jsx` | Create | Reusable facility dropdown |
| `frontend/src/components/ReferralCard.jsx` | Create | Referral list item component |
| `frontend/src/components/ReferralModal.jsx` | Create | Quick referral modal (one-tap) |
| `frontend/src/pages/ReferralListPage.jsx` | Create | Referral history + tracking |
| `frontend/src/pages/ReferralFormPage.jsx` | Create | Full referral form (manual) |
| `frontend/src/pages/FacilityListPage.jsx` | Create | Admin facility management |
| `frontend/src/pages/ResultPage.jsx` | Modify | Add emergency referral button |
| `frontend/src/pages/PatientDetailPage.jsx` | Modify | Add referral history tab |
| `frontend/src/pages/DashboardPage.jsx` | Modify | Add referral stats card |
| `frontend/src/components/NavBar.jsx` | Modify | Add Referrals link |
| `frontend/src/App.jsx` | Modify | Add new routes |
| `frontend/src/i18n/en.json` | Modify | Add English translations |
| `frontend/src/i18n/fr.json` | Modify | Add French translations |

### Mobile (new/modified)
| File | Action | Responsibility |
|------|--------|---------------|
| `mobile/types/index.ts` | Modify | Add Facility, Referral types |
| `mobile/services/api.ts` | Modify | Add facility + referral API functions |
| `mobile/stores/referralStore.ts` | Create | Referral state + offline queue |
| `mobile/components/FacilityPicker.tsx` | Create | Reusable facility picker |
| `mobile/components/ReferralCard.tsx` | Create | Referral list item |
| `mobile/app/(main)/refer.tsx` | Create | Referral list screen |
| `mobile/app/(main)/referral-form.tsx` | Create | Referral form screen |
| `mobile/app/(main)/result.tsx` | Modify | Add emergency referral button |
| `mobile/app/(main)/_layout.tsx` | Modify | Add Refer tab |
| `mobile/i18n/en.json` | Modify | Add English translations |
| `mobile/i18n/fr.json` | Modify | Add French translations |

---

## Task 1: Backend — Facility & Referral Database Models

**Files:**
- Modify: `backend/app/database.py`

- [ ] **Step 1: Add Facility model to database.py**

Add after the `User` class (around line 51):

```python
class Facility(Base):
    __tablename__ = "facilities"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String, nullable=False)
    level           = Column(String, nullable=False)  # health_post, health_center, district_hospital, regional_hospital, central_hospital
    phone           = Column(String, nullable=True)
    whatsapp        = Column(String, nullable=True)
    address         = Column(String, nullable=True)
    region          = Column(String, nullable=True)
    is_active       = Column(Boolean, default=True)
    suggested_by    = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved        = Column(Boolean, default=False)
    created_at      = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 2: Add Referral model to database.py**

Add after the `Facility` class:

```python
class Referral(Base):
    __tablename__ = "referrals"

    id                      = Column(Integer, primary_key=True, index=True)
    patient_id              = Column(Integer, ForeignKey("patients.id"), nullable=False)
    assessment_id           = Column(Integer, ForeignKey("assessments.id"), nullable=True)
    facility_id             = Column(Integer, ForeignKey("facilities.id"), nullable=False)
    facility_name           = Column(String, nullable=False)
    status                  = Column(String, default="SENT")  # SENT, RECEIVED, PATIENT_ARRIVED

    # Patient snapshot
    patient_name            = Column(String, nullable=False)
    patient_age             = Column(Integer, nullable=True)
    patient_phone           = Column(String, nullable=True)
    patient_blood_group     = Column(String, nullable=True)
    patient_allergies       = Column(String, nullable=True)
    emergency_contact_name  = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)

    # Pregnancy snapshot
    gravida                 = Column(Integer, nullable=True)
    parity                  = Column(Integer, nullable=True)
    edd_date                = Column(String, nullable=True)
    gestational_age         = Column(Integer, nullable=True)

    # Clinical snapshot
    systolic_bp             = Column(Float, nullable=True)
    diastolic_bp            = Column(Float, nullable=True)
    heart_rate              = Column(Integer, nullable=True)
    body_temp               = Column(Float, nullable=True)
    blood_sugar             = Column(Float, nullable=True)
    risk_level              = Column(String, nullable=True)
    risk_probability        = Column(Float, nullable=True)

    # Referral-specific
    complication_type       = Column(String, nullable=True)
    chw_notes               = Column(String, nullable=True)
    chw_id                  = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Timestamps
    sent_at                 = Column(DateTime, nullable=True)
    received_at             = Column(DateTime, nullable=True)
    patient_arrived_at      = Column(DateTime, nullable=True)
    created_at              = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 3: Verify models load without error**

Run: `cd /home/ace/Projects/MamaSafe/backend && python -c "from app.database import Facility, Referral; print('Models loaded OK')"`
Expected: `Models loaded OK`

- [ ] **Step 4: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/database.py && git commit -m "feat: add Facility and Referral models"
```

---

## Task 2: Backend — Referral Pydantic Schemas

**Files:**
- Create: `backend/app/schemas_referral.py`

- [ ] **Step 1: Create schemas_referral.py**

```python
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ── FACILITY ──────────────────────────────────────────────
class FacilityCreate(BaseModel):
    name:       str
    level:      str   # health_post, health_center, district_hospital, regional_hospital, central_hospital
    phone:      Optional[str] = None
    whatsapp:   Optional[str] = None
    address:    Optional[str] = None
    region:     Optional[str] = None

class FacilityOut(BaseModel):
    id:          int
    name:        str
    level:       str
    phone:       Optional[str]
    whatsapp:    Optional[str]
    address:     Optional[str]
    region:      Optional[str]
    is_active:   bool
    approved:    bool
    suggested_by: Optional[int]
    created_at:  datetime
    class Config:
        from_attributes = True


# ── REFERRAL ──────────────────────────────────────────────
class ReferralCreate(BaseModel):
    patient_id:         int
    assessment_id:      Optional[int] = None
    facility_id:        int
    complication_type:  Optional[str] = None
    chw_notes:          Optional[str] = None
    # Editable snapshot fields (optional overrides)
    systolic_bp:        Optional[float] = None
    diastolic_bp:       Optional[float] = None
    heart_rate:         Optional[int] = None
    body_temp:          Optional[float] = None
    blood_sugar:        Optional[float] = None
    gestational_age:    Optional[int] = None

class ReferralQuickCreate(BaseModel):
    assessment_id:      int
    facility_id:        int
    complication_type:  Optional[str] = None
    chw_notes:          Optional[str] = None

class ReferralOut(BaseModel):
    id:                      int
    patient_id:              int
    assessment_id:           Optional[int]
    facility_id:             int
    facility_name:           str
    status:                  str
    patient_name:            str
    patient_age:             Optional[int]
    patient_phone:           Optional[str]
    patient_blood_group:     Optional[str]
    patient_allergies:       Optional[str]
    emergency_contact_name:  Optional[str]
    emergency_contact_phone: Optional[str]
    gravida:                 Optional[int]
    parity:                  Optional[int]
    edd_date:                Optional[str]
    gestational_age:         Optional[int]
    systolic_bp:             Optional[float]
    diastolic_bp:            Optional[float]
    heart_rate:              Optional[int]
    body_temp:               Optional[float]
    blood_sugar:             Optional[float]
    risk_level:              Optional[str]
    risk_probability:        Optional[float]
    complication_type:       Optional[str]
    chw_notes:               Optional[str]
    chw_id:                  int
    sent_at:                 Optional[datetime]
    received_at:             Optional[datetime]
    patient_arrived_at:      Optional[datetime]
    created_at:              datetime
    class Config:
        from_attributes = True

class ReferralStatusUpdate(BaseModel):
    status: str = Field(..., pattern="^(RECEIVED|PATIENT_ARRIVED)$")

class ReferralStats(BaseModel):
    total_sent:          int
    total_received:      int
    total_arrived:       int
    completion_rate:     float
    avg_response_minutes: Optional[float]
    stale_count:         int
```

- [ ] **Step 2: Verify schema imports**

Run: `cd /home/ace/Projects/MamaSafe/backend && python -c "from app.schemas_referral import FacilityCreate, ReferralCreate, ReferralQuickCreate, ReferralOut, ReferralStats; print('Schemas OK')"`
Expected: `Schemas OK`

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/schemas_referral.py && git commit -m "feat: add facility and referral Pydantic schemas"
```

---

## Task 3: Backend — Facility Endpoints

**Files:**
- Create: `backend/app/routers/facilities.py`

- [ ] **Step 1: Create facilities.py router**

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db, Facility
from app.schemas_referral import FacilityCreate, FacilityOut
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["facilities"])


@router.get("/facilities", response_model=List[FacilityOut])
def list_facilities(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role == "admin":
        return db.query(Facility).filter(Facility.is_active == True).all()
    return db.query(Facility).filter(
        Facility.is_active == True, Facility.approved == True
    ).all()


@router.post("/facilities", response_model=FacilityOut)
def suggest_facility(
    data: FacilityCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    facility = Facility(**data.dict(), suggested_by=current_user.id, approved=False)
    db.add(facility)
    db.commit()
    db.refresh(facility)
    return facility


@router.post("/facilities/{facility_id}/approve", response_model=FacilityOut)
def approve_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.approved = True
    db.commit()
    db.refresh(facility)
    return facility


@router.patch("/facilities/{facility_id}", response_model=FacilityOut)
def update_facility(
    facility_id: int,
    data: FacilityCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    for field, value in data.dict(exclude_unset=True).items():
        setattr(facility, field, value)
    db.commit()
    db.refresh(facility)
    return facility


@router.delete("/facilities/{facility_id}")
def delete_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.is_active = False
    db.commit()
    return {"detail": "Facility deleted"}
```

- [ ] **Step 2: Verify router loads**

Run: `cd /home/ace/Projects/MamaSafe/backend && python -c "from app.routers.facilities import router; print(f'Facilities router: {len(router.routes)} routes')"`
Expected: `Facilities router: 5 routes`

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/routers/facilities.py && git commit -m "feat: add facility CRUD endpoints"
```

---

## Task 4: Backend — Referral Endpoints

**Files:**
- Create: `backend/app/routers/referrals.py`

- [ ] **Step 1: Create referrals.py router**

```python
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.database import get_db, Patient, Pregnancy, Assessment, Facility, Referral
from app.schemas_referral import (
    ReferralCreate, ReferralQuickCreate, ReferralOut, ReferralStatusUpdate, ReferralStats
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["referrals"])


def build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user):
    """Build the self-contained referral snapshot from patient/pregnancy/assessment data."""
    snapshot = {
        "patient_id": patient.id,
        "assessment_id": getattr(assessment, 'id', None) if assessment else None,
        "facility_id": facility.id,
        "facility_name": facility.name,
        "chw_id": current_user.id,
        "patient_name": patient.full_name,
        "patient_age": int(assessment.age) if assessment and assessment.age else None,
        "patient_phone": patient.phone,
        "patient_blood_group": patient.blood_group,
        "patient_allergies": patient.allergies,
        "emergency_contact_name": patient.emergency_contact_name,
        "emergency_contact_phone": patient.emergency_contact_phone,
        "gravida": pregnancy.gravida if pregnancy else None,
        "parity": pregnancy.parity if pregnancy else None,
        "edd_date": pregnancy.edd_date if pregnancy else None,
        "gestational_age": getattr(data, 'gestational_age', None),
        "systolic_bp": getattr(data, 'systolic_bp', None) or (assessment.systolic_bp if assessment else None),
        "diastolic_bp": getattr(data, 'diastolic_bp', None) or (assessment.diastolic_bp if assessment else None),
        "heart_rate": getattr(data, 'heart_rate', None) or (int(assessment.heart_rate) if assessment and assessment.heart_rate else None),
        "body_temp": getattr(data, 'body_temp', None) or (assessment.body_temp if assessment else None),
        "blood_sugar": getattr(data, 'blood_sugar', None) or (assessment.blood_sugar if assessment else None),
        "risk_level": assessment.risk_level if assessment else None,
        "risk_probability": assessment.prob_high if assessment else None,
        "complication_type": getattr(data, 'complication_type', None),
        "chw_notes": getattr(data, 'chw_notes', None),
        "sent_at": datetime.utcnow(),
        "status": "SENT",
    }
    return snapshot


@router.post("/referrals", response_model=ReferralOut)
def create_referral(
    data: ReferralCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    facility = db.query(Facility).filter(Facility.id == data.facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")

    assessment = None
    if data.assessment_id:
        assessment = db.query(Assessment).filter(Assessment.id == data.assessment_id).first()

    pregnancy = db.query(Pregnancy).filter(
        Pregnancy.patient_id == data.patient_id, Pregnancy.is_active == True
    ).first()

    snapshot = build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user)
    referral = Referral(**snapshot)
    db.add(referral)
    db.commit()
    db.refresh(referral)
    return referral


@router.post("/referrals/quick", response_model=ReferralOut)
def quick_referral(
    data: ReferralQuickCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    assessment = db.query(Assessment).filter(Assessment.id == data.assessment_id).first()
    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")

    facility = db.query(Facility).filter(Facility.id == data.facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")

    patient = None
    if assessment.patient_id:
        patient = db.query(Patient).filter(Patient.id == assessment.patient_id).first()

    pregnancy = None
    if patient:
        pregnancy = db.query(Pregnancy).filter(
            Pregnancy.patient_id == patient.id, Pregnancy.is_active == True
        ).first()

    if not patient:
        raise HTTPException(status_code=400, detail="Assessment has no linked patient. Use POST /referrals instead.")

    snapshot = build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user)
    referral = Referral(**snapshot)
    db.add(referral)
    db.commit()
    db.refresh(referral)
    return referral


@router.get("/referrals", response_model=List[ReferralOut])
def list_referrals(
    status: Optional[str] = None,
    facility_id: Optional[int] = None,
    patient_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = db.query(Referral)
    if current_user.role != "admin":
        q = q.filter(Referral.chw_id == current_user.id)
    if status:
        q = q.filter(Referral.status == status)
    if facility_id:
        q = q.filter(Referral.facility_id == facility_id)
    if patient_id:
        q = q.filter(Referral.patient_id == patient_id)
    return q.order_by(Referral.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/referrals/{referral_id}", response_model=ReferralOut)
def get_referral(
    referral_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    referral = db.query(Referral).filter(Referral.id == referral_id).first()
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")
    return referral


@router.patch("/referrals/{referral_id}/status", response_model=ReferralOut)
def update_referral_status(
    referral_id: int,
    data: ReferralStatusUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    referral = db.query(Referral).filter(Referral.id == referral_id).first()
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")

    referral.status = data.status
    now = datetime.utcnow()
    if data.status == "RECEIVED":
        referral.received_at = now
    elif data.status == "PATIENT_ARRIVED":
        referral.patient_arrived_at = now

    db.commit()
    db.refresh(referral)
    return referral


@router.get("/referrals/stats", response_model=ReferralStats)
def get_referral_stats(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = db.query(Referral)
    if current_user.role != "admin":
        q = q.filter(Referral.chw_id == current_user.id)

    total_sent = q.filter(Referral.status == "SENT").count()
    total_received = q.filter(Referral.status == "RECEIVED").count()
    total_arrived = q.filter(Referral.status == "PATIENT_ARRIVED").count()
    total_all = total_sent + total_received + total_arrived
    completion_rate = (total_arrived / total_all * 100) if total_all > 0 else 0.0

    # Avg response time (SENT -> RECEIVED) in minutes
    responded = q.filter(Referral.received_at.isnot(None)).all()
    avg_response_minutes = None
    if responded:
        deltas = [(r.received_at - r.sent_at).total_seconds() / 60 for r in responded if r.sent_at]
        avg_response_minutes = round(sum(deltas) / len(deltas), 1) if deltas else None

    # Stale: SENT for > 2 hours without status update
    from datetime import timedelta
    two_hours_ago = datetime.utcnow() - timedelta(hours=2)
    stale_count = q.filter(Referral.status == "SENT", Referral.sent_at < two_hours_ago).count()

    return ReferralStats(
        total_sent=total_sent,
        total_received=total_received,
        total_arrived=total_arrived,
        completion_rate=round(completion_rate, 1),
        avg_response_minutes=avg_response_minutes,
        stale_count=stale_count,
    )
```

- [ ] **Step 2: Verify router loads**

Run: `cd /home/ace/Projects/MamaSafe/backend && python -c "from app.routers.referrals import router; print(f'Referrals router: {len(router.routes)} routes')"`
Expected: `Referrals router: 7 routes`

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/routers/referrals.py && git commit -m "feat: add referral CRUD and quick-referral endpoints"
```

---

## Task 5: Backend — Delivery Service

**Files:**
- Create: `backend/app/services/delivery.py`

- [ ] **Step 1: Create delivery.py**

```python
"""SMS and WhatsApp delivery service for emergency referrals.

In production, integrate with:
- SMS: Africa's Talking, Twilio, or local Cameroon gateway
- WhatsApp: WhatsApp Business API (via Twilio or direct)

For now, this logs the messages. Replace send_sms/send_whatsapp
with actual gateway calls when API keys are configured.
"""

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def format_sms(referral) -> str:
    """Format a condensed SMS referral summary (≤160 chars per segment)."""
    name = referral.patient_name or "Unknown"
    age = referral.patient_age or "?"
    bp = f"{referral.systolic_bp:.0f}/{referral.diastolic_bp:.0f}" if referral.systolic_bp and referral.diastolic_bp else "?"
    hr = f"{referral.heart_rate}" if referral.heart_rate else "?"
    risk = (referral.risk_level or "UNKNOWN").upper()
    complication = referral.complication_type or "N/A"
    notes = (referral.chw_notes or "")[:60]

    msg = (
        f"[MamaSafe URGENT REFERRAL]\n"
        f"Patient: {name}, {age}y\n"
        f"BP: {bp} | HR: {hr}\n"
        f"Risk: {risk}\n"
        f"Complication: {complication}\n"
        f"Notes: {notes}"
    )
    return msg


def format_whatsapp(referral) -> str:
    """Format a rich WhatsApp referral summary."""
    name = referral.patient_name or "Unknown"
    age = referral.patient_age or "?"
    phone = referral.patient_phone or "N/A"
    blood = referral.patient_blood_group or "N/A"
    allergies = referral.patient_allergies or "None"
    gravida = referral.gravida or "?"
    parity = referral.parity or "?"
    edd = referral.edd_date or "N/A"
    ga = referral.gestational_age or "?"
    bp = f"{referral.systolic_bp:.0f}/{referral.diastolic_bp:.0f}" if referral.systolic_bp and referral.diastolic_bp else "N/A"
    hr = f"{referral.heart_rate}" if referral.heart_rate else "N/A"
    temp = f"{referral.body_temp:.1f}" if referral.body_temp else "N/A"
    sugar = f"{referral.blood_sugar:.1f}" if referral.blood_sugar else "N/A"
    risk = (referral.risk_level or "UNKNOWN").upper()
    prob = f"{(referral.risk_probability or 0) * 100:.0f}%" if referral.risk_probability else "N/A"
    complication = referral.complication_type or "N/A"
    notes = referral.chw_notes or "None"
    facility = referral.facility_name or "N/A"
    sent = referral.sent_at.strftime("%d %b %Y, %H:%M") if referral.sent_at else "N/A"

    msg = (
        f"\U0001f6a8 *MAMASAFE URGENT REFERRAL*\n\n"
        f"\U0001f464 *Patient:* {name}, {age} years\n"
        f"\U0001f4de *Phone:* {phone}\n"
        f"\U0001fa78 *Blood Group:* {blood}\n"
        f"\u2695\ufe0f *Allergies:* {allergies}\n\n"
        f"\U0001f930 *Pregnancy:* G{gravida}P{parity}, EDD: {edd}\n"
        f"\U0001f4ca *Gestational Age:* {ga} weeks\n\n"
        f"\U0001f493 *Vitals:*\n"
        f"  BP: {bp} mmHg\n"
        f"  HR: {hr} bpm\n"
        f"  Temp: {temp} \u00b0C\n"
        f"  Blood Sugar: {sugar} mmol/L\n\n"
        f"\u26a0\ufe0f *Risk Level:* {risk} ({prob} confidence)\n"
        f"\U0001f534 *Complication:* {complication}\n\n"
        f"\U0001f4dd *CHW Notes:* {notes}\n\n"
        f"\U0001f4cd *Referred to:* {facility}\n"
        f"\U0001f551 *Sent:* {sent}"
    )
    return msg


def send_sms(phone_number: str, message: str) -> bool:
    """Send SMS via gateway. Returns True on success.

    TODO: Integrate with Africa's Talking or Twilio:
        from africastalking import SMS
        sms = SMS()
        sms.send(message=message, recipients=[phone_number])
    """
    if not phone_number:
        logger.warning("No phone number for SMS delivery")
        return False
    logger.info(f"SMS to {phone_number}: {message[:80]}...")
    # Placeholder: replace with actual SMS gateway call
    return True


def send_whatsapp(phone_number: str, message: str) -> bool:
    """Send WhatsApp message via Business API. Returns True on success.

    TODO: Integrate with WhatsApp Business API:
        - Via Twilio: client.messages.create(from='whatsapp:+14155238886', body=message, to=f'whatsapp:{phone_number}')
        - Via direct API: POST to graph.facebook.com/v17.0/{phone_number_id}/messages
    """
    if not phone_number:
        logger.warning("No WhatsApp number for delivery")
        return False
    logger.info(f"WhatsApp to {phone_number}: {message[:80]}...")
    # Placeholder: replace with actual WhatsApp API call
    return True


def deliver_referral(referral) -> dict:
    """Send referral via all available channels. Returns delivery status dict."""
    results = {"sms": False, "whatsapp": False}

    sms_msg = format_sms(referral)
    whatsapp_msg = format_whatsapp(referral)

    if referral.facility and referral.facility.phone:
        results["sms"] = send_sms(referral.facility.phone, sms_msg)

    if referral.facility and referral.facility.facility_whatsapp:
        results["whatsapp"] = send_whatsapp(referral.facility.facility_whatsapp, whatsapp_msg)

    logger.info(f"Referral {referral.id} delivery: {results}")
    return results
```

- [ ] **Step 2: Verify module loads**

Run: `cd /home/ace/Projects/MamaSafe/backend && python -c "from app.services.delivery import deliver_referral, format_sms, format_whatsapp; print('Delivery service OK')"`
Expected: `Delivery service OK`

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && mkdir -p backend/app/services && touch backend/app/services/__init__.py && git add backend/app/services/ && git commit -m "feat: add SMS/WhatsApp delivery service"
```

---

## Task 6: Backend — Register New Routers

**Files:**
- Modify: `backend/app/main.py`

- [ ] **Step 1: Add imports and include routers in main.py**

Update the import line (line 4) to include the new routers:

```python
from app.routers import predict, assessments, auth, dashboard, anc, facilities, referrals
```

Add after `app.include_router(anc.router)` (around line 51):

```python
app.include_router(facilities.router)
app.include_router(referrals.router)
```

- [ ] **Step 2: Verify server starts**

Run: `cd /home/ace/Projects/MamaSafe/backend && timeout 5 python -c "from app.main import app; print('App loaded with', len(app.routes), 'routes')" 2>&1 || true`
Expected: Contains `App loaded with` and a route count > 20

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/main.py && git commit -m "feat: register facilities and referrals routers"
```

---

## Task 7: Frontend — API Client Functions

**Files:**
- Modify: `frontend/src/api/client.js`

- [ ] **Step 1: Add facility and referral API functions**

Append to `client.js`:

```javascript
// ── FACILITIES ──────────────────────────────────────────
export const getFacilities = async () => {
  const res = await client.get('/api/v1/facilities');
  return res.data;
};

export const suggestFacility = async (data) => {
  const res = await client.post('/api/v1/facilities', data);
  return res.data;
};

export const approveFacility = async (id) => {
  const res = await client.post(`/api/v1/facilities/${id}/approve`);
  return res.data;
};

// ── REFERRALS ──────────────────────────────────────────
export const createReferral = async (data) => {
  const res = await client.post('/api/v1/referrals', data);
  return res.data;
};

export const quickReferral = async (data) => {
  const res = await client.post('/api/v1/referrals/quick', data);
  return res.data;
};

export const getReferrals = async (params = {}) => {
  const res = await client.get('/api/v1/referrals', { params });
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

export const getReferralStats = async () => {
  const res = await client.get('/api/v1/referrals/stats');
  return res.data;
};
```

- [ ] **Step 2: Verify no syntax errors**

Run: `cd /home/ace/Projects/MamaSafe/frontend && node -e "require('./src/api/client.js')" 2>&1 | head -5 || echo "Module uses ESM imports, check manually"`

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/api/client.js && git commit -m "feat: add facility and referral API client functions"
```

---

## Task 8: Frontend — FacilityPicker Component

**Files:**
- Create: `frontend/src/components/FacilityPicker.jsx`

- [ ] **Step 1: Create FacilityPicker.jsx**

```jsx
import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { getFacilities, suggestFacility } from '../api/client';

export default function FacilityPicker({ value, onChange }) {
  const { t } = useTranslation();
  const [facilities, setFacilities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [newFacility, setNewFacility] = useState({ name: '', level: 'health_center', phone: '', whatsapp: '' });

  useEffect(() => {
    getFacilities()
      .then(setFacilities)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleSuggest = async () => {
    if (!newFacility.name.trim()) return;
    try {
      const created = await suggestFacility(newFacility);
      setFacilities([...facilities, created]);
      onChange(created.id);
      setShowAdd(false);
      setNewFacility({ name: '', level: 'health_center', phone: '', whatsapp: '' });
    } catch (err) {
      console.error('Failed to suggest facility', err);
    }
  };

  const LEVELS = [
    { value: 'health_post', label: 'Health Post' },
    { value: 'health_center', label: 'Health Center' },
    { value: 'district_hospital', label: 'District Hospital' },
    { value: 'regional_hospital', label: 'Regional Hospital' },
    { value: 'central_hospital', label: 'Central Hospital' },
  ];

  return (
    <div>
      <label className="block text-sm font-medium text-text-heading mb-1.5">
        {t('receiving_facility')}
      </label>
      {loading ? (
        <div className="h-11 bg-surface border border-border rounded-xl animate-pulse" />
      ) : (
        <select
          value={value || ''}
          onChange={(e) => onChange(Number(e.target.value) || null)}
          className="w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary outline-none"
        >
          <option value="">{t('select_facility')}</option>
          {facilities.map((f) => (
            <option key={f.id} value={f.id}>
              {f.name} ({LEVELS.find(l => l.value === f.level)?.label || f.level})
            </option>
          ))}
        </select>
      )}

      {!showAdd ? (
        <button
          type="button"
          onClick={() => setShowAdd(true)}
          className="mt-2 text-xs text-rose-500 font-semibold hover:underline"
        >
          + {t('suggest_new_facility')}
        </button>
      ) : (
        <div className="mt-3 p-3 bg-surface border border-border rounded-xl space-y-2">
          <input
            type="text"
            placeholder={t('facility_name')}
            value={newFacility.name}
            onChange={(e) => setNewFacility({ ...newFacility, name: e.target.value })}
            className="w-full bg-white border border-border rounded-lg px-3 py-2 text-sm"
          />
          <select
            value={newFacility.level}
            onChange={(e) => setNewFacility({ ...newFacility, level: e.target.value })}
            className="w-full bg-white border border-border rounded-lg px-3 py-2 text-sm"
          >
            {LEVELS.map((l) => (
              <option key={l.value} value={l.value}>{l.label}</option>
            ))}
          </select>
          <input
            type="text"
            placeholder={t('phone')}
            value={newFacility.phone}
            onChange={(e) => setNewFacility({ ...newFacility, phone: e.target.value })}
            className="w-full bg-white border border-border rounded-lg px-3 py-2 text-sm"
          />
          <input
            type="text"
            placeholder="WhatsApp"
            value={newFacility.whatsapp}
            onChange={(e) => setNewFacility({ ...newFacility, whatsapp: e.target.value })}
            className="w-full bg-white border border-border rounded-lg px-3 py-2 text-sm"
          />
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleSuggest}
              className="flex-1 bg-rose-500 text-white py-2 rounded-lg text-sm font-semibold hover:bg-rose-600 transition-colors"
            >
              {t('submit')}
            </button>
            <button
              type="button"
              onClick={() => setShowAdd(false)}
              className="px-3 py-2 text-sm text-text-muted hover:text-text-heading"
            >
              {t('cancel')}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/components/FacilityPicker.jsx && git commit -m "feat: add FacilityPicker component"
```

---

## Task 9: Frontend — ReferralCard Component

**Files:**
- Create: `frontend/src/components/ReferralCard.jsx`

- [ ] **Step 1: Create ReferralCard.jsx**

```jsx
import { useTranslation } from 'react-i18next';

const STATUS_CONFIG = {
  SENT: { color: 'bg-amber-100 text-amber-800', dot: 'bg-amber-500', labelKey: 'status_sent' },
  RECEIVED: { color: 'bg-blue-100 text-blue-800', dot: 'bg-blue-500', labelKey: 'status_received' },
  PATIENT_ARRIVED: { color: 'bg-green-100 text-green-800', dot: 'bg-green-500', labelKey: 'status_arrived' },
};

function timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

export default function ReferralCard({ referral, onClick }) {
  const { t } = useTranslation();
  const cfg = STATUS_CONFIG[referral.status] || STATUS_CONFIG.SENT;

  return (
    <button
      onClick={onClick}
      className="w-full text-left bg-white border border-border rounded-xl p-4 hover:border-rose-primary/40 transition-colors"
    >
      <div className="flex items-start justify-between mb-2">
        <div>
          <p className="text-sm font-semibold text-text-heading">{referral.patient_name}</p>
          <p className="text-xs text-text-muted">{referral.patient_age ? `${referral.patient_age}y` : ''} {referral.complication_type ? `· ${referral.complication_type}` : ''}</p>
        </div>
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold ${cfg.color}`}>
          <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
          {t(cfg.labelKey)}
        </span>
      </div>
      <div className="flex items-center justify-between text-xs text-text-muted">
        <span>{referral.facility_name}</span>
        <span>{timeAgo(referral.sent_at)}</span>
      </div>
    </button>
  );
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/components/ReferralCard.jsx && git commit -m "feat: add ReferralCard component"
```

---

## Task 10: Frontend — ReferralModal (One-Tap)

**Files:**
- Create: `frontend/src/components/ReferralModal.jsx`

- [ ] **Step 1: Create ReferralModal.jsx**

```jsx
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { quickReferral } from '../api/client';
import FacilityPicker from './FacilityPicker';

export default function ReferralModal({ assessment, patient, onClose, onSent }) {
  const { t } = useTranslation();
  const [facilityId, setFacilityId] = useState(null);
  const [complicationType, setComplicationType] = useState('');
  const [chwNotes, setChwNotes] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(null);

  if (!assessment) return null;

  const handleSend = async () => {
    if (!facilityId) { setError(t('select_facility_required')); return; }
    setSending(true);
    setError(null);
    try {
      await quickReferral({
        assessment_id: assessment.id || assessment.assessment_id,
        facility_id: facilityId,
        complication_type: complicationType || null,
        chw_notes: chwNotes || null,
      });
      onSent();
    } catch (err) {
      setError(err.response?.data?.detail || t('referral_failed'));
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full sm:max-w-lg sm:rounded-2xl rounded-t-2xl max-h-[85vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-border px-5 py-4 flex items-center justify-between rounded-t-2xl">
          <h2 className="text-base font-bold text-text-heading">{t('emergency_referral')}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-heading">
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        <div className="p-5 space-y-4">
          {/* Patient summary (read-only) */}
          {patient && (
            <div className="bg-surface rounded-xl p-3 space-y-1">
              <p className="text-sm font-semibold text-text-heading">{patient.full_name}</p>
              <p className="text-xs text-text-muted">
                {patient.blood_group ? `Blood: ${patient.blood_group}` : ''}
                {patient.allergies ? ` · Allergies: ${patient.allergies}` : ''}
              </p>
              {patient.emergency_contact_name && (
                <p className="text-xs text-text-muted">Contact: {patient.emergency_contact_name} {patient.emergency_contact_phone}</p>
              )}
            </div>
          )}

          {/* Clinical vitals (read-only summary) */}
          <div className="bg-surface rounded-xl p-3">
            <p className="text-xs font-semibold text-text-muted uppercase mb-2">{t('clinical_snapshot')}</p>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div><span className="text-text-muted">BP:</span> {assessment.systolic_bp}/{assessment.diastolic_bp}</div>
              <div><span className="text-text-muted">HR:</span> {assessment.heart_rate}</div>
              <div><span className="text-text-muted">Temp:</span> {assessment.body_temp}</div>
              <div><span className="text-text-muted">Sugar:</span> {assessment.blood_sugar}</div>
              <div><span className="text-text-muted">Risk:</span> <span className="font-semibold">{assessment.risk_level}</span></div>
            </div>
          </div>

          {/* Facility picker */}
          <FacilityPicker value={facilityId} onChange={setFacilityId} />

          {/* Complication type */}
          <div>
            <label className="block text-sm font-medium text-text-heading mb-1.5">{t('complication_type')}</label>
            <input
              type="text"
              value={complicationType}
              onChange={(e) => setComplicationType(e.target.value)}
              placeholder={t('complication_placeholder')}
              className="w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary outline-none"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-text-heading mb-1.5">{t('chw_notes')}</label>
            <textarea
              value={chwNotes}
              onChange={(e) => setChwNotes(e.target.value)}
              rows={2}
              className="w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary outline-none resize-none"
            />
          </div>

          {error && <p className="text-sm text-red-600">{error}</p>}

          {/* Send button */}
          <button
            onClick={handleSend}
            disabled={sending || !facilityId}
            className="w-full bg-red-600 text-white py-3 rounded-xl text-sm font-bold hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {sending ? (
              <span className="material-symbols-outlined text-[18px] animate-spin">progress_activity</span>
            ) : (
              <span className="material-symbols-outlined text-[18px]">send</span>
            )}
            {sending ? t('sending') : t('send_referral')}
          </button>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/components/ReferralModal.jsx && git commit -m "feat: add ReferralModal for one-tap emergency referral"
```

---

## Task 11: Frontend — Update ResultPage with Referral Button

**Files:**
- Modify: `frontend/src/pages/ResultPage.jsx`

- [ ] **Step 1: Add emergency referral button to ResultPage**

Import ReferralModal at the top of ResultPage.jsx:

```jsx
import { useState } from 'react';
import ReferralModal from '../components/ReferralModal';
```

Add state inside the component (after the existing destructuring):

```jsx
const [showReferral, setShowReferral] = useState(false);
```

Add the emergency referral button in the Actions section (before the existing "View Patient Card" Link), inside the `div className="flex flex-col gap-2.5"`:

```jsx
<button
  onClick={() => setShowReferral(true)}
  className="py-3 border-2 border-red-500 text-red-600 bg-white rounded-xl text-sm font-bold text-center hover:bg-red-50 transition-colors flex items-center justify-center gap-2"
>
  <span className="material-symbols-outlined text-[18px]">emergency_home</span>
  {t('emergency_referral')}
</button>
```

Add the ReferralModal render at the end of the component (before the closing `</main>`):

```jsx
{showReferral && (
  <ReferralModal
    assessment={state}
    patient={state.patient}
    onClose={() => setShowReferral(false)}
    onSent={() => { setShowReferral(false); alert(t('referral_sent_success')); }}
  />
)}
```

- [ ] **Step 2: Verify no syntax errors**

Run: `cd /home/ace/Projects/MamaSafe/frontend && npx vite build --mode development 2>&1 | tail -5`
Expected: Build succeeds or only minor warnings

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/pages/ResultPage.jsx && git commit -m "feat: add emergency referral button to assessment results"
```

---

## Task 12: Frontend — Referral List Page

**Files:**
- Create: `frontend/src/pages/ReferralListPage.jsx`

- [ ] **Step 1: Create ReferralListPage.jsx**

```jsx
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { getReferrals, getReferralStats, updateReferralStatus } from '../api/client';
import ReferralCard from '../components/ReferralCard';

export default function ReferralListPage() {
  const { t } = useTranslation();
  const [referrals, setReferrals] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [selectedReferral, setSelectedReferral] = useState(null);

  const loadData = () => {
    setLoading(true);
    const params = {};
    if (filter) params.status = filter;
    Promise.all([getReferrals(params), getReferralStats()])
      .then(([refs, st]) => { setReferrals(refs); setStats(st); })
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadData(); }, [filter]);

  const handleStatusUpdate = async (id, status) => {
    await updateReferralStatus(id, status);
    loadData();
    setSelectedReferral(null);
  };

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      </main>
    );
  }

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('referrals')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('referral_history_desc')}</p>
      </header>

      {/* Stats row */}
      {stats && (
        <div className="grid grid-cols-3 gap-3 mb-6">
          {[
            { label: t('sent'), value: stats.total_sent, color: 'text-amber-600', bg: 'bg-amber-50' },
            { label: t('received'), value: stats.total_received, color: 'text-blue-600', bg: 'bg-blue-50' },
            { label: t('arrived'), value: stats.total_arrived, color: 'text-green-600', bg: 'bg-green-50' },
          ].map((s) => (
            <div key={s.label} className={`${s.bg} rounded-xl p-3 text-center`}>
              <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
              <p className="text-xs text-text-muted">{s.label}</p>
            </div>
          ))}
        </div>
      )}

      {/* Filter */}
      <div className="flex gap-2 mb-4 overflow-x-auto">
        {['', 'SENT', 'RECEIVED', 'PATIENT_ARRIVED'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors ${
              filter === f ? 'bg-rose-500 text-white' : 'bg-surface text-text-muted hover:bg-border'
            }`}
          >
            {f ? t(`status_${f.toLowerCase()}`) : t('all')}
          </button>
        ))}
      </div>

      {/* Referral list */}
      {referrals.length === 0 ? (
        <div className="text-center py-16 border-2 border-dashed border-border rounded-2xl">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 block mb-3">send</span>
          <h3 className="text-base font-semibold text-text-heading mb-1">{t('no_referrals')}</h3>
          <p className="text-sm text-text-muted">{t('no_referrals_hint')}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {referrals.map((r) => (
            <ReferralCard key={r.id} referral={r} onClick={() => setSelectedReferral(r)} />
          ))}
        </div>
      )}

      {/* Detail modal */}
      {selectedReferral && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="bg-white w-full sm:max-w-lg sm:rounded-2xl rounded-t-2xl max-h-[85vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-border px-5 py-4 flex items-center justify-between rounded-t-2xl">
              <h2 className="text-base font-bold text-text-heading">{t('referral_details')}</h2>
              <button onClick={() => setSelectedReferral(null)} className="text-text-muted hover:text-text-heading">
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div className="bg-surface rounded-xl p-3">
                <p className="text-sm font-semibold text-text-heading">{selectedReferral.patient_name}</p>
                <p className="text-xs text-text-muted">{selectedReferral.patient_age}y · {selectedReferral.complication_type}</p>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div><span className="text-text-muted">BP:</span> {selectedReferral.systolic_bp}/{selectedReferral.diastolic_bp}</div>
                <div><span className="text-text-muted">HR:</span> {selectedReferral.heart_rate}</div>
                <div><span className="text-text-muted">Risk:</span> {selectedReferral.risk_level}</div>
                <div><span className="text-text-muted">Facility:</span> {selectedReferral.facility_name}</div>
              </div>
              {selectedReferral.chw_notes && (
                <p className="text-sm text-text-body bg-surface rounded-xl p-3">{selectedReferral.chw_notes}</p>
              )}
              {/* Status actions */}
              <div className="flex gap-2">
                {selectedReferral.status === 'SENT' && (
                  <button onClick={() => handleStatusUpdate(selectedReferral.id, 'RECEIVED')} className="flex-1 bg-blue-600 text-white py-2.5 rounded-xl text-sm font-semibold hover:bg-blue-700">{t('mark_received')}</button>
                )}
                {selectedReferral.status !== 'PATIENT_ARRIVED' && (
                  <button onClick={() => handleStatusUpdate(selectedReferral.id, 'PATIENT_ARRIVED')} className="flex-1 bg-green-600 text-white py-2.5 rounded-xl text-sm font-semibold hover:bg-green-700">{t('mark_arrived')}</button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/pages/ReferralListPage.jsx && git commit -m "feat: add ReferralListPage with status tracking"
```

---

## Task 13: Frontend — Update NavBar, App.jsx Routes, i18n

**Files:**
- Modify: `frontend/src/components/NavBar.jsx`
- Modify: `frontend/src/App.jsx`
- Modify: `frontend/src/i18n/en.json`
- Modify: `frontend/src/i18n/fr.json`

- [ ] **Step 1: Add Referrals link to NavBar**

In `navLinks` array (line 18-23), add:

```jsx
{ path: '/referrals', label: t('referrals'), icon: 'send' },
```

Update the `linkClass` function to handle `/referrals` path matching (add alongside the `/patients` check):

```jsx
const linkClass = (path) =>
  `text-sm transition-colors ${
    ['/patients', '/referrals'].some(p => location.pathname.startsWith(p))
      ? location.pathname.startsWith(path)
        ? 'text-rose-500 font-semibold'
        : 'text-text-body hover:text-rose-500'
      : location.pathname === path
        ? 'text-rose-500 font-semibold'
        : 'text-text-body hover:text-rose-500'
  }`;
```

- [ ] **Step 2: Add routes to App.jsx**

Add imports:

```jsx
import ReferralListPage from './pages/ReferralListPage';
```

Add routes inside the `<Route element={<ProtectedRoute><Layout /></ProtectedRoute}>` block:

```jsx
<Route path="/referrals" element={<ReferralListPage />} />
```

- [ ] **Step 3: Add i18n keys to en.json**

Add these keys:

```json
"referrals": "Referrals",
"referral_history_desc": "Track and manage emergency referrals to receiving facilities.",
"emergency_referral": "Emergency Referral",
"receiving_facility": "Receiving Facility",
"select_facility": "Select a facility...",
"suggest_new_facility": "Suggest a new facility",
"facility_name": "Facility Name",
"complication_type": "Complication Type",
"complication_placeholder": "e.g., Eclampsia, PPH, Obstructed labor",
"chw_notes": "CHW Notes",
"send_referral": "Send Referral",
" sending": "Sending...",
"referral_sent_success": "Referral sent successfully!",
"referral_failed": "Failed to send referral. Please try again.",
"select_facility_required": "Please select a receiving facility",
"clinical_snapshot": "Clinical Snapshot",
"status_sent": "Sent",
"status_received": "Received",
"status_arrived": "Arrived",
"status_pending_sync": "Pending Sync",
"all": "All",
"sent": "Sent",
"received": "Received",
"arrived": "Arrived",
"no_referrals": "No referrals yet",
"no_referrals_hint": "Emergency referrals will appear here after you send one.",
"referral_details": "Referral Details",
"mark_received": "Mark Received",
"mark_arrived": "Patient Arrived",
"refer": "Refer",
"new_referral": "New Referral"
```

- [ ] **Step 4: Add i18n keys to fr.json**

Add French translations:

```json
"referrals": "Référénces",
"referral_history_desc": "Suivre et gérer les références d'urgence vers les établissements récepteurs.",
"emergency_referral": "Référence d'Urgence",
"receiving_facility": "Établissement Récepteur",
"select_facility": "Sélectionner un établissement...",
"suggest_new_facility": "Suggérer un nouvel établissement",
"facility_name": "Nom de l'Établissement",
"complication_type": "Type de Complication",
"complication_placeholder": "ex: Éclampsie, HPP, Travail obstrué",
"chw_notes": "Notes de l'ASCS",
"send_referral": "Envoyer la Référence",
" sending": "Envoi...",
"referral_sent_success": "Référence envoyée avec succès!",
"referral_failed": "Échec de l'envoi. Veuillez réessayer.",
"select_facility_required": "Veuillez sélectionner un établissement récepteur",
"clinical_snapshot": "Aperçu Clinique",
"status_sent": "Envoyé",
"status_received": "Reçu",
"status_arrived": "Arrivé",
"status_pending_sync": "En attente",
"all": "Tous",
"sent": "Envoyés",
"received": "Reçus",
"arrivées": "Arrivées",
"no_referrals": "Pas encore de références",
"no_referrals_hint": "Les références d'urgence apparaîtront ici après envoi.",
"referral_details": "Détails de la Référence",
"mark_received": "Marquer Reçu",
"mark_arrived": "Patient Arrivé",
"refer": "Référer",
"new_referral": "Nouvelle Référence"
```

- [ ] **Step 5: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add frontend/src/components/NavBar.jsx frontend/src/App.jsx frontend/src/i18n/en.json frontend/src/i18n/fr.json && git commit -m "feat: add referral routes, nav link, and i18n translations"
```

---

## Task 14: Mobile — TypeScript Types & API Functions

**Files:**
- Modify: `mobile/types/index.ts`
- Modify: `mobile/services/api.ts`

- [ ] **Step 1: Add types to index.ts**

Append:

```typescript
export interface Facility {
  id: number;
  name: string;
  level: string;
  phone?: string;
  whatsapp?: string;
  address?: string;
  region?: string;
  is_active: boolean;
  approved: boolean;
  suggested_by?: number;
  created_at: string;
}

export interface Referral {
  id: number;
  patient_id: number;
  assessment_id?: number;
  facility_id: number;
  facility_name: string;
  status: "SENT" | "RECEIVED" | "PATIENT_ARRIVED";
  patient_name: string;
  patient_age?: number;
  patient_phone?: string;
  patient_blood_group?: string;
  patient_allergies?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  gravida?: number;
  parity?: number;
  edd_date?: string;
  gestational_age?: number;
  systolic_bp?: number;
  diastolic_bp?: number;
  heart_rate?: number;
  body_temp?: number;
  blood_sugar?: number;
  risk_level?: string;
  risk_probability?: number;
  complication_type?: string;
  chw_notes?: string;
  chw_id: number;
  sent_at?: string;
  received_at?: string;
  patient_arrived_at?: string;
  created_at: string;
}

export interface ReferralStats {
  total_sent: number;
  total_received: number;
  total_arrived: number;
  completion_rate: number;
  avg_response_minutes?: number;
  stale_count: number;
}

export interface ReferralPayload {
  patient_id: number;
  assessment_id?: number;
  facility_id: number;
  complication_type?: string;
  chw_notes?: string;
  systolic_bp?: number;
  diastolic_bp?: number;
  heart_rate?: number;
  body_temp?: number;
  blood_sugar?: number;
  gestational_age?: number;
}

export interface ReferralQuickPayload {
  assessment_id: number;
  facility_id: number;
  complication_type?: string;
  chw_notes?: string;
}
```

- [ ] **Step 2: Add API functions to api.ts**

Append:

```typescript
import type { Facility, Referral, ReferralStats, ReferralPayload, ReferralQuickPayload } from "../types";

export const getFacilities = async (): Promise<Facility[]> => {
  const res = await client.get("/api/v1/facilities");
  return res.data;
};

export const suggestFacility = async (data: { name: string; level: string; phone?: string; whatsapp?: string }): Promise<Facility> => {
  const res = await client.post("/api/v1/facilities", data);
  return res.data;
};

export const createReferral = async (payload: ReferralPayload): Promise<Referral> => {
  const res = await client.post("/api/v1/referrals", payload);
  return res.data;
};

export const quickReferral = async (payload: ReferralQuickPayload): Promise<Referral> => {
  const res = await client.post("/api/v1/referrals/quick", payload);
  return res.data;
};

export const getReferrals = async (params: Record<string, string> = {}): Promise<Referral[]> => {
  const res = await client.get("/api/v1/referrals", { params });
  return res.data;
};

export const updateReferralStatus = async (id: number, status: string): Promise<Referral> => {
  const res = await client.patch(`/api/v1/referrals/${id}/status`, { status });
  return res.data;
};

export const getReferralStats = async (): Promise<ReferralStats> => {
  const res = await client.get("/api/v1/referrals/stats");
  return res.data;
};
```

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/types/index.ts mobile/services/api.ts && git commit -m "feat: add referral types and API functions to mobile"
```

---

## Task 15: Mobile — Referral Store (Offline Queue)

**Files:**
- Create: `mobile/stores/referralStore.ts`

- [ ] **Step 1: Create referralStore.ts**

```typescript
import { create } from "zustand";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as api from "../services/api";
import { isOnline } from "../services/network";
import type { Referral, ReferralQuickPayload } from "../types";

interface QueuedReferral {
  id: string;
  payload: ReferralQuickPayload;
  timestamp: number;
  status: "pending" | "synced" | "error";
}

interface ReferralState {
  referrals: Referral[];
  queue: QueuedReferral[];
  isLoading: boolean;
  fetchReferrals: () => Promise<void>;
  submitQuickReferral: (payload: ReferralQuickPayload) => Promise<Referral>;
  hydrateQueue: () => Promise<void>;
  syncQueue: () => Promise<void>;
}

export const useReferralStore = create<ReferralState>((set, get) => ({
  referrals: [],
  queue: [],
  isLoading: false,

  fetchReferrals: async () => {
    set({ isLoading: true });
    try {
      const data = await api.getReferrals();
      set({ referrals: data });
    } catch {}
    set({ isLoading: false });
  },

  submitQuickReferral: async (payload) => {
    if (await isOnline()) {
      const result = await api.quickReferral(payload);
      set({ referrals: [result, ...get().referrals] });
      return result;
    } else {
      const queued: QueuedReferral = {
        id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
        payload,
        timestamp: Date.now(),
        status: "pending",
      };
      const queue = [...get().queue, queued];
      set({ queue });
      await AsyncStorage.setItem("referral_queue", JSON.stringify(queue));
      throw new Error("OFFLINE_QUEUED");
    }
  },

  hydrateQueue: async () => {
    const raw = await AsyncStorage.getItem("referral_queue");
    if (raw) set({ queue: JSON.parse(raw) });
  },

  syncQueue: async () => {
    const pending = get().queue.filter((q) => q.status === "pending");
    for (const item of pending) {
      try {
        await api.quickReferral(item.payload);
        item.status = "synced";
      } catch {
        item.status = "error";
      }
    }
    set({ queue: [...get().queue] });
    await AsyncStorage.setItem("referral_queue", JSON.stringify(get().queue));
  },
}));
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/stores/referralStore.ts && git commit -m "feat: add referralStore with offline queue"
```

---

## Task 16: Mobile — Refer Tab + Referral List Screen

**Files:**
- Modify: `mobile/app/(main)/_layout.tsx`
- Create: `mobile/app/(main)/refer.tsx`

- [ ] **Step 1: Add Refer tab to _layout.tsx**

Add to `TAB_ICONS`:

```typescript
refer: { focused: "send", unfocused: "send-outline" },
```

Add a new `Tabs.Screen` after the dashboard tab:

```tsx
<Tabs.Screen
  name="refer"
  options={{
    title: t("refer"),
    tabBarIcon: ({ focused }) => <TabIcon name="refer" focused={focused} />,
  }}
/>
```

- [ ] **Step 2: Create refer.tsx (referral list screen)**

```tsx
import { useEffect, useCallback } from "react";
import { View, Text, FlatList, TouchableOpacity, RefreshControl } from "react-native";
import { useTranslation } from "react-i18next";
import { useRouter } from "expo-router";
import { useReferralStore } from "../../stores/referralStore";
import Card from "../../components/ui/Card";
import Icon from "../../components/ui/Icon";
import Button from "../../components/ui/Button";

const STATUS_COLORS: Record<string, { bg: string; text: string; dot: string }> = {
  SENT: { bg: "bg-amber-100", text: "text-amber-800", dot: "bg-amber-500" },
  RECEIVED: { bg: "bg-blue-100", text: "text-blue-800", dot: "bg-blue-500" },
  PATIENT_ARRIVED: { bg: "bg-green-100", text: "text-green-800", dot: "bg-green-500" },
};

function timeAgo(dateStr?: string) {
  if (!dateStr) return "";
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

export default function ReferScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { referrals, isLoading, fetchReferrals } = useReferralStore();
  const [refreshing, setRefreshing] = React.useState(false);

  useEffect(() => { fetchReferrals(); }, []);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchReferrals();
    setRefreshing(false);
  }, []);

  const renderItem = ({ item }: { item: any }) => {
    const cfg = STATUS_COLORS[item.status] || STATUS_COLORS.SENT;
    return (
      <TouchableOpacity
        onPress={() => router.push({ pathname: "/(main)/referral-form", params: { id: item.id } })}
        className="mb-3"
      >
        <Card>
          <View className="flex-row justify-between items-start mb-2">
            <View className="flex-1">
              <Text className="text-sm font-semibold text-text-heading">{item.patient_name}</Text>
              <Text className="text-xs text-text-muted">
                {item.patient_age ? `${item.patient_age}y` : ""} {item.complication_type ? `· ${item.complication_type}` : ""}
              </Text>
            </View>
            <View className={`flex-row items-center gap-1 px-2 py-0.5 rounded-full ${cfg.bg}`}>
              <View className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
              <Text className={`text-[11px] font-semibold ${cfg.text}`}>{t(`status_${item.status.toLowerCase()}`)}</Text>
            </View>
          </View>
          <View className="flex-row justify-between">
            <Text className="text-xs text-text-muted">{item.facility_name}</Text>
            <Text className="text-xs text-text-muted">{timeAgo(item.sent_at)}</Text>
          </View>
        </Card>
      </TouchableOpacity>
    );
  };

  return (
    <View className="flex-1 bg-canvas">
      <View className="px-5 pt-8 pb-4">
        <Text className="text-2xl font-bold text-text-heading">{t("referrals")}</Text>
        <Text className="text-sm text-text-muted mt-1">{t("referral_history_desc")}</Text>
      </View>

      <FlatList
        data={referrals}
        keyExtractor={(item) => String(item.id)}
        renderItem={renderItem}
        contentContainerStyle={{ padding: 20, paddingTop: 0 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ListEmptyComponent={
          <View className="items-center py-16">
            <Icon name="send-outline" size={48} color="#8E8696" />
            <Text className="text-base font-semibold text-text-heading mt-4 mb-1">{t("no_referrals")}</Text>
            <Text className="text-sm text-text-muted text-center mb-6">{t("no_referrals_hint")}</Text>
            <Button onPress={() => router.push("/(main)/assess")}>{t("new_assessment")}</Button>
          </View>
        }
      />

      <TouchableOpacity
        onPress={() => router.push("/(main)/referral-form")}
        className="absolute bottom-6 right-5 w-14 h-14 bg-red-500 rounded-full items-center justify-center shadow-lg"
      >
        <Icon name="add" size={28} color="white" />
      </TouchableOpacity>
    </View>
  );
}
```

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/app/(main)/_layout.tsx mobile/app/(main)/refer.tsx && git commit -m "feat: add Refer tab and referral list screen"
```

---

## Task 17: Mobile — Update Result Screen with Referral Button

**Files:**
- Modify: `mobile/app/(main)/result.tsx`

- [ ] **Step 1: Add emergency referral button to result.tsx**

Import at the top:

```typescript
import { useReferralStore } from "../../stores/referralStore";
import { useRouter } from "expo-router";
```

Add the emergency referral button before the "Start New Assessment" button (before the last `<Button>`):

```tsx
{lastResult?.risk_level === "high risk" && (
  <Button
    variant="secondary"
    onPress={() => router.push("/(main)/referral-form")}
    style={{ borderColor: "#ef4444" }}
  >
    <Text className="text-red-600 font-semibold">{t("emergency_referral")}</Text>
  </Button>
)}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/app/(main)/result.tsx && git commit -m "feat: add emergency referral button to result screen"
```

---

## Task 18: Mobile — i18n Translations

**Files:**
- Modify: `mobile/i18n/en.json`
- Modify: `mobile/i18n/fr.json`

- [ ] **Step 1: Add English keys to en.json**

Append:

```json
"referrals": "Referrals",
"referral_history_desc": "Track emergency referrals to receiving facilities.",
"emergency_referral": "Emergency Referral",
"receiving_facility": "Receiving Facility",
"select_facility": "Select a facility...",
"complication_type": "Complication Type",
"complication_placeholder": "e.g., Eclampsia, PPH",
"chw_notes": "CHW Notes",
"send_referral": "Send Referral",
"sending": "Sending...",
"referral_sent_success": "Referral sent!",
"status_sent": "Sent",
"status_received": "Received",
"status_arrived": "Arrived",
"refer": "Refer",
"new_referral": "New Referral"
```

- [ ] **Step 2: Add French keys to fr.json**

Append:

```json
"referrals": "Référénces",
"referral_history_desc": "Suivre les références d'urgence.",
"emergency_referral": "Référence d'Urgence",
"receiving_facility": "Établissement Récepteur",
"select_facility": "Sélectionner un établissement...",
"complication_type": "Type de Complication",
"complication_placeholder": "ex: Éclampsie, HPP",
"chw_notes": "Notes de l'ASCS",
"send_referral": "Envoyer la Référence",
"sending": "Envoi...",
"referral_sent_success": "Référence envoyée!",
"status_sent": "Envoyé",
"status_received": "Reçu",
"status_arrived": "Arrivé",
"refer": "Référer",
"new_referral": "Nouvelle Référence"
```

- [ ] **Step 3: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/i18n/en.json mobile/i18n/fr.json && git commit -m "feat: add referral i18n translations (EN/FR)"
```

---

## Task 19: Mobile — Wire Up Queue Sync in Root Layout

**Files:**
- Modify: `mobile/app/_layout.tsx`

- [ ] **Step 1: Add referral queue hydration and sync**

Import the referral store:

```typescript
import { useReferralStore } from "../stores/referralStore";
```

In the root layout component, add referral queue hydration alongside the existing assessment queue hydration:

```typescript
const hydrateReferralQueue = useReferralStore((s) => s.hydrateQueue);
const syncReferralQueue = useReferralStore((s) => s.syncQueue);

useEffect(() => {
  hydrateReferralQueue();
}, []);

useEffect(() => {
  if (isConnected) {
    syncReferralQueue();
  }
}, [isConnected]);
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add mobile/app/_layout.tsx && git commit -m "feat: wire up referral queue sync in root layout"
```

---

## Task 20: Backend — Fix Delivery Service Field Name

**Files:**
- Modify: `backend/app/services/delivery.py`

- [ ] **Step 1: Fix the whatsapp field reference**

The Facility model uses `whatsapp` but the delivery service references `facility_whatsapp`. Fix line ~95:

```python
# Change this:
if referral.facility and referral.facility.facility_whatsapp:
    results["whatsapp"] = send_whatsapp(referral.facility.facility_whatsapp, whatsapp_msg)

# To this:
if referral.facility and referral.facility.whatsapp:
    results["whatsapp"] = send_whatsapp(referral.facility.whatsapp, whatsapp_msg)
```

- [ ] **Step 2: Commit**

```bash
cd /home/ace/Projects/MamaSafe && git add backend/app/services/delivery.py && git commit -m "fix: correct whatsapp field name in delivery service"
```

---

## Spec Coverage Check

| Spec Requirement | Task(s) |
|-----------------|---------|
| Facility & Referral DB models | Task 1 |
| Pydantic schemas | Task 2 |
| Facility CRUD + approval | Task 3 |
| Referral CRUD + quick endpoint + stats | Task 4 |
| SMS/WhatsApp delivery | Task 5 |
| Router registration | Task 6 |
| Frontend API client | Task 7 |
| FacilityPicker component | Task 8 |
| ReferralCard component | Task 9 |
| ReferralModal (one-tap) | Task 10 |
| Emergency referral button on results | Task 11 (web), Task 17 (mobile) |
| Referral list page with status tracking | Task 12 (web), Task 16 (mobile) |
| NavBar + routes + i18n (web) | Task 13 |
| Mobile types + API | Task 14 |
| Offline queue store | Task 15 |
| Mobile i18n | Task 18 |
| Queue sync in root layout | Task 19 |
| Delivery field name fix | Task 20 |

**All spec requirements covered.**
