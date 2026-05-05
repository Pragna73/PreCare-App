from __future__ import annotations

from sqlalchemy.orm import Session

from app.models import HealthMetricEntry


def upsert_health_metrics(
    db: Session,
    user_id: int,
    hemoglobin: float,
    systolic_bp: int,
    diastolic_bp: int,
    blood_glucose: float,
    weight_kg: float,
) -> HealthMetricEntry:
    row = HealthMetricEntry(
        user_id=user_id,
        hemoglobin=hemoglobin,
        systolic_bp=systolic_bp,
        diastolic_bp=diastolic_bp,
        blood_glucose=blood_glucose,
        weight_kg=weight_kg,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def get_latest_metrics(db: Session, user_id: int) -> HealthMetricEntry | None:
    return (
        db.query(HealthMetricEntry)
        .filter(HealthMetricEntry.user_id == user_id)
        .order_by(HealthMetricEntry.created_at.desc())
        .first()
    )


def _status(metric: str, value: float | int, extra: float | int | None = None) -> str:
    if metric == "hemoglobin":
        if value < 11.0:
            return "Low"
        if value > 15.0:
            return "High"
        return "Normal"

    if metric == "blood_pressure" and extra is not None:
        if value >= 140 or extra >= 90:
            return "High"
        if value < 90 or extra < 60:
            return "Low"
        return "Normal"

    if metric == "blood_glucose":
        if value >= 140:
            return "High"
        if value < 70:
            return "Low"
        return "Normal"

    if metric == "weight":
        if value < 45:
            return "Low"
        if value > 95:
            return "High"
        return "Normal"

    return "Normal"


def to_tracking_cards(row: HealthMetricEntry) -> list[dict[str, str]]:
    return [
        {
            "title": "Hemoglobin",
            "value": f"{row.hemoglobin:.1f} g/dL",
            "status": _status("hemoglobin", row.hemoglobin),
        },
        {
            "title": "Blood Pressure",
            "value": f"{row.systolic_bp}/{row.diastolic_bp} mmHg",
            "status": _status("blood_pressure", row.systolic_bp, row.diastolic_bp),
        },
        {
            "title": "Blood Glucose",
            "value": f"{row.blood_glucose:.0f} mg/dL",
            "status": _status("blood_glucose", row.blood_glucose),
        },
        {
            "title": "Weight",
            "value": f"{row.weight_kg:.1f} kg",
            "status": _status("weight", row.weight_kg),
        },
    ]
