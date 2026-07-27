from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta

from app.database import (get_db, Assessment, Patient, RiskEscalationEvent)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["risk-trend"])

RISK_NUMERIC = {"low risk": 1, "mid risk": 2, "high risk": 3}


def compute_trend(assessments: list) -> str:
    if len(assessments) < 2:
        return "insufficient_data"
    first_score = RISK_NUMERIC.get(assessments[0].risk_level, 0)
    last_score = RISK_NUMERIC.get(assessments[-1].risk_level, 0)
    if last_score > first_score:
        return "escalating"
    if last_score < first_score:
        return "improving"
    return "stable"


@router.get("/patients/{patient_id}/risk-trend")
def get_risk_trend(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    assessments = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .order_by(Assessment.created_at.asc())
          .all()
    )

    if not assessments:
        return {
            "patient_id":         patient_id,
            "patient_name":       patient.full_name,
            "total_assessments":  0,
            "current_risk_level": None,
            "risk_trend":         "no_data",
            "last_escalation":    None,
            "assessments":        [],
            "feature_trends":     {},
        }

    assessment_data = []
    for i, a in enumerate(assessments):
        assessment_data.append({
            "id":              a.id,
            "visit_number":    i + 1,
            "date":            str(a.created_at.date()),
            "risk_level":      a.risk_level,
            "risk_numeric":    RISK_NUMERIC.get(a.risk_level, 0),
            "confidence":      round(max(a.prob_high or 0,
                                         a.prob_low or 0,
                                         a.prob_mid or 0), 4),
            "prob_high":       a.prob_high,
            "prob_low":        a.prob_low,
            "prob_mid":        a.prob_mid,
            "systolic_bp":     a.systolic_bp,
            "diastolic_bp":    a.diastolic_bp,
            "blood_sugar":     a.blood_sugar,
            "body_temp":       a.body_temp,
            "heart_rate":      a.heart_rate,
            "age":             a.age,
            "shap_bs":         a.shap_bs,
            "shap_systolic":   a.shap_systolic,
            "shap_age":        a.shap_age,
        })

    feature_trends = {
        "systolic_bp":   [a.systolic_bp for a in assessments if a.systolic_bp],
        "diastolic_bp":  [a.diastolic_bp for a in assessments if a.diastolic_bp],
        "blood_sugar":   [a.blood_sugar for a in assessments if a.blood_sugar],
        "body_temp":     [a.body_temp for a in assessments if a.body_temp],
        "heart_rate":    [a.heart_rate for a in assessments if a.heart_rate],
        "shap_bs":       [a.shap_bs for a in assessments if a.shap_bs is not None],
        "shap_systolic": [a.shap_systolic for a in assessments if a.shap_systolic is not None],
        "shap_age":      [a.shap_age for a in assessments if a.shap_age is not None],
    }

    last_escalation = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .order_by(RiskEscalationEvent.created_at.desc())
          .first()
    )

    escalation_data = None
    if last_escalation:
        escalation_data = {
            "from": last_escalation.previous_risk_level,
            "to":   last_escalation.new_risk_level,
            "date": str(last_escalation.created_at.date()),
            "type": last_escalation.escalation_type,
        }

    return {
        "patient_id":         patient_id,
        "patient_name":       patient.full_name,
        "total_assessments":  len(assessments),
        "current_risk_level": assessments[-1].risk_level,
        "risk_trend":         compute_trend(assessments),
        "last_escalation":    escalation_data,
        "assessments":        assessment_data,
        "feature_trends":     feature_trends,
    }


