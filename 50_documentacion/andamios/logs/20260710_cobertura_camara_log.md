# Log de ejecución — Auditoría de cobertura del web service de la Cámara

**Fecha:** 2026-07-10
**Rama:** `explore/cobertura-camara` (desde `main`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `xml2`.
**Naturaleza:** andamio congelado (auditoría adversarial, no se actualiza).

## 1. Resumen

Auditoría adversarial de qué expone el web service de la Cámara
(`opendata.camara.cl`, 5 servicios / **49 operaciones**; el pipeline usa 8) que los
scripts 32-36 NO consumen. Se enumeró el catálogo completo, se bajó una respuesta
real de cada endpoint (usado y no usado) con su muestra en disco, y se sondearon
parámetros/endpoints alternativos. Resultado: **~14 gaps** en 4 entidades, más una
entidad completa no cubierta (comisiones). Un panel adversarial de dos agentes
re-derivó las afirmaciones de mayor riesgo y **corrigió un falso negativo mío**
(la asistencia SÍ trae justificación por diputado). No se tocó el pipeline.

## 2. Inventario de commits

| Fase | Tipo | Contenido |
|------|------|-----------|
| 1 | feat | `31f_auditar_cobertura_camara.R` + muestras crudas (`andamios/muestras/`) |
| 2 | docs | `auditoria_cobertura_camara.md` (tabla de gaps + Fase 4 + panel) + este log |

(Hashes al pie / en el reporte al chat.)

## 3. Cambios sustantivos con causa raíz

- **Script 31f** (nuevo, exploratorio, fuera de run_all): enumera catálogo,
  campos por endpoint (por UNIÓN de todos los items, no del primero — ver §7),
  y sondeos adversariales. Guarda muestras en `andamios/muestras/` (nunca en
  `20_insumos/`, el caché de producción).
- **Documento** con linaje campo-por-campo (Fase 1), catálogo + campos reales
  (Fase 2), tabla de gaps por entidad (Fase 3), implicancia sobre las 8 preguntas
  del contrato (Fase 4), y sección de panel adversarial.

## 4. Hallazgos (gaps con evidencia)

Los 3 de mayor impacto:
1. **Asistencia: nominal por sesión + fecha + justificación, agregados a una tasa
   (33).** El detalle por sesión, `Sesion/FechaInicio` y `Asistencia/Justificacion`
   están en la fuente; 33 los descarta. Evidencia: `camara_retornarSesionesXAnno_muestra.xml`,
   `camara_retornarSesionAsistencia_muestra.xml`. Confirma y **extiende** A23.
2. **Votaciones: join estructurado votación↔proyecto sin usar.** El pipeline extrae
   el boletín por regex de `Descripcion` → **31.5% de las votaciones (212/672) sin
   boletín** (recuento sobre `votos.rds`). `retornarProyectoLey/Votaciones/
   VotacionProyectoLey/Id` (+ `Articulo`, `TramiteConstitucional/Reglamentario`) da
   el join autoritativo. Evidencia: `camara_retornarProyectoLey_muestra.xml`,
   `camara_retornarVotacionesXProyectoLey_muestra.xml`.
3. **Roster: `RUT`/`RUTDV` descartados** (id nacional estable). Evidencia:
   `camara_retornarDiputadosPeriodoActual_muestra.xml`.

Otros: `Quorum` en votaciones (descartado; el Senado lo guarda); historial de
militancias (solo la vigente); `TipoAsistencia=2 (Justificado)` en catálogo pero
ausente en datos 2026 (gap latente, con guardia de dominio en 33); `ProyectoLey/Id`;
`retornarMensajesXAnno` (iniciativa ejecutiva, correctamente no procesada como
autoría). **Entidad no cubierta:** `WSComision/*` (sesiones y trabajo en comisión).

Confirmados NO (huecos reales de la fuente, verificados adversarialmente): distrito/
región por diputado; estado de tramitación por proyecto (solo `Admisible`).

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (toda inspección; 0 Python/jq/awk sobre artefactos) | PASA | 31f y todas las verificaciones en R; bash solo para git |
| Solo lectura sobre el pipeline (32-36, 39, 10_utils, config) | PASA | ningún archivo del pipeline modificado (git status) |
| No tocar `20_insumos/` (caché); muestras a `andamios/muestras/` | PASA | `writeBin` a `50_documentacion/andamios/muestras/` |
| `CORTE_FECHA` no alterada | PASA | 31f no la usa (usa `anio` literal para exploración) |
| Llaves como character | PASA | ids tratados como texto en la auditoría |
| No decidir metodología (solo marcar preguntas) | PASA | Fase 4 marca "sin cambio"/"cambia", no responde |
| Cortesía con la fuente (backoff 429, pausas) | PASA | `req_retry` transitorio 429/500 + `Sys.sleep(0.4)` |

## 6. Decisiones registradas

- **Usar httr2 propio en 31f** (no el cliente de producción) para controlar el
  barrido de catálogo y los parámetros alternativos; solo lectura.
- **Un boletín votado real** (18384-08) como muestra del join estructurado, hallado
  escaneando las descripciones de votaciones (no hardcodeado).
- **No barrer las 105/49 combinaciones**: muestra representativa por endpoint
  (exploración, no extracción), como pide el encargo.

## 7. Pendientes / lo que costó / lo que NO logré a la primera

- **Falso negativo propio, corregido por el panel:** mi enumeración inicial listaba
  los campos del PRIMER item de cada colección. La `Justificacion` de la asistencia
  aparece solo en los ausentes, así que la perdí y la reporté como inexistente. El
  Panel B la detectó; re-verifiqué y corregí 31f para unir los campos de TODOS los
  items. Es el hallazgo más honesto del encargo: sin panel adversarial, el gap de
  justificación se habría declarado inexistente.
- `retornarVotacionesXProyectoLey` dio HTTP 500 con `prmBoletin`/`prmProyectoLeyId`;
  el parámetro correcto (`prmNumeroBoletin`) se halló leyendo la firma en `?op=`.
- `retornarSesionesXLegislatura` con un id de legislatura tentativo (105) devolvió 0
  sesiones; no bloqueó (XAnno cubre el universo). No verifiqué el id correcto de
  legislatura para ese endpoint (menor).
- Las sondas de catálogo con `xpath_item="//*"` producen una unión ruidosa de paths
  (cosmético); las entidades clave usan xpaths específicos y quedan limpias.

## 8. Notas para el revisor

- La distinción "GAP" vs "confirmado NO" es deliberada: GAP = la fuente lo da y el
  pipeline no; confirmado NO = la fuente no lo expone (verificado adversarialmente,
  no heredado de un doc).
- Ninguna cifra se reporta sin recuento programático en el momento: el 31.5% se
  recontó sobre `votos.rds`; los campos-gap se re-verificaron en vivo antes de
  commitear.
- Este encargo NO corrige el pipeline: es inventario para decidir. Las implicancias
  sobre las 8 preguntas del contrato están marcadas, no resueltas.

## 9. Archivos nuevos (entregables)

- `30_procesamiento/31f_auditar_cobertura_camara.R`
- `50_documentacion/activa/auditoria_cobertura_camara.md`
- `50_documentacion/andamios/muestras/camara_*.xml` + `camara_catalogo_*.html`
- `50_documentacion/andamios/logs/20260710_cobertura_camara_log.md` (este)

Nota: el working tree traía cambios previos ajenos (estructura/backlog/decisiones/
traspasos y archivos de encargos); no se tocaron ni se incluyen en los commits.
