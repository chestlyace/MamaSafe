from datetime import date, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.schemas import DashboardSummary
from app.database import (
    get_db, Assessment, Patient, Pregnancy,
    ScheduledVisit, Referral, RiskEscalationEvent, User,
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["dashboard"])


def _get_district_chw_ids(db: Session, current_user) -> list[int]:
    """Get CHW IDs in the current user's district (for supervisors) or just the CHW's own ID."""
    if current_user.role == "admin":
        return [u.id for u in db.query(User.id).filter(User.role == "chw").all()]
    if current_user.role == "supervisor":
        return [u.id for u in db.query(User.id)
                .filter(User.role == "chw", User.district == current_user.district).all()]
    # CHW: only their own ID
    return [current_user.id]


def _get_district_patient_ids(db: Session, chw_ids: list[int]) -> list[int]:
    """Get patient IDs for the given CHW IDs."""
    return [p.id for p in db.query(Patient.id).filter(Patient.chw_id.in_(chw_ids)).all()]


@router.get("/dashboard/summary", response_model=DashboardSummary)
def get_summary(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Admin sees everything (preserve original behaviour)
    if current_user.role == "admin":
        total = db.query(Assessment).count()
        high  = db.query(Assessment).filter(Assessment.risk_level == "high risk").count()
        mid   = db.query(Assessment).filter(Assessment.risk_level == "mid risk").count()
        low   = db.query(Assessment).filter(Assessment.risk_level == "low risk").count()

        total_patients = db.query(Patient).count()
        active_pregnancies = db.query(Pregnancy).filter(Pregnancy.is_active == True).count()
        pending_referrals = db.query(Referral).filter(Referral.status == "SENT").count()

        today = str(date.today())
        end_week = str(date.today() + timedelta(days=7))
        upcoming_visits = (db.query(ScheduledVisit)
                             .filter(ScheduledVisit.scheduled_date >= today,
                                     ScheduledVisit.scheduled_date <= end_week,
                                     ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
                             .count())

        seven_days_ago = str(date.today() - timedelta(days=7))
        recent_escalations = (db.query(RiskEscalationEvent)
                               .filter(RiskEscalationEvent.created_at >= seven_days_ago)
                               .count())

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

    chw_ids = _get_district_chw_ids(db, current_user)
    patient_ids = _get_district_patient_ids(db, chw_ids)

    # Assessment counts (scoped to district patients)
    total = db.query(Assessment).filter(Assessment.patient_id.in_(patient_ids)).count() if patient_ids else 0
    high  = db.query(Assessment).filter(Assessment.patient_id.in_(patient_ids), Assessment.risk_level == "high risk").count() if patient_ids else 0
    mid   = db.query(Assessment).filter(Assessment.patient_id.in_(patient_ids), Assessment.risk_level == "mid risk").count() if patient_ids else 0
    low   = db.query(Assessment).filter(Assessment.patient_id.in_(patient_ids), Assessment.risk_level == "low risk").count() if patient_ids else 0

    # Patient & pregnancy counts (scoped to district CHWs)
    total_patients = len(patient_ids)
    active_pregnancies = (db.query(Pregnancy)
                           .filter(Pregnancy.patient_id.in_(patient_ids),
                                   Pregnancy.is_active == True)
                           .count()) if patient_ids else 0

    # Pending referrals (SENT status) - scoped to district CHWs
    pending_referrals = (db.query(Referral)
                          .filter(Referral.chw_id.in_(chw_ids),
                                  Referral.status == "SENT")
                          .count()) if chw_ids else 0

    # Upcoming scheduled visits (next 7 days) - scoped to district patients
    today = str(date.today())
    end_week = str(date.today() + timedelta(days=7))
    upcoming_visits = (db.query(ScheduledVisit)
                         .join(Pregnancy, Pregnancy.id == ScheduledVisit.pregnancy_id)
                         .join(Patient, Patient.id == Pregnancy.patient_id)
                         .filter(Patient.id.in_(patient_ids),
                                 ScheduledVisit.scheduled_date >= today,
                                 ScheduledVisit.scheduled_date <= end_week,
                                 ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
                         .count()) if patient_ids else 0

    # Recent escalations (last 7 days) - scoped to district CHWs
    seven_days_ago = str(date.today() - timedelta(days=7))
    recent_escalations = (db.query(RiskEscalationEvent)
                           .filter(RiskEscalationEvent.chw_id.in_(chw_ids),
                                   RiskEscalationEvent.created_at >= seven_days_ago)
                           .count()) if chw_ids else 0

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
