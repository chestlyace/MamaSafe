from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, date
from dateutil.relativedelta import relativedelta

from app.database import get_db, Patient, Pregnancy, ANCVisit, ScheduledVisit, User
from app.schemas_anc import (
    PatientCreate, PatientOut,
    PregnancyCreate, PregnancyOut,
    ANCVisitCreate, ANCVisitOut,
    ANCCardOut,
)
from app.routers.auth import get_current_user
from app.routers.schedule import auto_schedule_visits

router = APIRouter(prefix="/api/v1", tags=["anc"])


def calculate_edd(lmp_date_str: str) -> str:
    """Naegele's rule: EDD = LMP + 9 months + 7 days"""
    lmp = datetime.strptime(lmp_date_str, "%Y-%m-%d").date()
    edd = lmp + relativedelta(months=9, days=7)
    return str(edd)


def _accessible_chw_ids(db: Session, current_user) -> List[int]:
    if current_user.role == "admin":
        return [u.id for u in db.query(User.id).filter(User.role == "chw").all()]
    if current_user.role == "supervisor":
        return [current_user.id] + [u.id for u in db.query(User.id).filter(
            User.role == "chw",
            User.district == current_user.district,
        ).all()]
    return [current_user.id]


# ── PATIENTS ──────────────────────────────────────────────

@router.post("/patients", response_model=PatientOut)
def create_patient(
    data: PatientCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    patient = Patient(**data.dict(), chw_id=current_user.id)
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/patients", response_model=List[PatientOut])
def list_patients(
    skip: int = 0, limit: int = 50,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # CHWs see only their own patients; supervisors see their district's patients; admins see all
    chw_ids = _accessible_chw_ids(db, current_user)
    return (db.query(Patient)
              .filter(Patient.chw_id.in_(chw_ids))
              .offset(skip).limit(limit).all())


@router.get("/patients/{patient_id}", response_model=PatientOut)
def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    p = db.query(Patient).filter(Patient.id == patient_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Patient not found")
    return p


@router.get("/patients/{patient_id}/card", response_model=ANCCardOut)
def get_anc_card(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Returns the full ANC card — patient + active pregnancy + all visits"""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    pregnancy = (db.query(Pregnancy)
                   .filter(Pregnancy.patient_id == patient_id,
                           Pregnancy.is_active == True)
                   .first())
    visits = []
    if pregnancy:
        visits = (db.query(ANCVisit)
                    .filter(ANCVisit.pregnancy_id == pregnancy.id)
                    .order_by(ANCVisit.visit_number)
                    .all())

    # Also fetch past pregnancies for the "Past" tab
    all_pregnancies = (db.query(Pregnancy)
                         .filter(Pregnancy.patient_id == patient_id)
                         .order_by(Pregnancy.lmp_date.desc())
                         .all())

    return {
        "patient": patient,
        "pregnancy": pregnancy,
        "visits": visits,
        "pregnancies": all_pregnancies,
    }


# ── PREGNANCIES ───────────────────────────────────────────

@router.post("/pregnancies", response_model=PregnancyOut)
def register_pregnancy(
    data: PregnancyCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Deactivate any existing active pregnancy for this patient
    old_pregnancies = (db.query(Pregnancy)
                         .filter(Pregnancy.patient_id == data.patient_id,
                                 Pregnancy.is_active == True)
                         .all())
    for old in old_pregnancies:
        old.is_active = False
        # Cancel all scheduled visits for the old pregnancy
        (db.query(ScheduledVisit)
           .filter(ScheduledVisit.pregnancy_id == old.id,
                   ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
           .update({"status": "cancelled"}))

    edd = data.edd_date or calculate_edd(data.lmp_date)
    pregnancy = Pregnancy(**data.dict(exclude={"edd_date"}), edd_date=edd)
    db.add(pregnancy)
    db.commit()
    db.refresh(pregnancy)

    # Auto-generate 8 scheduled visits from LMP date
    auto_schedule_visits(db, pregnancy.id, data.lmp_date)

    return pregnancy


# ── ANC VISITS ────────────────────────────────────────────

@router.post("/anc-visits", response_model=ANCVisitOut)
def record_visit(
    data: ANCVisitCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Check visit number not already recorded for this pregnancy
    existing = (db.query(ANCVisit)
                  .filter(ANCVisit.pregnancy_id == data.pregnancy_id,
                          ANCVisit.visit_number == data.visit_number)
                  .first())
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Visit {data.visit_number} already recorded for this pregnancy")

    visit = ANCVisit(**data.dict())
    db.add(visit)
    db.commit()
    db.refresh(visit)

    # Auto-complete matching scheduled visit for this pregnancy/visit number
    scheduled = (db.query(ScheduledVisit)
                   .filter(ScheduledVisit.pregnancy_id == data.pregnancy_id,
                           ScheduledVisit.visit_number == data.visit_number,
                           ScheduledVisit.status.in_(["scheduled", "rescheduled"]))
                   .first())
    if scheduled:
        scheduled.status = "completed"
        scheduled.anc_visit_id = visit.id
        db.commit()

    return visit


@router.get("/anc-visits/{visit_id}", response_model=ANCVisitOut)
def get_visit(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(ANCVisit).filter(ANCVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    return visit


@router.patch("/anc-visits/{visit_id}", response_model=ANCVisitOut)
def update_visit(
    visit_id: int,
    data: ANCVisitCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(ANCVisit).filter(ANCVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
    for field, value in data.dict(exclude_unset=True).items():
        setattr(visit, field, value)
    db.commit()
    db.refresh(visit)
    return visit


@router.get("/pregnancies/{pregnancy_id}/visits",
            response_model=List[ANCVisitOut])
def list_visits(
    pregnancy_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(ANCVisit)
              .filter(ANCVisit.pregnancy_id == pregnancy_id)
              .order_by(ANCVisit.visit_number)
              .all())
