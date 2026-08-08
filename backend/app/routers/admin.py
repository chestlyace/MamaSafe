from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime, date, timedelta
import io
import csv
import secrets
import string

from app.database import (
    get_db, User, Patient, Assessment, Referral,
    Delivery, PostnatalScheduledVisit, ScheduledVisit,
    GrowthAlert, MentalHealthScreening, AuditLog, DistrictInvite,
    Facility, Pregnancy
)
from app.schemas_admin import (
    CHWSummary, HighRiskPatient, UserCreate,
    UserUpdate, MonthlyReport, InviteCodeCreate, InviteCodeOut,
    PatientTransferRequest, ChwPatientOut, AdminPatientOut,
    SupervisorOut, DistrictSummary, ChwRosterOut
)
from app.routers.auth import get_current_user, hash_password
from app.database import RiskEscalationEvent

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def require_supervisor(current_user = Depends(get_current_user)):
    if current_user.role not in ("supervisor", "admin"):
        raise HTTPException(status_code=403,
                            detail="Supervisor or admin access required")
    return current_user


def require_medical_supervisor(current_user = Depends(get_current_user)):
    if current_user.role != "supervisor":
        raise HTTPException(status_code=403,
                            detail="Supervisor access required")
    return current_user


def require_admin(current_user = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403,
                            detail="Admin access required")
    return current_user


def get_district_chw_ids(db: Session, supervisor) -> List[int]:
    if supervisor.role == "admin":
        return [u.id for u in db.query(User.id)
                .filter(User.role == "chw").all()]
    if supervisor.role == "supervisor":
        # Supervisor: see CHWs in their district plus their own directly-
        # created records (supervisors register patients/assessments
        # themselves; those rows carry the supervisor's own id).
        return [supervisor.id] + [u.id for u in db.query(User.id)
                .filter(User.role == "chw",
                        User.district == supervisor.district).all()]
    # CHW: only their own ID
    return [supervisor.id]


def get_district_patient_ids(db: Session, chw_ids: List[int]) -> List[int]:
    return [p.id for p in db.query(Patient.id)
            .filter(Patient.chw_id.in_(chw_ids)).all()]


def chw_status(days_since: Optional[int]) -> str:
    if days_since is None: return "never_active"
    if days_since <= 3:    return "active"
    if days_since <= 7:    return "inactive_warning"
    return "inactive"


# ── INVITE CODES ──────────────────────────────────────────

def _live_invite_status(invite, now: datetime) -> str:
    if invite.status != "pending":
        return invite.status
    if invite.expires_at and invite.expires_at < now:
        return "expired"
    return "pending"


def generate_invite_code(db: Session) -> str:
    alphabet = string.ascii_uppercase + string.digits
    while True:
        code = "".join(secrets.choice(alphabet) for _ in range(8))
        if not db.query(DistrictInvite.id).filter(DistrictInvite.code == code).first():
            return code


