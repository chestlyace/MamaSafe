"""APScheduler background jobs for postnatal care (PNC) visit reminders.

Runs daily:
  - 48-hour advance patient reminders
  - Same-day patient reminders
  - Missed PNC visit detection + CHW alerts
"""

from datetime import date, datetime, timedelta
from sqlalchemy.orm import Session
import logging

from app.database import (
    SessionLocal, Delivery, Patient, User,
    PostnatalScheduledVisit,
)
from app.services.delivery import send_whatsapp
from app.utils.whatsapp import build_pnc_reminder, build_pnc_day_reminder

logger = logging.getLogger("mamasafe.postnatal_jobs")


def _get_db() -> Session:
    db = SessionLocal()
    try:
        return db
    except Exception:
        db.close()
        raise


def job_send_pnc_48h_reminders():
    """Send 48-hour advance WhatsApp reminders for postnatal visits."""
    logger.info("Running PNC 48h reminder job...")
    db = _get_db()
    try:
        target_date = str(date.today() + timedelta(days=2))
        visits = (db.query(PostnatalScheduledVisit)
                    .filter(PostnatalScheduledVisit.scheduled_date == target_date,
                            PostnatalScheduledVisit.status == "scheduled",
                            PostnatalScheduledVisit.reminder_48h_sent == False)
                    .all())

        logger.info("Found %d PNC visits for %s", len(visits), target_date)

        for visit in visits:
            delivery = db.query(Delivery).filter(
                Delivery.id == visit.delivery_id).first()
            if not delivery:
                continue

            patient = db.query(Patient).filter(
                Patient.id == delivery.patient_id).first()
            if not patient or not patient.phone:
                continue

            chw = db.query(User).filter(
                User.id == patient.chw_id).first()

            message = build_pnc_reminder(
                patient_name=patient.full_name,
                visit_number=visit.visit_number,
                visit_label=visit.label or f"PNC {visit.visit_number}",
                visit_date=visit.scheduled_date,
                facility=patient.facility or "Your health centre",
                chw_name=chw.full_name if chw else "Your CHW",
                chw_phone=getattr(chw, 'whatsapp_number', '') or "",
                lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
            )

            result = send_whatsapp(patient.phone, message)

            visit.reminder_48h_sent = True
            db.commit()

            logger.info(
                "PNC 48h reminder for %s: %s",
                patient.full_name,
                "sent" if result["success"] else "failed"
            )

    except Exception as e:
        logger.error("PNC 48h reminder job failed: %s", e)
    finally:
        db.close()


def job_send_pnc_day_reminders():
    """Send same-day reminders for postnatal visits."""
    logger.info("Running PNC day-of reminder job...")
    db = _get_db()
    try:
        today = str(date.today())
        visits = (db.query(PostnatalScheduledVisit)
                    .filter(PostnatalScheduledVisit.scheduled_date == today,
                            PostnatalScheduledVisit.status == "scheduled")
                    .all())

        logger.info("Found %d PNC visits today (%s)", len(visits), today)

        for visit in visits:
            delivery = db.query(Delivery).filter(
                Delivery.id == visit.delivery_id).first()
            if not delivery:
                continue

            patient = db.query(Patient).filter(
                Patient.id == delivery.patient_id).first()
            if not patient or not patient.phone:
                continue

            if not visit.reminder_day_sent:
                message = build_pnc_day_reminder(
                    patient_name=patient.full_name,
                    visit_number=visit.visit_number,
                    visit_label=visit.label or f"PNC {visit.visit_number}",
                    facility=patient.facility or "Your health centre",
                    lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
                )
                send_whatsapp(patient.phone, message)
                visit.reminder_day_sent = True
                db.commit()

    except Exception as e:
        logger.error("PNC day reminder job failed: %s", e)
    finally:
        db.close()


def job_detect_missed_pnc_visits():
    """Mark unattended PNC visits as missed."""
    logger.info("Running PNC missed visit detection job...")
    db = _get_db()
    try:
        today = str(date.today())
        overdue = (db.query(PostnatalScheduledVisit)
                     .filter(PostnatalScheduledVisit.scheduled_date == today,
                             PostnatalScheduledVisit.status == "scheduled")
                     .all())

        for visit in overdue:
            visit.status = "missed"
            db.commit()
            logger.info("Marked PNC visit %d as missed", visit.id)

    except Exception as e:
        logger.error("PNC missed visit job failed: %s", e)
    finally:
        db.close()
