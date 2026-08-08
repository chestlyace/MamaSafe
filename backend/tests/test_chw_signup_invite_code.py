import os
import sys

import pytest

os.environ.setdefault("DATABASE_URL", "sqlite:////tmp/mamasafe_test_chw.db")
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.database import (  # noqa: E402
    Base,
    DistrictInvite,
    SessionLocal,
    User,
    engine,
)
from app.routers import auth  # noqa: E402


@pytest.fixture()
def db_session():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _supervisor(db):
    sup = User(
        username="sup",
        hashed_password="hash",
        role="supervisor",
        full_name="Sup",
        district="District A",
        region="North",
        is_active=True,
        must_change_password=False,
    )
    db.add(sup)
    db.flush()
    return sup


def _invite(db, *, code, supervisor):
    invite = DistrictInvite(
        code="ABCD1234",
        supervisor_id=supervisor.id,
        district=supervisor.district,
        status="pending",
    )
    db.add(invite)
    db.flush()
    return invite


def test_chw_signup_accepts_dashed_invite_code(db_session):
    sup = _supervisor(db_session)
    _invite(db_session, code="ABCD1234", supervisor=sup)

    payload = auth.ChwSignup(
        full_name="CHW One",
        username="chw-one",
        password="secret",
        facility="Clinic",
        invite_code="ABCD-1234",
    )
    result = auth.chw_signup(payload, db_session)
    assert result["message"] == "CHW account created. You can log in now."


def test_chw_signup_rejects_unknown_invite_code(db_session):
    _supervisor(db_session)

    payload = auth.ChwSignup(
        full_name="CHW Two",
        username="chw-two",
        password="secret",
        invite_code="ZZZZ9999",
    )
    with pytest.raises(Exception) as exc_info:
        auth.chw_signup(payload, db_session)
    assert "Invalid registration code" in str(exc_info.value)
