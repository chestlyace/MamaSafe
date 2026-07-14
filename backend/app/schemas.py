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


class SHAPExplanation(BaseModel):
    feature:    str
    shap_value: float
    raw_value:  float


class PredictResponse(BaseModel):
    risk_level:      str
    confidence:      float
    prob_high:       float
    prob_low:        float
    prob_mid:        float
    recommendation:  str
    shap_values:     list[SHAPExplanation]
    assessment_id:   int


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


class UserCreate(BaseModel):
    username:  str
    password:  str
    role:      Optional[str] = "chw"
    full_name: Optional[str] = None
    facility:  Optional[str] = None


class Token(BaseModel):
    access_token: str
    token_type:   str