@router.get("/invite-codes", response_model=List[InviteCodeOut])
def list_invite_codes(
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    query = db.query(DistrictInvite)
    if supervisor.role != "admin":
        query = query.filter(DistrictInvite.supervisor_id == supervisor.id)
    invites = query.order_by(DistrictInvite.created_at.desc()).all()

    now = datetime.utcnow()
    result = []
    for inv in invites:
        used_by = db.query(User).filter(User.id == inv.used_by_user_id).first()
        sup     = db.query(User).filter(User.id == inv.supervisor_id).first()
        result.append({
            "id":                  inv.id,
            "code":                inv.code,
            "district":            inv.district,
            "note":                inv.note,
            "status":              _live_invite_status(inv, now),
            "expires_at":          inv.expires_at,
            "created_at":          inv.created_at,
            "used_by_username":    used_by.username if used_by else None,
            "supervisor_username": sup.username if sup else None,
        })
    return result


@router.post("/invite-codes", status_code=201, response_model=InviteCodeOut)
def create_invite_code(
    payload: InviteCodeCreate,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    expires_at = None
    if payload.expires_in_days and payload.expires_in_days > 0:
        expires_at = datetime.utcnow() + timedelta(days=payload.expires_in_days)

    invite = DistrictInvite(
        code          = generate_invite_code(db),
        supervisor_id = supervisor.id,
        district      = supervisor.district,
        note          = payload.note,
        expires_at    = expires_at,
        status        = "pending",
    )
    db.add(invite)
    db.commit()
    db.refresh(invite)

    log = AuditLog(user_id=supervisor.id, action="invite_code_created",
                   target_type="district_invite", target_id=invite.id)
    db.add(log)
    db.commit()

    return {
        "id":         invite.id,
        "code":       invite.code,
        "district":   invite.district,
        "note":       invite.note,
        "status":     "pending",
        "expires_at": invite.expires_at,
        "created_at": invite.created_at,
    }


@router.post("/invite-codes/{invite_id}/revoke")
def revoke_invite_code(
    invite_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_supervisor)
):
    invite = db.query(DistrictInvite).filter(DistrictInvite.id == invite_id).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite code not found")
    if supervisor.role != "admin" and invite.supervisor_id != supervisor.id:
        raise HTTPException(status_code=403,
                            detail="You can only revoke your own invite codes")
    if invite.status != "pending":
        raise HTTPException(status_code=400,
                            detail="Only pending invite codes can be revoked")

    invite.status = "revoked"
    log = AuditLog(user_id=supervisor.id, action="invite_code_revoked",
                   target_type="district_invite", target_id=invite.id)
    db.add(log)
    db.commit()

    return {"message": "Invite code revoked"}


# ── SUPERVISOR PATIENT MANAGEMENT ────────────────────────

def _patient_risk_info(db: Session, patient) -> dict:
    latest = (db.query(Assessment)
                .filter(Assessment.patient_id == patient.id)
                .order_by(Assessment.created_at.desc()).first())
    return {
        "id":              patient.id,
        "full_name":       patient.full_name,
        "date_of_birth":   str(patient.date_of_birth) if patient.date_of_birth else None,
        "phone":           patient.phone,
        "facility":        patient.facility,
        "chw_id":          patient.chw_id,
        "risk_level":      latest.risk_level if latest else None,
        "last_assessment": str(latest.created_at.date()) if latest else None,
    }


@router.get("/chws/{chw_id}/patients", response_model=List[ChwPatientOut])
def get_chw_patients(
    chw_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    if chw_id not in chw_ids:
        raise HTTPException(status_code=403,
                            detail="CHW not in your district")
    patients = (db.query(Patient)
                  .filter(Patient.chw_id == chw_id)
                  .order_by(Patient.full_name).all())
    return [_patient_risk_info(db, p) for p in patients]


@router.get("/patients", response_model=List[AdminPatientOut])
def list_supervisor_patients(
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)
    chws        = db.query(User).filter(User.id.in_(chw_ids)).all()
    chw_names   = {u.id: u.full_name for u in chws}
    chw_district = {u.id: u.district for u in chws}

    result = []
    for pid in patient_ids:
        patient = db.query(Patient).filter(Patient.id == pid).first()
        if not patient:
            continue
        info = _patient_risk_info(db, patient)
        info["chw_name"] = chw_names.get(patient.chw_id)
        info["district"] = chw_district.get(patient.chw_id)
        result.append(info)
    return result


@router.post("/patients/{patient_id}/transfer")
def transfer_patient(
    patient_id: int,
    payload: PatientTransferRequest,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    old_chw_id = patient.chw_id
    if old_chw_id == payload.new_chw_id:
        raise HTTPException(status_code=400,
                            detail="Patient is already assigned to this CHW")

    chw_ids = get_district_chw_ids(db, supervisor)
    if old_chw_id not in chw_ids:
        raise HTTPException(status_code=403,
                            detail="Patient is not under a CHW in your district")
    new_chw = db.query(User).filter(User.id == payload.new_chw_id).first()
    if not new_chw or new_chw.role != "chw" or new_chw.id not in chw_ids:
        raise HTTPException(status_code=400,
                            detail="Target CHW not in your district")

    patient.chw_id = payload.new_chw_id
    db.query(Referral).filter(
        Referral.patient_id == patient_id,
        Referral.chw_id == old_chw_id
    ).update({"chw_id": payload.new_chw_id}, synchronize_session=False)
    db.query(RiskEscalationEvent).filter(
        RiskEscalationEvent.patient_id == patient_id,
        RiskEscalationEvent.chw_id == old_chw_id
    ).update({"chw_id": payload.new_chw_id}, synchronize_session=False)

    log = AuditLog(
        user_id=supervisor.id,
        action="patient_transferred",
        target_type="patient",
        target_id=patient_id,
    )
    db.add(log)
    db.commit()

    return {"message": "Patient transferred",
            "patient_id": patient_id,
            "old_chw_id": old_chw_id,
            "new_chw_id": payload.new_chw_id,
            "reason":     payload.reason}


# ── ADMIN OVERVIEW ────────────────────────────────────────

@router.get("/districts", response_model=List[DistrictSummary])
def list_districts(
    db: Session = Depends(get_db),
    _admin = Depends(require_admin)
):
    districts = {}
    for u in db.query(User).filter(User.role == "supervisor").all():
        if not u.district:
            continue
        d = districts.setdefault(u.district, {
            "district": u.district, "region": u.region,
            "supervisor_count": 0, "chw_count": 0,
            "patient_count": 0,
        })
        d["supervisor_count"] += 1
    for u in db.query(User).filter(User.role == "chw").all():
        if not u.district:
            continue
        d = districts.setdefault(u.district, {
            "district": u.district, "region": None,
            "supervisor_count": 0, "chw_count": 0,
            "patient_count": 0,
        })
        d["chw_count"] += 1

    # Region of a district = the region of its supervisors (first found)
    for name, d in districts.items():
        sup = (db.query(User)
                 .filter(User.role == "supervisor",
                         User.district == name).first())
        if sup:
            d["region"] = sup.region

    # Per-district patient registration volume
    for name, d in districts.items():
        chw_ids = [c.id for c in db.query(User.id)
                   .filter(User.role == "chw",
                           User.district == name).all()]
        d["patient_count"] = len(get_district_patient_ids(db, chw_ids))

    return list(districts.values())


@router.get("/supervisors", response_model=List[SupervisorOut])
def list_supervisors(
    db: Session = Depends(get_db),
    _admin = Depends(require_admin)
):
    result = []
    for u in (db.query(User)
                .filter(User.role == "supervisor")
                .order_by(User.district, User.full_name).all()):
        chw_ids = [c.id for c in
                   db.query(User.id).filter(User.role == "chw",
                                            User.district == u.district).all()]
        patient_ids = get_district_patient_ids(db, chw_ids)
        result.append({
            "id":            u.id,
            "full_name":     u.full_name,
            "username":      u.username,
            "district":      u.district,
            "region":        u.region,
            "is_active":     u.is_active,
            "last_active":   u.last_active,
            "chw_count":     len(chw_ids),
            "patient_count": len(patient_ids),
        })
    return result


@router.get("/facilities")
def list_admin_facilities(
    db: Session = Depends(get_db),
    _admin = Depends(require_admin)
):
    rows = (db.query(Facility).order_by(Facility.approved,
                                        Facility.name).all())
    return [{
        "id":          f.id,
        "name":        f.name,
        "district":    getattr(f, "district", None),
        "approved":    f.approved,
        "suggested_by": f.suggested_by,
        "is_active":   f.is_active,
        "created_at":  f.created_at,
    } for f in rows]


# ── DASHBOARD ─────────────────────────────────────────────

@router.get("/dashboard")
def get_dashboard(
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)

    today      = date.today()
    week_start = today - timedelta(days=7)
    last_week  = today - timedelta(days=14)

    total_chws = len([c for c in db.query(User)
                      .filter(User.role == "chw",
                              User.district == supervisor.district).all()])
    total_patients    = len(patient_ids)
    total_assessments = (db.query(Assessment)
                           .filter(Assessment.patient_id.in_(patient_ids))
                           .count())
    total_deliveries  = (db.query(Delivery)
                           .filter(Delivery.patient_id.in_(patient_ids))
                           .count())
    total_referrals   = (db.query(Referral)
                           .filter(Referral.chw_id.in_(chw_ids))
                           .count())

    risk_counts = {"low risk": 0, "mid risk": 0, "high risk": 0}
    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc())
                    .first())
        if latest:
            risk_counts[latest.risk_level] = risk_counts.get(
                latest.risk_level, 0) + 1

    active_today = (db.query(User)
                      .filter(User.id.in_(chw_ids),
                              func.date(User.last_active) == today)
                      .count())

    def week_stats(start, end):
        return {
            "assessments": (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids),
                                      func.date(Assessment.created_at) >= start,
                                      func.date(Assessment.created_at) <  end)
                              .count()),
            "referrals":   (db.query(Referral)
                              .filter(Referral.chw_id.in_(chw_ids),
                                      func.date(Referral.created_at) >= start,
                                      func.date(Referral.created_at) <  end)
                              .count()),
            "deliveries":  (db.query(Delivery)
                              .filter(Delivery.patient_id.in_(patient_ids),
                                      Delivery.delivery_date >= str(start),
                                      Delivery.delivery_date <  str(end))
                              .count()),
            "new_patients": (db.query(Patient)
                               .filter(Patient.chw_id.in_(chw_ids),
                                       func.date(Patient.created_at) >= start,
                                       func.date(Patient.created_at) <  end)
                               .count()),
        }

    completed_refs = (db.query(Referral)
                       .filter(Referral.chw_id.in_(chw_ids),
                               Referral.status == "PATIENT_ARRIVED")
                       .count())

    delivery_ids = [d.id for d in db.query(Delivery.id)
                    .filter(Delivery.patient_id.in_(patient_ids)).all()]

    def pnc_rate(visit_num):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == visit_num)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == visit_num,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        return round(done / total * 100, 1) if total else 0

    pending_escalations = (db.query(RiskEscalationEvent)
                             .join(Patient,
                                   RiskEscalationEvent.patient_id == Patient.id)
                             .filter(Patient.chw_id.in_(chw_ids),
                                     RiskEscalationEvent.created_at >=
                                     str(week_start))
                             .count())

    phq2_positive = (db.query(MentalHealthScreening)
                       .join(Patient,
                             MentalHealthScreening.patient_id == Patient.id)
                       .filter(Patient.chw_id.in_(chw_ids),
                               func.date(MentalHealthScreening.created_at) >=
                               date(today.year, today.month, 1))
                       .count())

    growth_alerts = (db.query(GrowthAlert)
                       .join(Patient,
                             GrowthAlert.patient_id == Patient.id)
                       .filter(Patient.chw_id.in_(chw_ids),
                               GrowthAlert.resolved == False)
                       .count())

    return {
        "district":               supervisor.district or "All districts",
        "region":                 supervisor.region,
        "total_chws":             total_chws,
        "active_chws_today":      active_today,
        "total_patients":         total_patients,
        "total_assessments":      total_assessments,
        "total_deliveries":       total_deliveries,
        "total_referrals":        total_referrals,
        "referral_completion_rate": round(
            completed_refs / total_referrals * 100, 1)
            if total_referrals else 0,
        "high_risk_active":       risk_counts.get("high risk", 0),
        "mid_risk_active":        risk_counts.get("mid risk", 0),
        "low_risk_active":        risk_counts.get("low risk", 0),
        "pnc1_completion_rate":   pnc_rate(1),
        "phq2_positive_this_month": phq2_positive,
        "growth_alerts_active":   growth_alerts,
        "pending_escalations":    pending_escalations,
        "this_week":              week_stats(week_start, today + timedelta(days=1)),
        "last_week":              week_stats(last_week, week_start),
    }


