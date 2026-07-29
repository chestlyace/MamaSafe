from sqlalchemy import create_engine, Column, Integer, Float, String, Boolean, DateTime, ForeignKey, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Assessment(Base):
    __tablename__ = "assessments"

    id              = Column(Integer, primary_key=True, index=True)
    patient_ref     = Column(String, nullable=True)
    age             = Column(Float, nullable=False)
    systolic_bp     = Column(Float, nullable=False)
    diastolic_bp    = Column(Float, nullable=False)
    blood_sugar     = Column(Float, nullable=False)
    body_temp       = Column(Float, nullable=False)
    heart_rate      = Column(Float, nullable=False)
    risk_level      = Column(String, nullable=False)
    prob_high       = Column(Float, nullable=False)
    prob_low        = Column(Float, nullable=False)
    prob_mid        = Column(Float, nullable=False)
    shap_bs         = Column(Float, nullable=True)
    shap_systolic   = Column(Float, nullable=True)
    shap_age        = Column(Float, nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)
    patient_id      = Column(Integer, ForeignKey("patients.id"), nullable=True)


class User(Base):
    __tablename__ = "users"

    id                     = Column(Integer, primary_key=True, index=True)
    username               = Column(String, unique=True, index=True)
    hashed_password        = Column(String)
    role                   = Column(String, default="chw")  # "admin" or "chw"
    is_active              = Column(Boolean, default=True)
    full_name              = Column(String, nullable=True)
    facility               = Column(String, nullable=True)  # health post name
    whatsapp_number        = Column(String, nullable=True)
    created_at             = Column(DateTime, default=datetime.utcnow)
    must_change_password   = Column(Boolean, default=True)


class Facility(Base):
    __tablename__ = "facilities"

    id              = Column(Integer, primary_key=True, index=True)
    name            = Column(String, nullable=False)
    level           = Column(String, nullable=False)  # health_post, health_center, district_hospital, regional_hospital, central_hospital
    phone           = Column(String, nullable=True)
    whatsapp        = Column(String, nullable=True)
    address         = Column(String, nullable=True)
    region          = Column(String, nullable=True)
    is_active       = Column(Boolean, default=True)
    suggested_by    = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved        = Column(Boolean, default=False)
    created_at      = Column(DateTime, default=datetime.utcnow)


class Referral(Base):
    __tablename__ = "referrals"

    id                      = Column(Integer, primary_key=True, index=True)
    patient_id              = Column(Integer, ForeignKey("patients.id"), nullable=True)
    assessment_id           = Column(Integer, ForeignKey("assessments.id"), nullable=True)
    facility_id             = Column(Integer, ForeignKey("facilities.id"), nullable=False)
    facility_name           = Column(String, nullable=False)
    status                  = Column(String, default="SENT")  # SENT, RECEIVED, PATIENT_ARRIVED

    # Patient snapshot
    patient_name            = Column(String, nullable=False)
    patient_age             = Column(Integer, nullable=True)
    patient_phone           = Column(String, nullable=True)
    patient_blood_group     = Column(String, nullable=True)
    patient_allergies       = Column(String, nullable=True)
    emergency_contact_name  = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)

    # Pregnancy snapshot
    gravida                 = Column(Integer, nullable=True)
    parity                  = Column(Integer, nullable=True)
    edd_date                = Column(String, nullable=True)
    gestational_age         = Column(Integer, nullable=True)

    # Clinical snapshot
    systolic_bp             = Column(Float, nullable=True)
    diastolic_bp            = Column(Float, nullable=True)
    heart_rate              = Column(Integer, nullable=True)
    body_temp               = Column(Float, nullable=True)
    blood_sugar             = Column(Float, nullable=True)
    risk_level              = Column(String, nullable=True)
    risk_probability        = Column(Float, nullable=True)

    # Referral-specific
    complication_type       = Column(String, nullable=True)
    chw_notes               = Column(String, nullable=True)
    chw_id                  = Column(Integer, ForeignKey("users.id"), nullable=False)

    # WhatsApp delivery
    whatsapp_sent           = Column(Boolean, default=False)
    whatsapp_message_id     = Column(String, nullable=True)

    # Timestamps
    sent_at                 = Column(DateTime, nullable=True)
    received_at             = Column(DateTime, nullable=True)
    patient_arrived_at      = Column(DateTime, nullable=True)
    created_at              = Column(DateTime, default=datetime.utcnow)


