import os
import json
import re
import time
from typing import Literal

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from openai import OpenAI

load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise RuntimeError("Falta OPENAI_API_KEY en el archivo .env")

client = OpenAI(api_key=api_key)
app = FastAPI(title="ArmonIA Backend")


class ArmoniaRequest(BaseModel):
    emotion: str = Field(..., min_length=1)
    intensity: str = Field(..., min_length=1)
    brief_context: str = ""
    user_message: str = ""
    recent_history_summary: str = ""


class ArmoniaResponse(BaseModel):
    validation: str
    next_message: str
    recommended_tool: Literal[
        "conversation",
        "breathing",
        "grounding",
        "reframe",
        "micro_action",
        "support_path",
    ]
    risk_level: Literal["low", "medium", "high"]
    should_offer_human_support: bool


SYSTEM_PROMPT = """
Eres el motor conversacional de ArmonIA, un asistente emocional breve.
Tu tarea NO es hacer terapia ni conversar libremente sin estructura.

Debes responder SIEMPRE en JSON válido con esta estructura exacta:
{
  "validation": "string",
  "next_message": "string",
  "recommended_tool": "conversation|breathing|grounding|reframe|micro_action|support_path",
  "risk_level": "low|medium|high",
  "should_offer_human_support": true
}

Reglas:
1. Sé breve, cálido, claro y humano.
2. Español latino neutro.
3. No prometas resultados.
4. No uses lenguaje clínico innecesario.
5. Si detectas posible riesgo serio, usa:
   - risk_level = "high"
   - should_offer_human_support = true
   - recommended_tool = "support_path"
6. Si hay ansiedad alta o mucha activación, prioriza breathing o grounding.
7. Si hay bloqueo, prioriza micro_action o conversation.
8. Si hay tristeza o pena sin riesgo alto, puedes usar conversation o reframe.
9. validation debe validar sin exagerar.
10. next_message debe ser una sola intervención breve, no un párrafo largo.
11. No agregues texto fuera del JSON.
12. Si el mensaje suena ambiguamente riesgoso, NO lo minimices.
13. Si el usuario parece muy agotado o desconectado, evita trivializar con frases como “es normal” sin matiz.
"""


HIGH_RISK_PATTERNS = [
    r"\bme quiero matar\b",
    r"\bquiero matarme\b",
    r"\bquiero morir\b",
    r"\bme quiero morir\b",
    r"\bno quiero vivir\b",
    r"\bno quiero seguir\b",
    r"\bno quiero existir\b",
    r"\bquisiera desaparecer para siempre\b",
    r"\bquiero desaparecer para siempre\b",
    r"\bquiero acabar con todo\b",
    r"\bquiero terminar con todo\b",
    r"\bquiero hacerme daño\b",
    r"\bme quiero hacer daño\b",
    r"\bpienso en matarme\b",
    r"\bpienso en suicidarme\b",
    r"\bquiero suicidarme\b",
    r"\bsuicidarme\b",
    r"\bsería mejor no despertar\b",
    r"\bno quiero despertar\b",
]

AMBIGUOUS_RISK_PATTERNS = [
    r"\bquiero olvidarme de todo\b",
    r"\btengo ganas de olvidarme de todo\b",
    r"\bme gustaría olvidarme de todo\b",
    r"\bquisiera olvidarme de todo\b",
    r"\bsolo quisiera olvidarme de todo\b",
    r"\bquiero desaparecer\b",
    r"\btengo ganas de desaparecer\b",
    r"\bme gustaría desaparecer\b",
    r"\bquisiera desaparecer\b",
    r"\bquisiera desaparecer un rato\b",
    r"\bquiero apagarme\b",
    r"\bquisiera apagarme\b",
    r"\bme gustaría apagarme\b",
    r"\bquiero desconectarme de todo\b",
    r"\bquisiera desconectarme de todo\b",
    r"\bme gustaría desconectarme de todo\b",
    r"\bno quiero pensar más\b",
    r"\bno quiero seguir pensando\b",
    r"\bquisiera dejar de pensar\b",
    r"\bno doy más\b",
    r"\bno puedo más\b",
    r"\bestoy agotado de todo\b",
    r"\bestoy cansado de todo\b",
    r"\bquiero dormir varios días\b",
    r"\bquiero dormir por días\b",
    r"\bquiero dormir todo el día\b",
    r"\bquiero descansar y dormir varios días seguidos\b",
    r"\bme gustaría dormir varios días\b",
    r"\bquisiera dormir varios días\b",
    r"\bquisiera dormirme y no pensar en nada\b",
    r"\bme gustaría dormirme y no pensar en nada\b",
    r"\bquiero irme lejos de todo\b",
    r"\bquisiera irme lejos de todo\b",
    r"\bme gustaría irme lejos de todo\b",
]

NEGATION_CONTEXT_PATTERNS = [
    r"\bno\b.*\bme quiero matar\b",
    r"\bno\b.*\bquiero morir\b",
    r"\bno\b.*\bquiero hacerme daño\b",
]


def normalize_text(text: str) -> str:
    return " ".join((text or "").strip().lower().split())


def matches_any(text: str, patterns: list[str]) -> bool:
    return any(re.search(pattern, text) for pattern in patterns)


