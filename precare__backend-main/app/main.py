from __future__ import annotations

from fastapi import FastAPI
import os 
import sys 
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.db import Base, engine, run_startup_migrations
from routers.agent import router as agent_router
from routers.ai import router as ai_router
from routers.appointments import router as appointments_router
from routers.auth import router as auth_router
from routers.dashboard import router as dashboard_router
from routers.emergency import router as emergency_router
from routers.health_tracking import router as health_tracking_router
from routers.internal import router as internal_router
from routers.maya import router as maya_router
from routers.reports import router as reports_router
from routers.twin import router as twin_router

Base.metadata.create_all(bind=engine)
run_startup_migrations()

app = FastAPI(
    title="PreCare Agentic Backend",
    description="Pregnancy report OCR + autonomous risk triage + appointment/emergency orchestration",
    version="1.0.0",
)


@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(auth_router)
app.include_router(reports_router)
app.include_router(ai_router)
app.include_router(agent_router)
app.include_router(appointments_router)
app.include_router(emergency_router)
app.include_router(dashboard_router)
app.include_router(twin_router)
app.include_router(health_tracking_router)
app.include_router(maya_router)
app.include_router(internal_router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", port=8000, reload=True)
