from sqlalchemy import create_engine, Column, Integer, Float, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
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


def create_tables():
    Base.metadata.create_all(bind=engine)
