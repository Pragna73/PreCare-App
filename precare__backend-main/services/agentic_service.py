from __future__ import annotations

import json
from typing import Any, TypedDict

from langgraph.graph import END, StateGraph
from sqlalchemy.orm import Session

from app.models import AgentActionLog, Appointment, Report
from services.ai_service import analyze_risk, is_pregnancy_medical_report
from services.appointment_service import schedule_nearest_doctor
from services.digital_twin_service import update_digital_twin
from services.emergency_service import trigger_emergency

REPORT_REJECTION_MESSAGE = (
    "No, this report is not accepted. Please provide only the medical reports of the pregnant woman."
)


class AgentState(TypedDict, total=False):
    db: Session
    patient_name: str
    filename: str
    extracted_text: str
    report: Report
    risk: dict[str, Any]
    planned_actions: list[dict[str, Any]]
    executed_actions: list[dict[str, Any]]
    requires_confirmation: bool
    confirmation_status: str


class ConfirmState(TypedDict, total=False):
    db: Session
    report: Report
    confirm: bool
    executed_actions: list[dict[str, Any]]


def _log(db: Session, report_id: int | None, phase: str, decision: str, details: dict[str, Any]) -> None:
    db.add(
        AgentActionLog(
            report_id=report_id,
            phase=phase,
            decision=decision,
            details=json.dumps(details),
        )
    )


def _plan_actions(risk: str) -> tuple[list[dict[str, Any]], bool, str]:
    risk = risk.upper()

    if risk == "FINE":
        return (
            [
                {
                    "action": "ASK_ROUTINE_APPOINTMENT",
                    "status": "WAITING_USER",
                    "payload": {
                        "message": "Do you want to book a routine prenatal appointment?",
                    },
                }
            ],
            True,
            "PENDING_USER",
        )

    if risk == "MODERATE":
        return (
            [
                {
                    "action": "AUTO_BOOK_NEAREST_DOCTOR",
                    "status": "PENDING_CONFIRMATION",
                    "payload": {
                        "message": "Nearest available doctor appointment is provisionally booked.",
                    },
                }
            ],
            True,
            "PENDING_USER",
        )

    return (
        [
            {
                "action": "TRIGGER_EMERGENCY_PROTOCOL",
                "status": "EXECUTING",
                "payload": {
                    "ambulance": True,
                    "doctor_alert": True,
                    "family_alert": True,
                },
            }
        ],
        False,
        "AUTO_EXECUTED",
    )


def _validate_report_node(state: AgentState) -> AgentState:
    db = state["db"]
    text = state["extracted_text"]
    accepted = is_pregnancy_medical_report(text)
    _log(db, None, "VALIDATION", "REPORT_VALIDATION", {"accepted": accepted})
    if not accepted:
        raise ValueError(REPORT_REJECTION_MESSAGE)
    return {}


def _perception_node(state: AgentState) -> AgentState:
    db = state["db"]
    extracted = state["extracted_text"]
    _log(db, None, "PERCEPTION", "TEXT_EXTRACTED", {"chars": len(extracted)})
    return {}


def _reasoning_node(state: AgentState) -> AgentState:
    db = state["db"]
    risk = analyze_risk(state["extracted_text"])
    _log(db, None, "REASONING", "RISK_CLASSIFIED", risk)
    return {"risk": risk}


def _planning_node(state: AgentState) -> AgentState:
    db = state["db"]
    plan, requires_confirmation, confirmation_status = _plan_actions(state["risk"]["risk"])
    _log(db, None, "PLANNING", "PLAN_READY", {"plan": plan})
    return {
        "planned_actions": plan,
        "requires_confirmation": requires_confirmation,
        "confirmation_status": confirmation_status,
    }