class RiskEscalationEvent(Base):
    __tablename__ = "risk_escalation_events"

    id                     = Column(Integer, primary_key=True, index=True)
    patient_id             = Column(Integer, ForeignKey("patients.id"), nullable=False)
    previous_assessment_id = Column(Integer, ForeignKey("assessments.id"), nullable=True)
    new_assessment_id      = Column(Integer, ForeignKey("assessments.id"), nullable=False)
    previous_risk_level    = Column(String, nullable=False)
    new_risk_level         = Column(String, nullable=False)
    escalation_type        = Column(String, nullable=False)
    whatsapp_sent          = Column(Boolean, default=False)
    whatsapp_error         = Column(String, nullable=True)
    chw_id                 = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at             = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient")
    chw     = relationship("User", foreign_keys=[chw_id])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class Patient(Base):
    __tablename__ = "patients"

    id              = Column(Integer, primary_key=True, index=True)
    full_name       = Column(String, nullable=False)
    date_of_birth   = Column(String, nullable=False)
    phone           = Column(String, nullable=True)
    address         = Column(String, nullable=True)
    facility        = Column(String, nullable=True)
    chw_id          = Column(Integer, ForeignKey("users.id"), nullable=True)
    blood_group     = Column(String, nullable=True)
    allergies       = Column(String, nullable=True)
    emergency_contact_name  = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    preferred_language      = Column(String, default="fr")  # "fr" or "en"
    created_at      = Column(DateTime, default=datetime.utcnow)

    pregnancies = relationship("Pregnancy", back_populates="patient",
                               cascade="all, delete-orphan")
    deliveries   = relationship("Delivery", back_populates="patient")


