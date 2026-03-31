# Contrato frontend/backend

## Objetivo

Definir el contrato real hoy implementado entre app y backend para:

- respuesta conversacional,
- recomendación semántica,
- evaluación de riesgo,
- feedback,
- y lectura básica de sesiones recientes.

El backend devuelve semántica del sistema, no nombres de pantallas Flutter.

---

## Estado actual

### Endpoints implementados

- `POST /armonia/respond`
- `POST /armonia/expressive-writing`
- `GET /sessions/recent`
- `POST /sessions/{session_id}/feedback`

### Regla

Este documento describe primero lo que hoy existe en código.
Los campos futuros o ideales se dejan explícitos como no implementados.

---

## 1. Request actual: `POST /armonia/respond`

### Payload implementado

- `emotion`
- `intensity`
- `brief_context`
- `user_message`

### Reglas

- `emotion` usa las emociones oficiales actuales.
- `intensity` usa `bajo`, `medio`, `alto`.
- `brief_context` es opcional.
- `user_message` es opcional y acotado en longitud.

### Lo que todavía no entra al request real

- contexto reciente estructurado,
- última intervención,
- feedback previo relevante,
- `dominant_state`,
- flags longitudinales,
- metadatos más ricos de sesión.

Eso puede existir en documentación futura, pero no forma parte del request implementado hoy.

---

## 2. Response actual: `POST /armonia/respond`

### Campos implementados

- `session_id`
- `validation`
- `next_message`
- `recommended_category`
- `recommended_tool`
- `risk_level`
- `should_offer_human_support`
- `dominant_state`

### Reglas

- `recommended_category` es la semántica principal cuando existe.
- `recommended_tool` sigue existiendo como compatibilidad temporal.
- `risk_level` usa:
  - `normal`
  - `vulnerability_high`
  - `crisis`
- `dominant_state` es opcional.

### Campo no implementado en contrato real

- `longitudinal_concern`

Hoy esa señal sigue viviendo principalmente en frontend/local.
No debe documentarse como si el backend ya la devolviera de forma oficial.

---

## 3. Feedback actual: `POST /sessions/{session_id}/feedback`

### Payload implementado

- `helped`
- `relief_feedback`
- `utility_feedback`

### Reglas

- `helped` puede llegar por compatibilidad.
- `relief_feedback` y `utility_feedback` ya están implementados.
- si llegan señales duales, el backend deriva:
  - `helped = relief_feedback || utility_feedback`
- si no llega ningún campo, el backend responde error.

### Respuesta actual

- `ok`
- `session_id`
- `helped`

---

## 4. Escritura expresiva actual: `POST /armonia/expressive-writing`

### Payload implementado

- `written_text`
- `emotion`
- `intensity`
- `brief_context`
- `intervention_origin`

### Response actual

- `reflection`
- `next_step`
- `risk_level`
- `should_offer_human_support`
- `context_tag`
- `possible_theme`
- `theme_confidence`

### Regla

- `context_tag`, `possible_theme` y `theme_confidence` son senales estructuradas de baja autoridad.
- no deben tratarse como diagnostico ni como verdad fija del usuario.
- hoy pueden alimentar continuidad y aprendizaje suave, pero no deben gobernar por si solos la categoria del motor.

---

## 5. Sesiones recientes: `GET /sessions/recent`

### Campos implementados por item

- `id`
- `emotion`
- `intensity`
- `recommended_category`
- `recommended_tool`
- `risk_level`
- `should_offer_human_support`
- `dominant_state`
- `helped`
- `created_at`

### Regla

Este endpoint ya devuelve más semántica que antes, pero todavía no expone:

- feedback dual completo,
- flags longitudinales,
- origen de intervención,
- ni lectura enriquecida de continuidad.

---

## 6. Reglas del contrato actual

- el backend no debe devolver nombres de pantallas,
- `recommended_category` es la fuente principal cuando exista,
- `recommended_tool` es compatibilidad temporal,
- riesgo y apoyo humano tienen prioridad sobre continuidad conversacional,
- `dominant_state` solo refina,
- un `401` no debe ocultarse bajo fallback funcional normal.

---

## 7. Compatibilidad legacy

### Sigue existiendo

- `recommended_tool`
- `helped`

### Regla

Se mantienen por compatibilidad temporal.
No deben seguir tratándose como la fuente conceptual principal del sistema.

La migración oficial va hacia:

1. `recommended_category`
2. `risk_level`
3. `dominant_state` opcional
4. `relief_feedback`
5. `utility_feedback`

---

## 8. Lo que sigue pendiente

- decidir si `/sessions/recent` pasará a alimentar continuidad real entre dispositivos,
- formalizar o descartar `longitudinal_concern` en contrato backend,
- definir si el backend recibirá más contexto estructurado en el request,
- versionar el contrato cuando la compatibilidad legacy empiece a retirarse.

---

## Regla de fallback

Si la respuesta llega incompleta o inconsistente:

- categoría inválida -> usar selector local,
- herramienta inválida -> ignorar herramienta y resolver por categoría,
- `risk_level` inválido -> aplicar criterio local conservador,
- backend caído -> fallback local con mensaje calmado,
- `401` -> tratar como error de autenticación, no como ayuda normal.
