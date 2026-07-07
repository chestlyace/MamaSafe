from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas import PredictRequest, PredictResponse
from app.models import predict as run_predict
from app.database import get_db, Assessment
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["prediction"])


@router.post("/predict", response_model=PredictResponse)
def predict_risk(
    request: PredictRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    result = run_predict(request.model_dump())

    record = Assessment(
        patient_ref   = request.patient_ref,
        age           = request.age,
        systolic_bp   = request.systolic_bp,
        diastolic_bp  = request.diastolic_bp,
        blood_sugar   = request.blood_sugar,
        body_temp     = request.body_temp,
        heart_rate    = request.heart_rate,
        risk_level    = result["risk_level"],
        prob_high     = result["prob_high"],
        prob_low      = result["prob_low"],
        prob_mid      = result["prob_mid"],
        shap_bs       = next((s["shap_value"] for s in result["shap_values"] if s["feature"] == "BS"), None),
        shap_systolic = next((s["shap_value"] for s in result["shap_values"] if s["feature"] == "SystolicBP"), None),
        shap_age      = next((s["shap_value"] for s in result["shap_values"] if s["feature"] == "Age"), None),
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return {**result, "assessment_id": record.id}