class Pregnancy(Base):
    __tablename__ = "pregnancies"

    id              = Column(Integer, primary_key=True, index=True)
    patient_id      = Column(Integer, ForeignKey("patients.id"), nullable=False)
    lmp_date        = Column(String, nullable=False)
    edd_date        = Column(String, nullable=True)
    gravida         = Column(Integer, default=1)
    parity          = Column(Integer, default=0)
    is_active       = Column(Boolean, default=True)
    delivery_date   = Column(String, nullable=True)
    delivery_outcome = Column(String, nullable=True)
    delivery_location = Column(String, nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    patient   = relationship("Patient", back_populates="pregnancies")
    delivery  = relationship("Delivery", back_populates="pregnancy", uselist=False)
    anc_visits = relationship("ANCVisit", back_populates="pregnancy",
                              cascade="all, delete-orphan")
    scheduled_visits = relationship("ScheduledVisit", back_populates="pregnancy",
                                    cascade="all, delete-orphan",
                                    order_by="ScheduledVisit.visit_number")


class ANCVisit(Base):
    __tablename__ = "anc_visits"

    id              = Column(Integer, primary_key=True, index=True)
    pregnancy_id    = Column(Integer, ForeignKey("pregnancies.id"), nullable=False)
    visit_number    = Column(Integer, nullable=False)
    visit_date      = Column(String, nullable=False)
    gestational_age = Column(Integer, nullable=True)
    weight          = Column(Float, nullable=True)
    systolic_bp     = Column(Float, nullable=True)
    diastolic_bp    = Column(Float, nullable=True)
    fundal_height   = Column(Float, nullable=True)
    foetal_hr       = Column(Integer, nullable=True)
    presentation    = Column(String, nullable=True)
    oedema          = Column(Boolean, default=False)
    urinalysis_protein = Column(String, nullable=True)
    urinalysis_glucose = Column(String, nullable=True)
    haemoglobin     = Column(Float, nullable=True)
    tt_vaccine      = Column(Boolean, default=False)
    malaria_prophylaxis = Column(Boolean, default=False)
    iron_supplements = Column(Boolean, default=False)
    notes           = Column(String, nullable=True)
    next_visit_date = Column(String, nullable=True)
    risk_assessment_id = Column(Integer, ForeignKey("assessments.id"), nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    pregnancy = relationship("Pregnancy", back_populates="anc_visits")


class ScheduledVisit(Base):
    __tablename__ = "scheduled_visits"

    id                     = Column(Integer, primary_key=True, index=True)
    pregnancy_id           = Column(Integer, ForeignKey("pregnancies.id"), nullable=False)
    visit_number           = Column(Integer, nullable=False)
    gestational_week       = Column(Integer, nullable=False)
    label                  = Column(String, nullable=True)
    scheduled_date         = Column(String, nullable=False)   # YYYY-MM-DD
    original_date          = Column(String, nullable=True)    # set if rescheduled
    reschedule_reason      = Column(String, nullable=True)
    status                 = Column(String, default="scheduled")
    # scheduled | completed | missed | rescheduled | cancelled
    anc_visit_id           = Column(Integer, ForeignKey("anc_visits.id"), nullable=True)
    reminder_48h_sent      = Column(Boolean, default=False)
    reminder_48h_sent_at   = Column(DateTime, nullable=True)
    reminder_day_sent      = Column(Boolean, default=False)
    reminder_day_sent_at   = Column(DateTime, nullable=True)
    whatsapp_delivered_48h = Column(Boolean, default=False)
    whatsapp_delivered_day = Column(Boolean, default=False)
    notes                  = Column(String, nullable=True)
    created_at             = Column(DateTime, default=datetime.utcnow)

    pregnancy = relationship("Pregnancy", back_populates="scheduled_visits")


class Delivery(Base):
    __tablename__ = "deliveries"

    id                 = Column(Integer, primary_key=True, index=True)
    pregnancy_id       = Column(Integer, ForeignKey("pregnancies.id"), nullable=False)
    patient_id         = Column(Integer, ForeignKey("patients.id"), nullable=False)
    delivery_date      = Column(String, nullable=False)
    delivery_location  = Column(String, nullable=True)
    delivered_by       = Column(String, nullable=True)
    complications      = Column(String, nullable=True)
    notes              = Column(String, nullable=True)
    created_at         = Column(DateTime, default=datetime.utcnow)

    pregnancy = relationship("Pregnancy", back_populates="delivery")
    patient   = relationship("Patient", back_populates="deliveries")
    newborns  = relationship("Newborn", back_populates="delivery",
                             cascade="all, delete-orphan")
    pnc_visits = relationship("PostnatalVisit", back_populates="delivery",
                              cascade="all, delete-orphan")
    scheduled_visits = relationship("PostnatalScheduledVisit",
                                    back_populates="delivery",
                                    cascade="all, delete-orphan")


class Newborn(Base):
    __tablename__ = "newborns"

    id               = Column(Integer, primary_key=True, index=True)
    delivery_id      = Column(Integer, ForeignKey("deliveries.id"), nullable=False)
    name             = Column(String, nullable=True)
    sex              = Column(String, nullable=False)
    birth_weight     = Column(Float, nullable=True)
    apgar_score      = Column(Integer, nullable=True)
    crying_at_birth  = Column(Boolean, default=True)
    breastfeeding    = Column(Boolean, default=False)
    malformations    = Column(String, nullable=True)
    status           = Column(String, default="alive")  # alive | stillbirth | neonatal_death
    created_at       = Column(DateTime, default=datetime.utcnow)

    delivery = relationship("Delivery", back_populates="newborns")


class PostnatalScheduledVisit(Base):
    __tablename__ = "postnatal_scheduled_visits"

    id                  = Column(Integer, primary_key=True, index=True)
    delivery_id         = Column(Integer, ForeignKey("deliveries.id"), nullable=False)
    visit_number        = Column(Integer, nullable=False)
    days_after_delivery = Column(Integer, nullable=False)
    label               = Column(String, nullable=True)
    scheduled_date      = Column(String, nullable=False)
    status              = Column(String, default="scheduled")
    # scheduled | completed | missed | cancelled
    postnatal_visit_id  = Column(Integer, ForeignKey("postnatal_visits.id"), nullable=True)
    reminder_48h_sent   = Column(Boolean, default=False)
    reminder_day_sent   = Column(Boolean, default=False)
    created_at          = Column(DateTime, default=datetime.utcnow)

    delivery       = relationship("Delivery", back_populates="scheduled_visits")
    postnatal_visit = relationship("PostnatalVisit",
                                   foreign_keys=[postnatal_visit_id],
                                   back_populates="scheduled_visit")


class PostnatalVisit(Base):
    __tablename__ = "postnatal_visits"

    id                = Column(Integer, primary_key=True, index=True)
    delivery_id       = Column(Integer, ForeignKey("deliveries.id"), nullable=False)
    visit_number      = Column(Integer, nullable=False)
    visit_date        = Column(String, nullable=False)
    mother_status     = Column(String, nullable=True)  # good | complications
    uterus_firm       = Column(Boolean, default=True)
    lochia_normal     = Column(Boolean, default=True)
    temperature       = Column(Float, nullable=True)
    systolic_bp       = Column(Float, nullable=True)
    diastolic_bp      = Column(Float, nullable=True)
    breast_exam       = Column(String, nullable=True)
    perineal_exam     = Column(String, nullable=True)
    hb_result         = Column(Float, nullable=True)
    malaria_test      = Column(Boolean, default=False)
    hiv_test          = Column(Boolean, default=False)
    mental_health     = Column(String, nullable=True)  # normal | concern
    notes             = Column(String, nullable=True)
    newborn_weight_kg = Column(Float, nullable=True)
    newborn_id        = Column(Integer, ForeignKey("newborns.id"), nullable=True)
    breastfeeding_status = Column(String, nullable=True)  # exclusive | mixed | not
    created_at        = Column(DateTime, default=datetime.utcnow)

    delivery        = relationship("Delivery", back_populates="pnc_visits")
    scheduled_visit = relationship("PostnatalScheduledVisit",
                                   back_populates="postnatal_visit",
                                   uselist=False)
    screenings      = relationship("MentalHealthScreening",
                                   back_populates="postnatal_visit")
    newborn         = relationship("Newborn")


class GrowthAlert(Base):
    __tablename__ = "growth_alerts"

    id                = Column(Integer, primary_key=True, index=True)
    newborn_id         = Column(Integer, ForeignKey("newborns.id"), nullable=False)
    patient_id         = Column(Integer, ForeignKey("patients.id"), nullable=False)
    postnatal_visit_id = Column(Integer, ForeignKey("postnatal_visits.id"), nullable=True)
    alert_type         = Column(String, nullable=False)
    # below_3rd_percentile | growth_faltering | failed_to_regain_birth_weight
    severity           = Column(String, default="warning")  # warning | critical
    message_en         = Column(String, nullable=False)
    message_fr         = Column(String, nullable=False)
    z_score            = Column(Float, nullable=True)
    resolved           = Column(Boolean, default=False)
    resolved_at        = Column(DateTime, nullable=True)
    created_at         = Column(DateTime, default=datetime.utcnow)

    newborn  = relationship("Newborn")
    patient  = relationship("Patient")
    visit    = relationship("PostnatalVisit")


class MentalHealthScreening(Base):
    __tablename__ = "mental_health_screenings"

    id                = Column(Integer, primary_key=True, index=True)
    postnatal_visit_id = Column(Integer, ForeignKey("postnatal_visits.id"), nullable=True)
    patient_id        = Column(Integer, ForeignKey("patients.id"), nullable=False)
    phq2_score        = Column(Integer, nullable=False)
    phq2_q1           = Column(Integer, nullable=True)
    phq2_q2           = Column(Integer, nullable=True)
    risk_level        = Column(String, nullable=False)  # low | high
    chw_alerted       = Column(Boolean, default=False)
    created_at        = Column(DateTime, default=datetime.utcnow)

    postnatal_visit = relationship("PostnatalVisit", back_populates="screenings")
    patient         = relationship("Patient")


def _migrate_columns(engine):
    """Add missing columns to existing tables without data loss."""
    inspector = inspect(engine)
    migrations = [
        ("referrals", "whatsapp_sent", "BOOLEAN DEFAULT FALSE"),
        ("referrals", "whatsapp_message_id", "VARCHAR"),
        ("users", "whatsapp_number", "VARCHAR"),
        ("patients", "preferred_language", "VARCHAR DEFAULT 'fr'"),
        ("risk_escalation_events", "whatsapp_error", "VARCHAR"),
        ("postnatal_visits", "newborn_weight_kg", "FLOAT"),
        ("postnatal_visits", "newborn_id", "INTEGER REFERENCES newborns(id)"),
        ("postnatal_visits", "breastfeeding_status", "VARCHAR"),
    ]
    for table, column, col_type in migrations:
        if table in inspector.get_table_names():
            existing = {col["name"] for col in inspector.get_columns(table)}
            if column not in existing:
                with engine.connect() as conn:
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"))
                    conn.commit()
                print(f"  Migration: added {table}.{column}")

    # Make referrals.patient_id nullable (was NOT NULL, now optional for assessment-only referrals)
    if "referrals" in inspector.get_table_names():
        cols = {col["name"]: col for col in inspector.get_columns("referrals")}
        if "patient_id" in cols and cols["patient_id"].get("nullable") is False:
            with engine.connect() as conn:
                conn.execute(text("ALTER TABLE referrals ALTER COLUMN patient_id DROP NOT NULL"))
                conn.commit()
            print("  Migration: referrals.patient_id made nullable")

    # Make mental_health_screenings.postnatal_visit_id nullable
    if "mental_health_screenings" in inspector.get_table_names():
        cols = {col["name"]: col for col in inspector.get_columns("mental_health_screenings")}
        if "postnatal_visit_id" in cols and cols["postnatal_visit_id"].get("nullable") is False:
            with engine.connect() as conn:
                conn.execute(text("ALTER TABLE mental_health_screenings ALTER COLUMN postnatal_visit_id DROP NOT NULL"))
                conn.commit()
            print("  Migration: mental_health_screenings.postnatal_visit_id made nullable")


def create_tables():
    Base.metadata.create_all(bind=engine)
    _migrate_columns(engine)
