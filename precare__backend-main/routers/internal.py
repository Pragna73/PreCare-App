from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(prefix="/internal", tags=["Internal Services"])


@router.get("/ocr")
def internal_ocr():
    return {"service": "ocr", "status": "ok"}


@router.get("/llm/analyze")
def internal_llm_analyze():
    return {"service": "llm_reasoning", "status": "ok"}


@router.get("/hospitals/nearest")
def internal_hospitals_nearest():
    return {"service": "hospital_finder", "status": "ok"}


@router.get("/emergency/ambulance")
def internal_ambulance():
    return {"service": "ambulance_api", "status": "ok"}


@router.get("/notify")
def internal_notify():
    return {"service": "notification", "status": "ok"}
