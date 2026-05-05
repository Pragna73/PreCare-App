from __future__ import annotations

from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models import Appointment

DOCTOR_ROSTER = [
    ("Dr. Kavya Nair", "City Women Hospital"),
    ("Dr. Meera Shah", "Apollo Prenatal Center"),
    ("Dr. Aditi Rao", "Sunrise Maternity Clinic"),
]


def schedule_nearest_doctor(
    db: Session,
    patient_name: str,
    report_id: int,
    auto_confirm: bool,
    notes: str,
) -> Appointment:
    doctor_name, hospital_name = DOCTOR_ROSTER[report_id % len(DOCTOR_ROSTER)]
    appointment_time = datetime.utcnow() + timedelta(hours=18 + (report_id % 5) * 2)

    appointment = Appointment(
        report_id=report_id,
        patient_name=patient_name,
        doctor_name=doctor_name,
        hospital_name=hospital_name,
        appointment_time=appointment_time,
        status="CONFIRMED" if auto_confirm else "PENDING_CONFIRMATION",
        notes=notes,
    )
    db.add(appointment)
    db.flush()
    return appointment