def _persist_report_node(state: AgentState) -> AgentState:
    db = state["db"]
    risk = state["risk"]
    plan = state["planned_actions"]

    report = Report(
        patient_name=state["patient_name"],
        filename=state["filename"],
        extracted_text=state["extracted_text"],
        risk_level=risk["risk"],
        risk_score=float(risk["score"]),
        ai_analysis=risk["reason"],
        recommendation=risk["recommendation"],
        auto_actions=json.dumps(plan),
        requires_confirmation=bool(state["requires_confirmation"]),
        confirmation_status=str(state["confirmation_status"]),
    )
    db.add(report)
    db.flush()
    _log(db, report.id, "PLANNING", "REPORT_CREATED", {"report_id": report.id})
    return {"report": report}


def _route_after_persist(state: AgentState) -> str:
    risk = state["risk"]["risk"].upper()
    if risk in {"MODERATE", "DANGER"}:
        return "acting"
    return "feedback"


def _acting_node(state: AgentState) -> AgentState:
    db = state["db"]
    report = state["report"]
    risk = state["risk"]
    executed: list[dict[str, Any]] = []

    if risk["risk"] == "MODERATE":
        appointment = schedule_nearest_doctor(
            db=db,
            patient_name=state["patient_name"],
            report_id=report.id,
            auto_confirm=False,
            notes="Auto-scheduled due to moderate indicators. Awaiting patient confirmation.",
        )
        action = {
            "action": "AUTO_BOOK_NEAREST_DOCTOR",
            "status": "PENDING_CONFIRMATION",
            "payload": {
                "appointment_id": appointment.id,
                "doctor": appointment.doctor_name,
                "hospital": appointment.hospital_name,
                "appointment_time": appointment.appointment_time.isoformat(),
            },
        }
        executed.append(action)
        _log(db, report.id, "ACTING", "APPOINTMENT_PROVISIONED", action)

    if risk["risk"] == "DANGER":
        severity = "CRITICAL" if float(risk["score"]) >= 0.9 else "SEVERE"
        emergency = trigger_emergency(
            db=db,
            report_id=report.id,
            severity=severity,
            notes="Emergency triggered by autonomous maternal risk assessment.",
        )
        action = {
            "action": "TRIGGER_EMERGENCY_PROTOCOL",
            "status": "DONE",
            "payload": {
                "emergency_id": emergency.id,
                "ambulance": emergency.ambulance_status,
                "doctor_alerted": emergency.doctor_alerted,
                "family_alerted": emergency.family_alerted,
            },
        }
        executed.append(action)
        _log(db, report.id, "ACTING", "EMERGENCY_TRIGGERED", action)

    if executed:
        report.auto_actions = json.dumps(executed)

    return {"executed_actions": executed}


def _feedback_node(state: AgentState) -> AgentState:
    db = state["db"]
    report = state["report"]
    risk = state["risk"]

    twin = update_digital_twin(
        db=db,
        report_id=report.id,
        patient_name=state["patient_name"],
        risk_level=risk["risk"],
        key_signals=risk.get("key_signals", []),
    )

    _log(
        db,
        report.id,
        "FEEDBACK",
        "DIGITAL_TWIN_UPDATED",
        {
            "snapshot_id": twin.id,
            "risk_trend_score": twin.risk_trend_score,
            "predicted_outlook": twin.predicted_outlook,
        },
    )
    return {}


def _finalize_node(state: AgentState) -> AgentState:
    db = state["db"]
    report = state["report"]
    db.commit()
    db.refresh(report)
    return {}


def _build_pipeline_graph():
    graph = StateGraph(AgentState)
    graph.add_node("validate", _validate_report_node)
    graph.add_node("perception", _perception_node)
    graph.add_node("reasoning", _reasoning_node)
    graph.add_node("planning", _planning_node)
    graph.add_node("persist", _persist_report_node)
    graph.add_node("acting", _acting_node)
    graph.add_node("feedback", _feedback_node)
    graph.add_node("finalize", _finalize_node)

    graph.set_entry_point("validate")
    graph.add_edge("validate", "perception")
    graph.add_edge("perception", "reasoning")
    graph.add_edge("reasoning", "planning")
    graph.add_edge("planning", "persist")
    graph.add_conditional_edges(
        "persist",
        _route_after_persist,
        {
            "acting": "acting",
            "feedback": "feedback",
        },
    )
    graph.add_edge("acting", "feedback")
    graph.add_edge("feedback", "finalize")
    graph.add_edge("finalize", END)

    return graph.compile()


