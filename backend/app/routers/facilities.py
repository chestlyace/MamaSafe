from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db, Facility
from app.schemas_referral import FacilityCreate, FacilityOut
from app.routers.auth import get_current_user

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
    facility = Facility(**data.dict(), suggested_by=current_user.id, approved=False)
    db.add(facility)
    db.commit()
    db.refresh(facility)
    return facility


@router.post("/facilities/{facility_id}/approve", response_model=FacilityOut)
def approve_facility(
    facility_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    facility = db.query(Facility).filter(Facility.id == facility_id).first()
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    facility.approved = True
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
