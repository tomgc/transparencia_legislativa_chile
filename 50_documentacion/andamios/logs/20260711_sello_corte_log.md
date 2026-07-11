# Log de ejecución — Sello de procedencia de corte en los intermedios (Bug 1 v07)

**Fecha:** 2026-07-11
**Rama:** `fix/sello-corte-intermedios` (desde `main`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución).

## 1. Resumen

Se cierra el bug de reproducibilidad del traspaso v07 §6 (Bug 1): los intermedios
`.rds` estaban gitignored y no declaraban a qué corte pertenecían, así que un `.rds`
residuo de otra corrida podía consolidarse en silencio (39 republica mal). La
corrección añade un **sello de procedencia** (atributos embebidos en cada `.rds`,
escritos centralmente en `escribir_atomico`) y una **validación en el 39** que falla
ruidosamente (`stop()` diagnóstico) ante cualquier intermedio sin sello, con corte
distinto de `CORTE_FECHA`, o incoherente con sus hermanos. No se republicó `docs/`;
producción intacta. La lógica de negocio de los 3x/39 no cambió.

**Decisión de un tropiezo:** el enunciado decía `CORTE_FECHA = 2026-07-06`; el
archivo real dice **2026-07-10**. Usé el valor real (invariante: nunca default
silencioso) y lo reporto.

## 2. Inventario de commits

| Fase | Tipo | Contenido |
|------|------|-----------|
| 1 | feat | `10_utils.R`: `sellar`, `hash_origen_de`, `ruta_cache`, `leer_sellado`, `validar_corte`; `escribir_atomico(hash_origen=)` |
| 2 | feat | 32-36 pasan el hash del cache de origen a `escribir_atomico` |
| 3 | feat | 39 valida procedencia (`leer_sellado` + `validar_corte`) antes de todo |
| 4 | docs | este log |

(Hashes en el reporte al chat.)

## 3. Cambios sustantivos con causa raíz

- **Causa raíz:** el cache crudo (`20_insumos/camara/`) SÍ lleva sello temporal en el
  nombre (`20260706_*`, `20260710_*`), pero el intermedio derivado NO; 39 lo consumía
  sin validar procedencia. Eslabón roto: el intermedio.
- **Fix Fase 1 (`10_utils.R`):** `escribir_atomico` ahora acepta `hash_origen`; si se
  pasa, sella el objeto (`sellar`) con `{corte_fecha, anio_proceso, hash_origen,
  escrito_en}` antes de escribir. Sin `hash_origen` (default) el comportamiento es
  idéntico → la llamada del 39 que escribe TEXTO json NO se rompe. `ruta_cache`
  factoriza la construcción de la clave del cache (reusada por `con_cache`).
- **Fix Fase 2 (32-36):** cada 3x pasa `hash_origen = hash_origen_de(ruta_cache(<su
  cache_key>, <su tope>))`. Único cambio; ninguna lógica de negocio tocada.
- **Fix Fase 3 (39):** carga los 5 intermedios con `leer_sellado`, acumula sus sellos
  y llama `validar_corte(sellos, CORTE_FECHA)` ANTES del `stopifnot` de character y de
  todo join/escritura. Sin sello válido, 39 no escribe nada.

## 4. Fase 0 — Arqueología del publish (cifras recontadas)

Reproduje la agregación del 33 desde cada cache y comparé `n_sesiones` contra los 155
perfiles publicados:

| cache | n_sesiones range | perfiles que calzan |
|-------|------------------|---------------------|
| `20260706_asistencia_long` | [18, 58] | **0/155** |
| `20260710_asistencia_long` | [18, 61] | **155/155** |
| intermedio on-disk `asistencia.rds` (antes del fix) | [18, 58] | 0/155 |

Control (votos, coincidencia conocida): cache `20260710` → 155/155; `20260706` →
0/155 (mi método reproduce la coincidencia conocida → método correcto).

**Conclusión Fase 0:** el publish vigente salió del cache **20260710**, que
corresponde a `CORTE_FECHA=2026-07-10`. El publish NO está stale; el intermedio
on-disk (del cache 06) SÍ lo estaba. `run_all(only=39)` con ese intermedio habría
republicado con `n_sesiones` máx 58 (mal). Ningún caso de detención #1 (algún cache
sí reproduce el publish).

## 5. Bugs / pruebas de que el bug quedó cerrado

**Prueba de falla (criterio 2), salida REAL** — adulteré `asistencia.rds` para
declarar corte 2026-07-06 y corrí `run_all(only=39)`:

```
STOP CAPTURADO -> Paso 39 (Consolidar JSON estatico) fallo: validar_corte:
'asistencia.rds' declara corte 2026-07-06, pero el corte vigente (CORTE_FECHA) es
2026-07-10. El intermedio NO corresponde al corte publicado; regenera los pasos
32-36 con CORTE_FECHA=2026-07-10.
```

docs/data quedó intacto tras la falla (155 perfiles; 39 falla antes de escribir).
Intermedio bueno restaurado (sello corte 2026-07-10).

**Diff regenerado vs publicado (Fase 4):** con los intermedios regenerados del cache
10 (cache-hit, 0 llamadas de red), 39 pasó la validación y produjo un JSON con
`n_sesiones` [43,61] mediana 43 y tasa **idénticos** al publicado: **0/155** perfiles
difieren (antes, con el intermedio stale, 155/155 diferían). El fix restaura la
reproducibilidad de `only=39`.

## 6. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (toda inspección/verificación en R) | PASA | arqueología, prueba de falla, diff y unit-test en R; bash solo git |
| No tocar `docs/` (producción intacta) | PASA | respaldo+restauro byte-idéntico; `git status docs/` LIMPIO |
| No tocar `20_insumos/` (cache read-only) | PASA | regeneración fue cache-hit (0 escrituras a insumos); 0 red |
| `CORTE_FECHA` nunca default silencioso | PASA | `sellar`/`corte_para_clave` hacen stop() si falta; usé el valor real 2026-07-10 |
| Llaves como character (stopifnot del 39 intacto) | PASA | no debilité el stopifnot; validar_corte se suma antes |
| No alterar lógica de negocio de 3x/39 | PASA | 3x solo agregan el arg `hash_origen`; 39 solo suma la compuerta |
| here::here()/rutas existentes; sin rutas absolutas | PASA | `ruta_cache` usa `ruta_insumos`; sin rutas hardcodeadas |
| Naming snake_case sin tildes/ñ | PASA | funciones nuevas en snake_case |
| 39 falla ante intermedio adulterado | PASA | §5 (salida real) |
| `run_all(only=39)` corre con intermedios coherentes | PASA | "Procedencia validada"; diff 0/155 |

## 7. Pendientes abiertos / # REVISAR (del titular)

- **Republicar docs/**: este encargo NO republica. El diff regenerado↔publicado es
  0/155 (el publish vigente ya es correcto, del cache 10). Los intermedios on-disk
  quedaron regenerados y sellados al corte 10, así que un `only=39` futuro reproduce
  el publish. Republicar es innecesario hoy, pero es decisión del titular.
- El sello protege hacia adelante: cualquier `only=39` con un intermedio de otro corte
  ahora falla ruidoso en vez de publicar mal.

## 7b. Panel adversarial (auto-auditoría, código R independiente)

Un agente de solo lectura re-derivó las dos afirmaciones de mayor riesgo con código
propio (manifiestos md5), sin ver mis scripts. Resultado — **sin contradecirme**:
- **(a) producción byte-idéntica:** `git status`/`git diff` de `docs/` y
  `40_salidas/json` vacíos antes y después; 155 perfiles intactos. SE SOSTIENE.
- **(b) 39 falla sin escribir:** probó DOS variantes corriendo `run_all(only=39)` en
  `tryCatch` con manifiesto md5 de `docs/data`: (1) corte distinto → `stop()` de
  `validar_corte` nombrando `asistencia.rds`; (2) sin sello → `stop()` de
  `leer_sellado`. En ambas el md5 de `docs/data` quedó **idéntico** (0 escritura
  parcial; la validación precede a todo `escribir_json`/copia). Restauró
  `asistencia.rds` byte-a-byte (md5 final == original). SE SOSTIENE.

El panel reforzó la conclusión con evidencia md5 más fuerte que mi propia prueba; no
halló efecto colateral.

## 8. Notas para el revisor

- El sello viaja como `attr(objeto,"sello")` dentro del `.rds`; sobrevive
  saveRDS/readRDS. Los `.rds` intermedios están gitignored (no se versionan): el sello
  es la única fuente de verdad de su procedencia.
- La llamada del 39 que escribe JSON (texto) por `escribir_atomico` NO pasa
  `hash_origen` → no se sella texto (caso de detención #3 evitado por diseño).
- Ninguna cifra sin recuento programático en el momento.

## 9. Archivos modificados

- `10_utils/10_utils.R` (mecanismo de sello)
- `30_procesamiento/{32,33,34,35,36}_*.R` (paso del hash de origen)
- `30_procesamiento/39_consolidar_json.R` (validación de procedencia)
- `50_documentacion/andamios/logs/20260711_sello_corte_log.md` (este)

Nota: el working tree traía cambios previos ajenos; no se tocaron ni se incluyen.
