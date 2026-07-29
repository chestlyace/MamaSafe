"""Growth tracking logic — measurements computation + alert detection."""

from datetime import datetime, date
from typing import List, Optional, Tuple
from app.database import PostnatalVisit, GrowthAlert, Newborn
from app.utils.who_growth_data import classify_weight
from sqlalchemy.orm import Session


def get_measurements(
    visits: List[PostnatalVisit],
    newborn: Newborn,
) -> list:
    """Compute growth measurements from postnatal visits.

    Each visit with newborn_weight_kg produces a measurement dict with
    age_days, weight_kg, z_score, percentile, classification.
    """
    if not newborn.birth_weight:
        return []

    delivery_date = _get_delivery_date(visits, newborn)

    measurements = []
    for v in visits:
        if v.newborn_weight_kg is None:
            continue
        age_days = _compute_age_days(v.visit_date, delivery_date)
        if age_days is None:
            continue
        result = classify_weight(newborn.sex, age_days, v.newborn_weight_kg)
        measurements.append({
            "visit_id": v.id,
            "visit_date": v.visit_date,
            "visit_number": v.visit_number,
            "newborn_id": newborn.id,
            "age_days": age_days,
            "weight_kg": v.newborn_weight_kg,
            "z_score": result["z_score"],
            "percentile": result["percentile"],
            "classification": result["classification"],
            "p3": result["p3"],
            "p15": result["p15"],
            "p50": result["p50"],
            "p85": result["p85"],
            "p97": result["p97"],
        })
    measurements.sort(key=lambda m: m["age_days"])
    return measurements


def detect_alerts(
    db: Session,
    newborn: Newborn,
    measurements: list,
) -> List[GrowthAlert]:
    """Detect growth alerts for a newborn.

    Three alert types:
    1. below_3rd_percentile — latest measurement below P3
    2. growth_faltering — crossed >=2 percentile lines between consecutive readings
    3. failed_to_regain_birth_weight — after 14 days, weight < birth weight
    """
    from app.database import GrowthAlert as GrowthAlertModel

    if not measurements:
        return []

    alerts = []
    latest = measurements[-1]

    # 1. Below 3rd percentile
    if latest["z_score"] < -1.881:
        alerts.append({
            "alert_type": "below_3rd_percentile",
            "severity": "critical",
            "message_en": (
                f"Warning: Newborn weight ({latest['weight_kg']}kg) is "
                f"below the 3rd percentile (z-score: {latest['z_score']:.2f}). "
                "Immediate assessment recommended."
            ),
            "message_fr": (
                f"Alerte : Le poids du nouveau-né ({latest['weight_kg']}kg) "
                f"est en dessous du 3e percentile (z-score : {latest['z_score']:.2f}). "
                "Évaluation immédiate recommandée."
            ),
            "z_score": latest["z_score"],
            "postnatal_visit_id": latest["visit_id"],
        })

    # 2. Growth faltering — crossed >=2 percentile lines
    PERCENTILE_ORDER = ["below_3rd", "3rd_to_15th", "15th_to_50th",
                        "50th_to_85th", "85th_to_97th", "above_97th"]
    percentile_rank = {p: i for i, p in enumerate(PERCENTILE_ORDER)}

    if len(measurements) >= 2:
        prev = measurements[-2]
        prev_rank = percentile_rank.get(prev["percentile"], 3)
        curr_rank = percentile_rank.get(latest["percentile"], 3)
        if curr_rank <= prev_rank - 2:
            alerts.append({
                "alert_type": "growth_faltering",
                "severity": "warning",
                "message_en": (
                    f"Growth faltering detected. Weight percentile dropped from "
                    f"'{prev['percentile']}' to '{latest['percentile']}' "
                    f"(z-score: {prev['z_score']:.2f} → {latest['z_score']:.2f})."
                ),
                "message_fr": (
                    "Ralentissement de la croissance détecté. Le percentile de poids "
                    f"est passé de '{prev['percentile']}' à '{latest['percentile']}' "
                    f"(z-score : {prev['z_score']:.2f} → {latest['z_score']:.2f})."
                ),
                "z_score": latest["z_score"],
                "postnatal_visit_id": latest["visit_id"],
            })

    # 3. Failed to regain birth weight after 14 days
    birth_weight_kg = (newborn.birth_weight or 0) / 1000.0
    if birth_weight_kg > 0 and latest["age_days"] >= 14:
        latest_weight = latest["weight_kg"]
        if latest_weight < birth_weight_kg:
            alerts.append({
                "alert_type": "failed_to_regain_birth_weight",
                "severity": "warning",
                "message_en": (
                    f"Newborn has not regained birth weight after {latest['age_days']} days. "
                    f"Current weight: {latest_weight}kg, birth weight: {birth_weight_kg}kg."
                ),
                "message_fr": (
                    f"Le nouveau-né n'a pas retrouvé son poids de naissance après "
                    f"{latest['age_days']} jours. Poids actuel : {latest_weight}kg, "
                    f"poids de naissance : {birth_weight_kg}kg."
                ),
                "z_score": latest["z_score"],
                "postnatal_visit_id": latest["visit_id"],
            })

    return alerts


def build_or_refresh_alerts(
    db: Session,
    newborn: Newborn,
    visits: List[PostnatalVisit],
) -> List[GrowthAlert]:
    """Remove old alerts for this newborn and create fresh ones."""
    from app.database import GrowthAlert as GrowthAlertModel

    db.query(GrowthAlertModel).filter(
        GrowthAlertModel.newborn_id == newborn.id,
        GrowthAlertModel.resolved == False,
    ).delete()

    measurements = get_measurements(visits, newborn)
    alerts = detect_alerts(db, newborn, measurements)

    created = []
    for alert_data in alerts:
        alert = GrowthAlertModel(
            newborn_id=newborn.id,
            patient_id=newborn.delivery.patient_id,
            **alert_data,
        )
        db.add(alert)
        created.append(alert)

    if created:
        db.commit()

    return created


def _get_delivery_date(visits: List[PostnatalVisit], newborn: Newborn) -> str:
    """Extract delivery date from the newborn's delivery record."""
    if newborn.delivery and newborn.delivery.delivery_date:
        return newborn.delivery.delivery_date
    if visits:
        for v in visits:
            if hasattr(v, "delivery") and v.delivery and v.delivery.delivery_date:
                return v.delivery.delivery_date
    return ""


def _compute_age_days(visit_date_str: str, delivery_date_str: str) -> Optional[int]:
    """Compute age in days at visit date vs delivery date."""
    try:
        visit = datetime.strptime(visit_date_str, "%Y-%m-%d").date()
        delivery = datetime.strptime(delivery_date_str, "%Y-%m-%d").date()
        return (visit - delivery).days
    except (ValueError, TypeError):
        return None
