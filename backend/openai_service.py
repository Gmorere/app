import json
import os
import re
import unicodedata
from typing import Literal

from dotenv import load_dotenv
from openai import OpenAI

from schemas import ArmoniaRequest, ArmoniaResponsePayload

load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise RuntimeError("Falta OPENAI_API_KEY en el archivo .env")

client = OpenAI(api_key=api_key)
MODEL_NAME = os.getenv("OPENAI_MODEL", "gpt-5-mini")

SYSTEM_PROMPT = """
Eres la capa conversacional de ArmonIA.
No decides pantallas ni herramientas concretas. No eres un chatbot generico.

Recibiras contexto estructurado con:
- emocion
- intensidad
- nivel de riesgo
- categoria recomendada
- historial breve

Debes responder SIEMPRE en JSON valido con esta estructura exacta:
{
  "validation": "string",
  "next_message": "string"
}

Reglas:
1. Se breve, calido, claro y humano.
2. Espanol latino neutro.
3. No prometas resultados.
4. No uses lenguaje clinico innecesario.
5. validation debe validar sin exagerar.
6. next_message debe ser una sola guia breve y accionable.
7. Si el riesgo es vulnerability_high o crisis, prioriza contencion, apoyo humano y claridad.
8. Si la categoria es support_path, no abras exploracion larga ni pidas seguir profundizando por chat.
9. Si la categoria es physical_regulation, orienta a bajar activacion o volver al cuerpo.
10. Si la categoria es mental_reframe, orienta a abrir otra mirada sin sonar abstracto.
11. Si la categoria es concrete_action, orienta a un paso pequeno y realizable.
12. Si la categoria es conversation, ordena y contiene sin convertirte en una charla larga.
13. No agregues texto fuera del JSON.
"""

EXPRESSIVE_WRITING_SYSTEM_PROMPT = """
Eres la capa de salida breve de escritura expresiva de ArmonIA.
No eres un chatbot generico. No abras conversacion larga.

Recibiras:
- texto escrito por el usuario
- emocion e intensidad opcionales
- contexto breve opcional

Debes responder SIEMPRE en JSON valido con esta estructura exacta:
{
  "reflection": "string",
  "next_step": "string"
}

Reglas:
1. Espanol latino neutro.
2. Se breve, claro y humano.
3. No hagas terapia, no interpretes de mas.
4. reflection debe nombrar que parece pesar mas o quedar mas presente.
5. next_step debe ser una sola orientacion simple y accionable.
6. Cada campo debe ser una sola frase breve pero con sustancia util.
7. Apunta a unas 18 a 28 palabras por campo.
8. Evita respuestas telegráficas o demasiado genéricas.
9. No conviertas esto en chat.
10. No uses frases vacias, coach ni autoayuda generica.
11. Si hay alguna senal favorable real, puedes nombrarla en positivo.
12. No agregues texto fuera del JSON.
"""

AllowedRiskScreening = Literal["safe", "vulnerability_high", "high_risk"]
AllowedCategory = Literal[
    "conversation",
    "physical_regulation",
    "mental_reframe",
    "concrete_action",
    "support_path",
]
AllowedDominantState = Literal[
    "hiperactivado",
    "bloqueado",
    "rumiativo",
    "agotado",
    "desconectado",
    "desbordado",
]

