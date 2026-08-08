from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.schemas import AssessmentOut
from app.database import get_db, Assessment, User
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["assessments"])


def _accessible_chw_ids(db: Session, current_user) -> List[int]:
    if current_user.role == "admin":
        return [u.id for u in db.query(User.id).filter(User.role == "chw").all()]
    if current_user.role == "supervisor":
        return [current_user.id] + [u.id for u in db.query(User.id).filter(
            User.role == "chw",
            User.district == current_user.district,
        ).all()]
    return [current_user.id]


@router.get("/assessments", response_model=List[AssessmentOut])
def get_assessments(
    skip: int = 0, limit: int = 20,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
): 
    query = db.query(Assessment)
    if current_user.role != "admin":
        query = query.filter(Assessment.created_by.in_(
            _accessible_chw_ids(db, current_user)
        ))
    return query.order_by(
        Assessment.created_at.desc()
    ).offset(skip).limit(limit).all()


@router.get("/assessments/{assessment_id}", response_model=AssessmentOut)
def get_assessment(
    assessment_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    record = db.query(Assessment).filter(Assessment.id == assessment_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Assessment not found")
    if current_user.role != "admin" and record.created_by not in _accessible_chw_ids(db, current_user):
        raise HTTPException(status_code=404, detail="Assessment not found")
    return record
