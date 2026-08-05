import os
import sys
from datetime import datetime, timedelta

import pytest

os.environ.setdefault("DATABASE_URL", "sqlite:////tmp/mamasafe_test.db")
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.database import (  # noqa: E402
    Base,
    Assessment,
    Patient,
    Pregnancy,
    RiskEscalationEvent,
    SessionLocal,
    User,
    engine,
)
from app.routers import assessments, anc, dashboard, risk_trend  # noqa: E402


@pytest.fixture()
def db_session():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _user(db, *, username, role, district=None):
    user = User(
        username=username,
        hashed_password="hash",
        role=role,
        full_name=username.title(),
        district=district,
        region="North",
        is_active=True,
        must_change_password=False,
    )
    db.add(user)
    db.flush()
    return user


def _patient(db, *, name, chw_id):
    patient = Patient(
        full_name=name,
        date_of_birth="1995-01-01",
        phone="+23700000000",
        chw_id=chw_id,
    )
    db.add(patient)
    db.flush()
    return patient


def _assessment(db, *, patient, created_by, risk_level, created_at):
    assessment = Assessment(
        patient_id=patient.id,
        patient_ref=str(patient.id),
        age=28,
        systolic_bp=120,
        diastolic_bp=80,
        blood_sugar=4.5,
        body_temp=36.8,
        heart_rate=88,
        risk_level=risk_level,
        prob_high=0.1,
        prob_low=0.2,
        prob_mid=0.7,
        created_by=created_by,
        created_at=created_at,
    )
    db.add(assessment)
    db.flush()
    return assessment


def _escalation(db, *, patient, chw_id, assessment, created_at):
    event = RiskEscalationEvent(
        patient_id=patient.id,
        previous_assessment_id=None,
        new_assessment_id=assessment.id,
        previous_risk_level="low risk",
        new_risk_level="high risk",
        escalation_type="low_risk_to_high_risk",
        chw_id=chw_id,
        created_at=created_at,
    )
    db.add(event)
    db.flush()
    return event


def test_supervisor_views_are_limited_to_their_district(db_session):
    supervisor = _user(db_session, username="sup", role="supervisor", district="District A")
    chw_a = _user(db_session, username="chw-a", role="chw", district="District A")
    chw_b = _user(db_session, username="chw-b", role="chw", district="District B")

    patient_a = _patient(db_session, name="Alice A", chw_id=chw_a.id)
    patient_b = _patient(db_session, name="Beatrice B", chw_id=chw_b.id)

    now = datetime.utcnow()
    district_assessment = _assessment(
        db_session,
        patient=patient_a,
        created_by=chw_a.id,
        risk_level="high risk",
        created_at=now - timedelta(days=1),
    )
    _assessment(
        db_session,
        patient=patient_b,
        created_by=chw_b.id,
        risk_level="low risk",
        created_at=now,
    )

    _escalation(
        db_session,
        patient=patient_a,
        chw_id=chw_a.id,
        assessment=district_assessment,
        created_at=now - timedelta(days=1),
    )
    _escalation(
        db_session,
        patient=patient_b,
        chw_id=chw_b.id,
        assessment=district_assessment,
        created_at=now,
    )

    db_session.add(Pregnancy(patient_id=patient_a.id, lmp_date="2026-01-01", is_active=True))
    db_session.add(Pregnancy(patient_id=patient_b.id, lmp_date="2026-01-01", is_active=True))
    db_session.commit()

    assessments_out = assessments.get_assessments(
        db=db_session,
        current_user=supervisor,
        skip=0,
        limit=20,
    )
    summary = dashboard.get_summary(db=db_session, current_user=supervisor)
    patients_out = anc.list_patients(db=db_session, current_user=supervisor)
    escalations_out = risk_trend.recent_escalations(
        db=db_session,
        current_user=supervisor,
        days=7,
        limit=10,
    )

    assert [a.id for a in assessments_out] == [district_assessment.id]
    assert summary["total_assessments"] == 1
    assert summary["high_risk_count"] == 1
    assert summary["total_patients"] == 1
    assert summary["active_pregnancies"] == 1
    assert [p.id for p in patients_out] == [patient_a.id]
    assert [e["patient_id"] for e in escalations_out] == [patient_a.id]