HIGH_RISK_PATTERNS = [
    r"\bme quiero matar\b",
    r"\bquiero matarme\b",
    r"\bvoy a matarme\b",
    r"\bme voy a matar\b",
    r"\bquiero matarme a mi mismo\b",
    r"\bquiero matarme a mi misma\b",
    r"\bquiero matarme yo\b",
    r"\bcomo puedo matarme\b",
    r"\bcomo podria matarme\b",
    r"\bcomo matarme\b",
    r"\bme puedes ayudar a matarme\b",
    r"\bpuedes ayudarme a matarme\b",
    r"\bquiero ayuda para matarme\b",
    r"\bquiero morir\b",
    r"\bme quiero morir\b",
    r"\bquisiera morirme\b",
    r"\bme gustaria morirme\b",
    r"\bno quiero vivir\b",
    r"\bno quiero vivir mas\b",
    r"\bno quiero seguir\b",
    r"\bno quiero seguir viviendo\b",
    r"\bno quiero seguir con vida\b",
    r"\bno quiero existir\b",
    r"\bquisiera desaparecer para siempre\b",
    r"\bquiero desaparecer para siempre\b",
    r"\bseria mejor si no estuviera\b",
    r"\bya no quiero estar aqui\b",
    r"\bquiero acabar con todo\b",
    r"\bquiero terminar con todo\b",
    r"\bquiero terminar con mi vida\b",
    r"\bquiero acabar con mi vida\b",
    r"\bquiero quitarme la vida\b",
    r"\bquisiera quitarme la vida\b",
    r"\bme gustaria quitarme la vida\b",
    r"\bvoy a quitarme la vida\b",
    r"\bme voy a quitar la vida\b",
    r"\bcomo puedo quitarme la vida\b",
    r"\bcomo podria quitarme la vida\b",
    r"\bcomo quitarme la vida\b",
    r"\bme puedes ayudar a quitarme la vida\b",
    r"\bpuedes ayudarme a quitarme la vida\b",
    r"\bquiero ayuda para quitarme la vida\b",
    r"\bquiero hacerme dano\b",
    r"\bme quiero hacerme dano\b",
    r"\bme quiero hacer dano\b",
    r"\bpienso en matarme\b",
    r"\bpienso en suicidarme\b",
    r"\bquiero suicidarme\b",
    r"\bvoy a suicidarme\b",
    r"\bme voy a suicidar\b",
    r"\bcomo puedo suicidarme\b",
    r"\bcomo podria suicidarme\b",
    r"\bcomo suicidarme\b",
    r"\bme puedes ayudar a suicidarme\b",
    r"\bpuedes ayudarme a suicidarme\b",
    r"\bquiero ayuda para suicidarme\b",
    r"\bsuicidarme\b",
    r"\bseria mejor no despertar\b",
    r"\bojala no despertar\b",
    r"\bno quiero despertar\b",
]

VIOLENCE_TO_OTHERS_PATTERNS = [
    r"\bquiero matarte\b",
    r"\bte quiero matar\b",
    r"\bvoy a matarte\b",
    r"\bte voy a matar\b",
    r"\bquiero matar a alguien\b",
    r"\bquiero matar a una persona\b",
    r"\bquiero hacerle dano a alguien\b",
    r"\bquiero hacer dano a alguien\b",
    r"\bquiero lastimar a alguien\b",
    r"\bquiero herir a alguien\b",
]

AMBIGUOUS_RISK_PATTERNS = [
    r"\bquiero olvidarme de todo\b",
    r"\btengo ganas de olvidarme de todo\b",
    r"\bme gustaria olvidarme de todo\b",
    r"\bquisiera olvidarme de todo\b",
    r"\bsolo quisiera olvidarme de todo\b",
    r"\bquiero desaparecer\b",
    r"\btengo ganas de desaparecer\b",
    r"\bme gustaria desaparecer\b",
    r"\bquisiera desaparecer\b",
    r"\bquisiera desaparecer un rato\b",
    r"\bquiero apagarme\b",
    r"\bquisiera apagarme\b",
    r"\bme gustaria apagarme\b",
    r"\bquiero desconectarme de todo\b",
    r"\bquisiera desconectarme de todo\b",
    r"\bme gustaria desconectarme de todo\b",
    r"\bno quiero pensar mas\b",
    r"\bno quiero seguir pensando\b",
    r"\bquisiera dejar de pensar\b",
    r"\bno doy mas\b",
    r"\bno puedo mas\b",
    r"\bya no doy mas\b",
    r"\bya no puedo mas\b",
    r"\bya no aguanto mas\b",
    r"\bno aguanto mas\b",
    r"\bno lo soporto mas\b",
    r"\bya no lo soporto mas\b",
    r"\bestoy agotad[oa] de todo\b",
    r"\bestoy cansad[oa] de todo\b",
    r"\bquiero dormir varios dias\b",
    r"\bquiero dormir por dias\b",
    r"\bquiero dormir todo el dia\b",
    r"\bquiero descansar y dormir varios dias seguidos\b",
    r"\bme gustaria dormir varios dias\b",
    r"\bquisiera dormir varios dias\b",
    r"\bquisiera dormirme y no pensar en nada\b",
    r"\bme gustaria dormirme y no pensar en nada\b",
    r"\bquiero irme lejos de todo\b",
    r"\bquisiera irme lejos de todo\b",
    r"\bme gustaria irme lejos de todo\b",
]

