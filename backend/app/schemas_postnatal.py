from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ── NEWBORN ──────────────────────────────────────────────
class NewbornCreate(BaseModel):
    name:            Optional[str] = None
    sex:             str
    birth_weight:    Optional[float] = None
    apgar_score:     Optional[int] = None
    crying_at_birth: bool = True
    breastfeeding:   bool = False
    malformations:   Optional[str] = None
    status:          str = "alive"

class NewbornOut(NewbornCreate):
    id:          int
    delivery_id: int
    created_at:  datetime
    class Config:
        from_attributes = True


# ── DELIVERY ─────────────────────────────────────────────
class DeliveryCreate(BaseModel):
    pregnancy_id:      int
    delivery_date:     str
    delivery_location: Optional[str] = None
    delivered_by:      Optional[str] = None
    complications:     Optional[str] = None
    notes:             Optional[str] = None
    newborns:          List[NewbornCreate] = []

class DeliveryOut(BaseModel):
    id:                int
    pregnancy_id:      int
    patient_id:        int
    delivery_date:     str
    delivery_location: Optional[str]
    delivered_by:      Optional[str]
    complications:     Optional[str]
    notes:             Optional[str]
    created_at:        datetime
    newborns:          List[NewbornOut] = []
    class Config:
        from_attributes = True


# ── POSTNATAL SCHEDULED VISIT ────────────────────────────
class PostnatalScheduledVisitOut(BaseModel):
    id:                  int
    delivery_id:         int
    visit_number:        int
    days_after_delivery: int
    label:               Optional[str]
    scheduled_date:      str
    status:              str
    postnatal_visit_id:  Optional[int]
    reminder_48h_sent:   bool
    reminder_day_sent:   bool
    created_at:          datetime
    class Config:
        from_attributes = True


# ── POSTNATAL VISIT ──────────────────────────────────────
class PostnatalVisitCreate(BaseModel):
    delivery_id:     int
    visit_number:    int = Field(..., ge=1, le=6)
    visit_date:      str
    mother_status:   Optional[str] = None
    uterus_firm:     bool = True
    lochia_normal:   bool = True
    temperature:     Optional[float] = None
    systolic_bp:     Optional[float] = None
    diastolic_bp:    Optional[float] = None
    breast_exam:     Optional[str] = None
    perineal_exam:   Optional[str] = None
    hb_result:       Optional[float] = None
    malaria_test:    bool = False
    hiv_test:        bool = False
    mental_health:   Optional[str] = None
    notes:           Optional[str] = None

class PostnatalVisitOut(PostnatalVisitCreate):
    id:          int
    created_at:  datetime
    class Config:
        from_attributes = True


# ── MENTAL HEALTH SCREENING ─────────────────────────────
class MentalHealthScreeningCreate(BaseModel):
    postnatal_visit_id: Optional[int] = None
    patient_id:         int
    phq2_score:         int = Field(..., ge=0, le=6)
    phq2_q1:            Optional[int] = None
    phq2_q2:            Optional[int] = None

class MentalHealthScreeningOut(MentalHealthScreeningCreate):
    id:          int
    risk_level:  str
    chw_alerted: bool
    created_at:  datetime
    class Config:
        from_attributes = True


# ── POSTNATAL SCHEDULE (for schedule tab) ────────────────
class PostnatalScheduleOut(BaseModel):
    delivery:        DeliveryOut
    scheduled_visits: List[PostnatalScheduledVisitOut] = []
    visits:          List[PostnatalVisitOut] = []
    class Config:
        from_attributes = True
