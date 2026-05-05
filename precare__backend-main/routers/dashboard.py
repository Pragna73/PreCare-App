from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Appointment, EmergencyLog, Report, User
from app.schemas import DashboardResponse
from app.security import assert_user_scope, get_current_user, require_roles
from services.public_id_service import parse_user_id

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/", response_model=DashboardResponse)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    last_report = (
        db.query(Report)
        .filter(Report.user_id == current_user.id)
        .order_by(Report.created_at.desc())
        .first()
    )

    upcoming_appointments = (
        db.query(Appointment)
        .filter(Appointment.user_id == current_user.id, Appointment.status.in_(["PENDING_CONFIRMATION", "CONFIRMED", "BOOKED", "SCHEDULED"]))
        .order_by(Appointment.appointment_time.asc())
        .limit(10)
        .all()
    )

    emergency = (
        db.query(EmergencyLog)
        .filter(EmergencyLog.user_id == current_user.id, EmergencyLog.status == "OPEN")
        .order_by(EmergencyLog.triggered_at.desc())
        .first()
    )

    total_reports = db.query(Report).filter(Report.user_id == current_user.id).count()
    danger_reports = db.query(Report).filter(Report.user_id == current_user.id, Report.risk_level == "DANGER").count()
    moderate_reports = db.query(Report).filter(Report.user_id == current_user.id, Report.risk_level == "MODERATE").count()

    ai_health_status = {
        "total_reports": total_reports,
        "danger_reports": danger_reports,
        "moderate_reports": moderate_reports,
        "latest_risk_level": last_report.risk_level if last_report else "N/A",
        "system_state": "ALERT" if emergency else "NORMAL",
    }

    return DashboardResponse(
        last_uploaded_report=last_report,
        ai_health_status=ai_health_status,
        upcoming_appointments=upcoming_appointments,
        emergency_status=emergency,
    )


@router.get("/{user_id}")
def user_dashboard(
    user_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("PATIENT", "DOCTOR", "EMERGENCY", "HEALTHCARE_STAFF", "ADMIN")),
):
    uid = parse_user_id(user_id)
    user = db.query(User).filter(User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    assert_user_scope(current_user, user.id)

    last_report = (
        db.query(Report)
        .filter(Report.user_id == user.id)
        .order_by(Report.created_at.desc())
        .first()
    )
    next_appointment = (
        db.query(Appointment)
        .filter(Appointment.user_id == user.id, Appointment.status.in_(["BOOKED", "SCHEDULED", "CONFIRMED", "PENDING_CONFIRMATION"]))
        .order_by(Appointment.appointment_time.asc())
        .first()
    )
    emergency = (
        db.query(EmergencyLog)
        .filter(EmergencyLog.user_id == user.id, EmergencyLog.status == "OPEN")
        .order_by(EmergencyLog.triggered_at.desc())
        .first()
    )

    health_status = "Stable"
    if last_report and last_report.risk_level == "DANGER":
        health_status = "Critical"
    elif last_report and last_report.risk_level == "MODERATE":
        health_status = "Warning"

    return {
        "last_report": {
            "id": last_report.public_id if last_report else None,
            "risk": last_report.risk_level if last_report else "N/A",
        },
        "health_status": health_status,
        "next_appointment": (
            {
                "doctor": next_appointment.doctor_name,
                "hospital": next_appointment.hospital_name,
                "status": next_appointment.status,
            }
            if next_appointment
            else None
        ),
        "emergency_status": "Ambulance on the way" if emergency else "No active emergency",
    }
