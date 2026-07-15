from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, date
from dateutil.relativedelta import relativedelta

from app.database import get_db, Patient, Pregnancy, ANCVisit
from app.schemas_anc import (
    PatientCreate, PatientOut,
    PregnancyCreate, PregnancyOut,
    ANCVisitCreate, ANCVisitOut,
    ANCCardOut, DeliveryUpdate
)
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["anc"])


def calculate_edd(lmp_date_str: str) -> str:
    """Naegele's rule: EDD = LMP + 9 months + 7 days"""
    lmp = datetime.strptime(lmp_date_str, "%Y-%m-%d").date()
    edd = lmp + relativedelta(months=9, days=7)
    return str(edd)


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
    # CHWs see only their own patients; admins see all
    if current_user.role == "admin":
        return db.query(Patient).offset(skip).limit(limit).all()
    return (db.query(Patient)
              .filter(Patient.chw_id == current_user.id)
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
    (db.query(Pregnancy)
       .filter(Pregnancy.patient_id == data.patient_id,
               Pregnancy.is_active == True)
       .update({"is_active": False}))

    edd = calculate_edd(data.lmp_date)
    pregnancy = Pregnancy(**data.dict(), edd_date=edd)
    db.add(pregnancy)
    db.commit()
    db.refresh(pregnancy)
    return pregnancy


@router.patch("/pregnancies/{pregnancy_id}/delivery",
              response_model=PregnancyOut)
def record_delivery(
    pregnancy_id: int,
    data: DeliveryUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    pregnancy = db.query(Pregnancy).filter(
        Pregnancy.id == pregnancy_id).first()
    if not pregnancy:
        raise HTTPException(status_code=404, detail="Pregnancy not found")

    pregnancy.delivery_date     = data.delivery_date
    pregnancy.delivery_outcome  = data.delivery_outcome
    pregnancy.delivery_location = data.delivery_location
    pregnancy.is_active         = False
    db.commit()
    db.refresh(pregnancy)
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
