from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field

AllowedEmotion = Literal["ansiedad", "sobrepasado", "bloqueado", "rabia", "tristeza"]
AllowedIntensity = Literal["bajo", "medio", "alto"]
AllowedTool = Literal[
    "conversation",
    "breathing",
    "grounding",
    "clench_fists",
    "movement",
    "sensory_pause",
    "reframe",
    "expressive_writing",
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
AllowedRisk = Literal["normal", "vulnerability_high", "crisis"]
AllowedDominantState = Literal[
    "hiperactivado",
    "bloqueado",
    "rumiativo",
    "agotado",
    "desconectado",
    "desbordado",
]


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
    dominant_state: AllowedDominantState | None = None


class ArmoniaResponsePayload(BaseModel):
    validation: str
    next_message: str
    recommended_category: AllowedCategory | None = None
    recommended_tool: AllowedTool
    risk_level: AllowedRisk
    should_offer_human_support: bool
    dominant_state: AllowedDominantState | None = None


class ExpressiveWritingRequest(BaseModel):
    written_text: str = Field(..., min_length=1, max_length=4000)
    emotion: str | None = Field(default=None, max_length=80)
    intensity: str | None = Field(default=None, max_length=40)
    brief_context: str = Field(default="", max_length=4000)


class ExpressiveWritingResponse(BaseModel):
    reflection: str
    next_step: str
    risk_level: AllowedRisk
    should_offer_human_support: bool


class SessionFeedbackRequest(BaseModel):
    helped: bool | None = None
    relief_feedback: bool | None = None
    utility_feedback: bool | None = None


class SessionFeedbackResponse(BaseModel):
    ok: bool
    session_id: int
    helped: bool


class SessionItem(BaseModel):
    id: int
    emotion: AllowedEmotion
    intensity: AllowedIntensity
    recommended_category: AllowedCategory | None = None
    recommended_tool: AllowedTool
    risk_level: AllowedRisk
    should_offer_human_support: bool
    dominant_state: AllowedDominantState | None = None
    helped: bool | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class RecentSessionsResponse(BaseModel):
    items: list[SessionItem]
