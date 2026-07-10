# Log de ejecución — Corte temporal explícito + actualización semanal

**Fecha:** 2026-07-10
**Rama:** `feature/corte-temporal-explicito` (desde `main` d704eab; sin push).
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Reemplaza `Sys.Date()` por un corte temporal EXPLÍCITO (`CORTE_FECHA`) en la
clave de caché, para que el refresh sea reproducible entre días (misma clave →
cache-hit, sin re-descarga ni drift; el corpus de la API crece día a día). Añade
el procedimiento de actualización semanal (manual en Positron, con esqueleto de
un futuro GitHub Actions marcado "no ejecutar aún") y un script de diff de
conteos como compuerta previa a publicar. Cuatro commits atómicos. Producción
intacta: `only=39` reproduce los 155 perfiles idénticos (salvo timestamp) con
los conteos de cierre v03. Sin push (no hay remoto). Pendiente 1 del traspaso v03.

## 2. Inventario de commits

| Fase | Hash | Tipo | Título |
|------|------|------|--------|
| 1 | `3765dbf` | feat | CORTE_FECHA reemplaza Sys.Date() en clave de cache |
| 2 | `e1af2b9` | chore | migrar snapshot de detalle al corte canonico 2026-07-06 |
| 3 | `e5c4fdd` | docs | procedimiento de actualizacion semanal |
| 4 | `a0d0c9c` | feat | script de diff de verificacion pre-publicacion |

## 3. Detalle por cambio

