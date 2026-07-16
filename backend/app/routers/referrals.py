from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.database import get_db, Patient, Pregnancy, Assessment, Facility, Referral
from app.schemas_referral import (
    ReferralCreate, ReferralQuickCreate, ReferralOut, ReferralStatusUpdate, ReferralStats
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["referrals"])


def build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user):
    """Build the self-contained referral snapshot from patient/pregnancy/assessment data."""
    snapshot = {
        "patient_id": patient.id,
        "assessment_id": getattr(assessment, 'id', None) if assessment else None,
        "facility_id": facility.id,
        "facility_name": facility.name,
        "chw_id": current_user.id,
        "patient_name": patient.full_name,
        "patient_age": int(assessment.age) if assessment and assessment.age else None,
        "patient_phone": patient.phone,
        "patient_blood_group": patient.blood_group,
        "patient_allergies": patient.allergies,
        "emergency_contact_name": patient.emergency_contact_name,
        "emergency_contact_phone": patient.emergency_contact_phone,
        "gravida": pregnancy.gravida if pregnancy else None,
        "parity": pregnancy.parity if pregnancy else None,
        "edd_date": pregnancy.edd_date if pregnancy else None,
        "gestational_age": getattr(data, 'gestational_age', None),
        "systolic_bp": getattr(data, 'systolic_bp', None) or (assessment.systolic_bp if assessment else None),
        "diastolic_bp": getattr(data, 'diastolic_bp', None) or (assessment.diastolic_bp if assessment else None),
        "heart_rate": getattr(data, 'heart_rate', None) or (int(assessment.heart_rate) if assessment and assessment.heart_rate else None),
        "body_temp": getattr(data, 'body_temp', None) or (assessment.body_temp if assessment else None),
        "blood_sugar": getattr(data, 'blood_sugar', None) or (assessment.blood_sugar if assessment else None),
        "risk_level": assessment.risk_level if assessment else None,
        "risk_probability": assessment.prob_high if assessment else None,
        "complication_type": getattr(data, 'complication_type', None),
        "chw_notes": getattr(data, 'chw_notes', None),
        "sent_at": datetime.utcnow(),
        "status": "SENT",
    }
    return snapshot


@router.post("/referrals", response_model=ReferralOut)
def create_referral(
    data: ReferralCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    facility = db.query(Facility).filter(Facility.id == data.facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")

    assessment = None
    if data.assessment_id:
        assessment = db.query(Assessment).filter(Assessment.id == data.assessment_id).first()

    pregnancy = db.query(Pregnancy).filter(
        Pregnancy.patient_id == data.patient_id, Pregnancy.is_active == True
    ).first()

    snapshot = build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user)
    referral = Referral(**snapshot)
    db.add(referral)
    db.commit()
    db.refresh(referral)
    return referral


@router.post("/referrals/quick", response_model=ReferralOut)
def quick_referral(
    data: ReferralQuickCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    assessment = db.query(Assessment).filter(Assessment.id == data.assessment_id).first()
    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")

    facility = db.query(Facility).filter(Facility.id == data.facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")

    patient = None
    if assessment.patient_id:
        patient = db.query(Patient).filter(Patient.id == assessment.patient_id).first()

    pregnancy = None
    if patient:
        pregnancy = db.query(Pregnancy).filter(
            Pregnancy.patient_id == patient.id, Pregnancy.is_active == True
        ).first()

    if not patient:
        raise HTTPException(status_code=400, detail="Assessment has no linked patient. Use POST /referrals instead.")

    snapshot = build_referral_snapshot(patient, pregnancy, assessment, facility, data, current_user)
    referral = Referral(**snapshot)
    db.add(referral)
    db.commit()
    db.refresh(referral)
    return referral


@router.get("/referrals", response_model=List[ReferralOut])
def list_referrals(
    status: Optional[str] = None,
    facility_id: Optional[int] = None,
    patient_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = db.query(Referral)
    if current_user.role != "admin":
        q = q.filter(Referral.chw_id == current_user.id)
    if status:
        q = q.filter(Referral.status == status)
    if facility_id:
        q = q.filter(Referral.facility_id == facility_id)
    if patient_id:
        q = q.filter(Referral.patient_id == patient_id)
    return q.order_by(Referral.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/referrals/{referral_id}", response_model=ReferralOut)
def get_referral(
    referral_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    referral = db.query(Referral).filter(Referral.id == referral_id).first()
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")
    return referral


@router.patch("/referrals/{referral_id}/status", response_model=ReferralOut)
def update_referral_status(
    referral_id: int,
    data: ReferralStatusUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    referral = db.query(Referral).filter(Referral.id == referral_id).first()
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")

    referral.status = data.status
    now = datetime.utcnow()
    if data.status == "RECEIVED":
        referral.received_at = now
    elif data.status == "PATIENT_ARRIVED":
        referral.patient_arrived_at = now

    db.commit()
    db.refresh(referral)
    return referral


@router.get("/referrals/stats", response_model=ReferralStats)
def get_referral_stats(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    q = db.query(Referral)
    if current_user.role != "admin":
        q = q.filter(Referral.chw_id == current_user.id)

    total_sent = q.filter(Referral.status == "SENT").count()
    total_received = q.filter(Referral.status == "RECEIVED").count()
    total_arrived = q.filter(Referral.status == "PATIENT_ARRIVED").count()
    total_all = total_sent + total_received + total_arrived
    completion_rate = (total_arrived / total_all * 100) if total_all > 0 else 0.0

    # Avg response time (SENT -> RECEIVED) in minutes
    responded = q.filter(Referral.received_at.isnot(None)).all()
    avg_response_minutes = None
    if responded:
        deltas = [(r.received_at - r.sent_at).total_seconds() / 60 for r in responded if r.sent_at]
        avg_response_minutes = round(sum(deltas) / len(deltas), 1) if deltas else None

    # Stale: SENT for > 2 hours without status update
    from datetime import timedelta
    two_hours_ago = datetime.utcnow() - timedelta(hours=2)
    stale_count = q.filter(Referral.status == "SENT", Referral.sent_at < two_hours_ago).count()

    return ReferralStats(
        total_sent=total_sent,
        total_received=total_received,
        total_arrived=total_arrived,
        completion_rate=round(completion_rate, 1),
        avg_response_minutes=avg_response_minutes,
        stale_count=stale_count,
    )