# ── CHW LIST ──────────────────────────────────────────────

@router.get("/chws")
def list_chws(
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    chws    = db.query(User).filter(User.id.in_(chw_ids),
                                   User.role == "chw").all()
    result  = []

    for chw in chws:
        patient_ids = [p.id for p in db.query(Patient.id)
                       .filter(Patient.chw_id == chw.id).all()]

        days_since = None
        if chw.last_active:
            days_since = (date.today() - chw.last_active.date()).days

        assessment_count = (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids))
                              .count())
        referral_count   = (db.query(Referral)
                              .filter(Referral.chw_id == chw.id)
                              .count())
        completed_refs   = (db.query(Referral)
                              .filter(Referral.chw_id == chw.id,
                                      Referral.status == "PATIENT_ARRIVED")
                              .count())
        high_risk = 0
        for pid in patient_ids:
            latest = (db.query(Assessment)
                        .filter(Assessment.patient_id == pid)
                        .order_by(Assessment.created_at.desc())
                        .first())
            if latest and latest.risk_level == "high risk":
                high_risk += 1

        result.append({
            "id":                       chw.id,
            "full_name":                chw.full_name,
            "username":                 chw.username,
            "facility":                 chw.facility,
            "district":                 chw.district,
            "is_active":                chw.is_active,
            "last_active":              chw.last_active,
            "days_since_active":        days_since,
            "patient_count":            len(patient_ids),
            "assessment_count":         assessment_count,
            "referral_count":           referral_count,
            "high_risk_count":          high_risk,
            "referral_completion_rate": round(
                completed_refs / referral_count * 100, 1)
                if referral_count else 0,
            "status":                   chw_status(days_since),
        })

    result.sort(key=lambda x: x["days_since_active"] or 9999)
    return result


