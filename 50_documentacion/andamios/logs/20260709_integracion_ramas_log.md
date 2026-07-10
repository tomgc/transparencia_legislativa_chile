# Log de ejecución — Integración de ramas a main

**Fecha:** 2026-07-09 (cierre 2026-07-10)
**Rama destino:** `main`
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Integración de tres ramas vivas a `main` (desde 7fb9852), en orden definido:
cache-fix → contenido-legible (reconciliando el paso 36) → explore (docs). Todos
los merges `--no-ff`. El único punto que git NO reconcilia solo (inconsistencia
semántica) se corrigió a mano: el paso 36 llamaba `con_cache` sin pasar tope
mientras 33/34/35 ya lo pasaban. Verificación end-to-end: `run_all(only = 39)`
regenera los perfiles idénticos a los del merge (solo cambia el timestamp
`generado`), con producción intacta (155/155, testigo 872 = 672 votos / 9
proyectos). Sin push. Ramas no borradas (decisión del titular).

## 2. Inventario de merges y commits

| Fase | Hash | Tipo | Qué |
|------|------|------|-----|
| 1 | `bff1b8d` | merge --no-ff | fix clave de cache codifica el tope (rama `fix/cache-key-tope`) |
| 2 | `4477526` | merge --no-ff | contenido legible y trazabilidad (rama `feature/contenido-legible-trazabilidad`) |
| 2 (fix) | `f46c539` | fix | 36 codifica el tope en la clave de cache (reconciliación semántica) |
| 3 | `457e417` | merge --no-ff | diagnóstico y muestras (rama `explore/contenido-proyectos-votos`) |
| 5 | `71ff7c3` | docs | versionar logs de contenido y cache |

## 3. Qué reconcilió git solo vs qué corregí a mano

**Git solo (auto-merge sin conflicto de texto):**
- `10_utils.R`: el parser `parsear_contenido_proyecto` (contenido-legible) y la
  nueva firma `con_cache(..., tope = NULL, ...)` + `sufijo_tope` (cache-fix) viven
  en zonas distintas del archivo → auto-merge limpio. Verificado post-merge:
  ambos aportes presentes (líneas 110 `sufijo_tope`, 125 `con_cache` con `tope`,
  178 `parsear_contenido_proyecto`).
- `00_run_all.R`: el paso 36 (contenido) y los cambios de 33/34/35 (cache) no
  colisionan.
- `estructura/` (explore): reemplazo del snapshot del escáner, sin conflicto.
- Ningún merge produjo conflicto de texto (regla de detención (a) no gatillada).

**Corregido a mano (lo que git no ve — inconsistencia SEMÁNTICA):**
- `30_procesamiento/36_extraer_detalle_proyectos.R`: su `con_cache` no pasaba
  tope. Se agregó `tope = Inf` (36 NO aplica un cap propio: procesa toda la
  unión congelada de boletines autorados + votados sin truncar → Inf = completo,
  el valor honesto; consistente con el esquema `_tope-inf` de 33/34/35 en
  producción). NO se pasó `MAX_PROYECTOS_DETALLE` porque 36 no lo aplica
  (procesa más que los autorados); decirlo en la clave sería falso.
- Se migró el snapshot de detalle al esquema nuevo:
  `20260709_detalle_proyectos_2026.rds → ..._tope-inf.rds` (contenido intacto).

## 4. Verificación end-to-end (post-merge)

| Check | Resultado |
|-------|-----------|
| `run_all(only = 39)` lee intermedios congelados, sin re-descargar | PASA (8.5s, `cache`/lectura de intermedios) |
| Perfiles regenerados idénticos al merge salvo `generado` | PASA (diff no-timestamp = 0 líneas) |
| Índice 155, tendencia null = 25, 155 perfiles | PASA |
| Testigo 872 = 672 votos / 9 proyectos | PASA |
| Split estructural en 872: votos con proyecto / null | PASA (460 / 212) |
| `materias` siempre array (nunca null) | PASA (0 violaciones) |
| grep de red en `docs/index.html` | 0 coincidencias |
| `docs/` completo en main (index.html + 10 woff2 + índice + 155 perfiles) | PASA |
| Churn de timestamp del JSON | descartado (no commiteado; se deja el del merge) |

