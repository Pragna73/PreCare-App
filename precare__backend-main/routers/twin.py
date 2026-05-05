from __future__ import annotations

import json

from pydantic import BaseModel
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import DigitalTwin
from app.security import assert_user_scope, get_current_user
from services.auth_service import get_user_by_public_id
from services.public_id_service import twin_public_id

router = APIRouter(prefix="/twin", tags=["Digital Twin"])


class TwinCreateRequest(BaseModel):
    user_id: str
    age: int
    bp_history: list[str]
    hemoglobin: float
    diabetes: bool


@router.post("/create")
def create_twin(
    body: TwinCreateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    user = get_user_by_public_id(db, body.user_id)
    assert_user_scope(current_user, user.id)

    high_bp = any(("160/" in bp or "170/" in bp or "180/" in bp) for bp in body.bp_history)
    if high_bp or body.hemoglobin < 10:
        risk_prediction = "High chance of preeclampsia"
        future_alert = "BP likely to worsen in 7 days"
    else:
        risk_prediction = "Moderate risk profile"
        future_alert = "Continue regular monitoring over next 7 days"

    twin = DigitalTwin(
        user_id=user.id,
        model_state=json.dumps(
            {
                "age": body.age,
                "bp_history": body.bp_history,
                "hemoglobin": body.hemoglobin,
                "diabetes": body.diabetes,
            }
        ),
        risk_prediction=risk_prediction,
        future_alert=future_alert,
    )
    db.add(twin)
    db.flush()
    twin.public_id = twin_public_id(twin.id)
    db.commit()

    return {
        "twin_id": twin.public_id,
        "risk_prediction": risk_prediction,
        "future_alert": future_alert,
    }
