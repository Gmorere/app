from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field

AllowedEmotion = Literal["ansiedad", "sobrepasado", "bloqueado", "rabia", "tristeza"]
AllowedIntensity = Literal["bajo", "medio", "alto"]
AllowedTool = Literal[
    "conversation",
    "breathing",
    "grounding",
    "reframe",
    "micro_action",
    "support_path",
]
AllowedCategory = Literal[
    "conversation",
    "physical_regulation",
    "mental_reframe",
    "concrete_action",
    "support_path",
]
AllowedRisk = Literal["low", "medium", "high"]


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    display_name: str | None = Field(default=None, max_length=120)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)


class UserOut(BaseModel):
    id: int
    email: EmailStr
    display_name: str | None = None

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    user: UserOut


class ArmoniaRequest(BaseModel):
    emotion: AllowedEmotion
    intensity: AllowedIntensity
    brief_context: str = ""
    user_message: str = Field(default="", max_length=4000)


class ArmoniaResponse(BaseModel):
    session_id: int
    validation: str
    next_message: str
    recommended_category: AllowedCategory | None = None
    recommended_tool: AllowedTool
    risk_level: AllowedRisk
    should_offer_human_support: bool


class ArmoniaResponsePayload(BaseModel):
    validation: str
    next_message: str
    recommended_category: AllowedCategory | None = None
    recommended_tool: AllowedTool
    risk_level: AllowedRisk
    should_offer_human_support: bool


class SessionFeedbackRequest(BaseModel):
    helped: bool


class SessionFeedbackResponse(BaseModel):
    ok: bool
    session_id: int
    helped: bool


class SessionItem(BaseModel):
    id: int
    emotion: AllowedEmotion
    intensity: AllowedIntensity
    recommended_tool: AllowedTool
    risk_level: AllowedRisk
    should_offer_human_support: bool
    helped: bool | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class RecentSessionsResponse(BaseModel):
    items: list[SessionItem]
