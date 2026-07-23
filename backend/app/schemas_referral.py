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
    patient_id:              Optional[int] = None
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
    whatsapp_sent:           Optional[bool] = None
    whatsapp_message_id:     Optional[str] = None
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

class WebhookWhatsApp(BaseModel):
    from_number: str
    text:        str
    timestamp:   Optional[str] = None
    secret:      Optional[str] = None
