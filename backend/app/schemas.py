from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class PredictRequest(BaseModel):
    age:          float = Field(..., ge=10,  le=70,  description="Patient age in years")
    systolic_bp:  float = Field(..., ge=70,  le=180, description="Systolic blood pressure mmHg")
    diastolic_bp: float = Field(..., ge=40,  le=120, description="Diastolic blood pressure mmHg")
    blood_sugar:  float = Field(..., ge=4,   le=25,  description="Blood sugar mmol/L")
    body_temp:    float = Field(..., ge=95,  le=105, description="Body temperature °F")
    heart_rate:   float = Field(..., ge=40,  le=100, description="Heart rate bpm")
    patient_ref:  Optional[str] = None
    patient_id:   Optional[int] = None
    pregnancy_id: Optional[int] = None


class SHAPExplanation(BaseModel):
    feature:    str
    shap_value: float
    raw_value:  float


class PredictResponse(BaseModel):
    risk_level:          str
    confidence:          float
    prob_high:           float
    prob_low:            float
    prob_mid:            float
    recommendation:      str
    shap_values:         list[SHAPExplanation]
    assessment_id:       int
    escalation_detected: bool = False
    escalation_type:     Optional[str] = None
    previous_risk_level: Optional[str] = None


class AssessmentOut(BaseModel):
    id:           int
    patient_ref:  Optional[str]
    age:          float
    systolic_bp:  float
    diastolic_bp: float
    blood_sugar:  float
    body_temp:    float
    heart_rate:   float
    risk_level:   str
    prob_high:    float
    prob_low:     float
    prob_mid:     float
    created_at:   datetime

    class Config:
        from_attributes = True


class DashboardSummary(BaseModel):
    total_assessments: int
    high_risk_count:   int
    mid_risk_count:    int
    low_risk_count:    int
    high_risk_pct:     float
    mid_risk_pct:      float
    low_risk_pct:      float
    total_patients:    int = 0
    active_pregnancies: int = 0
    pending_referrals:  int = 0
    upcoming_visits:    int = 0
    recent_escalations: int = 0


class UserCreate(BaseModel):
    username:  str
    password:  str
    role:      Optional[str] = "chw"
    full_name: Optional[str] = None
    facility:  Optional[str] = None


class SupervisorSignup(BaseModel):
    full_name:        str
    username:         str
    password:         str
    district:         str
    region:           Optional[str] = None
    whatsapp_number:  Optional[str] = None


class ChwSignup(BaseModel):
    full_name:        str
    username:         str
    password:         str
    facility:         Optional[str] = None
    whatsapp_number:  Optional[str] = None
    invite_code:      str


class Token(BaseModel):
    access_token: str
    token_type:   str


class UserProfileOut(BaseModel):
    id:              int
    username:        str
    full_name:       Optional[str] = None
    role:            str
    facility:        Optional[str] = None
    district:        Optional[str] = None
    region:          Optional[str] = None
    whatsapp_number: Optional[str] = None
    is_active:       bool
    last_active:     Optional[datetime] = None
    created_at:      Optional[datetime] = None

    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    full_name:       Optional[str] = None
    whatsapp_number: Optional[str] = None
    facility:        Optional[str] = None
    district:        Optional[str] = None
    region:          Optional[str] = None


class PasswordChange(BaseModel):
    current_password: str
    new_password:     str = Field(..., min_length=8)
