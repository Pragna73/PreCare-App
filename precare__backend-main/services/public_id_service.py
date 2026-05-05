from __future__ import annotations

from fastapi import HTTPException


def _parse(prefix: str, value: str, field_name: str) -> int:
    if not value.startswith(prefix):
        raise HTTPException(status_code=400, detail=f"Invalid {field_name} format")
    try:
        return int(value.split("_", 1)[1])
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid {field_name} format") from exc


def user_public_id(user_id: int) -> str:
    return f"usr_{user_id}"


def report_public_id(report_id: int) -> str:
    return f"rep_{report_id}"


def appointment_public_id(appointment_id: int) -> str:
    return f"apt_{appointment_id}"


def emergency_public_id(emergency_id: int) -> str:
    return f"emg_{emergency_id}"


def twin_public_id(twin_id: int) -> str:
    return f"twin_{twin_id}"


def parse_user_id(value: str) -> int:
    return _parse("usr_", value, "user_id")


def parse_report_id(value: str) -> int:
    return _parse("rep_", value, "report_id")


def parse_twin_id(value: str) -> int:
    return _parse("twin_", value, "twin_id")