EXPLICIT_DENIAL_PATTERNS = [
    r"\b(?:ya\s+)?no\s+me\s+quiero\s+matar\b",
    r"\b(?:ya\s+)?no\s+quiero\s+matarme\b",
    r"\b(?:ya\s+)?no\s+quiero\s+morir\b",
    r"\b(?:ya\s+)?no\s+quiero\s+hacerme\s+dano\b",
    r"\b(?:ya\s+)?no\s+me\s+quiero\s+hacer\s+dano\b",
]


def normalize_text(text: str) -> str:
    raw = (text or "").strip().lower()
    without_accents = unicodedata.normalize("NFKD", raw).encode("ascii", "ignore").decode("ascii")
    collapsed_spaces = " ".join(without_accents.split())
    softened = re.sub(r"(.)\1{2,}", r"\1", collapsed_spaces)
    replacements = {
        " q ": " que ",
        " xq ": " porque ",
        " kiero ": " quiero ",
        " kiero.": " quiero.",
        " kiero,": " quiero,",
        " qiero ": " quiero ",
        " qiero.": " quiero.",
        " qiero,": " quiero,",
        " qitarme ": " quitarme ",
        " qitarme.": " quitarme.",
        " qitarme,": " quitarme,",
        " matarm ": " matarme ",
        " matarmee ": " matarme ",
        " matarmeee ": " matarme ",
        " suicidarm ": " suicidarme ",
        " suicidarmee ": " suicidarme ",
        " suicidarmeee ": " suicidarme ",
        " vivirr ": " vivir ",
        " vidaa ": " vida ",
    }
    normalized = f" {softened} "
    for source, target in replacements.items():
        normalized = normalized.replace(source, target)
    return " ".join(normalized.split())


def has_high_risk_fragments(text: str) -> bool:
    normalized = f" {text} "

    self_harm_intent = any(
        fragment in normalized
        for fragment in [
            " quiero ",
            " me quiero ",
            " voy a ",
            " me voy a ",
            " ayuda para ",
            " ayudar a ",
            " como ",
            " no quiero ",
            " no quiero seguir ",
        ]
    )

    self_harm_targets = any(
        fragment in normalized
        for fragment in [
            " matarm",
            " suicid",
            " quitarme la vida",
            " terminar con mi vida",
            " acabar con mi vida",
            " morir",
            " seguir viviendo",
            " seguir con vida",
        ]
    )

    violence_targets = any(
        fragment in normalized
        for fragment in [
            " matarte",
            " matar a alguien",
            " matar a una persona",
            " lastimar a alguien",
            " herir a alguien",
            " hacer dano a alguien",
            " hacerle dano a alguien",
        ]
    )

    third_party_subject = any(
        fragment in normalized
        for fragment in [
            " otra persona ",
            " un amigo ",
            " una amiga ",
            " mi amigo ",
            " mi amiga ",
            " mi pareja ",
            " mi hijo ",
            " mi hija ",
            " mi hermano ",
            " mi hermana ",
            " alguien ",
        ]
    )

    third_party_intent = any(
        fragment in normalized
        for fragment in [
            " quiere ",
            " quiere saber ",
            " recomendaciones ",
            " que recomendaciones ",
            " consejos ",
            " opciones ",
            " formas ",
            " maneras ",
            " como ",
            " ayudar ",
            " ayuda para ",
        ]
    )

    third_party_targets = any(
        fragment in normalized
        for fragment in [
            " matarse",
            " suicid",
            " quitarse la vida",
            " terminar con todo",
            " terminar con su vida",
            " acabar con su vida",
            " morir",
        ]
    )

    third_party_high_risk = third_party_subject and third_party_intent and third_party_targets

    return (self_harm_intent and self_harm_targets) or violence_targets or third_party_high_risk


def matches_any(text: str, patterns: list[str]) -> bool:
    return any(re.search(pattern, text) for pattern in patterns)


def has_ambiguous_escape_language(text: str) -> bool:
    escape_verbs = ["olvidarme", "desaparecer", "apagarme", "desconectarme", "dormir", "irme"]
    soft_triggers = ["quiero", "quisiera", "me gustaria", "tengo ganas de", "solo quisiera"]
    return any(verb in text for verb in escape_verbs) and any(trigger in text for trigger in soft_triggers)