**`run_all(only = 36)` — NO se ejecutó (respetando el invariante no-re-descarga).**
La fecha del sistema rodó a 2026-07-10; `con_cache` codifica la fecha, así que 36
hoy buscaría `20260710_detalle_proyectos_2026_tope-inf.rds`, y el snapshot
congelado es `20260709_..._tope-inf.rds`. Demostrado estáticamente que el
**esquema de nombre coincide** (misma clave sin la fecha) → la migración/clave es
correcta; el cache-miss es puro **date-stamping** (# REVISAR heredado del fix de
cache), NO un defecto de integración. Correr 36 re-descargaría 317 boletines
(viola el invariante). La coherencia del JSON ya quedó probada por `only = 39`
desde los intermedios congelados (que son la fuente de los perfiles publicados).

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (pipeline + verificación) | PASA | merges + verificación + fix-36 en R/git; 0 Python |
| No push, no PR | PASA | todo local; ramas no borradas |
| No cambiar conteos de producción | PASA | 155/155, tendencia null=25, 872 = 672/9; JSON idéntico salvo timestamp |
| Llaves character; escritura atómica; sin CDN | PASA | 39 conserva stopifnot/escritura atómica; grep red = 0 |
| Merges atómicos y trazables; git status antes de cada op | PASA | `--no-ff`, pathspec explícito, sin `git add .` |

## 6. Estado final de ramas

- `main` = `71ff7c3` (integra las tres ramas + fix-36 + logs).
- `fix/cache-key-tope` (`7bd2297`), `feature/contenido-legible-trazabilidad`
  (`c678898`), `explore/contenido-proyectos-votos` (`63e6d57`),
  `feature/dashboard-fase2` (`83d293d`) — mergeadas (salvo dashboard, ya en 7fb9852);
  NO borradas (decisión del titular).

## 7. # REVISAR

- **Date-stamping de la clave de caché (heredado):** `con_cache` incluye
  `Sys.Date()`. Los snapshots congelados (06/09-jul) no dan cache-hit en días
  posteriores; hoy (10-jul) `only = 36` re-descargaría. El fix del tope resolvió
  la reutilización SILENCIOSA con tope distinto EL MISMO DÍA (el bug reportado),
  no el date-stamping. Un refresh coherente del año exigiría re-correr 32-36
  (cambia el corpus, que creció: 218→228 mociones). Fuera de alcance.
- **Dependencia aguas-arriba de 36:** el conjunto de boletines de 36 depende de
  los topes de 34/35 (vía `proyectos.rds`/`votos.rds`); esa dependencia queda
  codificada en LOS snapshots de 34/35, no en el de 36. Si se cambiara un tope de
  34/35 y se re-corriera 34/35 y luego 36 el mismo día sin refrescar, 36 podría
  reusar detalle del conjunto viejo. Edge no crítico; documentado.
- **Drift del corpus:** el pipeline regenera desde la API en vivo; los
  intermedios/JSON publicados son el snapshot congelado 2026-07-06/09. Un
  `run_all()` completo hoy traería datos más nuevos (y cambiaría conteos).

## 8. Notas para el revisor

- El commit `f46c539` (fix-36) es la única corrección de código post-merge; el
  resto son merges y versionado de docs.
- La verificación crítica (`only = 39` reproduce el JSON del merge salvo
  timestamp) prueba que las tres integraciones son coherentes entre sí: el 39
  enriquecido lee los intermedios (incluido `proyectos_detalle`) y produce los
  perfiles con contenido/trazabilidad, sobre el pipeline con la clave de caché
  arreglada.
- `main` queda como fuente única con: clave de caché con tope, contenido legible
  + trazabilidad voto→proyecto (paso 36, 39 enriquecido, frontend), y el
  diagnóstico + muestras como documentación.
