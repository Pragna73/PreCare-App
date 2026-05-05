from __future__ import annotations

import json
import re
import uuid
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, Depends
from sqlalchemy.orm import Session

from app.config import UPLOAD_DIR
from app.db import get_db
from app.models import Report
from app.security import assert_user_scope, get_current_user, require_roles
from services.ai_service import analyze_risk, is_pregnancy_medical_report
from services.auth_service import get_user_by_public_id
from services.appointment_service import schedule_nearest_doctor
from services.emergency_service import trigger_emergency
from services.ocr_service import extract_text
from services.public_id_service import parse_report_id, parse_user_id, report_public_id

router = APIRouter(prefix="/reports", tags=["Reports"])


def _parse_structured(text: str) -> dict[str, str]:
    out: dict[str, str] = {}

    bp = re.search(r"(\b\d{2,3}\s*/\s*\d{2,3}\b)", text)
    if bp:
        out["bp"] = bp.group(1).replace(" ", "")

    hemo = re.search(r"(?:hemoglobin|hb)\s*[:=-]?\s*(\d+(?:\.\d+)?)", text, re.IGNORECASE)
    if hemo:
        out["hemoglobin"] = hemo.group(1)

    protein = re.search(r"protein(?:uria)?\s*[:=-]?\s*(positive|negative|present|absent)", text, re.IGNORECASE)
    if protein:
        out["protein"] = protein.group(1).lower()

    return out