def screen_risk(user_message: str) -> AllowedRiskScreening:
    text = normalize_text(user_message)
    if not text:
        return "safe"
    if matches_any(text, EXPLICIT_DENIAL_PATTERNS):
        return "safe"
    if (
        matches_any(text, HIGH_RISK_PATTERNS)
        or matches_any(text, VIOLENCE_TO_OTHERS_PATTERNS)
        or has_high_risk_fragments(text)
    ):
        return "high_risk"
    if matches_any(text, AMBIGUOUS_RISK_PATTERNS) or has_ambiguous_escape_language(text):
        return "vulnerability_high"
    return "safe"


def build_risk_source_text(data: ArmoniaRequest) -> str:
    return normalize_text(f"{data.brief_context} {data.user_message}")


def infer_dominant_state(data: ArmoniaRequest) -> AllowedDominantState | None:
    text = build_risk_source_text(data)
    if not text:
        return None

    if data.emotion == "ansiedad":
        if any(fragment in text for fragment in ["pensar", "vueltas", "cabeza", "mente"]):
            return "rumiativo"
        if any(fragment in text for fragment in ["acelerad", "agita", "tembl", "pecho", "taquic", "nervios"]):
            return "hiperactivado"
        return None

    if data.emotion == "bloqueado":
        if any(fragment in text for fragment in ["paraliz", "congel", "trabado", "no puedo empezar", "no me sale"]):
            return "bloqueado"
        return None

    if data.emotion == "rabia":
        if any(fragment in text for fragment in ["sin energia", "agotado", "cansado"]):
            return "agotado"
        if any(fragment in text for fragment in ["gritar", "explota", "furia", "tenso"]):
            return "hiperactivado"
        return None

    if data.emotion == "tristeza":
        if any(fragment in text for fragment in ["desconect", "vacio", "nada siento"]):
            return "desconectado"
        if data.intensity == "alto" and any(
            fragment in text for fragment in ["agotado", "cansado", "sin energia", "pesad"]
        ):
            return "agotado"
        return None

    if data.emotion == "sobrepasado":
        if any(fragment in text for fragment in ["agotado", "cansado", "sin energia"]):
            return "agotado"
        if any(fragment in text for fragment in ["desbord", "saturad", "sobrepas", "no puedo mas", "no doy mas"]):
            return "desbordado"
        return None

    return None


def tool_to_category(tool: str) -> AllowedCategory:
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


def category_to_legacy_tool(
    category: AllowedCategory,
    emotion: str,
    intensity: str,
) -> str:
    if category == "support_path":
        return "support_path"
    if category == "mental_reframe":
        return "reframe"
    if category == "concrete_action":
        return "micro_action"
    if category == "physical_regulation":
        if emotion == "ansiedad" and intensity == "alto":
            return "breathing"
        return "grounding"
    return "conversation"


def build_history_summary(history_items: list[dict]) -> str:
    if not history_items:
        return "sin historial"

    lines = []
    for idx, item in enumerate(history_items[:5], start=1):
        category = tool_to_category(item.get("recommended_tool", "conversation"))
        lines.append(
            f"{idx}. emocion={item['emotion']}, intensidad={item['intensity']}, "
            f"categoria={category}, ayudo={item['helped']}, riesgo={item['risk_level']}"
        )
    return "\n".join(lines)


def build_user_prompt(
    data: ArmoniaRequest,
    category: AllowedCategory,
    risk_level: str,
    recent_history_summary: str,
) -> str:
    return f"""
Contexto actual del usuario:
- emocion: {data.emotion}
- intensidad: {data.intensity}
- categoria recomendada: {category}
- nivel de riesgo: {risk_level}
- contexto breve previo: {data.brief_context or 'sin contexto'}
- mensaje actual del usuario: {data.user_message or 'sin mensaje'}
- historial reciente resumido: {recent_history_summary or 'sin historial'}

Devuelve el JSON exacto pedido.
""".strip()


