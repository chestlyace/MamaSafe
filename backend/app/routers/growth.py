from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.database import (
    get_db, Patient, Newborn, PostnatalVisit, GrowthAlert,
)
from app.schemas_postnatal import (
    GrowthDataOut, GrowthSummaryOut, GrowthAlertOut, GrowthMeasurement,
)
from app.routers.auth import get_current_user
from app.utils.growth_tracker import (
    get_measurements, detect_alerts,
    build_or_refresh_alerts,
)

router = APIRouter(prefix="/api/v1/growth", tags=["growth"])


@router.get("/newborns/{newborn_id}", response_model=GrowthDataOut)
def get_newborn_growth(
    newborn_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    """Get full growth data for a newborn: measurements + alerts."""
    newborn = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    if not newborn:
        raise HTTPException(status_code=404, detail="Newborn not found")

    visits = (
        db.query(PostnatalVisit)
        .filter(
            PostnatalVisit.newborn_id == newborn_id,
            PostnatalVisit.newborn_weight_kg.isnot(None),
        )
        .order_by(PostnatalVisit.visit_date)
        .all()
    )

    measurements = get_measurements(visits, newborn)
    alerts = (
        db.query(GrowthAlert)
        .filter(
            GrowthAlert.newborn_id == newborn_id,
            GrowthAlert.resolved == False,
        )
        .order_by(GrowthAlert.created_at.desc())
        .all()
    )

    return {
        "newborn_id": newborn.id,
        "newborn_name": newborn.name,
        "sex": newborn.sex,
        "birth_weight_g": newborn.birth_weight,
        "measurements": measurements,
        "alerts": alerts,
    }


@router.get("/newborns/{newborn_id}/summary", response_model=GrowthSummaryOut)
def get_growth_summary(
    newborn_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    """Get a compact growth summary for a newborn."""
    newborn = db.query(Newborn).filter(Newborn.id == newborn_id).first()
    if not newborn:
        raise HTTPException(status_code=404, detail="Newborn not found")

    visits = (
        db.query(PostnatalVisit)
        .filter(
            PostnatalVisit.newborn_id == newborn_id,
            PostnatalVisit.newborn_weight_kg.isnot(None),
        )
        .order_by(PostnatalVisit.visit_date)
        .all()
    )

    measurements = get_measurements(visits, newborn)
    alerts = (
        db.query(GrowthAlert)
        .filter(
            GrowthAlert.newborn_id == newborn_id,
            GrowthAlert.resolved == False,
        )
        .order_by(GrowthAlert.created_at.desc())
        .all()
    )

    latest = measurements[-1] if measurements else None

    return {
        "newborn_id": newborn.id,
        "newborn_name": newborn.name,
        "sex": newborn.sex,
        "birth_weight_g": newborn.birth_weight,
        "latest_weight_kg": latest["weight_kg"] if latest else None,
        "latest_age_days": latest["age_days"] if latest else None,
        "latest_z_score": latest["z_score"] if latest else None,
        "latest_percentile": latest["percentile"] if latest else None,
        "latest_classification": latest["classification"] if latest else None,
        "active_alerts": alerts,
        "measurement_count": len(measurements),
    }


@router.get("/patients/{patient_id}/summary", response_model=List[GrowthSummaryOut])
def list_patient_growth_summaries(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    """Get growth summaries for all newborns of a patient."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    newborns = (
        db.query(Newborn)
        .join(Newborn.delivery)
        .filter(Newborn.delivery.has(patient_id=patient_id))
        .all()
    )

    if not newborns:
        return []

    summaries = []
    for nb in newborns:
        visits = (
            db.query(PostnatalVisit)
            .filter(
                PostnatalVisit.newborn_id == nb.id,
                PostnatalVisit.newborn_weight_kg.isnot(None),
            )
            .order_by(PostnatalVisit.visit_date)
            .all()
        )
        measurements = get_measurements(visits, nb)
        alerts = (
            db.query(GrowthAlert)
            .filter(
                GrowthAlert.newborn_id == nb.id,
                GrowthAlert.resolved == False,
            )
            .order_by(GrowthAlert.created_at.desc())
            .all()
        )
        latest = measurements[-1] if measurements else None
        summaries.append({
            "newborn_id": nb.id,
            "newborn_name": nb.name,
            "sex": nb.sex,
            "birth_weight_g": nb.birth_weight,
            "latest_weight_kg": latest["weight_kg"] if latest else None,
            "latest_age_days": latest["age_days"] if latest else None,
            "latest_z_score": latest["z_score"] if latest else None,
            "latest_percentile": latest["percentile"] if latest else None,
            "latest_classification": latest["classification"] if latest else None,
            "active_alerts": alerts,
            "measurement_count": len(measurements),
        })
    return summaries


@router.get("/alerts", response_model=List[GrowthAlertOut])
def list_growth_alerts(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    """List all unresolved growth alerts across all patients."""
    return (
        db.query(GrowthAlert)
        .filter(GrowthAlert.resolved == False)
        .order_by(GrowthAlert.created_at.desc())
        .limit(50)
        .all()
    )


@router.patch("/alerts/{alert_id}/resolve", response_model=GrowthAlertOut)
def resolve_growth_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    """Mark a growth alert as resolved."""
    alert = db.query(GrowthAlert).filter(GrowthAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Growth alert not found")
    alert.resolved = True
    alert.resolved_at = datetime.utcnow()
    db.commit()
    db.refresh(alert)
    return alert
