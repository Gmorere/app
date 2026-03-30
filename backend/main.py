import logging
import time
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import inspect, text
from sqlalchemy.orm import Session

from auth import create_access_token, get_current_user, hash_password, verify_password
from db import Base, engine, get_db
from models import SessionRecord, User
from openai_service import generate_armonia_response, generate_expressive_writing_output
from schemas import (
    ArmoniaRequest,
    ArmoniaResponse,
    AuthResponse,
    ExpressiveWritingRequest,
    ExpressiveWritingResponse,
    LoginRequest,
    RecentSessionsResponse,
    RegisterRequest,
    SessionFeedbackRequest,
    SessionFeedbackResponse,
    SessionItem,
    UserOut,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("armonia-backend")

app = FastAPI(title="ArmonIA Backend")
Base.metadata.create_all(bind=engine)


def _ensure_session_columns() -> None:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    if "sessions" not in existing_tables:
        return

    existing_columns = {
        column["name"]
        for column in inspector.get_columns("sessions")
    }

    alter_statements = []
    if "recommended_category" not in existing_columns:
        alter_statements.append(
            "ALTER TABLE sessions ADD COLUMN IF NOT EXISTS recommended_category VARCHAR(80)"
        )
    if "dominant_state" not in existing_columns:
        alter_statements.append(
            "ALTER TABLE sessions ADD COLUMN IF NOT EXISTS dominant_state VARCHAR(50)"
        )
    if "relief_feedback" not in existing_columns:
        alter_statements.append(
            "ALTER TABLE sessions ADD COLUMN IF NOT EXISTS relief_feedback BOOLEAN"
        )
    if "utility_feedback" not in existing_columns:
        alter_statements.append(
            "ALTER TABLE sessions ADD COLUMN IF NOT EXISTS utility_feedback BOOLEAN"
        )

    if not alter_statements:
        return

    with engine.begin() as connection:
        for statement in alter_statements:
            connection.execute(text(statement))


_ensure_session_columns()


def _category_from_tool(tool: str) -> str:
    normalized = (tool or "").strip().lower()

    if normalized in {"breathing", "grounding", "clench_fists", "movement", "sensory_pause"}:
        return "physical_regulation"
    if normalized in {"reframe", "expressive_writing"}:
        return "mental_reframe"
    if normalized == "micro_action":
        return "concrete_action"
    if normalized == "support_path":
        return "support_path"
    return "conversation"


def _normalize_risk_level(risk_level: str | None) -> str:
    normalized = (risk_level or "").strip().lower()

    if normalized == "low":
        return "normal"
    if normalized == "medium":
        return "vulnerability_high"
    if normalized == "high":
        return "crisis"
    if normalized in {"normal", "vulnerability_high", "crisis"}:
        return normalized
    return "normal"


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
                "risk_level": _normalize_risk_level(row.risk_level),
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
            recommended_category=(
                ai_result.recommended_category
                or _category_from_tool(ai_result.recommended_tool)
            ),
            recommended_tool=ai_result.recommended_tool,
            risk_level=ai_result.risk_level,
            should_offer_human_support=ai_result.should_offer_human_support,
            dominant_state=ai_result.dominant_state,
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
            dominant_state=ai_result.dominant_state,
        )
    except HTTPException:
        raise
    except Exception as exc:
        total_ms = round((time.perf_counter() - request_start) * 1000, 1)
        logger.exception("respond error | user_id=%s | total_ms=%s", current_user.id, total_ms)
        raise HTTPException(status_code=500, detail="Error interno del servidor") from exc


@app.post("/armonia/expressive-writing", response_model=ExpressiveWritingResponse)
def expressive_writing_output(
    payload: ExpressiveWritingRequest,
    current_user: User = Depends(get_current_user),
):
    try:
        result = generate_expressive_writing_output(
            written_text=payload.written_text,
            emotion=payload.emotion,
            intensity=payload.intensity,
            brief_context=payload.brief_context,
        )

        logger.info(
            "expressive_writing ok | user_id=%s | risk=%s | human_support=%s",
            current_user.id,
            result["risk_level"],
            result["should_offer_human_support"],
        )

        return ExpressiveWritingResponse(
            reflection=str(result["reflection"]),
            next_step=str(result["next_step"]),
            risk_level=str(result["risk_level"]),
            should_offer_human_support=bool(result["should_offer_human_support"]),
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("expressive_writing error | user_id=%s", current_user.id)
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
    items = [
        SessionItem(
            id=session.id,
            emotion=session.emotion,
            intensity=session.intensity,
            recommended_category=(
                session.recommended_category
                or _category_from_tool(session.recommended_tool)
            ),
            recommended_tool=session.recommended_tool,
            risk_level=_normalize_risk_level(session.risk_level),
            should_offer_human_support=session.should_offer_human_support,
            dominant_state=session.dominant_state,
            helped=session.helped,
            created_at=session.created_at,
        )
        for session in sessions
    ]
    return RecentSessionsResponse(items=items)


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

    relief_feedback = payload.relief_feedback
    utility_feedback = payload.utility_feedback

    if relief_feedback is None and utility_feedback is None and payload.helped is None:
        raise HTTPException(status_code=422, detail="Feedback incompleto")

    if relief_feedback is not None or utility_feedback is not None:
        session.relief_feedback = relief_feedback
        session.utility_feedback = utility_feedback
        session.helped = relief_feedback is True or utility_feedback is True
    else:
        session.helped = payload.helped
    db.commit()
    db.refresh(session)

    return SessionFeedbackResponse(ok=True, session_id=session.id, helped=session.helped)
