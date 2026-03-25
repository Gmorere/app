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
    recommended_tool = Column(String(80), nullable=False)
    risk_level = Column(String(20), nullable=False, default="low")
    should_offer_human_support = Column(Boolean, nullable=False, default=False)
    helped = Column(Boolean, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    user = relationship("User", back_populates="sessions")
