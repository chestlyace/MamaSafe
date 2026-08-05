from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas import PredictRequest, PredictResponse
from app.models import predict as run_predict
from app.database import get_db, Assessment
from app.routers.auth import get_current_user
from app.utils.risk_tracking import check_and_handle_escalation

router = APIRouter(prefix="/api/v1", tags=["prediction"])


@router.post("/predict", response_model=PredictResponse)
def predict_risk(
    request: PredictRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    result = run_predict(request.model_dump())

    record = Assessment(
        patient_ref   = request.patient_ref,
        patient_id    = request.patient_id,
        created_by    = current_user.id,
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

    # Longitudinal risk tracking — check for escalation
    escalation = None
    if request.patient_id:
        escalation = check_and_handle_escalation(
            db             = db,
            patient_id     = request.patient_id,
            new_assessment = record,
            chw            = current_user,
        )

    response = {**result, "assessment_id": record.id}
    if escalation:
        response["escalation_detected"] = True
        response["escalation_type"] = escalation.escalation_type
        response["previous_risk_level"] = escalation.previous_risk_level
    else:
        response["escalation_detected"] = False

    return response