def build_expressive_writing_prompt(
    written_text: str,
    emotion: str | None,
    intensity: str | None,
    brief_context: str,
) -> str:
    return f"""
Contexto opcional:
- emocion: {emotion or 'sin dato'}
- intensidad: {intensity or 'sin dato'}
- contexto breve: {brief_context or 'sin contexto'}

Texto escrito por el usuario:
{written_text}

Devuelve el JSON exacto pedido.
""".strip()


def choose_vulnerability_category(
    data: ArmoniaRequest,
    recent_history: list[dict],
) -> AllowedCategory:
    base_category = choose_category(data, recent_history)
    dominant_state = infer_dominant_state(data)

    if base_category == "mental_reframe":
        return "conversation"

    if dominant_state in {"hiperactivado", "desbordado"} and base_category == "conversation":
        return "physical_regulation"

    return base_category


def build_vulnerability_response(
    data: ArmoniaRequest,
    recent_history: list[dict],
) -> ArmoniaResponsePayload:
    category = choose_vulnerability_category(data, recent_history)
    dominant_state = infer_dominant_state(data)

    return ArmoniaResponsePayload(
        validation="Lo que dices suena a un nivel de agotamiento o desesperanza que quiero tomar con mucho cuidado.",
        next_message="No quiero cargarte con demasiado ahora. Voy a proponerte una ayuda breve y tambien voy a dejarte apoyo humano visible por si lo necesitas.",
        recommended_category=category,
        recommended_tool=category_to_legacy_tool(category, data.emotion, data.intensity),
        risk_level="vulnerability_high",
        should_offer_human_support=True,
        dominant_state=dominant_state,
    )


def build_crisis_response() -> ArmoniaResponsePayload:
    return ArmoniaResponsePayload(
        validation="Lo que estas expresando me importa y no quiero tomarlo a la ligera.",
        next_message="Quiero llevarte a apoyo humano ahora mismo. No voy a seguir profundizando esto por chat.",
        recommended_category="support_path",
        recommended_tool="support_path",
        risk_level="crisis",
        should_offer_human_support=True,
        dominant_state=None,
    )


def get_helpful_categories(history_items: list[dict], emotion: str, intensity: str) -> list[AllowedCategory]:
    helpful_categories: list[AllowedCategory] = []

    for item in history_items:
        if item.get("helped") is not True:
            continue
        if item.get("emotion") != emotion or item.get("intensity") != intensity:
            continue
        category = tool_to_category(item.get("recommended_tool", "conversation"))
        if category == "support_path":
            continue
        if category not in helpful_categories:
            helpful_categories.append(category)

    return helpful_categories


def choose_category(
    data: ArmoniaRequest,
    recent_history: list[dict],
) -> AllowedCategory:
    helpful_categories = get_helpful_categories(recent_history, data.emotion, data.intensity)
    dominant_state = infer_dominant_state(data)

    if data.emotion == "ansiedad":
        if dominant_state == "rumiativo":
            if data.intensity == "alto":
                return "conversation"
            return "mental_reframe"
        if data.intensity in {"alto", "medio"}:
            if "conversation" in helpful_categories and data.intensity == "medio":
                return "conversation"
            return "physical_regulation"
        if "mental_reframe" in helpful_categories:
            return "mental_reframe"
        return "conversation"

    if data.emotion == "sobrepasado":
        if dominant_state == "agotado":
            return "conversation" if data.intensity == "alto" else "concrete_action"
        if data.intensity == "alto":
            return "concrete_action"
        if data.intensity == "medio":
            if "physical_regulation" in helpful_categories:
                return "physical_regulation"
            return "concrete_action"
        return "concrete_action"

    if data.emotion == "bloqueado":
        if data.intensity == "bajo":
            if "mental_reframe" in helpful_categories:
                return "mental_reframe"
            return "concrete_action"
        if "mental_reframe" in helpful_categories and data.intensity == "medio":
            return "mental_reframe"
        return "concrete_action"

    if data.emotion == "rabia":
        if data.intensity in {"alto", "medio"}:
            return "physical_regulation"
        if "mental_reframe" in helpful_categories:
            return "mental_reframe"
        return "conversation"

    if data.emotion == "tristeza":
        if dominant_state == "desconectado" and data.intensity != "alto":
            return "conversation"
        if data.intensity == "alto":
            return "conversation"
        if data.intensity == "medio":
            if "mental_reframe" in helpful_categories:
                return "mental_reframe"
            return "conversation"
        if "mental_reframe" in helpful_categories:
            return "mental_reframe"
        return "conversation"

    return "conversation"