### 3.1 CORTE_FECHA (Fase 1)
- `10_configuracion.R`: constante `CORTE_FECHA <- "2026-07-06"` (AAAA-MM-DD,
  character), sin default silencioso; comentario que explica el rol; nota del
  tope actualizada (ya no # REVISAR: la clave codifica tope + corte).
- `10_utils.R`: `corte_para_clave()` valida (formato AAAA-MM-DD; `stop()` claro
  si falta/vacía/inválida) y devuelve la forma compacta AAAAMMDD; `con_cache`
  la usa en vez de `Sys.Date()`.
- `00_run_all.R`: valida el corte al INICIO de `run_all()`
  (`invisible(corte_para_clave())`), no a mitad de pipeline; loguea el corte.
- Verificación: dos `run_all(only=34)` consecutivos → cache-hit, mtime del
  snapshot sin cambio (sin re-descarga); `stop()` claro al inicio sin corte.

### 3.2 Migración de snapshots (Fase 2 — decisión, ver §6)
- Único rename: `20260709_detalle_proyectos_2026_tope-inf.rds →
  20260706_...` (corte canónico único 2026-07-06). Los demás ya estaban en
  20260706. Verificación: `only=39` reproduce perfiles idénticos; `only=36`
  cache-hit del detalle (317/317, sin re-descarga).

### 3.3 Procedimiento semanal (Fase 3)
- `50_documentacion/activa/procedimiento_actualizacion.md`: 5 pasos manuales
  (respaldar JSON, fijar CORTE_FECHA, `run_all()`, diff de conteos ANTES de
  publicar, commit `data: refresh corte AAAA-MM-DD`) + esqueleto de GitHub
  Actions marcado "NO EJECUTAR AÚN — pendiente 2" (sin crear .yml).

### 3.4 Script de diff (Fase 4)
- `10_utils/10_diff_conteos.R`: `diff_conteos_json(dir_a, dir_b)` compara
  perfiles/votaciones/mociones/split con-sin-proyecto entre dos versiones del
  JSON; standalone (`Rscript ... <A> <B>`) o sourced. Ubicación: `10_utils/`
  (utilidad reusable, no paso de pipeline; POLITICA 1.2.4). Verificación:
  self-diff = 0 en todos los conteos.

## 4. Bugs

Ninguno. El supuesto del encargo (con_cache usa `Sys.Date()`) se confirmó
exacto; no había una tercera dependencia de `Sys.Date()` (grep: la única en
clave de caché es `10_utils.R`; las demás `Sys.time()` son timestamps de display
en log_msg / metadatos.generado / doc de exploración / duraciones de run_all).

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (pipeline + verificación) | PASA | todo en R; 0 Python |
| Llaves de identificación character | PASA | `corte_para_clave` devuelve character; sin cambios de tipo en llaves |
| `only=39` reproduce perfiles idénticos desde intermedios congelados, sin re-descargar | PASA | 8.5s sin descarga; diff JSON vs commit = solo `generado` |
| Ningún push; no crear remoto | PASA | 4 commits locales; no se tocó origin (no existe) |
| No alterar MAPA_PARTIDO_TENDENCIA / tendencia | PASA | no se tocó; índice tendencia null=25 |
| Web estática sin CDN (grep red docs/index.html) | PASA | 0 coincidencias (docs/index.html no se tocó) |
| Rama nueva, no main | PASA | `feature/corte-temporal-explicito` |

## 6. Decisión de la Fase 2 y su porqué

**Decisión:** corte canónico ÚNICO `CORTE_FECHA = 2026-07-06` para todo el
dataset publicado; solo se renombró el snapshot de detalle (capturado 09-jul) a
ese corte. **Porqué:** el objetivo del encargo es reproducibilidad sin drift bajo
UN corte. La extracción sustantiva (votos/proyectos/asistencia, que definen los
conteos) fue el 06-jul; el detalle (título/tipo/materias) se capturó el 09-jul
pero es enriquecimiento estable de los MISMOS proyectos del 06-jul, no dato
nuevo. Etiquetar todo con corte 06-jul es honesto (el dataset es "as-of 06-jul")
y hace que un `run_all` con `CORTE_FECHA=2026-07-06` dé cache-hit en TODO, sin
re-descarga. **Alternativa descartada:** corte por-fecha-real-de-descarga (detalle
→ 09-jul), que dejaría cortes distintos y un run con un solo `CORTE_FECHA`
re-descargaría el detalle → drift, justo lo que este encargo elimina. La opción
"archivar y partir limpio" también se descartó: re-descargaría todo el corpus
(no reproducible), sin beneficio.

## 7. Auto-auditoría (código propio, no de memoria)

`only=39` sobre los intermedios congelados, conteos vs cierre v03:
- perfiles = **155** (esperado 155) — PASA
- índice tendencia null = **25** (esperado 25) — PASA
- testigo 872 n_votaciones = **672** (esperado 672) — PASA
- testigo 872 split con/sin proyecto = **460 / 212** (esperado 460/212) — PASA
- JSON regenerado vs commit = solo el timestamp `generado` (churn descartado).

## 8. Pendientes abiertos / # REVISAR

- **Pendiente 2 (fuera de este encargo):** no hay remoto (`origin` no existe);
  la migración a GitHub y el workflow de Actions (esqueleto ya documentado en el
  procedimiento) dependen de ese paso.
- **Refresh real a un corte nuevo:** este encargo dejó el mecanismo y la
  reproducibilidad del corte 2026-07-06; el primer refresh a un corte posterior
  (que SÍ re-descarga y cambia conteos, esperado) lo ejecuta el titular con el
  procedimiento. El diff de conteos es la compuerta.
- El script de diff compara TOTALES; no hace diff por-diputado (un cambio
  compensado —un diputado sube, otro baja, mismo total— no lo detectaría). Para
  el objetivo de sanidad pre-publicación (detectar caídas/saltos globales) es
  suficiente; un diff por-id sería una mejora futura.

## 9. Notas para el revisor

- `CORTE_FECHA` es el único parámetro que el titular edita en cada refresh
  semanal; el resto es `run_all()`.
- La verificación de reproducibilidad (`only=39` = perfiles idénticos) NO
  depende de la decisión de Fase 2 (lee intermedios, no snapshots); se verificó
  igual y pasa.
- Los snapshots quedaron todos bajo el corte 2026-07-06; un `run_all()` completo
  HOY con ese corte daría cache-hit en todo (sin re-descarga). Un corte nuevo
  re-descargaría (refresh real).