@router.get("/chws/roster", response_model=List[ChwRosterOut])
def list_admin_chw_roster(
    db: Session = Depends(get_db),
    _admin = Depends(require_admin)
):
    result = []
    for chw in (db.query(User)
                  .filter(User.role == "chw")
                  .order_by(User.district, User.full_name).all()):
        patient_count = (db.query(Patient.id)
                           .filter(Patient.chw_id == chw.id).count())
        result.append({
            "id":          chw.id,
            "full_name":   chw.full_name,
            "username":    chw.username,
            "facility":    chw.facility,
            "district":    chw.district,
            "is_active":   chw.is_active,
            "last_active": chw.last_active,
            "patient_count": patient_count,
        })
    return result


# ── CHW DETAIL STATS ──────────────────────────────────────

@router.get("/chws/{chw_id}/stats")
def chw_detail_stats(
    chw_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw = db.query(User).filter(User.id == chw_id).first()
    if not chw:
        raise HTTPException(status_code=404, detail="CHW not found")

    patient_ids  = [p.id for p in db.query(Patient.id)
                    .filter(Patient.chw_id == chw_id).all()]
    delivery_ids = [d.id for d in db.query(Delivery.id)
                    .filter(Delivery.patient_id.in_(patient_ids)).all()]

    risk_dist = {"low": 0, "mid": 0, "high": 0}
    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc()).first())
        if latest:
            key = latest.risk_level.replace(" risk", "")
            risk_dist[key] = risk_dist.get(key, 0) + 1

    anc_completion = {}
    for vn in range(1, 9):
        total = (db.query(ScheduledVisit)
                   .join(Patient,
                         Patient.id == ScheduledVisit.pregnancy_id)
                   .filter(Patient.chw_id == chw_id,
                           ScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(ScheduledVisit)
                   .join(Patient,
                         Patient.id == ScheduledVisit.pregnancy_id)
                   .filter(Patient.chw_id == chw_id,
                           ScheduledVisit.visit_number == vn,
                           ScheduledVisit.status == "completed")
                   .count())
        anc_completion[f"visit_{vn}"] = round(
            done / total * 100, 1) if total else 0

    pnc_completion = {}
    for vn in range(1, 4):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        pnc_completion[f"pnc_{vn}"] = round(
            done / total * 100, 1) if total else 0

    weekly_activity = []
    for w in range(3, -1, -1):
        week_start = date.today() - timedelta(weeks=w+1)
        week_end   = date.today() - timedelta(weeks=w)
        weekly_activity.append({
            "week":        str(week_start),
            "assessments": (db.query(Assessment)
                              .filter(Assessment.patient_id.in_(patient_ids),
                                      func.date(Assessment.created_at) >= week_start,
                                      func.date(Assessment.created_at) <  week_end)
                              .count()),
            "referrals":   (db.query(Referral)
                              .filter(Referral.chw_id == chw_id,
                                      func.date(Referral.created_at) >= week_start,
                                      func.date(Referral.created_at) <  week_end)
                              .count()),
        })

    patients = db.query(Patient).filter(Patient.chw_id == chw_id).all()
    patient_list = []
    for p in patients:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == p.id)
                    .order_by(Assessment.created_at.desc()).first())
        patient_list.append({
            "id":               p.id,
            "full_name":        p.full_name,
            "risk_level":       latest.risk_level if latest else None,
            "last_assessment":  str(latest.created_at.date()) if latest else None,
        })

    ref_count   = (db.query(Referral)
                     .filter(Referral.chw_id == chw_id).count())
    comp_refs   = (db.query(Referral)
                     .filter(Referral.chw_id == chw_id,
                             Referral.status == "PATIENT_ARRIVED").count())

    return {
        "chw_id":                     chw_id,
        "full_name":                  chw.full_name,
        "username":                   chw.username,
        "facility":                   chw.facility,
        "last_active":                chw.last_active,
        "patient_count":              len(patient_ids),
        "assessment_count":           (db.query(Assessment)
                                         .filter(Assessment.patient_id
                                                 .in_(patient_ids)).count()),
        "referral_count":             ref_count,
        "referral_completion_rate":   round(comp_refs / ref_count * 100, 1)
                                      if ref_count else 0,
        "risk_distribution":          risk_dist,
        "anc_completion":             anc_completion,
        "pnc_completion":             pnc_completion,
        "weekly_activity":            weekly_activity,
        "patients":                   patient_list,
    }


