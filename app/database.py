from sqlalchemy import create_engine, Column, Integer, Float, String, Boolean, DateTime, ForeignKey
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
    created_at             = Column(DateTime, default=datetime.utcnow)
    must_change_password   = Column(Boolean, default=True)


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
    date_of_birth   = Column(String, nullable=False)   # YYYY-MM-DD
    phone           = Column(String, nullable=True)
    address         = Column(String, nullable=True)
    facility        = Column(String, nullable=True)
    chw_id          = Column(Integer, ForeignKey("users.id"), nullable=True)
    blood_group     = Column(String, nullable=True)
    allergies       = Column(String, nullable=True)
    emergency_contact_name  = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    # relationships
    pregnancies     = relationship("Pregnancy", back_populates="patient",
                                   cascade="all, delete-orphan")


class Pregnancy(Base):
    __tablename__ = "pregnancies"

    id              = Column(Integer, primary_key=True, index=True)
    patient_id      = Column(Integer, ForeignKey("patients.id"), nullable=False)
    lmp_date        = Column(String, nullable=False)   # Last Menstrual Period YYYY-MM-DD
    edd_date        = Column(String, nullable=True)    # Estimated Due Date (auto-calculated)
    gravida         = Column(Integer, default=1)       # total pregnancies including this one
    parity          = Column(Integer, default=0)       # previous deliveries
    is_active       = Column(Boolean, default=True)
    delivery_date   = Column(String, nullable=True)
    delivery_outcome = Column(String, nullable=True)  # live_birth, stillbirth, miscarriage
    delivery_location = Column(String, nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    patient         = relationship("Patient", back_populates="pregnancies")
    anc_visits      = relationship("ANCVisit", back_populates="pregnancy",
                                   cascade="all, delete-orphan")


class ANCVisit(Base):
    __tablename__ = "anc_visits"

    id              = Column(Integer, primary_key=True, index=True)
    pregnancy_id    = Column(Integer, ForeignKey("pregnancies.id"), nullable=False)
    visit_number    = Column(Integer, nullable=False)   # 1 through 8
    visit_date      = Column(String, nullable=False)    # YYYY-MM-DD
    gestational_age = Column(Integer, nullable=True)    # weeks
    weight          = Column(Float, nullable=True)      # kg
    systolic_bp     = Column(Float, nullable=True)
    diastolic_bp    = Column(Float, nullable=True)
    fundal_height   = Column(Float, nullable=True)      # cm
    foetal_hr       = Column(Integer, nullable=True)    # bpm
    presentation    = Column(String, nullable=True)     # cephalic, breech, transverse
    oedema          = Column(Boolean, default=False)
    urinalysis_protein = Column(String, nullable=True)  # negative, trace, +1, +2, +3
    urinalysis_glucose = Column(String, nullable=True)
    haemoglobin     = Column(Float, nullable=True)      # g/dL
    tt_vaccine      = Column(Boolean, default=False)    # tetanus toxoid given
    malaria_prophylaxis = Column(Boolean, default=False)
    iron_supplements = Column(Boolean, default=False)
    notes           = Column(String, nullable=True)
    next_visit_date = Column(String, nullable=True)
    risk_assessment_id = Column(Integer, ForeignKey("assessments.id"), nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    pregnancy       = relationship("Pregnancy", back_populates="anc_visits")


def create_tables():
    Base.metadata.create_all(bind=engine)
