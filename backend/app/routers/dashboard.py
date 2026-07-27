from datetime import date, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas import DashboardSummary
from app.database import (
    get_db, Assessment, Patient, Pregnancy,
    ScheduledVisit, Referral, RiskEscalationEvent,
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["dashboard"])


@router.get("/dashboard/summary", response_model=DashboardSummary)
def get_summary(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    total = db.query(Assessment).count()
    high  = db.query(Assessment).filter(Assessment.risk_level == "high risk").count()
    mid   = db.query(Assessment).filter(Assessment.risk_level == "mid risk").count()
    low   = db.query(Assessment).filter(Assessment.risk_level == "low risk").count()

    # Patient & pregnancy counts (CHW-scoped)
    if current_user.role == "admin":
        patient_q = db.query(Patient)
        pregnancy_q = db.query(Pregnancy)
    else:
        patient_q = db.query(Patient).filter(Patient.chw_id == current_user.id)
        pregnancy_q = (db.query(Pregnancy)
                         .join(Patient, Patient.id == Pregnancy.patient_id)
                         .filter(Patient.chw_id == current_user.id))

    total_patients = patient_q.count()
    active_pregnancies = pregnancy_q.filter(Pregnancy.is_active == True).count()

    # Pending referrals (SENT status)
    referral_q = db.query(Referral).filter(Referral.status == "SENT")
    if current_user.role != "admin":
        referral_q = referral_q.filter(Referral.chw_id == current_user.id)
    pending_referrals = referral_q.count()

    # Upcoming scheduled visits (next 7 days)
    today = str(date.today())
    end_week = str(date.today() + timedelta(days=7))
    visit_q = (db.query(ScheduledVisit)
                 .filter(ScheduledVisit.scheduled_date >= today,
                         ScheduledVisit.scheduled_date <= end_week,
                         ScheduledVisit.status.in_(["scheduled", "rescheduled"])))
    if current_user.role != "admin":
        visit_q = (visit_q
                     .join(Pregnancy, Pregnancy.id == ScheduledVisit.pregnancy_id)
                     .join(Patient, Patient.id == Pregnancy.patient_id)
                     .filter(Patient.chw_id == current_user.id))
    upcoming_visits = visit_q.count()

    # Recent escalations (last 7 days)
    seven_days_ago = str(date.today() - timedelta(days=7))
    esc_q = db.query(RiskEscalationEvent).filter(
        RiskEscalationEvent.created_at >= seven_days_ago)
    if current_user.role != "admin":
        esc_q = esc_q.filter(RiskEscalationEvent.chw_id == current_user.id)
    recent_escalations = esc_q.count()

    return {
        "total_assessments": total,
        "high_risk_count":   high,
        "mid_risk_count":    mid,
        "low_risk_count":    low,
        "high_risk_pct":     round(high / total * 100, 1) if total else 0,
        "mid_risk_pct":      round(mid  / total * 100, 1) if total else 0,
        "low_risk_pct":      round(low  / total * 100, 1) if total else 0,
        "total_patients":     total_patients,
        "active_pregnancies": active_pregnancies,
        "pending_referrals":  pending_referrals,
        "upcoming_visits":    upcoming_visits,
        "recent_escalations": recent_escalations,
    }
