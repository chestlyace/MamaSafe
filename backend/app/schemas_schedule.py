from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ScheduledVisitOut(BaseModel):
    id:                     int
    pregnancy_id:           int
    visit_number:           int
    gestational_week:       int
    label:                  Optional[str]
    scheduled_date:         str
    original_date:          Optional[str]
    reschedule_reason:      Optional[str]
    status:                 str
    anc_visit_id:           Optional[int]
    reminder_48h_sent:      bool
    reminder_day_sent:      bool
    whatsapp_delivered_48h: bool
    whatsapp_delivered_day: bool
    notes:                  Optional[str]
    created_at:             datetime

    class Config:
        from_attributes = True


class RescheduleRequest(BaseModel):
    new_date: str   # YYYY-MM-DD
    reason:   Optional[str] = None


class CompleteVisitRequest(BaseModel):
    anc_visit_id: int
