# Estado actual y gaps conocidos

## Estado general

ArmonIA ya tiene una base funcional bastante más alineada con la visión de producto que al inicio de esta etapa.

Hoy existen en repo:

- flujo guiado estable,
- onboarding de primera sesión,
- guía reabrible,
- Home más orientado a intervención + continuidad,
- feedback dual,
- cierre resuelto dentro de feedback con aterrizaje en Home,
- Pulso con vista `Hoy` y `Acumulado`,
- Historial más útil y mejor jerarquizado,
- Fono Ayuda y Support Path activos,
- contacto de confianza configurable,
- backend con persistencia semántica más rica que la versión inicial.

---

## Componentes confirmados

- selección de emoción,
- selección de intensidad,
- motor de intervención,
- pantallas de intervención,
- conversación como herramienta secundaria,
- feedback,
- cierre dentro de feedback,
- historial,
- pulso emocional,
- Fono Ayuda,
- Support Path,
- onboarding,
- guía reabrible `Cómo funciona ArmonIA`,
- contacto de confianza,
- backend FastAPI con sesiones y feedback.
- escritura expresiva con señales estructuradas en shadow mode.

---

## Lo que ya quedó corregido

- bypass directo de Home a conversación con emoción/intensidad inventadas,
- loop de conversación al sugerir `conversation`,
- `general` visible al usuario en Home e Historial,
- feedback neutral/bad sin impacto suficiente,
- falta de onboarding,
- falta de continuidad visible en Home,
- Pulso sin separación entre lectura actual y acumulada,
- cierre demasiado técnico con `popUntil(isFirst)`,
- persistencia backend demasiado pobre para categoría, estado dominante y feedback dual.

---

## Gaps reales que siguen abiertos

### 1. Continuidad por cuenta todavía es limitada

Existe endpoint remoto de sesiones recientes, pero la continuidad visible y el aprendizaje siguen muy apoyados en lógica local del dispositivo.

Las señales estructuradas de escritura ya existen, pero su uso en recomendaciones sigue siendo deliberadamente suave y local.

### 2. `longitudinal_concern` sigue sin contrato backend oficial

Hoy la señal longitudinal existe sobre todo en frontend/local.
No está cerrada todavía como parte oficial del contrato remoto.

### 3. Historial aún arrastra compatibilidad legacy del modelo de Pulso

La UX ya mejoró, pero semánticamente la pantalla todavía consume parte del esquema viejo de datos de pulso.

### 4. ExercisesScreen sigue sin rol plenamente consolidado

La pantalla existe, pero su lugar exacto en la navegación activa y su grado de vigencia productiva todavía requieren validación final.

### 5. Limpieza editorial aún incompleta

Ya se corrigieron varias pantallas y documentos, pero todavía pueden quedar textos legacy o inconsistencias de copy fuera del núcleo principal revisado.

### 6. Falta QA integral de versión

No basta con validaciones puntuales por pantalla.
Sigue pendiente una pasada end-to-end de:

- onboarding,
- flujo guiado,
- conversación secundaria,
- pulso,
- historial,
- crisis,
- feedback y cierre.

---

## Riesgos estructurales vigentes

- seguir acumulando lógica local sin decidir cuánto aprendizaje debe pasar a backend,
- mantener compatibilidad legacy demasiado tiempo,
- documentar como “implementado” algo que en realidad sigue solo local o parcial,
- abrir nuevas líneas de producto antes de consolidar la base ya implementada.

---

## Prioridad técnica recomendada hoy

1. QA integral de la versión actual.
2. Limpieza editorial/documental restante.
3. Decidir estrategia real de continuidad por cuenta.
4. Reducir compatibilidad legacy que ya no aporta valor.
