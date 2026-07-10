# Log de ejecución — Exploración API Senado v02 (cierre de huecos)

**Fecha:** 2026-07-10
**Rama:** `explore/api-senado-v02` (ramificada de `explore/api-senado`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `jsonlite` (+ `xml2` heredado).
**Naturaleza:** andamio congelado (diagnóstico insumos-first, no se actualiza).

## 1. Resumen

Se cerraron los tres huecos que dejó v01, descubriendo el **backend JSON del sitio
`senado.cl`** (`https://web-back.senado.cl/api/`). Ese backend expone roster,
asistencia y votaciones con un **identificador estable de parlamentario**
(`ID_PARLAMENTARIO`/`PARLID`) consistente entre las tres entidades y con el `PARLID`
de wspublico. **H1, H2 y H3: resueltos.** El fuzzy name matching que v01 daba por
inevitable **se elimina**. `opendata.congreso.cl` resultó ser un portal de
documentación (no una API nueva). No se construyó pipeline; solo se agregaron
archivos nuevos (31c, doc v02, 5 muestras, este log).

## 2. Qué se descubrió por hueco (fuente + evidencia)

| Hueco | Resultado | Fuente | Evidencia (muestra) |
|-------|-----------|--------|---------------------|
| H1 asistencia | RESUELTO | `api/sessions/attendance?id_legislatura=504` | 51 senadores, `ID_PARLAMENTARIO`, asistió/justificado/sin_justificar sobre 105 sesiones |
| H2 roster 50 | RESUELTO | `api/parlamentarios?vigentes=1` (`CAMARA=S`) | 205 vigentes = 155 D + **50 S**, 26 columnas con id, partido_id, circunscripción, región |
| H3 ids estables | RESUELTO | `api/votes?id_votacion=<id>` | voto nominal agrupado por sentido, cada votante con **`PARLID`**; `BOLETIN` para join a proyecto |

`opendata.congreso.cl`: directorio de 214 recursos (jsonapi) que enlaza wspublico
(Senado) y wscamaradiputados.asmx (Cámara). `node--parlamentarios` trae `field_id`
(=PARLID) pero delgado. No es la fuente de datos; lo es `web-back.senado.cl`.

## 3. Muestras guardadas (auto-auditadas, JSON parseable)

Ruta: `50_documentacion/andamios/exploracion_api_senado_v02/`

| Archivo | bytes | verificación |
|---------|-------|-------------|
| `opendata_congreso_jsonapi_root_muestra.json` | 24054 | OK — 214 tipos de recurso |
| `senado_backend_parlamentarios_vigentes_muestra.json` | 294010 | OK — total 205; S=50, D=155 |
| `senado_backend_asistencia_muestra.json` | 11393 | OK — 51 senadores, `ID_PARLAMENTARIO` presente |
| `senado_backend_votos_lista_muestra.json` | 62820 | OK — 8685 votaciones, columna `BOLETIN` presente |
| `senado_backend_voto_detalle_muestra.json` | 7354 | OK — boletín 18029-17, `PARLID` en cada voto nominal |

Consistencia de id verificada: `1110` (Pedro Araya) aparece en roster (CAMARA=S) y
en asistencia; y el detalle de voto trae PARLID (911 Kuschel, etc.).

## 4. Huecos / # REVISAR residuales

- **Proyectos (detalle):** el backend no tiene endpoint de proyectos; el detalle
  (título, estado, trámites, materias, autores) sigue en `wspublico/tramitacion.php`
  (v01). Autorías por nombre, pero **cruzables a id sin fuzzy** vía
  `NOMBRE_COMPLETO_POR_APELLIDOS` del roster (mismo formato que wspublico).
- **PARTIDO_ID** del backend es un código propio ≠ códigos de la Cámara → crosswalk
  a `MAPA_PARTIDO_TENDENCIA` pendiente (metodológico).
- **id_legislatura backend (504) ≠ wspublico (374):** espacios distintos.
- **Asistencia agregada** por legislatura (no per-sesión nominal en el endpoint
  probado); suficiente para la tasa del dashboard.
- El backend NO es API documentada/versionada (backend de un sitio): puede cambiar
  de forma. Mitigación: 31c regenera muestras para detectar drift de esquema.

## 5. Qué costó

- El giro clave fue mirar `senado.cl` (no solo wspublico): su HTML Next.js embebe
  llamadas a `web-back.senado.cl`. Se extrajeron los endpoints reales parseando el
  HTML de las páginas de listado y de asistencia en R (no se asumieron).
- El `jsonapi` de Drupal (214 recursos) despistaba: `node--parlamentarios` es
  delgado; la API útil es la capa propia `/api/` (patrón `?vigentes=1`,
  `?id_legislatura=`, `?id_votacion=`).
- El detalle de voto agrupa por sentido (`{SI,NO,ABSTENCION,PAREO}`) con el votante
  anidado; hubo que desanidar en R (simplifyVector=FALSE) para ver el `PARLID`.
- El `%||%` de `10_utils.R` falla sobre vectores largos (`is.na` vectorizado); se
  evitó con un `if (is.null(...))` explícito en 31c.

## 6. Decisiones tomadas

- **Reusar helpers de `10_utils.R`** (`instalar_si_falta`, `log_msg`) pero cliente
  HTTP propio `httr2` con User-Agent de navegador (el backend rechaza sin UA).
- **Muestras como bytes crudos** (`writeBin(resp_body_raw)`).
- **Ids de legislatura/votación fijos** (504, 11155) documentados como
  representativos y descubiertos de las llamadas XHR reales del sitio.
- **No detenerse:** ningún caso de detención se materializó (ver §7); el encargo se
  completó de punta a punta.

## 7. Casos de detención — ninguno se materializó

- #1 (auth/API key): NO — todos los endpoints son públicos, sin registro.
- #2 (asistencia solo PDF/inexistente): NO — asistencia estructurada en JSON.
- #3 (sin ids estables, fuzzy inevitable): NO — **al contrario**, hay id estable;
  el hallazgo #1 es justamente que el gap de identidad se resuelve.
- #4 (insumos de referencia ausentes): NO — los 4 verificados presentes en Fase 0.

## 8. Invariantes verificados

| Invariante | Estado |
|-----------|--------|
| R único lenguaje (toda inspección en R; 0 Python/curl+jq) | PASA |
| httr2/xml2/jsonlite; parseo HTML en R (rvest/xml2) | PASA |
| Identificadores como character (documentado; PARLID) | PASA |
| Naming sin tildes/ñ/espacios en archivos nuevos | PASA |
| NO modificar pipeline, 31b, 10_utils, config | PASA |
| NO tocar 20_insumos/, 40_salidas/, docs/ | PASA |
| 31c NO agregado a run_all/PASOS | PASA |
| No inventar cobertura (opendata.congreso.cl reportado como directorio real) | PASA |
| Rama explore/api-senado-v02; sin push/PR/merge | PASA |
| Cambios heredados de otra sesión no tocados ni incluidos | PASA |

## 9. Archivos nuevos (entregables)

- `30_procesamiento/31c_explorar_api_senado_v02.R`
- `50_documentacion/activa/exploracion_api_senado_v02.md`
- `50_documentacion/andamios/exploracion_api_senado_v02/*.json` (5 muestras)
- `50_documentacion/andamios/logs/20260710_exploracion_api_senado_v02_log.md` (este)

Nota: el working tree traía cambios previos ajenos (estructura/backlog/decisiones/
traspasos y el propio `encargo_exploracion_senado_v02.md`); no se tocaron ni se
incluyen en los commits.
