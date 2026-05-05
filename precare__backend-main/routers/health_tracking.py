from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.schemas import HealthMetricsRequest, HealthTrackingResponse
from app.security import get_current_user
from services.health_tracking_service import get_latest_metrics, to_tracking_cards, upsert_health_metrics

router = APIRouter(prefix="/health-tracking", tags=["Health Tracking"])


@router.post("/metrics", response_model=HealthTrackingResponse)
def create_metrics(
    body: HealthMetricsRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    row = upsert_health_metrics(
        db=db,
        user_id=current_user.id,
        hemoglobin=body.hemoglobin,
        systolic_bp=body.systolic_bp,
        diastolic_bp=body.diastolic_bp,
        blood_glucose=body.blood_glucose,
        weight_kg=body.weight_kg,
    )
    return HealthTrackingResponse(cards=to_tracking_cards(row), captured_at=row.created_at)


@router.get("/summary", response_model=HealthTrackingResponse)
def get_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    row = get_latest_metrics(db=db, user_id=current_user.id)
    if not row:
        raise HTTPException(status_code=404, detail="No health metrics found")

    return HealthTrackingResponse(cards=to_tracking_cards(row), captured_at=row.created_at)
