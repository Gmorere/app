import logging
import time
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from auth import create_access_token, get_current_user, hash_password, verify_password
from db import Base, engine, get_db
from models import SessionRecord, User
from openai_service import generate_armonia_response
from schemas import (
    ArmoniaRequest,
    ArmoniaResponse,
    AuthResponse,
    LoginRequest,
    RecentSessionsResponse,
    RegisterRequest,
    SessionFeedbackRequest,
    SessionFeedbackResponse,
    UserOut,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("armonia-backend")

app = FastAPI(title="ArmonIA Backend")
Base.metadata.create_all(bind=engine)


def _category_from_tool(tool: str) -> str:
    normalized = (tool or "").strip().lower()

    if normalized in {"breathing", "grounding"}:
        return "physical_regulation"
    if normalized == "reframe":
        return "mental_reframe"
    if normalized == "micro_action":
        return "concrete_action"
    if normalized == "support_path":
        return "support_path"
    return "conversation"


@app.get("/")
def root():
    return {"message": "ArmonIA backend running"}


@app.get("/health")
def health(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"ok": True}


@app.post("/auth/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing_user:
        raise HTTPException(status_code=409, detail="El email ya está registrado")

    user = User(
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        display_name=payload.display_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id)
    return AuthResponse(access_token=access_token, user=UserOut.model_validate(user))


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email.lower(), User.is_active.is_(True)).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id)
    return AuthResponse(access_token=access_token, user=UserOut.model_validate(user))


@app.get("/auth/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


@app.post("/armonia/respond", response_model=ArmoniaResponse)
def armonia_respond(
    payload: ArmoniaRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    request_start = time.perf_counter()

    try:
        recent_rows = (
            db.query(SessionRecord)
            .filter(SessionRecord.user_id == current_user.id)
            .order_by(SessionRecord.created_at.desc())
            .limit(5)
            .all()
        )
        recent_history = [
            {
                "emotion": row.emotion,
                "intensity": row.intensity,
                "recommended_tool": row.recommended_tool,
                "helped": row.helped,
                "risk_level": row.risk_level,
            }
            for row in recent_rows
        ]

        ai_result = generate_armonia_response(payload, recent_history)

        session = SessionRecord(
            user_id=current_user.id,
            emotion=payload.emotion,
            intensity=payload.intensity,
            brief_context=payload.brief_context or None,
            user_message=payload.user_message or None,
            validation=ai_result.validation,
            next_message=ai_result.next_message,
            recommended_tool=ai_result.recommended_tool,
            risk_level=ai_result.risk_level,
            should_offer_human_support=ai_result.should_offer_human_support,
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        total_ms = round((time.perf_counter() - request_start) * 1000, 1)
        logger.info(
            "respond ok | user_id=%s | session_id=%s | emotion=%s | intensity=%s | tool=%s | risk=%s | total_ms=%s",
            current_user.id,
            session.id,
            payload.emotion,
            payload.intensity,
            ai_result.recommended_tool,
            ai_result.risk_level,
            total_ms,
        )

        return ArmoniaResponse(
            session_id=session.id,
            validation=ai_result.validation,
            next_message=ai_result.next_message,
            recommended_category=(
                ai_result.recommended_category
                or _category_from_tool(ai_result.recommended_tool)
            ),
            recommended_tool=ai_result.recommended_tool,
            risk_level=ai_result.risk_level,
            should_offer_human_support=ai_result.should_offer_human_support,
        )
    except HTTPException:
        raise
    except Exception as exc:
        total_ms = round((time.perf_counter() - request_start) * 1000, 1)
        logger.exception("respond error | user_id=%s | total_ms=%s", current_user.id, total_ms)
        raise HTTPException(status_code=500, detail="Error interno del servidor") from exc


@app.get("/sessions/recent", response_model=RecentSessionsResponse)
def get_recent_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    sessions = (
        db.query(SessionRecord)
        .filter(SessionRecord.user_id == current_user.id)
        .order_by(SessionRecord.created_at.desc())
        .limit(20)
        .all()
    )
    return RecentSessionsResponse(items=sessions)


@app.post("/sessions/{session_id}/feedback", response_model=SessionFeedbackResponse)
def save_feedback(
    session_id: int,
    payload: SessionFeedbackRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = (
        db.query(SessionRecord)
        .filter(SessionRecord.id == session_id, SessionRecord.user_id == current_user.id)
        .first()
    )
    if not session:
        raise HTTPException(status_code=404, detail="Sesión no encontrada")

    session.helped = payload.helped
    db.commit()
    db.refresh(session)

    return SessionFeedbackResponse(ok=True, session_id=session.id, helped=session.helped)
