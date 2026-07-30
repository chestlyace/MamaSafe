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
