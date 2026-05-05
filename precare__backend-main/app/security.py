from __future__ import annotations

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User
from services.auth_service import get_user_from_token

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if not credentials or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")
    return get_user_from_token(db, credentials.credentials)


def require_roles(*allowed_roles: str):
    allowed = {r.upper() for r in allowed_roles}

    def _checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role.upper() not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient role privileges",
            )
        return current_user

    return _checker


def assert_user_scope(current_user: User, target_user_id: int) -> None:
    role = current_user.role.upper()
    if role in {"DOCTOR", "EMERGENCY", "HEALTHCARE_STAFF", "ADMIN"}:
        return
    if current_user.id != target_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access another user's records",
        )
