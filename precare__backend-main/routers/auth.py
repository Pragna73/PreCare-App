from __future__ import annotations

from pydantic import BaseModel
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.schemas import (
    AuthTokenResponse,
    EmergencyContactCreateRequest,
    EmergencyContactResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)
from app.security import bearer_scheme, get_current_user
from services.auth_service import (
    add_emergency_contact,
    authenticate_user,
    issue_token,
    list_emergency_contacts,
    register_user,
    revoke_token,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


class SignupRequest(BaseModel):
    email: str
    password: str
    name: str
    role: str = "PATIENT"
    phone: str | None = None
    emergency_contact: str | None = None


class SignupResponse(BaseModel):
    status: str
    user_id: str
    token: str


class LoginResponse(BaseModel):
    status: str
    token: str
    user: dict


@router.post("/signup", response_model=SignupResponse)
def signup(body: SignupRequest, db: Session = Depends(get_db)):
    user = register_user(
        db=db,
        email=body.email,
        full_name=body.name,
        password=body.password,
        role=body.role,
        mobile=body.phone,
        emergency_contact_name=body.name,
        emergency_contact_phone=body.emergency_contact,
    )
    token = issue_token(db=db, user=user)
    return SignupResponse(status="success", user_id=user.public_id or f"usr_{user.id}", token=token.token)


@router.post("/register", response_model=UserResponse)
def register(body: UserRegisterRequest, db: Session = Depends(get_db)):
    user = register_user(
        db=db,
        email=body.email,
        full_name=body.full_name,
        password=body.password,
        role=body.role,
        mobile=body.mobile,
        emergency_contact_name=body.emergency_contact_name,
        emergency_contact_phone=body.emergency_contact_phone,
    )
    return user


@router.post("/login")
def login(body: UserLoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db=db, email=body.email, password=body.password)
    token = issue_token(db=db, user=user)
    return {
        "status": "success",
        "token": token.token,
        "user": {
            "id": user.public_id or f"usr_{user.id}",
            "name": user.full_name,
            "role": user.role.lower(),
        },
    }


@router.post("/login/legacy", response_model=AuthTokenResponse)
def login_legacy(body: UserLoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db=db, email=body.email, password=body.password)
    token = issue_token(db=db, user=user)
    return AuthTokenResponse(
        access_token=token.token,
        expires_at=token.expires_at,
        user=user,
    )


@router.get("/me", response_model=UserResponse)
def me(current_user=Depends(get_current_user)):
    return current_user


@router.post("/logout")
def logout(credentials=Depends(bearer_scheme), db: Session = Depends(get_db)):
    if credentials and credentials.scheme.lower() == "bearer":
        revoke_token(db=db, token=credentials.credentials)
    return {"status": "logged_out"}


@router.post("/emergency-contacts", response_model=EmergencyContactResponse)
def create_emergency_contact(
    body: EmergencyContactCreateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return add_emergency_contact(
        db=db,
        user_id=current_user.id,
        label=body.label,
        phone_number=body.phone_number,
        relationship=body.relationship,
        is_primary=body.is_primary,
    )


@router.get("/emergency-contacts", response_model=list[EmergencyContactResponse])
def get_emergency_contacts(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_emergency_contacts(db=db, user_id=current_user.id)
