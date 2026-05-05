from __future__ import annotations

import random

from pydantic import BaseModel
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import EmergencyLog, Report
from app.security import assert_user_scope, get_current_user, require_roles
from services.auth_service import get_user_by_public_id
from services.public_id_service import emergency_public_id

router = APIRouter(prefix="/emergency", tags=["Emergency"])


class EmergencyTriggerRequest(BaseModel):
    user_id: str
    location: str
    severity: str


@router.post("/trigger")
def trigger_emergency(
    body: EmergencyTriggerRequest,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("PATIENT", "DOCTOR", "EMERGENCY", "HEALTHCARE_STAFF", "ADMIN")),
):
    user = get_user_by_public_id(db, body.user_id)
    assert_user_scope(current_user, user.id)
    last_report = db.query(Report).filter(Report.user_id == user.id).order_by(Report.created_at.desc()).first()

    eta = random.randint(5, 12)
    emergency = EmergencyLog(
        user_id=user.id,
        report_id=last_report.id if last_report else None,
        severity=body.severity.upper(),
        ambulance_status="dispatched",
        doctor_alerted=True,
        family_alerted=True,
        eta_minutes=eta,
        status="OPEN",
        notes=f"Location: {body.location}",
    )
    db.add(emergency)
    db.flush()
    emergency.public_id = emergency_public_id(emergency.id)
    db.commit()

    return {
        "ambulance": "dispatched",
        "doctor_alerted": True,
        "family_notified": True,
        "eta_minutes": eta,
    }
