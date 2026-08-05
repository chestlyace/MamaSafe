from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db, Facility, User
from app.schemas_referral import FacilityCreate, FacilityOut
from app.routers.auth import get_current_user
from app.routers.admin import require_supervisor

router = APIRouter(prefix="/api/v1", tags=["facilities"])


@router.get("/facilities", response_model=List[FacilityOut])
def list_facilities(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role == "admin":
        return db.query(Facility).filter(Facility.is_active == True).all()
    return db.query(Facility).filter(
        Facility.is_active == True, Facility.approved == True
    ).all()


@router.post("/facilities", response_model=FacilityOut)
def suggest_facility(
    data: FacilityCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    is_approved = current_user.role in ("supervisor", "admin")
    facility = Facility(
        **data.dict(),
        suggested_by=None if is_approved else current_user.id,
        approved=is_approved,
    )
    db.add(facility)
    db.commit()
    db.refresh(facility)
    return facility


@router.get("/facilities/pending", response_model=List[FacilityOut])
def list_pending_facilities(
    db: Session = Depends(get_db),
    current_user = Depends(require_supervisor)
):
    facilities = (db.query(Facility)
                  .filter(Facility.approved == False, Facility.is_active == True)
                  .order_by(Facility.created_at.asc())
                  .all())
    ids = {f.suggested_by for f in facilities if f.suggested_by}
    name_map = dict(
        db.query(User.id, User.username).filter(User.id.in_(ids)).all()
    ) if ids else {}
    result = []
    for f in facilities:
        out = FacilityOut.model_validate(f)
        out.suggested_by_name = name_map.get(f.suggested_by)
        result.append(out)
    return result


@router.post("/facilities/{facility_id}/approve", response_model=FacilityOut)
def approve_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_supervisor)
):
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.approved = True
    db.commit()
    db.refresh(facility)
    return facility


@router.post("/facilities/{facility_id}/reject", response_model=FacilityOut)
def reject_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_supervisor)
):
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.approved = False
    facility.is_active = False
    db.commit()
    db.refresh(facility)
    return facility


@router.patch("/facilities/{facility_id}", response_model=FacilityOut)
def update_facility(
    facility_id: int,
    data: FacilityCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    for field, value in data.dict(exclude_unset=True).items():
        setattr(facility, field, value)
    db.commit()
    db.refresh(facility)
    return facility


@router.delete("/facilities/{facility_id}")
def delete_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.is_active = False
    db.commit()
    return {"detail": "Facility deleted"}
