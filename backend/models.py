from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from db import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(Text, nullable=False)
    display_name = Column(String(120), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    beta_access = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    sessions = relationship("SessionRecord", back_populates="user", cascade="all, delete-orphan")


class SessionRecord(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    emotion = Column(String(50), nullable=False)
    intensity = Column(String(20), nullable=False)
    brief_context = Column(Text, nullable=True)
    user_message = Column(Text, nullable=True)
    validation = Column(Text, nullable=False)
    next_message = Column(Text, nullable=False)
    recommended_category = Column(String(80), nullable=True)
    recommended_tool = Column(String(80), nullable=False)
    risk_level = Column(String(20), nullable=False, default="low")
    should_offer_human_support = Column(Boolean, nullable=False, default=False)
    dominant_state = Column(String(50), nullable=True)
    relief_feedback = Column(Boolean, nullable=True)
    utility_feedback = Column(Boolean, nullable=True)
    helped = Column(Boolean, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    user = relationship("User", back_populates="sessions")


class ExpressiveWritingSignalRecord(Base):
    __tablename__ = "expressive_writing_signals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    emotion = Column(String(50), nullable=True)
    intensity = Column(String(20), nullable=True)
    intervention_origin = Column(String(40), nullable=False, default="manual_library")
    reflection = Column(Text, nullable=False)
    next_step = Column(Text, nullable=False)
    context_tag = Column(String(80), nullable=False)
    possible_theme = Column(String(80), nullable=False)
    theme_confidence = Column(String(20), nullable=False, default="low")
    risk_level = Column(String(20), nullable=False, default="normal")
    should_offer_human_support = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())


class V3DayCaptureRecord(Base):
    __tablename__ = "v3_day_captures"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    day_key = Column(String(10), nullable=False, index=True)
    capture_date = Column(DateTime(timezone=True), nullable=False)
    day_mode = Column(String(40), nullable=False)
    traction_signals_json = Column(Text, nullable=False, default="[]")
    friction_signals_json = Column(Text, nullable=False, default="[]")
    visible_bet = Column(Text, nullable=False, default="")
    tomorrow_guard = Column(Text, nullable=False, default="")
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )


class V3PulseSnapshotRecord(Base):
    __tablename__ = "v3_pulse_snapshots"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    day_key = Column(String(10), nullable=False, index=True)
    captured_at = Column(DateTime(timezone=True), nullable=False)
    energy = Column(Integer, nullable=False)
    load = Column(Integer, nullable=False)
    calm = Column(Integer, nullable=False)
    connection = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )


class V3ExerciseFeedbackRecord(Base):
    __tablename__ = "v3_exercise_feedback"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    client_entry_id = Column(String(120), nullable=False, index=True)
    exercise_id = Column(String(80), nullable=False)
    helpful = Column(Boolean, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False)
    day_mode = Column(String(40), nullable=True)
    stored_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
