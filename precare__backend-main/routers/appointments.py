from __future__ import annotations

from datetime import datetime, timedelta

from pydantic import BaseModel
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Appointment
from app.security import assert_user_scope, get_current_user
from services.auth_service import get_user_by_public_id
from services.public_id_service import appointment_public_id

router = APIRouter(prefix="/appointments", tags=["Appointments"])


class BookRequest(BaseModel):
    user_id: str
    preferred_date: str


class AutoBookRequest(BaseModel):
    user_id: str
    location: str


@router.post("/book")
def book_appointment(
    body: BookRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    user = get_user_by_public_id(db, body.user_id)
    assert_user_scope(current_user, user.id)

    appt_time = datetime.utcnow() + timedelta(days=1)
    appointment = Appointment(
        user_id=user.id,
        patient_name=user.full_name,
        doctor_name="Dr. Sharma",
        hospital_name="Apollo Clinic",
        appointment_time=appt_time,
        status="BOOKED",
        notes=f"Preferred date: {body.preferred_date}",
    )
    db.add(appointment)
    db.flush()
    appointment.public_id = appointment_public_id(appointment.id)
    db.commit()

    return {
        "status": "booked",
        "doctor": appointment.doctor_name,
        "hospital": appointment.hospital_name,
        "time": "10:30 AM",
    }


@router.post("/auto-book")
def auto_book_appointment(
    body: AutoBookRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    user = get_user_by_public_id(db, body.user_id)
    assert_user_scope(current_user, user.id)

    appt_time = datetime.utcnow() + timedelta(hours=2)
    appointment = Appointment(
        user_id=user.id,
        patient_name=user.full_name,
        doctor_name="Dr. Meena",
        hospital_name="Cloudnine Hospital",
        appointment_time=appt_time,
        status="SCHEDULED",
        notes=f"Auto-booked near {body.location}",
    )
    db.add(appointment)
    db.flush()
    appointment.public_id = appointment_public_id(appointment.id)
    db.commit()

    return {
        "status": "scheduled",
        "doctor": appointment.doctor_name,
        "hospital": appointment.hospital_name,
        "time": "Within 2 hours",
    }
