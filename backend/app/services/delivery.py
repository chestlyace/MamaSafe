"""WhatsApp delivery service for emergency referrals via Baileys gateway.

Sends referral notifications to receiving facilities through the local
Baileys Node.js subprocess (localhost:3001). Handles both formatted
WhatsApp messages and plain SMS fallback formatting.
"""

import os
import logging
import httpx
from typing import Optional

logger = logging.getLogger(__name__)

BAILEYS_URL = os.getenv("BAILEYS_URL", "http://localhost:3001")


def format_sms(referral) -> str:
    """Format a condensed SMS referral summary (<=160 chars per segment)."""
    name = referral.patient_name or "Unknown"
    age = referral.patient_age or "?"
    bp = f"{referral.systolic_bp:.0f}/{referral.diastolic_bp:.0f}" if referral.systolic_bp and referral.diastolic_bp else "?"
    hr = f"{referral.heart_rate}" if referral.heart_rate else "?"
    risk = (referral.risk_level or "UNKNOWN").upper()
    complication = referral.complication_type or "N/A"
    notes = (referral.chw_notes or "")[:60]

    msg = (
        f"[MamaSafe URGENT REFERRAL]\n"
        f"Patient: {name}, {age}y\n"
        f"BP: {bp} | HR: {hr}\n"
        f"Risk: {risk}\n"
        f"Complication: {complication}\n"
        f"Notes: {notes}"
    )
    return msg


def format_whatsapp(referral) -> str:
    """Format a rich WhatsApp referral summary."""
    name = referral.patient_name or "Unknown"
    age = referral.patient_age or "?"
    phone = referral.patient_phone or "N/A"
    blood = referral.patient_blood_group or "N/A"
    allergies = referral.patient_allergies or "None"
    gravida = referral.gravida or "?"
    parity = referral.parity or "?"
    edd = referral.edd_date or "N/A"
    ga = referral.gestational_age or "?"
    bp = f"{referral.systolic_bp:.0f}/{referral.diastolic_bp:.0f}" if referral.systolic_bp and referral.diastolic_bp else "N/A"
    hr = f"{referral.heart_rate}" if referral.heart_rate else "N/A"
    temp = f"{referral.body_temp:.1f}" if referral.body_temp else "N/A"
    sugar = f"{referral.blood_sugar:.1f}" if referral.blood_sugar else "N/A"
    risk = (referral.risk_level or "UNKNOWN").upper()
    prob = f"{(referral.risk_probability or 0) * 100:.0f}%" if referral.risk_probability else "N/A"
    complication = referral.complication_type or "N/A"
    notes = referral.chw_notes or "None"
    facility = referral.facility_name or "N/A"
    sent = referral.sent_at.strftime("%d %b %Y, %H:%M") if referral.sent_at else "N/A"

    ref_id = str(referral.id).zfill(4) if referral.id else "????"

    msg = (
        f"\U0001f6a8 *MAMASAFE URGENT REFERRAL*\n\n"
        f"\U0001f464 *Patient:* {name}, {age} years\n"
        f"\U0001f4de *Phone:* {phone}\n"
        f"\U0001fa78 *Blood Group:* {blood}\n"
        f"\u2695\ufe0f *Allergies:* {allergies}\n\n"
        f"\U0001f930 *Pregnancy:* G{gravida}P{parity}, EDD: {edd}\n"
        f"\U0001f4ca *Gestational Age:* {ga} weeks\n\n"
        f"\U0001f493 *Vitals:*\n"
        f"  BP: {bp} mmHg\n"
        f"  HR: {hr} bpm\n"
        f"  Temp: {temp} \u00b0C\n"
        f"  Blood Sugar: {sugar} mmol/L\n\n"
        f"\u26a0\ufe0f *Risk Level:* {risk} ({prob} confidence)\n"
        f"\U0001f534 *Complication:* {complication}\n\n"
        f"\U0001f4dd *CHW Notes:* {notes}\n\n"
        f"\U0001f4cd *Referred to:* {facility}\n"
        f"\U0001f551 *Sent:* {sent}\n"
        f"\U0001f4cb *Referral:* #{ref_id}\n\n"
        f"Reply *RECEIVED #{ref_id}* to confirm."
    )
    return msg


def send_whatsapp(phone_number: str, message: str) -> dict:
    """Send WhatsApp message via Baileys gateway.

    Returns:
        dict: {success: bool, message_id: str|None, error: str|None}
    """
    if not phone_number:
        logger.warning("No phone number for WhatsApp delivery")
        return {"success": False, "message_id": None, "error": "No phone number"}

    try:
        resp = httpx.post(
            f"{BAILEYS_URL}/send",
            json={"phone": phone_number, "message": message},
            timeout=10.0,
        )
        result = resp.json()
        if result.get("success"):
            return {"success": True, "message_id": result.get("message_id"), "error": None}
        else:
            return {"success": False, "message_id": None, "error": result.get("error", "Unknown")}
    except httpx.ConnectError:
        logger.error("Baileys gateway not reachable at %s", BAILEYS_URL)
        return {"success": False, "message_id": None, "error": "Baileys gateway not running"}
    except Exception as e:
        logger.error("WhatsApp delivery failed: %s", e)
        return {"success": False, "message_id": None, "error": str(e)}


def deliver_referral(referral) -> dict:
    """Send referral notification via WhatsApp. Returns delivery status dict.

    This is the main entry point called after referral creation.
    WhatsApp is the primary channel. SMS is not used (WhatsApp covers
    all phones in Cameroon via Baileys).
    """
    results = {"whatsapp": False, "whatsapp_message_id": None}

    # Prefer facility WhatsApp number, fall back to phone
    phone = None
    if hasattr(referral, 'facility') and referral.facility:
        phone = referral.facility.whatsapp or referral.facility.phone

    if not phone:
        logger.warning("Referral %s: No phone number for facility", referral.id)
        return results

    message = format_whatsapp(referral)
    wa_result = send_whatsapp(phone, message)
    results["whatsapp"] = wa_result["success"]
    results["whatsapp_message_id"] = wa_result.get("message_id")

    if wa_result["success"]:
        logger.info("Referral %s: WhatsApp sent to %s", referral.id, phone)
    else:
        logger.warning("Referral %s: WhatsApp failed — %s", referral.id, wa_result.get("error"))

    return results
