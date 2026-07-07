from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas import DashboardSummary
from app.database import get_db, Assessment
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/v1", tags=["dashboard"])


@router.get("/dashboard/summary", response_model=DashboardSummary)
def get_summary(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    total = db.query(Assessment).count()
    high  = db.query(Assessment).filter(Assessment.risk_level == "high risk").count()
    mid   = db.query(Assessment).filter(Assessment.risk_level == "mid risk").count()
    low   = db.query(Assessment).filter(Assessment.risk_level == "low risk").count()

    return {
        "total_assessments": total,
        "high_risk_count":   high,
        "mid_risk_count":    mid,
        "low_risk_count":    low,
        "high_risk_pct":     round(high / total * 100, 1) if total else 0,
        "mid_risk_pct":      round(mid  / total * 100, 1) if total else 0,
        "low_risk_pct":      round(low  / total * 100, 1) if total else 0,
    }
