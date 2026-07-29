from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta

from app.database import (
    get_db, Patient, Pregnancy,
    Delivery, Newborn, PostnatalVisit, PostnatalScheduledVisit,
    MentalHealthScreening,
)
from app.schemas_postnatal import (
    DeliveryCreate, DeliveryOut,
    PostnatalVisitCreate, PostnatalVisitOut,
    PostnatalScheduledVisitOut,
    MentalHealthScreeningCreate, MentalHealthScreeningOut,
    PostnatalScheduleOut,
)
from app.routers.auth import get_current_user
from app.services.delivery import send_whatsapp
from app.utils.growth_tracker import build_or_refresh_alerts

router = APIRouter(prefix="/api/v1", tags=["postnatal"])

PNC_SCHEDULE = [
    {"visit_number": 1, "days_after_delivery": 1,  "label": "PNC 1 — 24h check"},
    {"visit_number": 2, "days_after_delivery": 6,  "label": "PNC 2 — Day 6"},
    {"visit_number": 3, "days_after_delivery": 42, "label": "PNC 3 — Day 42"},
]


def _schedule_pnc_visits(db: Session, delivery: Delivery):
    """Create the 3 standard PNC scheduled visits."""
    base = datetime.strptime(delivery.delivery_date, "%Y-%m-%d")
    for entry in PNC_SCHEDULE:
        scheduled_date = base + timedelta(days=entry["days_after_delivery"])
        visit = PostnatalScheduledVisit(
            delivery_id=delivery.id,
            visit_number=entry["visit_number"],
            days_after_delivery=entry["days_after_delivery"],
            label=entry["label"],
            scheduled_date=scheduled_date.strftime("%Y-%m-%d"),
        )
        db.add(visit)
    db.commit()


def _send_delivery_whatsapp(patient: Patient, delivery: Delivery):
    """Send delivery notification WhatsApp to the patient."""
    phone = patient.phone
    if not phone:
        return
    lang = patient.preferred_language or "fr"
    if lang == "en":
        msg = (
            f"\U0001f476 *MamaSafe — Delivery Recorded*\n\n"
            f"Hello {patient.full_name},\n\n"
            f"Your delivery on *{delivery.delivery_date}* has been recorded.\n\n"
            f"\U0001f4cb *Your postnatal care schedule:*\n"
            f"• Visit 1 (Day 1): {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d')}\n"
            f"• Visit 2 (Day 6): {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=6)).strftime('%Y-%m-%d')}\n"
            f"• Visit 3 (Day 42): {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=42)).strftime('%Y-%m-%d')}\n\n"
            f"Please attend all visits for your recovery and your baby's health.\n\n"
            f"_MamaSafe supports you and your newborn._"
        )
    else:
        msg = (
            f"\U0001f476 *MamaSafe — Accouchement enregistré*\n\n"
            f"Bonjour {patient.full_name},\n\n"
            f"Votre accouchement du *{delivery.delivery_date}* a été enregistré.\n\n"
            f"\U0001f4cb *Votre calendrier de soins postnataux :*\n"
            f"• Visite 1 (Jour 1) : {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d')}\n"
            f"• Visite 2 (Jour 6) : {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=6)).strftime('%Y-%m-%d')}\n"
            f"• Visite 3 (Jour 42) : {(datetime.strptime(delivery.delivery_date, '%Y-%m-%d') + timedelta(days=42)).strftime('%Y-%m-%d')}\n\n"
            f"Veuillez assister à toutes les visites pour votre récupération et la santé de votre bébé.\n\n"
            f"_MamaSafe vous accompagne avec votre nouveau-né._"
        )
    send_whatsapp(phone, msg)


# ── DELIVERIES ────────────────────────────────────────────

@router.post("/deliveries", response_model=DeliveryOut)
def record_delivery(
    data: DeliveryCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    pregnancy = db.query(Pregnancy).filter(Pregnancy.id == data.pregnancy_id).first()
    if not pregnancy:
        raise HTTPException(status_code=404, detail="Pregnancy not found")

    patient = db.query(Patient).filter(Patient.id == pregnancy.patient_id).first()

    # Close the pregnancy
    pregnancy.is_active = False

    delivery = Delivery(
        pregnancy_id=data.pregnancy_id,
        patient_id=pregnancy.patient_id,
        delivery_date=data.delivery_date,
        delivery_location=data.delivery_location,
        delivered_by=data.delivered_by,
        complications=data.complications,
        notes=data.notes,
    )
    db.add(delivery)
    db.flush()

    for nb in data.newborns:
        newborn = Newborn(delivery_id=delivery.id, **nb.dict())
        db.add(newborn)

    db.commit()
    db.refresh(delivery)

    _schedule_pnc_visits(db, delivery)
    _send_delivery_whatsapp(patient, delivery)

    return delivery


@router.get("/deliveries/{delivery_id}", response_model=DeliveryOut)
def get_delivery(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=404, detail="Delivery not found")
    return delivery


@router.get("/patients/{patient_id}/deliveries", response_model=List[DeliveryOut])
def list_patient_deliveries(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(Delivery)
              .filter(Delivery.patient_id == patient_id)
              .order_by(Delivery.delivery_date.desc())
              .all())


# ── POSTNATAL VISITS ─────────────────────────────────────

@router.post("/postnatal-visits", response_model=PostnatalVisitOut)
def record_postnatal_visit(
    data: PostnatalVisitCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    existing = (db.query(PostnatalVisit)
                  .filter(PostnatalVisit.delivery_id == data.delivery_id,
                          PostnatalVisit.visit_number == data.visit_number)
                  .first())
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Postnatal visit {data.visit_number} already recorded for this delivery")

    visit = PostnatalVisit(**data.dict())
    db.add(visit)
    db.flush()

    scheduled = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id == data.delivery_id,
                           PostnatalScheduledVisit.visit_number == data.visit_number,
                           PostnatalScheduledVisit.status.in_(["scheduled"]))
                   .first())
    if scheduled:
        scheduled.status = "completed"
        scheduled.postnatal_visit_id = visit.id

    db.commit()
    db.refresh(visit)

    if data.newborn_id and data.newborn_weight_kg is not None:
        newborn = db.query(Newborn).filter(Newborn.id == data.newborn_id).first()
        if newborn:
            visits_with_weights = (
                db.query(PostnatalVisit)
                .filter(
                    PostnatalVisit.newborn_id == data.newborn_id,
                    PostnatalVisit.newborn_weight_kg.isnot(None),
                )
                .order_by(PostnatalVisit.visit_date)
                .all()
            )
            build_or_refresh_alerts(db, newborn, visits_with_weights)

    return visit