# ── HIGH-RISK PATIENTS ────────────────────────────────────

@router.get("/high-risk-patients")
def get_high_risk_patients(
    days_since_assessment: int = 7,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)
    result      = []

    for pid in patient_ids:
        latest = (db.query(Assessment)
                    .filter(Assessment.patient_id == pid)
                    .order_by(Assessment.created_at.desc()).first())
        if not latest or latest.risk_level != "high risk":
            continue

        patient = db.query(Patient).filter(Patient.id == pid).first()
        chw     = db.query(User).filter(
            User.id == patient.chw_id).first() if patient else None

        days_since = (date.today() - latest.created_at.date()).days

        referral_made = (db.query(Referral)
                           .filter(Referral.patient_id == pid,
                                   Referral.risk_level == "high risk")
                           .first()) is not None

        result.append({
            "patient_id":             pid,
            "full_name":              patient.full_name if patient else "Unknown",
            "age":                    latest.age,
            "facility":               patient.facility if patient else None,
            "chw_name":               chw.full_name if chw else None,
            "chw_id":                 patient.chw_id if patient else None,
            "risk_level":             "high risk",
            "confidence":             round(latest.prob_high or 0, 3),
            "last_assessment_date":   str(latest.created_at.date()),
            "days_since_assessment":  days_since,
            "flagged":                days_since >= days_since_assessment,
            "systolic_bp":            latest.systolic_bp,
            "blood_sugar":            latest.blood_sugar,
            "referral_made":          referral_made,
        })

    result.sort(key=lambda x: x["days_since_assessment"], reverse=True)
    return result


