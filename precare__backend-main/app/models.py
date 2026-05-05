from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text

from .db import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    public_id = Column(String, unique=True, nullable=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=False)
    mobile = Column(String, nullable=True)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False, default="PATIENT")
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    label = Column(String, nullable=False, default="Emergency")
    phone_number = Column(String, nullable=False)
    relationship = Column(String, nullable=True)
    is_primary = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class HealthMetricEntry(Base):
    __tablename__ = "health_metrics"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    hemoglobin = Column(Float, nullable=False)
    systolic_bp = Column(Integer, nullable=False)
    diastolic_bp = Column(Integer, nullable=False)
    blood_glucose = Column(Float, nullable=False)
    weight_kg = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class MayaMessage(Base):
    __tablename__ = "maya_messages"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class AuthToken(Base):
    __tablename__ = "auth_tokens"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(String, unique=True, nullable=False, index=True)
    is_revoked = Column(Boolean, nullable=False, default=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True)
    public_id = Column(String, unique=True, nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    patient_name = Column(String, nullable=False, default="Unknown")
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=True)
    file_url = Column(String, nullable=True)
    extracted_text = Column(Text, nullable=False, default="")
    structured_data = Column(Text, nullable=False, default="{}")
    risk_level = Column(String, nullable=False, default="UNKNOWN")
    risk_score = Column(Float, nullable=False, default=0.0)
    ai_analysis = Column(Text, nullable=False, default="")
    recommendation = Column(Text, nullable=False, default="")
    auto_actions = Column(Text, nullable=False, default="[]")
    requires_confirmation = Column(Boolean, nullable=False, default=False)
    confirmation_status = Column(String, nullable=False, default="NOT_REQUIRED")
    created_at = Column(DateTime, default=datetime.utcnow)


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True)
    public_id = Column(String, unique=True, nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=True)
    patient_name = Column(String, nullable=False)
    doctor_name = Column(String, nullable=False)
    hospital_name = Column(String, nullable=False)
    appointment_time = Column(DateTime, nullable=False)
    status = Column(String, nullable=False, default="PENDING")
    notes = Column(Text, nullable=False, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class EmergencyLog(Base):
    __tablename__ = "emergencies"

    id = Column(Integer, primary_key=True)
    public_id = Column(String, unique=True, nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=True)
    severity = Column(String, nullable=False)
    ambulance_status = Column(String, nullable=False, default="NOT_TRIGGERED")
    doctor_alerted = Column(Boolean, nullable=False, default=False)
    family_alerted = Column(Boolean, nullable=False, default=False)
    eta_minutes = Column(Integer, nullable=True)
    status = Column(String, nullable=False, default="OPEN")
    notes = Column(Text, nullable=False, default="")
    triggered_at = Column(DateTime, default=datetime.utcnow)


class DigitalTwinSnapshot(Base):
    __tablename__ = "digital_twin_snapshots"

    id = Column(Integer, primary_key=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=False)
    patient_name = Column(String, nullable=False)
    risk_trend_score = Column(Float, nullable=False)
    predicted_outlook = Column(String, nullable=False)
    key_signals = Column(Text, nullable=False, default="[]")
    created_at = Column(DateTime, default=datetime.utcnow)


class DigitalTwin(Base):
    __tablename__ = "digital_twins"

    id = Column(Integer, primary_key=True)
    public_id = Column(String, unique=True, nullable=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    model_state = Column(Text, nullable=False, default="{}")
    risk_prediction = Column(String, nullable=False, default="")
    future_alert = Column(String, nullable=False, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class AgentActionLog(Base):
    __tablename__ = "agent_actions"

    id = Column(Integer, primary_key=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=True)
    phase = Column(String, nullable=False)
    decision = Column(String, nullable=False)
    details = Column(Text, nullable=False, default="{}")
    created_at = Column(DateTime, default=datetime.utcnow)
