from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.schemas import AssessmentOut
from app.database import get_db, Assessment
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["assessments"])


@router.get("/assessments", response_model=List[AssessmentOut])
def get_assessments(
    skip: int = 0, limit: int = 20,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return db.query(Assessment).order_by(
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
    return record
