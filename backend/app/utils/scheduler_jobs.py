"""APScheduler background jobs for ANC visit reminders.

Three jobs run daily:
  1. 07:00 — 48-hour patient reminders
  2. 06:00 — Same-day patient reminders + CHW daily list
  3. 18:00 — Missed visit detection + CHW alerts
"""

from datetime import date, datetime, timedelta
from sqlalchemy.orm import Session
import logging

from app.database import SessionLocal, ScheduledVisit, Patient, Pregnancy, User
from app.services.delivery import send_whatsapp
from app.utils.whatsapp import (
    build_48h_reminder, build_day_reminder,
    build_chw_daily_list, build_missed_visit_alert,
)

logger = logging.getLogger("mamasafe.scheduler")

VISIT_LABELS = {
    1: "Booking visit",
    2: "Second trimester check",
    3: "Anomaly screen",
    4: "Glucose screening",
    5: "Birth plan begins",
    6: "Presentation check",
    7: "Final preparation",
    8: "Pre-labour review",
}


def _get_db() -> Session:
    db = SessionLocal()
    try:
        return db
    except Exception:
        db.close()
        raise


def job_send_48h_reminders():
    """Send 48-hour advance WhatsApp reminders to patients with visits in 2 days."""
    logger.info("Running 48h reminder job...")
    db = _get_db()
    try:
        target_date = str(date.today() + timedelta(days=2))
        visits = (db.query(ScheduledVisit)
                    .filter(ScheduledVisit.scheduled_date == target_date,
                            ScheduledVisit.status == "scheduled",
                            ScheduledVisit.reminder_48h_sent == False)
                    .all())

        logger.info("Found %d visits for %s", len(visits), target_date)

        for visit in visits:
            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient or not patient.phone:
                logger.warning("Patient %s has no phone — skipping", pregnancy.patient_id)
                continue

            chw = db.query(User).filter(
                User.id == patient.chw_id).first()

            message = build_48h_reminder(
                patient_name=patient.full_name,
                visit_number=visit.visit_number,
                visit_label=visit.label or VISIT_LABELS.get(visit.visit_number, ""),
                visit_date=visit.scheduled_date,
                facility=patient.facility or "Your health centre",
                chw_name=chw.full_name if chw else "Your CHW",
                chw_phone=getattr(chw, 'whatsapp_number', '') or "",
                lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
            )

            result = send_whatsapp(patient.phone, message)

            visit.reminder_48h_sent    = True
            visit.reminder_48h_sent_at = datetime.utcnow()
            visit.whatsapp_delivered_48h = result.get("success", False)
            db.commit()

            logger.info(
                "48h reminder for patient %s: %s",
                patient.full_name,
                "sent" if result["success"] else "failed"
            )

    except Exception as e:
        logger.error("48h reminder job failed: %s", e)
    finally:
        db.close()


def job_send_day_reminders_and_chw_list():
    """Send same-day patient reminders and compile CHW daily patient lists."""
    logger.info("Running day-of reminder and CHW list job...")
    db = _get_db()
    try:
        today = str(date.today())
        visits = (db.query(ScheduledVisit)
                    .filter(ScheduledVisit.scheduled_date == today,
                            ScheduledVisit.status == "scheduled")
                    .all())

        logger.info("Found %d visits today (%s)", len(visits), today)

        chw_visit_map = {}

        for visit in visits:
            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient:
                continue

            chw = db.query(User).filter(User.id == patient.chw_id).first()
            if not chw:
                continue

            if chw.id not in chw_visit_map:
                chw_visit_map[chw.id] = {"chw": chw, "visits": []}
            chw_visit_map[chw.id]["visits"].append({
                "patient_name":  patient.full_name,
                "patient_phone": patient.phone,
                "visit_number":  visit.visit_number,
                "label":         visit.label or VISIT_LABELS.get(visit.visit_number, ""),
            })

            if not visit.reminder_day_sent and patient.phone:
                message = build_day_reminder(
                    patient_name=patient.full_name,
                    visit_number=visit.visit_number,
                    facility=patient.facility or "Your health centre",
                    lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
                )
                result = send_whatsapp(patient.phone, message)
                visit.reminder_day_sent    = True
                visit.reminder_day_sent_at = datetime.utcnow()
                visit.whatsapp_delivered_day = result.get("success", False)
                db.commit()

        date_str = datetime.now().strftime("%A %d %B %Y")
        for chw_id, data in chw_visit_map.items():
            chw = data["chw"]
            chw_phone = getattr(chw, 'whatsapp_number', None)
            if not chw_phone:
                continue
            message = build_chw_daily_list(
                chw_name=chw.full_name or chw.username,
                visits=data["visits"],
                date_str=date_str,
            )
            send_whatsapp(chw_phone, message)
            logger.info("Sent daily list to CHW %s: %d visits", chw.username, len(data["visits"]))

    except Exception as e:
        logger.error("Day reminder job failed: %s", e)
    finally:
        db.close()


def job_detect_missed_visits():
    """Mark unattended visits as missed and alert CHWs."""
    logger.info("Running missed visit detection job...")
    db = _get_db()
    try:
        today = str(date.today())
        overdue = (db.query(ScheduledVisit)
                     .filter(ScheduledVisit.scheduled_date == today,
                             ScheduledVisit.status == "scheduled")
                     .all())

        logger.info("Found %d unattended visits for %s", len(overdue), today)

        chw_missed_map = {}

        for visit in overdue:
            visit.status = "missed"
            db.commit()

            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient:
                continue

            chw = db.query(User).filter(User.id == patient.chw_id).first()
            if not chw:
                continue

            if chw.id not in chw_missed_map:
                chw_missed_map[chw.id] = {"chw": chw, "missed": []}
            chw_missed_map[chw.id]["missed"].append({
                "patient_name":  patient.full_name,
                "patient_phone": patient.phone,
                "visit_number":  visit.visit_number,
            })

        date_str = datetime.now().strftime("%A %d %B %Y")
        for chw_id, data in chw_missed_map.items():
            chw = data["chw"]
            chw_phone = getattr(chw, 'whatsapp_number', None)
            if not chw_phone:
                continue
            message = build_missed_visit_alert(
                chw_name=chw.full_name or chw.username,
                missed=data["missed"],
                date_str=date_str,
            )
            send_whatsapp(chw_phone, message)
            logger.info(
                "Sent missed visit alert to CHW %s: %d missed",
                chw.username, len(data["missed"])
            )

    except Exception as e:
        logger.error("Missed visit job failed: %s", e)
    finally:
        db.close()
