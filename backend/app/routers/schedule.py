"""ANC Visit Scheduler — API endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date, timedelta, datetime

from app.database import get_db, ScheduledVisit, Pregnancy, Patient, User
from app.schemas_schedule import ScheduledVisitOut, RescheduleRequest, CompleteVisitRequest
from app.routers.auth import get_current_user
from app.services.delivery import send_whatsapp
from app.utils.whatsapp import build_reschedule_confirmation, build_48h_reminder

router = APIRouter(prefix="/api/v1/schedule", tags=["schedule"])


def _accessible_patient_ids(db: Session, current_user) -> list[int]:
    """Return patient IDs the current user is allowed to see."""
    if current_user.role == "admin":
        return [p.id for p in db.query(Patient.id).all()]
    if current_user.role == "supervisor":
        chw_ids = [u.id for u in db.query(User.id)
                   .filter(User.role == "chw",
                           User.district == current_user.district).all()]
        return [p.id for p in db.query(Patient.id)
                .filter(Patient.chw_id.in_(chw_ids)).all()]
    return [p.id for p in db.query(Patient.id)
            .filter(Patient.chw_id == current_user.id).all()]

VISIT_SCHEDULE = [
    {"visit_number": 1, "gestational_week": 8,  "label": "Booking visit"},
    {"visit_number": 2, "gestational_week": 16, "label": "Second trimester check"},
    {"visit_number": 3, "gestational_week": 20, "label": "Anomaly screen"},
    {"visit_number": 4, "gestational_week": 26, "label": "Glucose screening"},
    {"visit_number": 5, "gestational_week": 30, "label": "Birth plan begins"},
    {"visit_number": 6, "gestational_week": 34, "label": "Presentation check"},
    {"visit_number": 7, "gestational_week": 36, "label": "Final preparation"},
    {"visit_number": 8, "gestational_week": 38, "label": "Pre-labour review"},
]


def auto_schedule_visits(db: Session, pregnancy_id: int, lmp_date_str: str):
    """Called automatically when a pregnancy is registered.
    Creates 8 ScheduledVisit records based on LMP date.
    Skips any visit numbers that already exist for this pregnancy."""
    existing_numbers = {
        sv.visit_number for sv in
        db.query(ScheduledVisit.visit_number)
          .filter(ScheduledVisit.pregnancy_id == pregnancy_id)
          .all()
    }
    lmp = datetime.strptime(lmp_date_str, "%Y-%m-%d").date()
    for v in VISIT_SCHEDULE:
        if v["visit_number"] in existing_numbers:
            continue
        visit_date = lmp + timedelta(weeks=v["gestational_week"])
        sv = ScheduledVisit(
            pregnancy_id    = pregnancy_id,
            visit_number    = v["visit_number"],
            gestational_week = v["gestational_week"],
            label           = v["label"],
            scheduled_date  = str(visit_date),
            status          = "scheduled",
        )
        db.add(sv)
    db.commit()


@router.get("/{pregnancy_id}", response_model=List[ScheduledVisitOut])
def get_schedule(
    pregnancy_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get the full 8-visit schedule for a pregnancy."""
    return (db.query(ScheduledVisit)
              .filter(ScheduledVisit.pregnancy_id == pregnancy_id)
              .order_by(ScheduledVisit.visit_number)
              .all())