@router.get("/postnatal-visits/{visit_id}", response_model=PostnatalVisitOut)
def get_postnatal_visit(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(PostnatalVisit).filter(PostnatalVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Postnatal visit not found")
    return visit


@router.get("/deliveries/{delivery_id}/visits",
            response_model=List[PostnatalVisitOut])
def list_postnatal_visits(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(PostnatalVisit)
              .filter(PostnatalVisit.delivery_id == delivery_id)
              .order_by(PostnatalVisit.visit_number)
              .all())


# ── SCHEDULE ──────────────────────────────────────────────

@router.get("/deliveries/{delivery_id}/schedule",
            response_model=PostnatalScheduleOut)
def get_postnatal_schedule(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    delivery = db.query(Delivery).filter(Delivery.id == delivery_id).first()
    if not delivery:
        raise HTTPException(status_code=404, detail="Delivery not found")

    scheduled = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id == delivery_id)
                   .order_by(PostnatalScheduledVisit.visit_number)
                   .all())
    visits = (db.query(PostnatalVisit)
                .filter(PostnatalVisit.delivery_id == delivery_id)
                .order_by(PostnatalVisit.visit_number)
                .all())
    return {"delivery": delivery, "scheduled_visits": scheduled, "visits": visits}


@router.patch("/postnatal-scheduled-visits/{visit_id}/status",
              response_model=PostnatalScheduledVisitOut)
def update_scheduled_visit_status(
    visit_id: int,
    status: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = (db.query(PostnatalScheduledVisit)
               .filter(PostnatalScheduledVisit.id == visit_id).first())
    if not visit:
        raise HTTPException(status_code=404, detail="Scheduled visit not found")
    if status not in ("scheduled", "completed", "missed", "cancelled"):
        raise HTTPException(status_code=400, detail="Invalid status")
    visit.status = status
    db.commit()
    db.refresh(visit)
    return visit


@router.patch("/postnatal-scheduled-visits/{visit_id}/reschedule",
              response_model=PostnatalScheduledVisitOut)
def reschedule_postnatal_visit(
    visit_id: int,
    new_date: str,
    reason: str = "",
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = (db.query(PostnatalScheduledVisit)
               .filter(PostnatalScheduledVisit.id == visit_id).first())
    if not visit:
        raise HTTPException(status_code=404, detail="Scheduled visit not found")
    visit.scheduled_date = new_date
    visit.status = "rescheduled"
    db.commit()
    db.refresh(visit)
    return visit


# ── MENTAL HEALTH ─────────────────────────────────────────

@router.post("/mental-health-screens",
             response_model=MentalHealthScreeningOut)
def create_screening(
    data: MentalHealthScreeningCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    risk = "high" if data.phq2_score >= 3 else "low"
    screening = MentalHealthScreening(
        **data.dict(),
        risk_level=risk,
    )
    db.add(screening)
    db.flush()

    if risk == "high":
        screening.chw_alerted = True
        patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
        visit = db.query(PostnatalVisit).filter(PostnatalVisit.id == data.postnatal_visit_id).first()
        if patient and patient.phone:
            lang = patient.preferred_language or "fr"
            score = data.phq2_score
            if lang == "en":
                msg = (
                    f"\u26a0\ufe0f *MamaSafe — Mental Health Alert*\n\n"
                    f"Patient: *{patient.full_name}*\n"
                    f"PHQ-2 Score: *{score}/6* (high risk)\n\n"
                    f"This patient may need mental health support. "
                    f"Please follow up at the next visit.\n\n"
                    f"_MamaSafe_"
                )
            else:
                msg = (
                    f"\u26a0\ufe0f *MamaSafe — Alerte Santé mentale*\n\n"
                    f"Patiente : *{patient.full_name}*\n"
                    f"Score PHQ-2 : *{score}/6* (risque élevé)\n\n"
                    f"Cette patiente peut avoir besoin de soutien en santé mentale. "
                    f"Veuillez faire le suivi lors de la prochaine visite.\n\n"
                    f"_MamaSafe_"
                )
            if current_user.whatsapp_number:
                send_whatsapp(current_user.whatsapp_number, msg)

    db.commit()
    db.refresh(screening)
    return screening


@router.get("/patients/{patient_id}/mental-health-screens",
            response_model=List[MentalHealthScreeningOut])
def list_patient_screenings(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(MentalHealthScreening)
              .filter(MentalHealthScreening.patient_id == patient_id)
              .order_by(MentalHealthScreening.created_at.desc())
              .all())
