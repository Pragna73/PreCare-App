from __future__ import annotations

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from app.db import SessionLocal, get_db
from app.schemas import MayaChatRequest, MayaChatResponse, MayaGroupedHistoryResponse, MayaMessageResponse
from app.security import get_current_user
from services.auth_service import get_user_from_token
from services.maya_service import chat_with_maya, get_chat_history, get_grouped_chat_history

router = APIRouter(prefix="/maya", tags=["Ask Maya"])


@router.post("/chat", response_model=MayaChatResponse)
def ask_maya(
    body: MayaChatRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    out = chat_with_maya(db=db, user_id=current_user.id, message=body.message)
    return MayaChatResponse(
        reply=out["reply"],
        latest_risk=out["latest_risk"],
    )


@router.get("/chat/history", response_model=list[MayaMessageResponse])
def maya_history(
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_chat_history(db=db, user_id=current_user.id, limit=min(max(limit, 1), 100))


@router.get("/chat/history/grouped", response_model=MayaGroupedHistoryResponse)
def maya_history_grouped(
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_grouped_chat_history(db=db, user_id=current_user.id, limit=min(max(limit, 1), 300))


@router.websocket("/ws")
async def maya_chat_ws(websocket: WebSocket):
    await websocket.accept()
    token = websocket.query_params.get("token", "")

    db = SessionLocal()
    try:
        user = get_user_from_token(db, token)
    except Exception:
        await websocket.send_json({"error": "Unauthorized websocket token"})
        await websocket.close(code=1008)
        db.close()
        return

    try:
        while True:
            message = await websocket.receive_text()
            out = chat_with_maya(db=db, user_id=user.id, message=message)
            await websocket.send_json(out)
    except WebSocketDisconnect:
        pass
    finally:
        db.close()