@router.get("/today/list")
def get_todays_visits(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all visits scheduled for today across the user's patients."""
    today = str(date.today())
    accessible_patient_ids = _accessible_patient_ids(db, current_user)
    visits = (db.query(ScheduledVisit)
                .filter(ScheduledVisit.scheduled_date == today,
                        ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
                .all())
    result = []
    for v in visits:
        preg = db.query(Pregnancy).filter(
            Pregnancy.id == v.pregnancy_id,
            Pregnancy.is_active == True).first()
        if not preg:
            continue
        if preg.patient_id not in accessible_patient_ids:
            continue
        patient = db.query(Patient).filter(Patient.id == preg.patient_id).first()
        if not patient:
            continue
        result.append({
            "visit_id":      v.id,
            "visit_number":  v.visit_number,
            "label":         v.label,
            "patient_name":  patient.full_name,
            "patient_phone": patient.phone,
            "patient_id":    patient.id,
            "pregnancy_id":  v.pregnancy_id,
        })
    return result


@router.get("/upcoming/list")
def get_upcoming_visits(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get the next N days of scheduled visits for the user's patients."""
    today = date.today()
    end   = today + timedelta(days=days)
    accessible_patient_ids = _accessible_patient_ids(db, current_user)
    visits = (db.query(ScheduledVisit)
                .filter(ScheduledVisit.scheduled_date >= str(today),
                        ScheduledVisit.scheduled_date <= str(end),
                        ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
                .order_by(ScheduledVisit.scheduled_date)
                .all())
    result = []
    for v in visits:
        preg = db.query(Pregnancy).filter(
            Pregnancy.id == v.pregnancy_id,
            Pregnancy.is_active == True).first()
        if not preg:
            continue
        if preg.patient_id not in accessible_patient_ids:
            continue
        patient = db.query(Patient).filter(Patient.id == preg.patient_id).first()
        if not patient:
            continue
        result.append({
            "visit_id":       v.id,
            "visit_number":   v.visit_number,
            "label":          v.label,
            "scheduled_date": v.scheduled_date,
            "patient_name":   patient.full_name,
            "patient_id":     patient.id,
        })
    return result


@router.patch("/{visit_id}/reschedule", response_model=ScheduledVisitOut)
async def reschedule_visit(
    visit_id: int,
    data: RescheduleRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Reschedule a visit to a new date."""
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    if not visit.original_date:
        visit.original_date = visit.scheduled_date

    visit.scheduled_date     = data.new_date
    visit.status             = "rescheduled"
    visit.reschedule_reason  = data.reason
    visit.reminder_48h_sent  = False
    visit.reminder_day_sent  = False
    db.commit()
    db.refresh(visit)

    preg = db.query(Pregnancy).filter(
        Pregnancy.id == visit.pregnancy_id).first()
    if preg:
        patient = db.query(Patient).filter(
            Patient.id == preg.patient_id).first()
        if patient and patient.phone:
            message = build_reschedule_confirmation(
                patient_name=patient.full_name,
                visit_number=visit.visit_number,
                new_date=data.new_date,
                facility=patient.facility or "Your health centre",
                lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
            )
            send_whatsapp(patient.phone, message)

    return visit


@router.patch("/{visit_id}/complete", response_model=ScheduledVisitOut)
def complete_visit(
    visit_id: int,
    data: CompleteVisitRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Mark a scheduled visit as completed."""
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    visit.status       = "completed"
    visit.anc_visit_id = data.anc_visit_id
    db.commit()
    db.refresh(visit)
    return visit


@router.patch("/{visit_id}/cancel", response_model=ScheduledVisitOut)
def cancel_visit(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Cancel a specific scheduled visit."""
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    visit.status = "cancelled"
    db.commit()
    db.refresh(visit)
    return visit


@router.post("/send-reminder/{visit_id}")
async def manual_reminder(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Manually trigger a WhatsApp reminder for a specific visit."""
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    preg = db.query(Pregnancy).filter(
        Pregnancy.id == visit.pregnancy_id).first()
    patient = db.query(Patient).filter(
        Patient.id == preg.patient_id).first() if preg else None
    chw = db.query(User).filter(
        User.id == patient.chw_id).first() if patient else None

    if not patient or not patient.phone:
        raise HTTPException(status_code=400,
                            detail="Patient has no phone number")

    message = build_48h_reminder(
        patient_name=patient.full_name,
        visit_number=visit.visit_number,
        visit_label=visit.label or "",
        visit_date=visit.scheduled_date,
        facility=patient.facility or "Your health centre",
        chw_name=chw.full_name if chw else "Your CHW",
        chw_phone=getattr(chw, 'whatsapp_number', '') or "",
        lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
    )

    result = send_whatsapp(patient.phone, message)
    return {"success": result["success"], "status": result.get("error", "sent")}


@router.get("/analytics/summary")
def schedule_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Summary statistics for the user's visit schedule."""
    patient_ids = _accessible_patient_ids(db, current_user)
    pregnancy_ids = [
        pr.id for pr in db.query(Pregnancy).filter(
            Pregnancy.patient_id.in_(patient_ids)).all()
    ]
    q = db.query(ScheduledVisit).filter(
        ScheduledVisit.pregnancy_id.in_(pregnancy_ids))

    total     = q.count()
    completed = q.filter(ScheduledVisit.status == "completed").count()
    missed    = q.filter(ScheduledVisit.status == "missed").count()
    today     = str(date.today())
    end_week  = str(date.today() + timedelta(days=7))
    upcoming  = q.filter(ScheduledVisit.status == "scheduled",
                          ScheduledVisit.scheduled_date >= today,
                          ScheduledVisit.scheduled_date <= end_week).count()

    return {
        "total_scheduled":     total,
        "completed":           completed,
        "missed":              missed,
        "upcoming_this_week":  upcoming,
        "completion_rate":     round(completed / total * 100, 1) if total else 0,
        "missed_rate":         round(missed / total * 100, 1) if total else 0,
    }


# ── DEV-ONLY ──────────────────────────────────────────────

@router.post("/test/run-jobs")
def run_jobs_manually(current_user = Depends(get_current_user)):
    """Manually trigger all scheduler jobs (dev only)."""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    from app.utils.scheduler_jobs import (
        job_send_48h_reminders,
        job_send_day_reminders_and_chw_list,
        job_detect_missed_visits,
    )
    job_send_48h_reminders()
    job_send_day_reminders_and_chw_list()
    job_detect_missed_visits()
    return {"message": "All jobs executed"}
