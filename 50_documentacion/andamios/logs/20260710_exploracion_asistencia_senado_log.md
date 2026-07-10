# Log de ejecución — Asistencia nominal por sesión del Senado (H1-bis)

**Fecha:** 2026-07-10
**Rama:** `explore/api-senado-v02-asistencia` (de `explore/api-senado-v02`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `jsonlite`.
**Naturaleza:** andamio congelado (diagnóstico insumos-first, no se actualiza).

## 1. Resumen

**Veredicto: SÍ existe asistencia NOMINAL POR SESIÓN del Senado**, estructurada y
cruzable por `ID_PARLAMENTARIO`. El endpoint que v02 usó para el agregado es
**polimórfico**: `api/sessions/attendance?id_legislatura=<id>` da el agregado por
legislatura; **`api/sessions/attendance?id_sesion=<id>` da el detalle nominal de esa
sesión** (Asiste/Ausente + justificación, por senador, con id estable). v02 solo
probó `id_legislatura`, de ahí su conclusión incompleta. La vía primaria (backend)
resolvió; no fue necesaria la secundaria. No se construyó pipeline; solo archivos
nuevos.

## 2. Qué se descubrió

| Pregunta | Respuesta | Evidencia |
|----------|-----------|-----------|
| ¿Nominal por sesión? | **SÍ** | `attendance?id_sesion=<id>` → `DATA[]` con ASISTENCIA + JUSTIFICACION por senador |
| ¿Endpoint/parámetro? | `api/sessions/attendance?id_sesion=<ID_SESION>` | otros nombres (`id_reunion`, `id`, `session_id`) → vacío; el correcto es `id_sesion` |
| ¿Id estable? | **SÍ** (`ID_PARLAMENTARIO`) | id 1110 (Araya) presente en ambas sesiones; cruza con roster |
| ¿Universo de sesiones? | `api/sessions?id_legislatura=<id>` (504 → total 105) | también `ID_SESION` viene en `api/votes` |
| ¿Contrato simétrico? | **SÍ** (nominal por sesión en ambas cámaras) | análogo al `33_extraer_asistencia.R` de la Cámara |

## 3. Muestras guardadas (auto-auditadas, JSON parseable)

Ruta: `50_documentacion/andamios/exploracion_asistencia_senado/`

| Archivo | bytes | verificación |
|---------|-------|-------------|
| `senado_backend_sesiones_legislatura_504_muestra.json` | 1909 | OK — 10 sesiones (total 105) |
| `senado_backend_sesion_10221_muestra.json` (reciente, 08-07-2026) | 11394 | OK — 50 senadores, 48 Asiste/2 Ausente, id 1110 presente |
| `senado_backend_sesion_9884_muestra.json` (histórica, 05-03-2025) | 11458 | OK — 50 senadores, 46 Asiste/4 Ausente, id 1110 presente |

Cruce por id contra el roster vigente v02: sesión reciente **50/50**; sesión
histórica **31/50** (los otros 19 dejaron el Senado en la renovación de marzo-2026).

## 4. Huecos / # REVISAR

- **Membresía dependiente del tiempo:** el join asistencia↔roster es determinista
  por id, pero debe hacerse contra el padrón **vigente en la fecha de la sesión**
  (usar `api/parlamentarios` sin `vigentes=1` para historia), no contra el roster
  actual. Sesiones viejas cruzan <50 con el roster vigente (esperado).
- **`JUSTIFICACION`** coexiste con "Asiste" en algunos registros (p. ej. 6
  justificaciones y 4 ausentes en la sesión 9884): el motivo puede asociarse a
  ausencias parciales/permisos, no solo a la ausencia total. A precisar si se usa.
- **id_legislatura backend (504 = "372" humano) ≠ wspublico (374):** espacios de id
  distintos; no mezclar (ya anotado en v02).

## 5. Qué costó

- La clave fue no asumir que `attendance` era mono-paramétrico: probar `id_sesion`
  reveló el modo nominal. Se listaron las sesiones reales (`api/sessions`) para
  obtener `ID_SESION` válidos en vez de adivinar.
- Se descartaron nombres de parámetro alternativos (`id_reunion`/`id`/`session_id`
  → respuesta vacía de 37 bytes) y endpoints hermanos (`/api/sessions/<id>`,
  `/api/attendance`, `/api/sala/asistencia` → 404) con muestra real, no por
  suposición.
- El cruce 31/50 en la sesión histórica pareció un problema hasta verificar una
  sesión reciente (50/50): confirmó que es cambio de composición, no un fallo de id.

## 6. Decisiones tomadas

- **Muestrear 2 sesiones de periodos distintos** (reciente 10221 + histórica 9884)
  para evidenciar el detalle nominal Y el efecto del cambio de roster.
- **`id_sesion` reciente derivado de `api/votes`** (mayor `ID_SESION`) →
  reproducible sin hardcodear una fecha.
- **No explorar la vía secundaria** (`asist_x_senador`): la Fase 1 resolvió el
  veredicto; además esa vía sugiere COMISIONES, no SALA (fuera del contrato).
- Muestras como bytes crudos (`writeBin`), reusando helpers de `10_utils.R`.

## 7. Casos de detención — ninguno se materializó

- #1 (auth/API key): NO — endpoint público sin registro.
- #2 (solo PDF / inexistente): NO — JSON estructurado nominal por sesión.
- #3 (nominal sin id, solo nombre): NO — trae `ID_PARLAMENTARIO`.
- #4 (insumo de referencia ausente): NO — los 4 verificados en Fase 0.

## 8. Invariantes verificados

| Invariante | Estado |
|-----------|--------|
| R único lenguaje (toda inspección en R; 0 Python/curl+jq) | PASA |
| httr2/jsonlite; parseo en R | PASA |
| Identificadores como character (ID_PARLAMENTARIO, ID_SESION) | PASA |
| Naming sin tildes/ñ/espacios en archivos nuevos | PASA |
| NO modificar 31c, 33, pipeline, config | PASA |
| NO tocar 20_insumos/, 40_salidas/, docs/ | PASA |
| 31d NO agregado a run_all/PASOS | PASA |
| No inventar cobertura (vía secundaria declarada no verificada) | PASA |
| Rama explore/api-senado-v02-asistencia; sin push/PR/merge | PASA |
| Cambios heredados no tocados ni incluidos | PASA |

## 9. Archivos nuevos (entregables)

- `30_procesamiento/31d_explorar_asistencia_senado.R`
- `50_documentacion/activa/exploracion_asistencia_senado.md`
- `50_documentacion/andamios/exploracion_asistencia_senado/*.json` (3 muestras)
- `50_documentacion/andamios/logs/20260710_exploracion_asistencia_senado_log.md` (este)

Nota: el working tree traía cambios previos ajenos (estructura/backlog/decisiones/
traspasos y los archivos de encargo); no se tocaron ni se incluyen en los commits.
