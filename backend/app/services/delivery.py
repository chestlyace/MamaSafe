"""SMS and WhatsApp delivery service for emergency referrals.

In production, integrate with:
- SMS: Africa's Talking, Twilio, or local Cameroon gateway
- WhatsApp: WhatsApp Business API (via Twilio or direct)

For now, this logs the messages. Replace send_sms/send_whatsapp
with actual gateway calls when API keys are configured.
"""

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def format_sms(referral) -> str:
    """Format a condensed SMS referral summary (≤160 chars per segment)."""
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
        f"\U0001f551 *Sent:* {sent}"
    )
    return msg


def send_sms(phone_number: str, message: str) -> bool:
    """Send SMS via gateway. Returns True on success.

    TODO: Integrate with Africa's Talking or Twilio:
        from africastalking import SMS
        sms = SMS()
        sms.send(message=message, recipients=[phone_number])
    """
    if not phone_number:
        logger.warning("No phone number for SMS delivery")
        return False
    logger.info(f"SMS to {phone_number}: {message[:80]}...")
    # Placeholder: replace with actual SMS gateway call
    return True


def send_whatsapp(phone_number: str, message: str) -> bool:
    """Send WhatsApp message via Business API. Returns True on success.

    TODO: Integrate with WhatsApp Business API:
        - Via Twilio: client.messages.create(from='whatsapp:+14155238886', body=message, to=f'whatsapp:{phone_number}')
        - Via direct API: POST to graph.facebook.com/v17.0/{phone_number_id}/messages
    """
    if not phone_number:
        logger.warning("No WhatsApp number for delivery")
        return False
    logger.info(f"WhatsApp to {phone_number}: {message[:80]}...")
    # Placeholder: replace with actual WhatsApp API call
    return True


def deliver_referral(referral) -> dict:
    """Send referral via all available channels. Returns delivery status dict."""
    results = {"sms": False, "whatsapp": False}

    sms_msg = format_sms(referral)
    whatsapp_msg = format_whatsapp(referral)

    if referral.facility and referral.facility.phone:
        results["sms"] = send_sms(referral.facility.phone, sms_msg)

    if referral.facility and referral.facility.whatsapp:
        results["whatsapp"] = send_whatsapp(referral.facility.whatsapp, whatsapp_msg)

    logger.info(f"Referral {referral.id} delivery: {results}")
    return results
