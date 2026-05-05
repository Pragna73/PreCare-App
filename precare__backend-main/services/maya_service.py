from __future__ import annotations

from datetime import datetime, timedelta

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from sqlalchemy.orm import Session

from app.config import settings
from app.llm_factory import get_llm
from app.models import HealthMetricEntry, MayaMessage, Report

NON_HEALTH_REPLY = (
    "I don't know the answer for you provided. I only assisted you through the health related questions."
)


def _fallback_reply(user_message: str, latest_risk: str | None) -> str:
    text = user_message.lower()

    if any(k in text for k in ["heavy bleeding", "severe pain", "faint", "unconscious", "chest pain"]):
        return "This sounds serious. Please seek emergency medical care immediately. I can trigger emergency support if you want."

    if any(k in text for k in ["bleeding", "headache", "pain", "fever", "vomit", "dizziness"]):
        return "If symptoms are severe or worsening, please seek emergency care now. I can help you start emergency flow."

    if "appointment" in text or "doctor" in text:
        return "I can help book a doctor appointment. Upload your latest report and confirm the suggested action."

    if latest_risk == "DANGER":
        return "Your latest report indicates high risk. Please follow emergency instructions and stay with a caregiver."

    if latest_risk == "MODERATE":
        return "Your recent report shows warning signs. Please keep your vitals updated and confirm your nearest doctor appointment."

    return "Tell me your symptoms or upload your report and I’ll guide you on the next step."


def _llm_reply(
    db: Session,
    user_id: int,
    user_message: str,
    latest_risk: str | None,
) -> str | None:
    try:
        llm = get_llm(settings.llm_model, temperature=0.3)
    except Exception:
        return None

    recent_messages = (
        db.query(MayaMessage)
        .filter(MayaMessage.user_id == user_id)
        .order_by(MayaMessage.created_at.desc())
        .limit(10)
        .all()
    )
    recent_messages.reverse()

    latest_metrics = (
        db.query(HealthMetricEntry)
        .filter(HealthMetricEntry.user_id == user_id)
        .order_by(HealthMetricEntry.created_at.desc())
        .first()
    )

    metrics_context = "No recent vitals uploaded."
    if latest_metrics:
        metrics_context = (
            f"Hemoglobin: {latest_metrics.hemoglobin:.1f} g/dL, "
            f"BP: {latest_metrics.systolic_bp}/{latest_metrics.diastolic_bp} mmHg, "
            f"Glucose: {latest_metrics.blood_glucose:.0f} mg/dL, "
            f"Weight: {latest_metrics.weight_kg:.1f} kg"
        )

    system_prompt = f"""
You are Maya, a caring pregnancy health assistant.

Rules:
- Only answer pregnancy and health related topics.
- If user asks non-health topics, reply exactly:
  "{NON_HEALTH_REPLY}"
- Never provide medical diagnosis.
- If symptoms are severe (heavy bleeding, fainting, severe pain, high fever), advise emergency care immediately.
- Be empathetic, concise, and action-oriented.
- Suggest next steps (upload report, book appointment, emergency) when helpful.

Context:
Latest risk: {latest_risk or 'N/A'}
Latest vitals: {metrics_context}
"""

    messages = [SystemMessage(content=system_prompt)]

    for item in recent_messages:
        if item.role == "assistant":
            messages.append(AIMessage(content=item.content))
        else:
            messages.append(HumanMessage(content=item.content))

    messages.append(HumanMessage(content=user_message))

    try:
        out = llm.invoke(messages)
    except Exception:
        return None

    reply = out.content if hasattr(out, "content") else str(out)
    return reply.strip() if reply else None


def chat_with_maya(db: Session, user_id: int, message: str) -> dict:
    # 🔐 Safe query (works with or without user_id column)
    query = db.query(Report).order_by(Report.created_at.desc())

    if hasattr(Report, "user_id"):
        query = query.filter(Report.user_id == user_id)

    last_report = query.first()
    latest_risk = last_report.risk_level if last_report else None

    user_row = MayaMessage(user_id=user_id, role="user", content=message)
    db.add(user_row)
    db.flush()

    reply = _llm_reply(
        db=db,
        user_id=user_id,
        user_message=message,
        latest_risk=latest_risk,
    ) or _fallback_reply(message, latest_risk)

    bot_row = MayaMessage(user_id=user_id, role="assistant", content=reply)
    db.add(bot_row)
    db.commit()

    return {
        "reply": reply,
        "latest_risk": latest_risk or "N/A",
    }


def get_chat_history(db: Session, user_id: int, limit: int = 30) -> list[MayaMessage]:
    return (
        db.query(MayaMessage)
        .filter(MayaMessage.user_id == user_id)
        .order_by(MayaMessage.created_at.asc())
        .limit(limit)
        .all()
    )


def get_grouped_chat_history(db: Session, user_id: int, limit: int = 100) -> dict[str, list[MayaMessage]]:
    rows = (
        db.query(MayaMessage)
        .filter(MayaMessage.user_id == user_id)
        .order_by(MayaMessage.created_at.asc())
        .limit(limit)
        .all()
    )

    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)

    grouped = {
        "today": [],
        "yesterday": [],
        "earlier": [],
    }

    for row in rows:
        message_date = row.created_at.date() if row.created_at else today
        if message_date == today:
            grouped["today"].append(row)
        elif message_date == yesterday:
            grouped["yesterday"].append(row)
        else:
            grouped["earlier"].append(row)

    return grouped
