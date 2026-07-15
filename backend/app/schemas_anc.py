from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from dateutil.relativedelta import relativedelta


# ── PATIENT ──────────────────────────────────────────────
class PatientCreate(BaseModel):
    full_name:               str
    date_of_birth:           str   # YYYY-MM-DD
    phone:                   Optional[str] = None
    address:                 Optional[str] = None
    facility:                Optional[str] = None
    blood_group:             Optional[str] = None
    allergies:               Optional[str] = None
    emergency_contact_name:  Optional[str] = None
    emergency_contact_phone: Optional[str] = None

class PatientOut(PatientCreate):
    id:         int
    chw_id:     Optional[int]
    created_at: datetime
    class Config:
        from_attributes = True


# ── PREGNANCY ─────────────────────────────────────────────
class PregnancyCreate(BaseModel):
    patient_id:  int
    lmp_date:    str              # YYYY-MM-DD
    gravida:     int = 1
    parity:      int = 0

class PregnancyOut(BaseModel):
    id:               int
    patient_id:       int
    lmp_date:         str
    edd_date:         Optional[str]
    gravida:          int
    parity:           int
    is_active:        bool
    delivery_date:    Optional[str]
    delivery_outcome: Optional[str]
    created_at:       datetime
    class Config:
        from_attributes = True


# ── ANC VISIT ─────────────────────────────────────────────
class ANCVisitCreate(BaseModel):
    pregnancy_id:       int
    visit_number:       int = Field(..., ge=1, le=8)
    visit_date:         str
    gestational_age:    Optional[int]   = None
    weight:             Optional[float] = None
    systolic_bp:        Optional[float] = None
    diastolic_bp:       Optional[float] = None
    fundal_height:      Optional[float] = None
    foetal_hr:          Optional[int]   = None
    presentation:       Optional[str]   = None
    oedema:             bool = False
    urinalysis_protein: Optional[str]   = None
    urinalysis_glucose: Optional[str]   = None
    haemoglobin:        Optional[float] = None
    tt_vaccine:         bool = False
    malaria_prophylaxis: bool = False
    iron_supplements:   bool = False
    notes:              Optional[str]   = None
    next_visit_date:    Optional[str]   = None
    risk_assessment_id: Optional[int]   = None

class ANCVisitOut(ANCVisitCreate):
    id:         int
    created_at: datetime
    class Config:
        from_attributes = True


# ── FULL ANC CARD (patient + pregnancy + visits) ──────────
class ANCCardOut(BaseModel):
    patient:      PatientOut
    pregnancy:    Optional[PregnancyOut] = None
    visits:       List[ANCVisitOut] = []
    pregnancies:  List[PregnancyOut] = []
    class Config:
        from_attributes = True


# ── DELIVERY UPDATE ───────────────────────────────────────
class DeliveryUpdate(BaseModel):
    delivery_date:     str
    delivery_outcome:  str   # live_birth, stillbirth, miscarriage
    delivery_location: Optional[str] = None
