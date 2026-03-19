import os
import json
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
"""


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


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/armonia/respond", response_model=ArmoniaResponse)
def armonia_respond(payload: ArmoniaRequest):
    try:
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

        raw_text = response.output_text
        parsed = json.loads(raw_text)
        return ArmoniaResponse(**parsed)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error backend IA: {str(e)}")