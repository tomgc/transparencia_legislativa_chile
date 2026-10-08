# Log de ejecución — Fix de la clave de caché (codificar el tope)

**Fecha:** 2026-07-09
**Rama:** `fix/cache-key-tope` (desde `main` 7fb9852; sin push).
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Salda la deuda técnica del pendiente 2 del traspaso v02: `con_cache()` armaba la
ruta del snapshot sin codificar el tope de extracción (`MAX_*_DETALLE`), que se
aplica DENTRO de `fn_descarga` (después de la decisión de caché). Cambiar un tope
y re-correr el mismo día reutilizaba el snapshot con el tope viejo (cobertura
silenciosamente incorrecta). Se codificó el tope en la clave, se migraron los
snapshots de producción del año completo al esquema nuevo, y se demostró
empíricamente que el bug ya no ocurre. Producción intacta (155/155, testigo 872).
Dos commits atómicos (FASE C no genera artefactos versionables). Sin push.

## 2. Inventario de commits

| Fase | Hash | Tipo | Título |
|------|------|------|--------|
| A | `3cd00a2` | fix | clave de cache codifica el tope de extraccion |
| B | `7bd2297` | chore | migrar snapshots de produccion al esquema de clave con tope |
| C | (sin commit) | — | verificación con snapshot de debug, luego limpiado |
| D | (este log) | docs | log de la sesión |

## 3. Cambio de firma de con_cache y formato del sufijo

`con_cache(nombre_cache, fn_descarga, tope = NULL, origen = "cache")` — nuevo
parámetro `tope`, posición 3 (antes de `origen`). Como los 4 call-sites pasan
`origen` por nombre, el orden posicional no rompe nada.

Helper `sufijo_tope(tope)`:

| tope | sufijo | ejemplo de ruta |
|------|--------|-----------------|
| `NULL` | `""` (retrocompatible) | `20260709_votos_long_2026.rds` |
| `Inf` | `_tope-inf` | `20260709_votos_long_2026_tope-inf.rds` |
| `n` (finito) | `_tope-<n>` | `20260709_votos_long_2026_tope-120.rds` |

Call-sites: 33 pasa `MAX_SESIONES_DETALLE`, 34 `MAX_VOTACIONES_DETALLE`, 35
`MAX_PROYECTOS_DETALLE`. 32 (diputados) NO lleva tope → sufijo vacío
(retrocompatible). No se tocó la lógica de refrescar ni la escritura atómica.

Verificación FASE A (unit test en R, sin red): `sufijo_tope(Inf)="_tope-inf"`,
`(120L)="_tope-120"`, `(NULL)=""`.

## 4. Snapshots migrados (viejo → nuevo)

Determinación del tope **con certeza** (no adivinado), por cobertura real
contrastada con el año completo y con el intermedio publicado:

| Snapshot | Cobertura real | Tope | Acción |
|----------|----------------|------|--------|
| `20260706_asistencia_long_2026.rds` | 58 sesiones con datos (= 59 celebradas − 1 sin asistencia; `MAX_SESIONES` siempre Inf; max n_sesiones del intermedio = 58, coincide) | Inf | → `..._tope-inf.rds` |
| `20260706_votos_long_2026.rds` | 672 votaciones (año completo) | Inf | → `..._tope-inf.rds` |
| `20260706_proyectos_long_2026.rds` | 218 boletines (mociones Cámara, año completo) | Inf | → `..._tope-inf.rds` |
| `20260706_diputados.rds` | roster; `con_cache` sin tope | — | **no migrado** (sufijo vacío) |

**Ninguno ambiguo** → la regla de detención (b) no se gatilló. La migración solo
cambia el NOMBRE; el contenido es idéntico (renombre, `file.rename`, con chequeo
de que el destino no existiera).

## 5. Verificación FASE C (el bug ya no ocurre)

Corrida de debug aislada (no producción): `con_cache("votos_long_2026", fn,
tope = 5L)` con descarga capada en 5 votaciones. Evidencia:
- Ruta para `tope=Inf` hoy (`20260709_..._tope-inf.rds`) ≠ ruta para `tope=5`
  (`20260709_..._tope-5.rds`) → **rutas distintas** → un cambio de tope no
  reutiliza el snapshot viejo.
- Se creó `20260709_votos_long_2026_tope-5.rds` con **5** votaciones (≤5).
- El `..._tope-inf.rds` de HOY **no** existe (no se re-descargó producción).
- El snapshot de producción `20260706_votos_long_2026_tope-inf.rds` quedó intacto.

**Limpieza (obligatoria):** se borró el snapshot de debug `..._tope-5.rds`. No se
tocó ninguna constante de tope (el 5 se pasó directo a `con_cache`, no vía
config), así que no hubo constantes que restaurar. Estado final de
`20_insumos/camara/`: solo producción (3 × `_tope-inf` + `diputados`).

## 6. Producción intacta

`run_all(only = 39)` (lee intermedios congelados, NO re-extrae): 155 perfiles,
índice 155, tendencia null=25, testigo 872 (Jaime Mulet) = 672 votos / 9
proyectos. La rotación de timestamps `generado` del JSON regenerado se descartó
(no se commiteó; el commit de FASE B es solo los renombres de snapshots).

## 7. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (pipeline + verificación) | PASA | fix, migración, debug y verificación en R; 0 Python |
| Llaves character; escritura atómica | PASA | `con_cache` conserva `escribir_atomico`; sin cambios de tipo |
| No cambiar conteos de producción | PASA | snapshots solo renombrados; 155/155, testigo 872 intacto |
| No re-descargar salvo debug FASE C (tope pequeño) | PASA | solo 6 llamadas de debug (lista + 5 detalles); producción no tocada |
| No alterar tendencia/frontend/JSON de salida | PASA | JSON churn descartado; frontend no tocado; tendencia null=25 |
| No push, no PR | PASA | 2 commits locales en la rama fix |

## 8. Pendientes y # REVISAR

- **# REVISAR (date-stamping de la clave):** `con_cache` usa `Sys.Date()` en la
  clave, así que los snapshots del 2026-07-06 NO se reutilizan hoy (2026-07-09):
  la clave incluye la fecha. La migración de nombres es por consistencia del
  esquema y provenance, no habilita cache-hit hoy (fecha distinta). El fix del
  tope resuelve la reutilización SILENCIOSA con tope distinto EL MISMO DÍA, que
  era el bug reportado. Si se quisiera reutilizar snapshots entre días habría que
  repensar el date-stamping (fuera de alcance).
- El resto del pipeline (32) y otros `con_cache` sin tope siguen retrocompatibles.

## 9. Notas para el revisor

- La firma de `con_cache` cambió (nuevo `tope` en posición 3); todos los
  call-sites del repo usan `origen=` por nombre, así que la compatibilidad
  posicional se mantiene. Un `con_cache(x, fn, "algo")` posicional de 3 args
  (si existiera) ahora bindearía `tope="algo"` — no hay ninguno así en el repo.
- FASE C no produce artefactos versionables (snapshot de debug borrado); su
  evidencia vive en este log.
- La rama parte de `main`; los cambios de las ramas `feature/contenido-legible`
  y `explore/contenido-proyectos-votos` no están aquí. Si esas se mergean a main
  primero, este fix (y su call-site 36, que también debería pasar
  `tope = MAX_PROYECTOS_DETALLE` si aplica) tendría que reconciliarse — # REVISAR
  al integrar: el paso 36 de la feature branch usa `con_cache` sin tope para
  `detalle_proyectos`; evaluar si conviene codificar su tope también.