# ── REFERRAL ANALYTICS ────────────────────────────────────

@router.get("/referral-analytics")
def referral_analytics(
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    refs    = db.query(Referral).filter(Referral.chw_id.in_(chw_ids)).all()

    total     = len(refs)
    by_status = {}
    for r in refs:
        by_status[r.status] = by_status.get(r.status, 0) + 1

    receipt_times = []
    arrival_times = []
    for r in refs:
        if r.received_at and r.sent_at:
            receipt_times.append(
                (r.received_at - r.sent_at).total_seconds() / 3600)
        if r.patient_arrived_at and r.sent_at:
            arrival_times.append(
                (r.patient_arrived_at - r.sent_at).total_seconds() / 3600)

    facility_map = {}
    for r in refs:
        fn = r.facility_name or "Unknown"
        if fn not in facility_map:
            facility_map[fn] = {"total": 0, "arrived": 0}
        facility_map[fn]["total"] += 1
        if r.status == "PATIENT_ARRIVED":
            facility_map[fn]["arrived"] += 1

    by_facility = [
        {
            "facility_name":    fn,
            "total":            d["total"],
            "arrived":          d["arrived"],
            "completion_rate":  round(d["arrived"] / d["total"] * 100, 1)
                                if d["total"] else 0,
        }
        for fn, d in facility_map.items()
    ]
    by_facility.sort(key=lambda x: x["total"], reverse=True)

    chw_map = {}
    for r in refs:
        if r.chw_id not in chw_map:
            chw_map[r.chw_id] = {"total": 0, "arrived": 0}
        chw_map[r.chw_id]["total"] += 1
        if r.status == "PATIENT_ARRIVED":
            chw_map[r.chw_id]["arrived"] += 1

    by_chw = []
    for chw_id, d in chw_map.items():
        chw = db.query(User).filter(User.id == chw_id).first()
        by_chw.append({
            "chw_name":       chw.full_name if chw else f"CHW #{chw_id}",
            "total":          d["total"],
            "arrived":        d["arrived"],
            "completion_rate": round(d["arrived"] / d["total"] * 100, 1)
                               if d["total"] else 0,
        })
    by_chw.sort(key=lambda x: x["total"], reverse=True)

    arrived = by_status.get("PATIENT_ARRIVED", 0)

    return {
        "total_referrals":       total,
        "sent":                  by_status.get("SENT", 0),
        "received":              by_status.get("RECEIVED", 0),
        "patient_arrived":       arrived,
        "completion_rate":       round(arrived / total * 100, 1)
                                 if total else 0,
        "avg_hours_to_receipt":  round(sum(receipt_times) /
                                       len(receipt_times), 1)
                                if receipt_times else None,
        "avg_hours_to_arrival":  round(sum(arrival_times) /
                                       len(arrival_times), 1)
                                if arrival_times else None,
        "high_risk_referrals":   sum(1 for r in refs
                                     if r.risk_level == "high risk"),
        "by_facility":           by_facility,
        "by_chw":                by_chw,
    }


# ── MONTHLY REPORT ────────────────────────────────────────

@router.get("/report/monthly")
def monthly_report(
    year:  int = Query(...),
    month: int = Query(...),
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    from calendar import monthrange
    chw_ids     = get_district_chw_ids(db, supervisor)
    patient_ids = get_district_patient_ids(db, chw_ids)

    month_start = date(year, month, 1)
    month_end   = date(year, month, monthrange(year, month)[1])

    def in_month(col):
        return and_(func.date(col) >= month_start,
                    func.date(col) <= month_end)

    total_assessments = (db.query(Assessment)
                           .filter(Assessment.patient_id.in_(patient_ids),
                                   in_month(Assessment.created_at))
                           .count())

    risk_in_month = {"high risk": 0, "mid risk": 0, "low risk": 0}
    for a in (db.query(Assessment)
                .filter(Assessment.patient_id.in_(patient_ids),
                        in_month(Assessment.created_at)).all()):
        risk_in_month[a.risk_level] = risk_in_month.get(a.risk_level, 0) + 1

    total_referrals = (db.query(Referral)
                         .filter(Referral.chw_id.in_(chw_ids),
                                 in_month(Referral.created_at))
                         .count())
    arrived_refs    = (db.query(Referral)
                         .filter(Referral.chw_id.in_(chw_ids),
                                 in_month(Referral.created_at),
                                 Referral.status == "PATIENT_ARRIVED")
                         .count())

    deliveries = (db.query(Delivery)
                    .filter(Delivery.patient_id.in_(patient_ids),
                            Delivery.delivery_date >= str(month_start),
                            Delivery.delivery_date <= str(month_end))
                    .all())
    live_births = sum(1 for d in deliveries if d.pregnancy and
                      d.pregnancy.delivery_outcome == "live_birth")
    stillbirths = sum(1 for d in deliveries if d.pregnancy and
                      d.pregnancy.delivery_outcome == "stillbirth")

    delivery_ids = [d.id for d in deliveries]

    def pnc_rate(vn):
        total = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn)
                   .count())
        done  = (db.query(PostnatalScheduledVisit)
                   .filter(PostnatalScheduledVisit.delivery_id.in_(delivery_ids),
                           PostnatalScheduledVisit.visit_number == vn,
                           PostnatalScheduledVisit.status == "completed")
                   .count())
        return round(done / total * 100, 1) if total else 0

    phq2_base = db.query(MentalHealthScreening).join(
        Patient, MentalHealthScreening.patient_id == Patient.id
    ).filter(Patient.chw_id.in_(chw_ids), in_month(MentalHealthScreening.created_at))
    phq2_screens  = phq2_base.count()
    phq2_positive = phq2_base.filter(
        MentalHealthScreening.risk_level == "high").count()

    growth_alerts = (db.query(GrowthAlert)
                       .join(Patient,
                             GrowthAlert.patient_id == Patient.id)
                       .filter(Patient.chw_id.in_(chw_ids),
                               in_month(GrowthAlert.created_at))
                       .count())

    from app.database import PostnatalVisit
    bf_visits = (db.query(PostnatalVisit)
                   .filter(PostnatalVisit.delivery_id.in_(delivery_ids),
                           PostnatalVisit.breastfeeding_status.isnot(None))
                   .all())
    excl_bf   = sum(1 for v in bf_visits
                    if v.breastfeeding_status == "exclusive")
    bf_rate   = round(excl_bf / len(bf_visits) * 100, 1) if bf_visits else 0

    new_patients = (db.query(Patient)
                      .filter(Patient.chw_id.in_(chw_ids),
                              in_month(Patient.created_at))
                      .count())

    active_chws = (db.query(User)
                     .filter(User.id.in_(chw_ids),
                             User.last_active >= datetime(year, month, 1))
                     .count())

    import calendar
    month_name = calendar.month_name[month]

    return {
        "district":                     supervisor.district or "All",
        "region":                       supervisor.region,
        "year":                         year,
        "month":                        month,
        "reporting_period":             f"{month_name} {year}",
        "total_chws":                   len(chw_ids),
        "active_chws":                  active_chws,
        "total_patients_registered":    len(patient_ids),
        "new_patients_this_month":      new_patients,
        "total_assessments":            total_assessments,
        "high_risk_detected":           risk_in_month.get("high risk", 0),
        "mid_risk_detected":            risk_in_month.get("mid risk", 0),
        "low_risk_detected":            risk_in_month.get("low risk", 0),
        "total_referrals":              total_referrals,
        "referral_completion_rate":     round(arrived_refs /
                                              total_referrals * 100, 1)
                                        if total_referrals else 0,
        "total_deliveries":             len(deliveries),
        "live_births":                  live_births,
        "stillbirths":                  stillbirths,
        "pnc1_completion_rate":         pnc_rate(1),
        "pnc2_completion_rate":         pnc_rate(2),
        "pnc3_completion_rate":         pnc_rate(3),
        "phq2_screens_performed":       phq2_screens,
        "phq2_positive_count":          phq2_positive,
        "growth_alerts_generated":      growth_alerts,
        "exclusive_breastfeeding_rate": bf_rate,
        "generated_at":                 datetime.utcnow(),
    }


