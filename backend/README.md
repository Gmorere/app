# Backend ArmonIA

Backend FastAPI para autenticacion, sesiones emocionales y respuestas guiadas.

## Requisitos

- Python 3.11+
- Postgres accesible por `DATABASE_URL`
- clave de OpenAI en `OPENAI_API_KEY`

## Instalacion

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

## Variables de entorno

Minimas:

- `DATABASE_URL`
- `OPENAI_API_KEY`

Opcional:

- `OPENAI_MODEL`

## Arranque local

```bash
uvicorn main:app --reload
```

## Deploy en Render

Configuracion recomendada:

- Root Directory: `backend`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Health Check Path: `/health`

Variables obligatorias en Render:

- `DATABASE_URL`
- `OPENAI_API_KEY`
- `JWT_SECRET_KEY`

Opcional:

- `OPENAI_MODEL`

El repo ahora incluye:

- [render.yaml](/C:/Users/Gonzalo%20Morere/Desktop/armoniav2_app/render.yaml)
- [Procfile](/C:/Users/Gonzalo%20Morere/Desktop/armoniav2_app/backend/Procfile)
- [runtime.txt](/C:/Users/Gonzalo%20Morere/Desktop/armoniav2_app/backend/runtime.txt)

Si `/health` responde pero `/auth/register` da `404`, el deploy activo probablemente no corresponde a este backend o esta usando otro `Root Directory`.

## Endpoints utiles

- `GET /`
- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /armonia/respond`
- `GET /sessions/recent`
- `POST /sessions/{session_id}/feedback`

## Contrato principal

`POST /armonia/respond`

Entrada:

- `emotion`
- `intensity`
- `brief_context`
- `user_message`

Salida:

- `session_id`
- `validation`
- `next_message`
- `recommended_tool`
- `risk_level`
- `should_offer_human_support`

Los valores validos reales estan definidos en `schemas.py`.