def has_ambiguous_escape_language(text: str) -> bool:
    escape_verbs = [
        "olvidarme",
        "desaparecer",
        "apagarme",
        "desconectarme",
        "dormir",
        "irme",
    ]
    soft_triggers = [
        "quiero",
        "quisiera",
        "me gustaría",
        "tengo ganas de",
        "solo quisiera",
    ]

    return any(verb in text for verb in escape_verbs) and any(
        trigger in text for trigger in soft_triggers
    )


def screen_risk(user_message: str) -> Literal["safe", "ambiguous_risk", "high_risk"]:
    text = normalize_text(user_message)

    if not text:
        return "safe"

    if matches_any(text, NEGATION_CONTEXT_PATTERNS):
        return "safe"

    if matches_any(text, HIGH_RISK_PATTERNS):
        return "high_risk"

    if matches_any(text, AMBIGUOUS_RISK_PATTERNS) or has_ambiguous_escape_language(text):
        return "ambiguous_risk"

    return "safe"


def build_user_prompt(data: ArmoniaRequest) -> str:
    return f"""
Contexto actual del usuario:
- emoción: {data.emotion}
- intensidad: {data.intensity}
- contexto breve previo: {data.brief_context or "sin contexto"}
- mensaje actual del usuario: {data.user_message or "sin mensaje"}
- historial reciente resumido: {data.recent_history_summary or "sin historial"}

Devuelve el JSON exacto pedido.
""".strip()


def build_high_risk_response() -> ArmoniaResponse:
    return ArmoniaResponse(
        validation=(
            "Lo que estás expresando me importa y no quiero tomarlo a la ligera."
        ),
        next_message=(
            "Quiero acompañarte a buscar apoyo humano ahora mismo. No tienes que manejar esto solo."
        ),
        recommended_tool="support_path",
        risk_level="high",
        should_offer_human_support=True,
    )


def build_ambiguous_risk_response() -> ArmoniaResponse:
    return ArmoniaResponse(
        validation=(
            "Lo que dices suena a un nivel de agotamiento o desconexión que quiero tomar con cuidado."
        ),
        next_message=(
            "Antes de seguir, necesito chequear algo importante contigo: ¿esto se siente más como cansancio extremo, o como ganas de hacerte daño o no seguir?"
        ),
        recommended_tool="conversation",
        risk_level="medium",
        should_offer_human_support=True,
    )


@app.get("/")
def root():
    return {"message": "ArmonIA backend running"}


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/armonia/respond", response_model=ArmoniaResponse)
def armonia_respond(payload: ArmoniaRequest):
    request_start = time.perf_counter()

    try:
        screening_start = time.perf_counter()
        risk_screening = screen_risk(payload.user_message)
        screening_ms = round((time.perf_counter() - screening_start) * 1000, 1)

        print(
            f"[ArmonIA] Screening -> risk={risk_screening} | "
            f"emotion={payload.emotion} | intensity={payload.intensity} | "
            f"screening_ms={screening_ms}"
        )

        if risk_screening == "high_risk":
            total_ms = round((time.perf_counter() - request_start) * 1000, 1)
            print(f"[ArmonIA] Response path=high_risk_local | total_ms={total_ms}")
            return build_high_risk_response()

        if risk_screening == "ambiguous_risk":
            total_ms = round((time.perf_counter() - request_start) * 1000, 1)
            print(f"[ArmonIA] Response path=ambiguous_risk_local | total_ms={total_ms}")
            return build_ambiguous_risk_response()

        openai_start = time.perf_counter()
        response = client.responses.create(
            model="gpt-5-mini",
            input=[
                {
                    "role": "system",
                    "content": [{"type": "input_text", "text": SYSTEM_PROMPT}],
                },
                {
                    "role": "user",
                    "content": [{"type": "input_text", "text": build_user_prompt(payload)}],
                },
            ],
            text={
                "format": {
                    "type": "json_schema",
                    "name": "armonia_response",
                    "schema": {
                        "type": "object",
                        "additionalProperties": False,
                        "properties": {
                            "validation": {"type": "string"},
                            "next_message": {"type": "string"},
                            "recommended_tool": {
                                "type": "string",
                                "enum": [
                                    "conversation",
                                    "breathing",
                                    "grounding",
                                    "reframe",
                                    "micro_action",
                                    "support_path",
                                ],
                            },
                            "risk_level": {
                                "type": "string",
                                "enum": ["low", "medium", "high"],
                            },
                            "should_offer_human_support": {"type": "boolean"},
                        },
                        "required": [
                            "validation",
                            "next_message",
                            "recommended_tool",
                            "risk_level",
                            "should_offer_human_support",
                        ],
                    },
                }
            },
        )
        openai_ms = round((time.perf_counter() - openai_start) * 1000, 1)

        raw_text = response.output_text
        parsed = json.loads(raw_text)
        result = ArmoniaResponse(**parsed)

        total_ms = round((time.perf_counter() - request_start) * 1000, 1)
        print(
            f"[ArmonIA] Response path=openai | openai_ms={openai_ms} | "
            f"total_ms={total_ms} | tool={result.recommended_tool} | risk={result.risk_level}"
        )

        return result

    except Exception as e:
        total_ms = round((time.perf_counter() - request_start) * 1000, 1)
        print(f"[ArmonIA] ERROR | total_ms={total_ms} | detail={str(e)}")
        raise HTTPException(status_code=500, detail=f"Error backend IA: {str(e)}")