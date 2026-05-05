from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import EmergencyLog


def trigger_emergency(
    db: Session,
    report_id: int,
    severity: str,
    notes: str,
) -> EmergencyLog:
    severity = severity.upper()
    ambulance_required = severity in {"CRITICAL", "SEVERE"}

    emergency = EmergencyLog(
        report_id=report_id,
        severity=severity,
        ambulance_status="TRIGGERED" if ambulance_required else "STANDBY",
        doctor_alerted=True,
        family_alerted=True,
        status="OPEN",
        notes=notes,
    )
    db.add(emergency)
    db.flush()
    return emergency
