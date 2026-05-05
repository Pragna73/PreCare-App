from __future__ import annotations

import json

from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import AgentActionLog, Appointment, EmergencyLog, Report
from app.security import assert_user_scope, get_current_user
from services.auth_service import get_user_by_public_id
from services.public_id_service import parse_report_id

router = APIRouter(prefix="/agent", tags=["Agent"])


class PlanRequest(BaseModel):
    user_id: str
    risk_level: str
    report_id: str


class ConfirmRequest(BaseModel):
    report_id: str
    action_taken: bool


@router.post("/plan")
def plan_actions(
    body: PlanRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    user = get_user_by_public_id(db, body.user_id)
    assert_user_scope(current_user, user.id)
    rid = parse_report_id(body.report_id)
    report = db.query(Report).filter(Report.id == rid).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    risk = body.risk_level.upper()
    plan: list[str]
    actions: dict[str, bool]

    if risk == "FINE":
        plan = ["Ask user for routine appointment"]
        actions = {"ambulance": False, "doctor_alert": False, "family_alert": False}
        report.requires_confirmation = True
        report.confirmation_status = "PENDING_USER"
    elif risk == "MODERATE":
        plan = ["Auto-book nearest doctor", "Request user confirmation"]
        actions = {"ambulance": False, "doctor_alert": True, "family_alert": False}
        report.requires_confirmation = True
        report.confirmation_status = "PENDING_USER"

        existing = db.query(Appointment).filter(Appointment.report_id == report.id).first()
        if not existing:
            appointment = Appointment(
                user_id=user.id,
                report_id=report.id,
                patient_name=user.full_name,
                doctor_name="Dr. Meena",
                hospital_name="Cloudnine Hospital",
                appointment_time=report.created_at,
                status="PENDING_CONFIRMATION",
                notes="Auto booked by agent planner",
            )
            db.add(appointment)
    else:
        plan = ["Call ambulance", "Notify nearest hospital", "Alert emergency contact"]
        actions = {"ambulance": True, "doctor_alert": True, "family_alert": True}
        report.requires_confirmation = False
        report.confirmation_status = "AUTO_EXECUTED"

        emergency = EmergencyLog(
            user_id=user.id,
            report_id=report.id,
            severity="HIGH",
            ambulance_status="dispatched",
            doctor_alerted=True,
            family_alerted=True,
            eta_minutes=7,
            status="OPEN",
            notes="Triggered from agent planner",
        )
        db.add(emergency)

    report.auto_actions = json.dumps(plan)
    db.add(
        AgentActionLog(
            report_id=report.id,
            phase="PLANNING",
            decision=risk,
            details=json.dumps({"plan": plan, "actions": actions}),
        )
    )
    db.commit()

    return {"plan": plan, "actions": actions}


@router.post("/confirm")
def confirm_action(
    body: ConfirmRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    rid = parse_report_id(body.report_id)
    report = db.query(Report).filter(Report.id == rid).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.user_id:
        assert_user_scope(current_user, report.user_id)

    report.confirmation_status = "CONFIRMED" if body.action_taken else "DECLINED"
    db.add(
        AgentActionLog(
            report_id=report.id,
            phase="FEEDBACK",
            decision="USER_CONFIRMATION",
            details=json.dumps({"action_taken": body.action_taken}),
        )
    )
    db.commit()

    return {"status": "confirmed", "agent_learning": "updated"}