def generate_copy(
    data: ArmoniaRequest,
    category: AllowedCategory,
    risk_level: str,
    recent_history: list[dict],
) -> dict[str, str]:
    recent_history_summary = build_history_summary(recent_history)
    response = client.responses.create(
        model=MODEL_NAME,
        input=[
            {
                "role": "system",
                "content": [{"type": "input_text", "text": SYSTEM_PROMPT}],
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": build_user_prompt(
                            data=data,
                            category=category,
                            risk_level=risk_level,
                            recent_history_summary=recent_history_summary,
                        ),
                    }
                ],
            },
        ],
        text={
            "format": {
                "type": "json_schema",
                "name": "armonia_copy_response",
                "schema": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "validation": {"type": "string"},
                        "next_message": {"type": "string"},
                    },
                    "required": ["validation", "next_message"],
                },
            }
        },
    )

    parsed = json.loads(response.output_text)
    validation = str(parsed.get("validation", "")).strip()
    next_message = str(parsed.get("next_message", "")).strip()

    if not validation or not next_message:
        raise ValueError("La respuesta conversacional llego incompleta")

    return {
        "validation": validation,
        "next_message": next_message,
    }


def generate_armonia_response(data: ArmoniaRequest, recent_history: list[dict]) -> ArmoniaResponsePayload:
    risk_screening = screen_risk(build_risk_source_text(data))
    dominant_state = infer_dominant_state(data)

    if risk_screening == "high_risk":
        return build_crisis_response()

    if risk_screening == "vulnerability_high":
        return build_vulnerability_response(data, recent_history)

    category = choose_category(data, recent_history)
    copy = generate_copy(
        data=data,
        category=category,
        risk_level="normal",
        recent_history=recent_history,
    )

    return ArmoniaResponsePayload(
        validation=copy["validation"],
        next_message=copy["next_message"],
        recommended_category=category,
        recommended_tool=category_to_legacy_tool(category, data.emotion, data.intensity),
        risk_level="normal",
        should_offer_human_support=False,
        dominant_state=dominant_state,
    )


def generate_expressive_writing_output(
    *,
    written_text: str,
    emotion: str | None = None,
    intensity: str | None = None,
    brief_context: str = "",
) -> dict[str, str | bool]:
    normalized_text = normalize_text(f"{brief_context} {written_text}")
    risk_screening = screen_risk(normalized_text)

    if risk_screening == "high_risk":
        return {
            "reflection": "Ahora lo mas importante no es seguir profundizando por aqui, sino acercarte a apoyo humano.",
            "next_step": "Ve a apoyo ahora y toma contacto con una persona real o una linea de ayuda.",
            "risk_level": "crisis",
            "should_offer_human_support": True,
        }

    if risk_screening == "vulnerability_high":
        return {
            "reflection": "Parece que esto ya no esta siendo solo una molestia puntual, sino algo que te esta sobrepasando.",
            "next_step": "Si puedes, busca apoyo humano visible ahora o usa una ayuda breve antes de seguir cargandote.",
            "risk_level": "vulnerability_high",
            "should_offer_human_support": True,
        }

    response = client.responses.create(
        model=MODEL_NAME,
        input=[
            {
                "role": "system",
                "content": [{"type": "input_text", "text": EXPRESSIVE_WRITING_SYSTEM_PROMPT}],
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": build_expressive_writing_prompt(
                            written_text=written_text,
                            emotion=emotion,
                            intensity=intensity,
                            brief_context=brief_context,
                        ),
                    }
                ],
            },
        ],
        text={
            "format": {
                "type": "json_schema",
                "name": "expressive_writing_response",
                "schema": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "reflection": {"type": "string"},
                        "next_step": {"type": "string"},
                    },
                    "required": ["reflection", "next_step"],
                },
            }
        },
    )

    parsed = json.loads(response.output_text)
    reflection = str(parsed.get("reflection", "")).strip()
    next_step = str(parsed.get("next_step", "")).strip()

    if not reflection or not next_step:
        raise ValueError("La salida de escritura expresiva llego incompleta")

    return {
        "reflection": reflection,
        "next_step": next_step,
        "risk_level": "normal",
        "should_offer_human_support": False,
    }