@router.get("/report/monthly/csv")
def monthly_report_csv(
    year:  int = Query(...),
    month: int = Query(...),
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    report = monthly_report(year, month, db, supervisor)
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Indicator", "Value"])
    for key, value in report.items():
        if key != "generated_at":
            writer.writerow([
                key.replace("_", " ").title(),
                value
            ])
    output.seek(0)
    filename = f"MamaSafe_Report_{report['district']}_{year}_{month:02d}.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# ── USER MANAGEMENT ───────────────────────────────────────

@router.get("/users")
def list_users(
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    chw_ids = get_district_chw_ids(db, supervisor)
    return db.query(User).filter(User.id.in_(chw_ids),
                                 User.role == "chw").all()


@router.post("/users")
def create_chw(
    data: UserCreate,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    existing = db.query(User).filter(User.username == data.username).first()
    if existing:
        raise HTTPException(status_code=400,
                            detail="Username already exists")
    user = User(
        username        = data.username,
        hashed_password = hash_password(data.password),
        full_name       = data.full_name,
        facility        = data.facility,
        district        = data.district or supervisor.district,
        region          = data.region or supervisor.region,
        whatsapp_number = data.whatsapp_number,
        role            = "chw",
        must_change_password = True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    log = AuditLog(user_id=supervisor.id, action="user_created",
                   target_type="user", target_id=user.id)
    db.add(log)
    db.commit()

    return {"message": "CHW account created",
            "user_id": user.id,
            "username": user.username,
            "temporary_password": data.password}


@router.patch("/users/{user_id}")
def update_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    return {"message": "User updated"}


@router.patch("/users/{user_id}/deactivate")
def deactivate_user(
    user_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    log = AuditLog(user_id=supervisor.id, action="user_deactivated",
                   target_type="user", target_id=user_id)
    db.add(log)
    db.commit()
    return {"message": f"User {user.username} deactivated"}


@router.patch("/users/{user_id}/activate")
def activate_user(
    user_id: int,
    db: Session = Depends(get_db),
    supervisor = Depends(require_medical_supervisor)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = True
    db.commit()
    return {"message": f"User {user.username} activated"}
