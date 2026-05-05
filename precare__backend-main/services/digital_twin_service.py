from __future__ import annotations

import json

from sqlalchemy.orm import Session

from app.models import DigitalTwinSnapshot, Report


RISK_SCORE_MAP = {
    "FINE": 0.2,
    "MODERATE": 0.6,
    "DANGER": 0.9,
    "URGENT": 1.0,
}


def update_digital_twin(
    db: Session,
    report_id: int,
    patient_name: str,
    risk_level: str,
    key_signals: list[str],
) -> DigitalTwinSnapshot:
    recent = (
        db.query(Report)
        .filter(Report.patient_name == patient_name)
        .order_by(Report.created_at.desc())
        .limit(6)
        .all()
    )

    historical_scores = [r.risk_score for r in recent]
    current = RISK_SCORE_MAP.get(risk_level.upper(), 0.5)
    if historical_scores:
        trend_score = (sum(historical_scores) / len(historical_scores) + current) / 2
    else:
        trend_score = current

    if trend_score < 0.35:
        outlook = "Stable pregnancy trend. Continue routine prenatal monitoring."
    elif trend_score < 0.7:
        outlook = "Moderate risk trend. Increase monitoring and follow-up frequency."
    else:
        outlook = "High risk trend. Maintain close medical supervision and emergency readiness."

    snapshot = DigitalTwinSnapshot(
        report_id=report_id,
        patient_name=patient_name,
        risk_trend_score=round(trend_score, 3),
        predicted_outlook=outlook,
        key_signals=json.dumps(key_signals),
    )
    db.add(snapshot)
    db.flush()
    return snapshot
