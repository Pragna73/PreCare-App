from __future__ import annotations

from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Report
from app.security import assert_user_scope, get_current_user
from services.ai_service import analyze_risk
from services.public_id_service import parse_report_id

router = APIRouter(prefix="/ai", tags=["AI"])


class AnalyzeRiskRequest(BaseModel):
    report_id: str
    text: str | None = None


@router.post("/analyze-risk")
def analyze_risk_endpoint(
    body: AnalyzeRiskRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    rid = parse_report_id(body.report_id)
    report = db.query(Report).filter(Report.id == rid).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.user_id:
        assert_user_scope(current_user, report.user_id)

    text = body.text or report.extracted_text
    if not text:
        raise HTTPException(status_code=400, detail="No text available for analysis")

    result = analyze_risk(text)

    report.risk_level = result["risk"]
    report.risk_score = float(result["score"])
    report.ai_analysis = result["reason"]
    report.recommendation = result["recommendation"]
    db.commit()

    return {
        "risk_level": result["risk"],
        "confidence": result["score"],
        "reasoning": result["reason"],
        "recommendation": result["recommendation"],
    }
