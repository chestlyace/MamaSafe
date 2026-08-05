from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from app.database import get_db, User
from app.schemas import UserProfileOut, UserProfileUpdate, PasswordChange
from app.routers.auth import get_current_user, verify_password, hash_password

router = APIRouter(prefix="/api/v1/users", tags=["users"])

# Fields a user may edit about themselves, per role.
ROLE_EDITABLE_FIELDS = {
    "chw":        {"full_name", "whatsapp_number", "facility"},
    "supervisor": {"full_name", "whatsapp_number", "district", "region"},
    "admin":      {"full_name", "whatsapp_number"},
}


@router.get("/me", response_model=UserProfileOut)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.patch("/me", response_model=UserProfileOut)
def update_me(
    update: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    allowed = ROLE_EDITABLE_FIELDS.get(current_user.role, set())
    sent = update.dict(exclude_unset=True)
    for field in sent:
        if field not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"You cannot edit {field}",
            )

    for field, value in sent.items():
        setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/me/password")
def change_my_password(
    change: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(change.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    current_user.hashed_password = hash_password(change.new_password)
    current_user.must_change_password = False
    db.commit()
    return {"message": "Password updated successfully"}