@router.get("/patients/{patient_id}/risk-summary")
def get_risk_summary(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    assessments = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .order_by(Assessment.created_at.desc())
          .limit(2)
          .all()
    )

    if not assessments:
        return {
            "patient_id":         patient_id,
            "total_assessments":  0,
            "current_risk_level": None,
            "risk_trend":         "no_data",
            "escalation_count":   0,
        }

    current = assessments[0]
    previous = assessments[1] if len(assessments) > 1 else None

    RISK_ORDER = {"low risk": 1, "mid risk": 2, "high risk": 3}
    trend = "stable"
    if previous:
        cs = RISK_ORDER.get(current.risk_level, 0)
        ps = RISK_ORDER.get(previous.risk_level, 0)
        if cs > ps:
            trend = "escalating"
        elif cs < ps:
            trend = "improving"

    escalation_count = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .count()
    )

    total = (
        db.query(Assessment)
          .filter(Assessment.patient_id == patient_id)
          .count()
    )

    return {
        "patient_id":           patient_id,
        "total_assessments":    total,
        "current_risk_level":   current.risk_level,
        "previous_risk_level":  previous.risk_level if previous else None,
        "last_assessment_date": str(current.created_at.date()),
        "risk_trend":           trend,
        "escalation_count":     escalation_count,
    }


@router.get("/patients/{patient_id}/escalations")
def get_patient_escalations(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    events = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.patient_id == patient_id)
          .order_by(RiskEscalationEvent.created_at.desc())
          .all()
    )
    return [
        {
            "id":                     e.id,
            "from":                   e.previous_risk_level,
            "to":                     e.new_risk_level,
            "escalation_type":        e.escalation_type,
            "date":                   str(e.created_at.date()),
            "whatsapp_sent":          e.whatsapp_sent,
            "whatsapp_error":         getattr(e, "whatsapp_error", None),
            "previous_assessment_id": e.previous_assessment_id,
            "new_assessment_id":      e.new_assessment_id,
        }
        for e in events
    ]


@router.get("/risk-escalations/recent")
def recent_escalations(
    days: int = 7,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    since = date.today() - timedelta(days=days)
    q = (
        db.query(RiskEscalationEvent)
          .filter(RiskEscalationEvent.created_at >= str(since))
          .order_by(RiskEscalationEvent.created_at.desc())
    )
    if current_user.role != "admin":
        q = q.filter(RiskEscalationEvent.chw_id == current_user.id)

    events = q.limit(limit).all()

    result = []
    for e in events:
        patient = db.query(Patient).filter(Patient.id == e.patient_id).first()
        result.append({
            "patient_id":      e.patient_id,
            "patient_name":    patient.full_name if patient else "Unknown",
            "from":            e.previous_risk_level,
            "to":              e.new_risk_level,
            "escalation_type": e.escalation_type,
            "date":            str(e.created_at.date()),
            "whatsapp_sent":   e.whatsapp_sent,
        })
    return result


@router.get("/risk-escalations/analytics")
def escalation_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    q = db.query(RiskEscalationEvent)
    if current_user.role != "admin":
        q = q.filter(RiskEscalationEvent.chw_id == current_user.id)

    total = q.count()
    low_to_mid = q.filter(
        RiskEscalationEvent.escalation_type == "low_risk_to_mid_risk"
    ).count()
    mid_to_high = q.filter(
        RiskEscalationEvent.escalation_type == "mid_risk_to_high_risk"
    ).count()
    low_to_high = q.filter(
        RiskEscalationEvent.escalation_type == "low_risk_to_high_risk"
    ).count()

    subq = (
        db.query(Assessment.patient_id,
                 func.max(Assessment.created_at).label("latest"))
          .filter(Assessment.patient_id.isnot(None))
          .group_by(Assessment.patient_id)
          .subquery()
    )
    latest_assessments = (
        db.query(Assessment)
          .join(subq, (Assessment.patient_id == subq.c.patient_id) &
                      (Assessment.created_at == subq.c.latest))
          .filter(Assessment.risk_level == "high risk")
          .count()
    )

    one_week_ago = date.today() - timedelta(days=7)
    this_week = q.filter(
        RiskEscalationEvent.created_at >= str(one_week_ago)
    ).count()

    return {
        "total_escalations":            total,
        "low_to_mid":                   low_to_mid,
        "mid_to_high":                  mid_to_high,
        "low_to_high":                  low_to_high,
        "patients_currently_high_risk": latest_assessments,
        "patients_escalated_this_week": this_week,
    }
