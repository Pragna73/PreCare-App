from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import AuthToken, EmergencyContact, User

TOKEN_TTL_HOURS = 24
ALLOWED_ROLES = {"PATIENT", "DOCTOR", "EMERGENCY", "HEALTHCARE_STAFF", "ADMIN"}


def _hash_password(password: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{password}".encode("utf-8")).hexdigest()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    return f"{salt}${_hash_password(password, salt)}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt, digest = stored_hash.split("$", 1)
    except ValueError:
        return False
    return secrets.compare_digest(_hash_password(password, salt), digest)


def user_public_id(user_id: int) -> str:
    return f"usr_{user_id}"


def parse_user_public_id(public_id: str) -> int:
    if not public_id.startswith("usr_"):
        raise HTTPException(status_code=400, detail="Invalid user_id format")
    try:
        return int(public_id.split("_", 1)[1])
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid user_id format") from exc


def get_user_by_public_id(db: Session, public_id: str) -> User:
    row = db.query(User).filter(User.public_id == public_id).first()
    if row:
        return row
    # Backward compatibility when public_id wasn't populated
    user_id = parse_user_public_id(public_id)
    row = db.query(User).filter(User.id == user_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
    row.public_id = user_public_id(row.id)
    db.commit()
    db.refresh(row)
    return row


def register_user(
    db: Session,
    email: str,
    full_name: str,
    password: str,
    role: str = "PATIENT",
    mobile: str | None = None,
    emergency_contact_name: str | None = None,
    emergency_contact_phone: str | None = None,
) -> User:
    existing = db.query(User).filter(User.email == email.lower()).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    normalized_role = role.upper()
    if normalized_role not in ALLOWED_ROLES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid role")

    user = User(
        email=email.lower(),
        full_name=full_name,
        password_hash=hash_password(password),
        role=normalized_role,
        mobile=mobile,
        emergency_contact_name=emergency_contact_name,
        emergency_contact_phone=emergency_contact_phone,
        is_active=True,
    )
    db.add(user)
    db.flush()

    user.public_id = user_public_id(user.id)

    if emergency_contact_phone:
        contact = EmergencyContact(
            user_id=user.id,
            label="Primary Contact",
            phone_number=emergency_contact_phone,
            relationship=emergency_contact_name,
            is_primary=True,
        )
        db.add(contact)

    db.commit()
    db.refresh(user)
    return user


def add_emergency_contact(
    db: Session,
    user_id: int,
    label: str,
    phone_number: str,
    relationship: str | None,
    is_primary: bool,
) -> EmergencyContact:
    if is_primary:
        (
            db.query(EmergencyContact)
            .filter(EmergencyContact.user_id == user_id)
            .update({"is_primary": False})
        )

    contact = EmergencyContact(
        user_id=user_id,
        label=label,
        phone_number=phone_number,
        relationship=relationship,
        is_primary=is_primary,
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


def list_emergency_contacts(db: Session, user_id: int) -> list[EmergencyContact]:
    return (
        db.query(EmergencyContact)
        .filter(EmergencyContact.user_id == user_id)
        .order_by(EmergencyContact.is_primary.desc(), EmergencyContact.created_at.desc())
        .all()
    )


def authenticate_user(db: Session, email: str, password: str) -> User:
    user = db.query(User).filter(User.email == email.lower()).first()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User is inactive")
    if not user.public_id:
        user.public_id = user_public_id(user.id)
        db.commit()
        db.refresh(user)
    return user


def issue_token(db: Session, user: User) -> AuthToken:
    token = secrets.token_urlsafe(48)
    expires_at = datetime.utcnow() + timedelta(hours=TOKEN_TTL_HOURS)

    auth_token = AuthToken(
        user_id=user.id,
        token=token,
        expires_at=expires_at,
        is_revoked=False,
    )
    db.add(auth_token)
    db.commit()
    db.refresh(auth_token)
    return auth_token


def revoke_token(db: Session, token: str) -> None:
    row = db.query(AuthToken).filter(AuthToken.token == token).first()
    if row:
        row.is_revoked = True
        db.commit()


def get_user_from_token(db: Session, token: str) -> User:
    row = (
        db.query(AuthToken)
        .filter(AuthToken.token == token, AuthToken.is_revoked.is_(False))
        .first()
    )
    if not row or row.expires_at < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    user = db.query(User).filter(User.id == row.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token user")
    if not user.public_id:
        user.public_id = user_public_id(user.id)
        db.commit()
        db.refresh(user)
    return user
