from __future__ import annotations

import json
import re
from typing import Any

from app.config import settings
from app.llm_factory import get_llm


def _extract_json(text: str) -> dict[str, Any] | None:
    candidate = text.strip()
    if candidate.startswith("```"):
        candidate = candidate.strip("`")
        candidate = candidate.replace("json", "", 1).strip()

    try:
        return json.loads(candidate)
    except Exception:
        pass

    match = re.search(r"\{[\s\S]*\}", text)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except Exception:
        return None


def _llm_json(prompt: str) -> dict[str, Any] | None:
    try:
        llm = get_llm(settings.llm_model, temperature=0, json_mode=True)
    except Exception:
        return None

    try:
        out = llm.invoke(prompt)
    except Exception:
        return None

    content = getattr(out, "content", "")
    if isinstance(content, list):
        text = " ".join(str(part.get("text", "")) for part in content if isinstance(part, dict)).strip()
    else:
        text = str(content).strip()

    return _extract_json(text)


def _normalize_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"true", "yes", "1", "accepted", "accept"}
    return bool(value)


def _normalize_risk_payload(data: dict[str, Any]) -> dict[str, Any]:
    risk = str(data.get("risk", "MODERATE")).upper()
    if risk not in {"FINE", "MODERATE", "DANGER"}:
        risk = "MODERATE"

    try:
        score = float(data.get("score", 0.5))
    except Exception:
        score = 0.5
    score = max(0.0, min(1.0, score))

    reason = str(data.get("reason", "Risk analysis generated."))
    recommendation = str(data.get("recommendation", "Follow medical guidance."))

    key_signals = data.get("key_signals", [])
    if not isinstance(key_signals, list):
        key_signals = [str(key_signals)]
    key_signals = [str(s) for s in key_signals]

    return {
        "risk": risk,
        "score": score,
        "reason": reason,
        "recommendation": recommendation,
        "key_signals": key_signals,
        "model": str(data.get("model", settings.llm_model)),
    }


def _fallback_report_validation(extracted_text: str) -> bool:
    text = extracted_text.lower().strip()
    if len(text) < 20:
        return False

    # Minimal non-dictionary fallback: require signs of both medical context and pregnancy context.
    has_pregnancy_context = bool(
        re.search(r"\b(pregnan|antenatal|prenatal|obstetric|trimester|fetal|foetal|gravida|gestation)\w*\b", text)
    )
    has_medical_context = bool(
        re.search(r"\b(report|lab|test|result|clinical|diagnosis|patient|hospital|clinic)\b", text)
        or re.search(r"\b\d{2,3}\s*/\s*\d{2,3}\b", text)
    )
    return has_pregnancy_context and has_medical_context


def is_pregnancy_medical_report(extracted_text: str) -> bool:
    prompt = (
        "You are a medical document gatekeeper for a prenatal app. "
        "Classify whether the given text is a pregnancy-related medical report. "
        "Return only JSON with keys: accepted (boolean), reason (string).\n\n"
        "Accept only if it appears to be a medical/clinical report relevant to a pregnant patient.\n"
        f"TEXT:\n{extracted_text[:8000]}"
    )
    result = _llm_json(prompt)
    if result:
        return _normalize_bool(result.get("accepted", False))
    return _fallback_report_validation(extracted_text)


def _fallback_risk_analysis(extracted_text: str) -> dict[str, Any]:
    text = extracted_text.lower()

    bp_match = re.search(r"(\d{2,3})\s*/\s*(\d{2,3})", text)
    systolic = int(bp_match.group(1)) if bp_match else None
    diastolic = int(bp_match.group(2)) if bp_match else None

    hb_match = re.search(r"(?:hemoglobin|hb)\s*[:=-]?\s*(\d+(?:\.\d+)?)", text)
    hb = float(hb_match.group(1)) if hb_match else None

    protein_present = bool(re.search(r"protein(?:uria)?\s*[:=-]?\s*(present|positive|\+\+|\+\+\+)", text))

    signals: list[str] = []
    if systolic is not None and diastolic is not None:
        signals.append(f"bp:{systolic}/{diastolic}")
    if hb is not None:
        signals.append(f"hb:{hb}")
    if protein_present:
        signals.append("proteinuria:positive")

    if (systolic is not None and systolic >= 160) or (diastolic is not None and diastolic >= 100) or protein_present:
        return {
            "risk": "DANGER",
            "score": 0.92,
            "reason": "Critical maternal indicators found in report.",
            "recommendation": "Emergency protocol should be activated immediately.",
            "key_signals": signals or ["critical_indicators_detected"],
            "model": "fallback",
        }

    if (systolic is not None and systolic >= 140) or (diastolic is not None and diastolic >= 90) or (hb is not None and hb < 10.5):
        return {
            "risk": "MODERATE",
            "score": 0.64,
            "reason": "Moderate-risk maternal indicators found.",
            "recommendation": "Schedule nearest prenatal consultation and monitor vitals.",
            "key_signals": signals or ["moderate_indicators_detected"],
            "model": "fallback",
        }

    return {
        "risk": "FINE",
        "score": 0.2,
        "reason": "No major maternal risk indicators were detected.",
        "recommendation": "Continue routine prenatal care and regular checkups.",
        "key_signals": signals or ["no_critical_signals_detected"],
        "model": "fallback",
    }


def analyze_risk(extracted_text: str) -> dict[str, Any]:
    prompt = (
        "You are an autonomous obstetric triage reasoning agent. "
        "Analyze this pregnancy medical report text and return strict JSON with keys: "
        "risk (FINE|MODERATE|DANGER), score (0-1), reason, recommendation, key_signals (array). "
        "Use clinical reasoning, especially BP, proteinuria, bleeding, severe symptoms, hemoglobin, glucose.\n\n"
        f"REPORT TEXT:\n{extracted_text[:12000]}"
    )
    result = _llm_json(prompt)
    if result:
        result["model"] = settings.llm_model
        return _normalize_risk_payload(result)
    return _fallback_risk_analysis(extracted_text)