@router.post("/upload")
def upload_report(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    user = get_user_by_public_id(db, user_id)
    assert_user_scope(current_user, user.id)

    ext = Path(file.filename or "report").suffix.lower()
    if ext not in {".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".txt", ".md", ".pdf"}:
        raise HTTPException(status_code=400, detail="Unsupported file type. Use PDF/Image/TXT")

    stored_name = f"{uuid.uuid4().hex}{ext}"
    path = UPLOAD_DIR / stored_name
    with path.open("wb") as dst:
        dst.write(file.file.read())

    try:
        extracted_text = extract_text(str(path))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if not is_pregnancy_medical_report(extracted_text):
        raise HTTPException(
            status_code=400,
            detail="No, this report is not accepted. Please provide only the medical reports of the pregnant woman.",
        )

    structured = _parse_structured(extracted_text)
    risk = analyze_risk(extracted_text)
    risk_level_map = {"FINE": "GOOD", "MODERATE": "WARNING", "DANGER": "DANGER"}
    outcome_risk = risk_level_map.get(risk["risk"], "WARNING")

    report = Report(
        user_id=user.id,
        patient_name=user.full_name,
        filename=file.filename or stored_name,
        file_path=str(path),
        file_url=str(path),
        extracted_text=extracted_text,
        structured_data=json.dumps(structured),
        risk_level=outcome_risk,
        risk_score=float(risk["score"]),
        ai_analysis=risk["reason"],
        recommendation=risk["recommendation"],
    )
    db.add(report)
    db.flush()

    report.public_id = report_public_id(report.id)
    outcome: dict
    if outcome_risk == "GOOD":
        report.requires_confirmation = True
        report.confirmation_status = "PENDING_USER"
        outcome = {
            "type": "GOOD",
            "message": "Do you want to book a routine appointment?",
            "auto_actions": {"appointment_auto_booked": False, "emergency_triggered": False},
        }
    elif outcome_risk == "WARNING":
        appt = schedule_nearest_doctor(
            db=db,
            patient_name=user.full_name,
            report_id=report.id,
            auto_confirm=False,
            notes="Auto-scheduled due to warning indicators. Awaiting user confirmation.",
        )
        report.requires_confirmation = True
        report.confirmation_status = "PENDING_USER"
        outcome = {
            "type": "WARNING",
            "message": "Nearest doctor auto-scheduled. Please confirm appointment.",
            "auto_actions": {
                "appointment_auto_booked": True,
                "doctor": appt.doctor_name,
                "hospital": appt.hospital_name,
                "status": appt.status,
            },
        }
    else:
        severity = "CRITICAL" if float(risk["score"]) >= 0.9 else "SEVERE"
        emergency = trigger_emergency(
            db=db,
            report_id=report.id,
            severity=severity,
            notes="Emergency triggered automatically for danger risk.",
        )
        report.requires_confirmation = False
        report.confirmation_status = "AUTO_EXECUTED"
        outcome = {
            "type": "DANGER",
            "message": "Emergency protocol triggered immediately.",
            "auto_actions": {
                "ambulance": emergency.ambulance_status,
                "doctor_alerted": emergency.doctor_alerted,
                "family_alerted": emergency.family_alerted,
            },
        }

    report.auto_actions = json.dumps(outcome["auto_actions"])
    db.commit()

    return {
        "status": "processed",
        "report_id": report.public_id,
        "report_analysis": {
            "extracted_text": extracted_text,
            "structured_data": structured,
            "risk_level": outcome_risk,
            "confidence": float(risk["score"]),
            "reasoning": risk["reason"],
            "recommendation": risk["recommendation"],
        },
        "outcome": outcome,
    }


@router.post("/{report_id}/extract")
def extract_report(report_id: str, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    rid = parse_report_id(report_id)
    report = db.query(Report).filter(Report.id == rid).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.user_id:
        assert_user_scope(current_user, report.user_id)
    if not report.file_path:
        raise HTTPException(status_code=400, detail="File path missing for report")

    text = extract_text(report.file_path)
    structured = _parse_structured(text)

    report.extracted_text = text
    report.structured_data = json.dumps(structured)
    db.commit()

    return {
        "report_id": report.public_id or report_id,
        "extracted_text": text,
        "structured_data": structured,
    }


@router.get("/user/{user_id}")
def get_user_reports(
    user_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    uid = parse_user_id(user_id)
    assert_user_scope(current_user, uid)

    reports = (
        db.query(Report)
        .filter(Report.user_id == uid)
        .order_by(Report.created_at.desc())
        .all()
    )
    return {
        "user_id": user_id,
        "count": len(reports),
        "reports": [
            {
                "report_id": r.public_id or report_public_id(r.id),
                "filename": r.filename,
                "risk_level": r.risk_level,
                "confidence": r.risk_score,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ],
    }


@router.get("/all")
def get_all_reports(
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("DOCTOR", "EMERGENCY", "HEALTHCARE_STAFF", "ADMIN")),
):
    reports = db.query(Report).order_by(Report.created_at.desc()).all()
    return {
        "count": len(reports),
        "reports": [
            {
                "report_id": r.public_id or report_public_id(r.id),
                "user_id": f"usr_{r.user_id}" if r.user_id else None,
                "patient_name": r.patient_name,
                "risk_level": r.risk_level,
                "confidence": r.risk_score,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ],
    }


@router.get("/{report_id}")
def get_report_by_id(
    report_id: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    rid = parse_report_id(report_id)
    report = db.query(Report).filter(Report.id == rid).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.user_id:
        assert_user_scope(current_user, report.user_id)

    try:
        structured_data = json.loads(report.structured_data or "{}")
    except Exception:
        structured_data = {}

    try:
        auto_actions = json.loads(report.auto_actions or "{}")
    except Exception:
        auto_actions = {}

    return {
        "report_id": report.public_id or report_id,
        "user_id": f"usr_{report.user_id}" if report.user_id else None,
        "patient_name": report.patient_name,
        "filename": report.filename,
        "extracted_text": report.extracted_text,
        "structured_data": structured_data,
        "risk_level": report.risk_level,
        "confidence": report.risk_score,
        "reasoning": report.ai_analysis,
        "recommendation": report.recommendation,
        "auto_actions": auto_actions,
        "confirmation_status": report.confirmation_status,
        "created_at": report.created_at.isoformat() if report.created_at else None,
    }
