"""WhatsApp webhook and pairing endpoint.

Receives inbound WhatsApp messages from the Baileys gateway and
processes them as referral status updates. Also proxies pairing
requests to the Baileys subprocess.
"""

import os
import logging
import httpx
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db, Referral, Facility
from app.schemas_referral import WebhookWhatsApp
from app.services.delivery import send_whatsapp

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["webhook"])

WEBHOOK_SECRET = os.getenv("WEBHOOK_SECRET", "")
BAILEYS_URL = os.getenv("BAILEYS_URL", "http://localhost:3001")


@router.post("/whatsapp/pair")
def request_pairing_code(data: dict):
    """Proxy pairing request to Baileys gateway.

    Body: { "phone": "237612345678" }
    Returns: { "code": "XXXX-XXXX" }
    """
    phone = data.get("phone")
    if not phone:
        raise HTTPException(status_code=400, detail="phone is required")
    try:
        resp = httpx.post(f"{BAILEYS_URL}/pair", json={"phone": phone}, timeout=15.0)
        result = resp.json()
        if "code" in result:
            return {"code": result["code"]}
        raise HTTPException(status_code=502, detail=result.get("error", "Pairing failed"))
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Baileys gateway not running")


@router.get("/whatsapp/qr")
def get_qr_code():
    """Get QR code for linking WhatsApp. Returns a data URL image to scan."""
    try:
        resp = httpx.get(f"{BAILEYS_URL}/qr", timeout=10.0)
        result = resp.json()
        if result.get("connected"):
            return {"connected": True, "user": result.get("user")}
        return {"connected": False, "qr": result.get("qr"), "status": result.get("status")}
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Baileys gateway not running")


@router.get("/whatsapp/status")
def get_whatsapp_status():
    """Check WhatsApp connection status."""
    try:
        resp = httpx.get(f"{BAILEYS_URL}/health", timeout=5.0)
        return resp.json()
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Baileys gateway not running")


@router.post("/referrals/webhook/whatsapp")
def receive_whatsapp(data: WebhookWhatsApp, db: Session = Depends(get_db)):
    """Process inbound WhatsApp reply from a facility.

    Expects JSON: {from_number, text, timestamp, secret}
    Text should be "RECEIVED" or "PATIENT_ARRIVED" (case-insensitive).
    Handles both phone-number and @lid sender formats.
    """
    if WEBHOOK_SECRET and data.secret != WEBHOOK_SECRET:
        raise HTTPException(status_code=403, detail="Invalid webhook secret")

    raw = data.text.strip().upper() if data.text else ""
    words = raw.split()

    # Parse keyword and optional referral ID (e.g., "RECEIVED #0042" or "RECEIVED 42")
    keyword = words[0] if words else ""
    ref_id = None
    for w in words[1:]:
        cleaned = w.lstrip("#").strip()
        if cleaned.isdigit():
            ref_id = int(cleaned)
            break

    status_map = {
        "RECEIVED": "RECEIVED",
        "PATIENT_ARRIVED": "PATIENT_ARRIVED",
        "ARRIVED": "PATIENT_ARRIVED",
        # French
        "RECU": "RECEIVED",
    }
    new_status = status_map.get(keyword)
    if not new_status:
        logger.info("Ignoring WhatsApp reply: %s", raw[:50])
        return {"status": "ignored", "message": "Unrecognized keyword. Reply RECEIVED or ARRIVED."}

    # Normalize sender phone number
    phone = data.from_number.replace("+", "").replace(" ", "").replace("-", "")
    if "@" in phone:
        phone = phone.split("@")[0]

    # Try to find the facility by phone number
    facility = db.query(Facility).filter(
        (Facility.whatsapp == phone) | (Facility.phone == phone)
    ).first()

    # Fallback: if no facility matched by phone but we have a referral ID,
    # look up the referral directly and use its linked facility
    referral = None
    if not facility and ref_id:
        referral = db.query(Referral).filter(Referral.id == ref_id).first()
        if referral:
            facility = db.query(Facility).filter(Facility.id == referral.facility_id).first()
            logger.info("LID fallback: referral #%s linked to facility %s", ref_id, facility.id if facility else None)

    if not facility:
        logger.info("WhatsApp from unknown number: %s", phone)
        return {"status": "ignored", "message": "Sender not registered."}

    # Find referral: by ID if provided, otherwise most recent SENT for this facility
    if not referral and ref_id:
        referral = (
            db.query(Referral)
            .filter(Referral.id == ref_id, Referral.facility_id == facility.id)
            .first()
        )
        if referral and referral.status == new_status:
            logger.info("Referral %s already in status %s", ref_id, referral.status)
            return {"status": "ignored", "message": f"Referral #{ref_id} already {referral.status}."}
        if referral and referral.status == "PATIENT_ARRIVED":
            logger.info("Referral %s already completed", ref_id)
            return {"status": "ignored", "message": f"Referral #{ref_id} already completed."}
    if not referral:
        referral = (
            db.query(Referral)
            .filter(Referral.facility_id == facility.id, Referral.status == "SENT")
            .order_by(Referral.created_at.desc())
            .first()
        )

    if not referral:
        logger.info("No pending referral for facility %s", facility.id)
        return {"status": "ignored", "message": "No pending referral."}

    referral.status = new_status
    now = datetime.utcnow()
    if new_status == "RECEIVED":
        referral.received_at = now
    elif new_status == "PATIENT_ARRIVED":
        referral.patient_arrived_at = now
    db.commit()

    # Send confirmation back to the facility using their registered phone/whatsapp
    confirm_phone = facility.whatsapp or facility.phone
    if confirm_phone:
        confirm_map = {
            "RECEIVED": "confirmed as RECEIVED",
            "PATIENT_ARRIVED": "confirmed as PATIENT ARRIVED",
        }
        confirm_text = confirm_map.get(new_status, "updated")
        msg = (
            f"MamaSafe Confirmation\n\n"
            f"Referral #{referral.id} for {referral.patient_name} has been {confirm_text}.\n\n"
            f"Thank you."
        )
        send_whatsapp(confirm_phone, msg)
    else:
        logger.warning("Facility %s has no phone number for confirmation", facility.id)

    logger.info("Referral %s updated to %s via WhatsApp", referral.id, new_status)
    return {"status": "ok", "referral_id": referral.id, "new_status": new_status}
