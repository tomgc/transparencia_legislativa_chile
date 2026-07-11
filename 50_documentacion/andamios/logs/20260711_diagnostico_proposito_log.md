# Log de ejecución — Diagnóstico de propósito (brecha promesa↔entrega)

**Fecha:** 2026-07-11
**Rama:** `explore/diagnostico-proposito` (desde `explore/cobertura-camara`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `xml2` + `jsonlite`.
**Naturaleza:** andamio congelado (diagnóstico, no se actualiza).

## 1. Resumen

Se midió la brecha entre lo que el portal promete (objetivo del proyecto) y lo que
entrega. Hallazgo central de la Fase 1: **NO hay datos erróneos ni incompletos
publicados por el join** — el join autoritativo (490 boletines, 0 fallos) clasifica
las 672 votaciones en (d)=460 confirmadas, (c)=0 erróneas, (a)=0 incompletas,
(b)=212 estructurales; suma 672. El 31,5 % sin boletín es 100 % estructural
(Resolución/Acuerdo/Otros), confirmando —con evidencia autoritativa— la conclusión
v03 y **contradiciendo la hipótesis del encargo** (el join no recupera ninguna).
Fases 2-4 cuantifican el resto. Un panel de dos agentes re-derivó las cifras y aportó
hallazgos que yo no había medido (materias, recorte a 16 votos, y —perseguido— el
desync intermedio↔publicado). No se tocó producción.

## 2. Inventario de commits

| Fase | Tipo | Contenido |
|------|------|-----------|
| 1 | feat | `31g_diagnostico_proposito.R` + muestras (mapa autoritativo, comisión, territorio BCN) |
| 2 | docs | `diagnostico_proposito.md` (Fases 1-4 + panel + tabla de brechas) + este log |

(Hashes en el reporte al chat.)

## 3. Cifras clave (todas recontadas en el momento)

- **Fase 1 (join, 490 boletines, 0 fallos):** d=460, c=0, a=0, b=212 (suma 672). Mapa
  autoritativo guardado en `andamios/muestras/f1_mapa_votacion_boletin.rds`.
- **Fase 2:** distrito/region nulos 155/155; votos ilegibles 27 974/84 927 (32,9 %),
  mediana por diputado 0,351; materias 0/1311 proyectos y 1737/56 953 votos (3 %);
  asistencia publicada n_sesiones [43,61], 85/155 <61; consistencia índice↔perfiles
  0/155; integridad 0/0.
- **Fase 3:** el frontend usa la mayoría de campos, no usa `fecha_nacimiento`/`alias`;
  columna+filtro Región 100 % "Sin dato"; degradación honesta (`|| '—'`), documentada.
- **Fase 4a:** `retornarComision` → membresía con `Diputado/Id` (cruzable); asistencia
  a comisión no confirmada (comisiones muestreadas con 0 sesiones 2025/2026).
- **Fase 4b:** territorio — camara.cl (cruce perfecto por id, WAF/403), SERVEL (por
  nombre), datos.bcn.cl (SPARQL accesible, ontología por aprender), WSComun (sin
  vínculo diputado). Ninguna es a la vez accesible por máquina Y cruzable por id.

## 4. Hallazgos que NO estaban en el plan (perseguidos)

- **Desync intermedio↔publicado:** `asistencia.rds` on-disk (máx 58, 11:58) ≠
  `docs/data` publicado (máx 61, 16:13); 155/155 perfiles difieren; `votos.rds` sí
  coincide. Los intermedios están gitignored → reflejan la última corrida local,
  desincronizada del publish commiteado. `run_all(only=39)` hoy republicaría con
  asistencia stale. Toca producción (reproducibilidad). # REVISAR del titular.
- **Materias casi ausentes** (0 %/3 %) y **recorte a 16 votos** en la UI: aportados por
  el agente ciudadano, verificados por mí.

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (toda inspección, incl. .json/.html/.rds, en R) | PASA | 31g y toda verificación en R; bash solo git; filtrado de git status en R |
| Solo lectura sobre producción (32-36, 39, config, 40_salidas, docs) | PASA | ningún archivo de producción modificado |
| Muestras a `andamios/muestras/`, nunca a `20_insumos/` | PASA | `writeBin`/`saveRDS` a andamios |
| Llaves como character (boletín, votacion_id, diputado_id) | PASA | `como_llave` en el join; comparaciones character |
| No decidir metodología; solo medir y marcar | PASA | tabla de brechas sin recomendaciones; Fase 4 sin decisión |
| Cortesía con la fuente (backoff 429/500, Sys.sleep) | PASA | `req_retry` transitorio + `Sys.sleep(0.35)`; 0 fallos en 490 llamadas |
| CORTE_FECHA no alterada | PASA | 31g no la toca |

## 6. Qué costó / lo que fallé a la primera / lo que el panel corrigió

- **El join completo son 490 llamadas** (~4 min con pausas). Cero fallos de la fuente
  (cortés). La hipótesis del encargo (el join recupera parte del 31,5 %) resultó
  **falsa**: recupera 0. Lo reporté como el dato medido, no como fracaso.
- **Fallé a la primera en la asistencia:** reporté el rango [18,58] del intermedio
  on-disk sin notar que NO era el publicado. Perseguir la discrepancia (un perfil con
  61 > máx intermedio 58) destapó el desync — el hallazgo de mayor sorpresa del encargo.
  Lección repetida de la auditoría previa: no confiar en un artefacto sin verificar de
  qué corrida viene.
- El **agente ciudadano** midió materias y el recorte a 16 votos, brechas de producto
  que mi barrido técnico no había cuantificado.
- El escape `\.` en `Rscript -e` vuelve a romper en zsh; se resolvió escribiendo los
  scripts a archivo (patrón ya conocido del proyecto).

## 7. Pendientes abiertos / # REVISAR (del titular, no resueltos aquí)

- Desync intermedio↔publicado (reproducibilidad): ¿re-generar los intermedios al
  corte publicado antes del próximo `only=39`?
- Territorio: elegir fuente (trade-off id-cruzable vs accesible).
- Comisiones / justificación de inasistencia / asistencia por sesión: recuperables por
  pipeline; decisión de alcance.

## 8. Notas para el revisor

- Ninguna cifra sin recuento programático en el momento. El desync se verificó cruzando
  id por id (155/155) y con mtimes.
- El diagnóstico NO corrige nada: es inventario para decidir. La tabla de brechas
  distingue causa (fuente/pipeline/frontend/diseño) y si toca producción.

## 9. Archivos nuevos (entregables)

- `30_procesamiento/31g_diagnostico_proposito.R`
- `50_documentacion/activa/diagnostico_proposito.md`
- `50_documentacion/andamios/muestras/{f1_mapa_votacion_boletin.rds, camara_retornarComision_muestra.xml, territorio_bcn_persona_muestra.txt}` (la muestra de sesiones de comisión no se generó: las comisiones muestreadas devolvieron 0 sesiones)
- `50_documentacion/andamios/logs/20260711_diagnostico_proposito_log.md` (este)

Nota: el working tree traía cambios previos ajenos; no se tocaron ni se incluyen.
