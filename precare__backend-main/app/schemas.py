from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class EmergencyContactCreateRequest(BaseModel):
    label: str = Field(default="Emergency")
    phone_number: str
    relationship: str | None = None
    is_primary: bool = False


class EmergencyContactResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    label: str
    phone_number: str
    relationship: str | None
    is_primary: bool
    created_at: datetime


class HealthMetricsRequest(BaseModel):
    hemoglobin: float
    systolic_bp: int
    diastolic_bp: int
    blood_glucose: float
    weight_kg: float


class HealthTrackingCard(BaseModel):
    title: str
    value: str
    status: str


class HealthTrackingResponse(BaseModel):
    cards: list[HealthTrackingCard]
    captured_at: datetime


class MayaChatRequest(BaseModel):
    message: str = Field(min_length=1)


class MayaChatResponse(BaseModel):
    reply: str
    latest_risk: str


class MayaMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role: str
    content: str
    created_at: datetime


class MayaGroupedHistoryResponse(BaseModel):
    today: list[MayaMessageResponse]
    yesterday: list[MayaMessageResponse]
    earlier: list[MayaMessageResponse]


class UserRegisterRequest(BaseModel):
    email: str
    full_name: str
    password: str = Field(min_length=8)
    role: str = Field(default="PATIENT")
    mobile: str | None = None
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None


class UserLoginRequest(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    full_name: str
    role: str
    mobile: str | None
    emergency_contact_name: str | None
    emergency_contact_phone: str | None
    is_active: bool


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    user: UserResponse


class DecisionAction(BaseModel):
    action: str
    status: str
    payload: dict[str, Any] = Field(default_factory=dict)


class RiskAssessment(BaseModel):
    risk: str
    score: float
    reason: str
    recommendation: str
    key_signals: list[str] = Field(default_factory=list)


class UploadResponse(BaseModel):
    report_id: int
    patient_name: str
    extracted_text: str
    risk: RiskAssessment
    agent_plan: list[DecisionAction]
    requires_confirmation: bool
    confirmation_status: str


class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_name: str
    filename: str
    risk_level: str
    risk_score: float
    ai_analysis: str
    recommendation: str
    auto_actions: str
    requires_confirmation: bool
    confirmation_status: str
    created_at: datetime


class AppointmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_name: str
    doctor_name: str
    hospital_name: str
    appointment_time: datetime
    status: str
    notes: str


class EmergencyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    report_id: int
    severity: str
    ambulance_status: str
    doctor_alerted: bool
    family_alerted: bool
    status: str
    notes: str
    triggered_at: datetime


class DashboardResponse(BaseModel):
    last_uploaded_report: ReportResponse | None
    ai_health_status: dict[str, Any]
    upcoming_appointments: list[AppointmentResponse]
    emergency_status: EmergencyResponse | None


class ConfirmationRequest(BaseModel):
    confirm: bool


class ConfirmationResponse(BaseModel):
    report_id: int
    confirmation_status: str
    executed_actions: list[DecisionAction]
