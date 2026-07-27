from sqlalchemy.orm import Session
from datetime import datetime, date
from app.database import (Assessment, Patient, User, RiskEscalationEvent)
from app.services.delivery import send_whatsapp
import logging

logger = logging.getLogger("mamasafe.risk_tracking")

RISK_ORDER = {"low risk": 1, "mid risk": 2, "high risk": 3}

ESCALATION_MESSAGES_FR = {
    "low_to_mid": (
        "⚠️ *MamaSafe — Escalade de risque*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a augmenté :\n\n"
        "🟡 *RISQUE FAIBLE → RISQUE MOYEN*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "Action recommandée : Augmentez la fréquence des visites "
        "et surveillez de près.\n\n"
        "_MamaSafe_"
    ),
    "mid_to_high": (
        "🚨 *MamaSafe — ALERTE RISQUE ÉLEVÉ*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a fortement "
        "augmenté :\n\n"
        "🔴 *RISQUE MOYEN → RISQUE ÉLEVÉ*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "⚡ *Action requise : Référer immédiatement à un hôpital "
        "de district.*\n\n"
        "_MamaSafe_"
    ),
    "low_to_high": (
        "🚨 *MamaSafe — ALERTE URGENTE*\n\n"
        "Bonjour {chw_name},\n\n"
        "Le risque de votre patiente *{patient_name}* a augmenté "
        "de façon critique :\n\n"
        "🔴 *RISQUE FAIBLE → RISQUE ÉLEVÉ*\n\n"
        "📊 Facteurs principaux :\n{signals}\n\n"
        "⚡ *Action requise : RÉFÉRER EN URGENCE IMMÉDIATEMENT.*\n\n"
        "_MamaSafe_"
    ),
}

ESCALATION_MESSAGES_EN = {
    "low_to_mid": (
        "⚠️ *MamaSafe — Risk Escalation*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk level has increased:\n\n"
        "🟡 *LOW RISK → MID RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "Recommended action: Increase visit frequency and monitor "
        "closely.\n\n"
        "_MamaSafe_"
    ),
    "mid_to_high": (
        "🚨 *MamaSafe — HIGH RISK ALERT*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk level has escalated:\n\n"
        "🔴 *MID RISK → HIGH RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "⚡ *Action required: Refer to district hospital immediately.*"
        "\n\n_MamaSafe_"
    ),
    "low_to_high": (
        "🚨 *MamaSafe — URGENT ALERT*\n\n"
        "Hello {chw_name},\n\n"
        "Your patient *{patient_name}*'s risk has jumped critically:\n\n"
        "🔴 *LOW RISK → HIGH RISK*\n\n"
        "📊 Key drivers:\n{signals}\n\n"
        "⚡ *Action required: EMERGENCY REFERRAL IMMEDIATELY.*\n\n"
        "_MamaSafe_"
    ),
}


def build_signal_lines(assessment) -> str:
    """Format top SHAP-driven signals for WhatsApp message."""
    signals = []
    if assessment.systolic_bp:
        signals.append(f"• Tension systolique : {assessment.systolic_bp} mmHg")
    if assessment.blood_sugar:
        signals.append(f"• Glycémie : {assessment.blood_sugar} mmol/L")
    if assessment.diastolic_bp:
        signals.append(f"• Tension diastolique : {assessment.diastolic_bp} mmHg")
    return "\n".join(signals[:3])


def get_escalation_type(prev_level: str, new_level: str) -> str:
    prev = prev_level.replace(" ", "_")
    new = new_level.replace(" ", "_")
    return f"{prev}_to_{new}"


def check_and_handle_escalation(
    db: Session,
    patient_id: int,
    new_assessment,
    chw,
):
    """
    Called after every new assessment is saved.
    Compares with previous assessment for same patient.
    Fires WhatsApp alert to CHW if risk has escalated.
    Returns the escalation event if one was detected, else None.
    """
    previous = (
        db.query(Assessment)
          .filter(
              Assessment.patient_id == patient_id,
              Assessment.id != new_assessment.id
          )
          .order_by(Assessment.created_at.desc())
          .first()
    )

    if not previous:
        logger.info(f"First assessment for patient {patient_id} — no comparison")
        return None

    prev_score = RISK_ORDER.get(previous.risk_level, 0)
    new_score = RISK_ORDER.get(new_assessment.risk_level, 0)

    if new_score <= prev_score:
        direction = "stable" if new_score == prev_score else "improving"
        logger.info(
            f"Patient {patient_id}: {previous.risk_level} → "
            f"{new_assessment.risk_level} ({direction})"
        )
        return None

    # Escalation confirmed
    escalation_type = get_escalation_type(
        previous.risk_level, new_assessment.risk_level
    )
    logger.warning(
        f"ESCALATION: Patient {patient_id}: {previous.risk_level} → "
        f"{new_assessment.risk_level} ({escalation_type})"
    )

    event = RiskEscalationEvent(
        patient_id             = patient_id,
        previous_assessment_id = previous.id,
        new_assessment_id      = new_assessment.id,
        previous_risk_level    = previous.risk_level,
        new_risk_level         = new_assessment.risk_level,
        escalation_type        = escalation_type,
        chw_id                 = chw.id if chw else None,
        whatsapp_sent          = False,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    # Alert deduplication — skip if CHW already alerted today
    today = str(date.today())
    already_alerted_today = (
        db.query(RiskEscalationEvent)
          .filter(
              RiskEscalationEvent.patient_id == patient_id,
              RiskEscalationEvent.whatsapp_sent == True,
              RiskEscalationEvent.created_at >= today,
              RiskEscalationEvent.id != event.id,
          )
          .first()
    )
    if already_alerted_today:
        logger.info(
            f"CHW already alerted for patient {patient_id} today — skipping"
        )
        return event

    # Send WhatsApp alert to CHW
    chw_phone = getattr(chw, "whatsapp_number", None) if chw else None
    if chw_phone:
        patient = db.query(Patient).filter(Patient.id == patient_id).first()
        lang = getattr(patient, "preferred_language", "fr") or "fr"

        templates = ESCALATION_MESSAGES_FR if lang == "fr" else ESCALATION_MESSAGES_EN
        template = templates.get(escalation_type, templates["mid_to_high"])

        message = template.format(
            chw_name     = chw.full_name or chw.username,
            patient_name = patient.full_name if patient else f"Patient #{patient_id}",
            signals      = build_signal_lines(new_assessment),
        )

        result = send_whatsapp(chw_phone, message)
        event.whatsapp_sent = result.get("success", False)
        if not event.whatsapp_sent:
            event.whatsapp_error = result.get("error", "unknown")
        db.commit()

        logger.info(
            f"Escalation WhatsApp to CHW {chw.username}: "
            f"{'sent' if event.whatsapp_sent else 'failed'}"
        )

    return event