def run_agentic_pipeline(
    db: Session,
    patient_name: str,
    filename: str,
    extracted_text: str,
) -> tuple[Report, dict[str, Any]]:
    app = _build_pipeline_graph()
    final = app.invoke(
        {
            "db": db,
            "patient_name": patient_name,
            "filename": filename,
            "extracted_text": extracted_text,
        }
    )

    report = final["report"]
    risk = final["risk"]
    executed = final.get("executed_actions") or []
    planned = final.get("planned_actions") or []

    return report, {
        "risk": risk,
        "plan": executed if executed else planned,
        "requires_confirmation": report.requires_confirmation,
        "confirmation_status": report.confirmation_status,
    }


def _confirm_decision_node(state: ConfirmState) -> ConfirmState:
    db = state["db"]
    report = state["report"]
    confirm = bool(state["confirm"])
    executed: list[dict[str, Any]] = []

    if report.risk_level == "FINE":
        if confirm:
            appointment = schedule_nearest_doctor(
                db=db,
                patient_name=report.patient_name,
                report_id=report.id,
                auto_confirm=True,
                notes="Routine appointment requested by patient confirmation.",
            )
            executed.append(
                {
                    "action": "BOOK_ROUTINE_APPOINTMENT",
                    "status": "DONE",
                    "payload": {
                        "appointment_id": appointment.id,
                        "doctor": appointment.doctor_name,
                        "hospital": appointment.hospital_name,
                        "appointment_time": appointment.appointment_time.isoformat(),
                    },
                }
            )
        report.confirmation_status = "CONFIRMED" if confirm else "DECLINED"

    elif report.risk_level == "MODERATE":
        appt = (
            db.query(Appointment)
            .filter(Appointment.report_id == report.id)
            .order_by(Appointment.created_at.desc())
            .first()
        )
        if appt:
            appt.status = "CONFIRMED" if confirm else "CANCELLED"
            executed.append(
                {
                    "action": "AUTO_BOOK_NEAREST_DOCTOR",
                    "status": appt.status,
                    "payload": {
                        "appointment_id": appt.id,
                        "doctor": appt.doctor_name,
                        "hospital": appt.hospital_name,
                        "appointment_time": appt.appointment_time.isoformat(),
                    },
                }
            )
        report.confirmation_status = "CONFIRMED" if confirm else "DECLINED"

    if executed:
        report.auto_actions = json.dumps(executed)

    _log(
        db,
        report.id,
        "FEEDBACK",
        "USER_CONFIRMATION_RECEIVED",
        {"confirm": confirm, "actions": executed},
    )
    return {"executed_actions": executed}


def _confirm_finalize_node(state: ConfirmState) -> ConfirmState:
    db = state["db"]
    report = state["report"]
    db.commit()
    db.refresh(report)
    return {}


def _build_confirm_graph():
    graph = StateGraph(ConfirmState)
    graph.add_node("decide", _confirm_decision_node)
    graph.add_node("finalize", _confirm_finalize_node)

    graph.set_entry_point("decide")
    graph.add_edge("decide", "finalize")
    graph.add_edge("finalize", END)

    return graph.compile()


def confirm_pending_actions(db: Session, report: Report, confirm: bool) -> list[dict[str, Any]]:
    app = _build_confirm_graph()
    final = app.invoke({"db": db, "report": report, "confirm": confirm})
    return final.get("executed_actions") or []
