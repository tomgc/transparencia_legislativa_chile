# Log de ejecución — P-58: resolución de los dos PRs abiertos, por hunk

- **Encargo:** `50_documentacion/andamios/50_encargo_p58_resolucion_prs.md`
- **Sesión:** 16. **Fecha de ejecución:** 2026-08-06.
- **Resultado:** `main` publicando el contrato de asistencia ya retirado, con el corte
  `2026-08-03` del bot. 0 PRs abiertos. Sin regeneración del pipeline.
- **Commits producidos:** `97bd816` (merge PR #3), `ade2882` (merge de `origin/main` en
  la rama de retiro, resuelto por hunk), `cc98e45` (merge PR #4).

---

## 1. Estado inicial (Fase 0)

| Qué | Valor | Fuente |
|---|---|---|
| Rama activa | `main`, al día con `origin/main` en `c083dcc` | `git status`, `git branch -vv` |
| PRs abiertos | 2 | `gh pr list -R tomgc/... --state open --json number,title,headRefName,baseRefName,mergeable` |
| PR #4 | `retiro/contrato-legacy-asistencia` → `main`, `MERGEABLE` | ídem |
| PR #3 | `refresh/2026-08-03` → `main`, `UNKNOWN` | ídem |
| `CORTE_FECHA` vigente | `"2026-07-27"`, en `10_utils/10_configuracion.R` **línea 41** | `grep -n CORTE_FECHA` sobre el archivo en disco |
| Árbol de trabajo | limpio salvo 2 untracked reconocidos: `.claude/settings.local.json` y el propio encargo | `git status` |

**Corrección a una premisa del encargo (Fase 0.4).** El encargo afirmaba que los commits
`25a579f` y `53d78b5` seguían locales. Medido: **ya estaban pusheados**.
`git rev-list --left-right --count origin/retiro/...  ... retiro/...` devuelve `0 0`, y
`git branch -r --contains` ubica ambos en `origin/retiro/contrato-legacy-asistencia`. No
alteró el plan: solo hizo que el push de la Fase 5.1 subiera únicamente el merge nuevo.

**Compuerta 0: PASA.** 2 PRs, ramas esperadas, sin cambios no reconocidos.

---

## 2. Resumen de conteos del PR del bot (Fase 1), reproducido

Del cuerpo del PR #3 (fuente: `gh pr view 3 -R tomgc/... --json body`):

```
Comparacion de conteos JSON
  A (previo): /home/runner/work/_temp/json_previo
  B (nuevo):  40_salidas/json

conteo                   A (previo)    B (nuevo)  diff (B-A)
------------------------------------------------------------
perfiles                        155          155          +0
votaciones                    96397        96397          +0
mociones                       1625         1625          +0
votos_con_proyecto            65478        65478          +0
votos_sin_proyecto            30919        30919          +0
------------------------------------------------------------
Sin diferencias de conteo (JSON equivalentes en totales clave).
```

**Lectura (no del gate, del ejecutor):** los cinco conteos son idénticos, `+0` en todos.
No hay caída de volumen ni cambio de sentido; es el patrón esperable de un refresh que
mueve el corte sin que la fuente haya agregado sesiones o votaciones nuevas en la ventana.
Conforme → se mergeó.

**Compuerta 1: PASA.** `origin/main` avanzó `c083dcc` → `97bd816`, y
`CORTE_FECHA <- "2026-08-03"` leído de `origin/main:10_utils/10_configuracion.R` línea 41
(`git show origin/main:10_utils/10_configuracion.R | grep -n "^CORTE_FECHA"`).

---

## 3. Medición del conflicto ANTES de resolver (Fase 2)

`git -C <raíz> merge origin/main` sobre `retiro/contrato-legacy-asistencia` falló con
conflictos, como estaba previsto. Se midió sin resolver nada, con `medir_conflicto()` en R
sobre las rutas de `git diff --name-only --diff-filter=U`.

**Denominador: 310 archivos en conflicto.**

| Medición | Valor | Denominador |
|---|---|---|
| `n_hunks == 1` | 310 | 310 |
| `ok_forma` (1 `<<<<<<<`, 1 `=======`, 1 `>>>>>>>`) TRUE | 310 | 310 |
| `solo_generado` (todo el cuerpo del hunk es la línea `"generado"`) TRUE | 310 | 310 |
| en `40_salidas/json/perfiles/` | 155 | 310 |
| en `docs/data/perfiles/` | 155 | 310 |

Tabla de frecuencias de `n_hunks`: un único nivel, `1`, con 310 observaciones.

`stopifnot()` pasó sobre los 310. La premisa del encargo (un solo hunk por archivo, y ese
hunk es `metadatos.generado`) queda **confirmada por medición de esta sesión**, no
heredada de la sesión 15.

**Compuerta 2: PASA.**

---

## 4. Criterio de resolución del hunk (Fase 3), declarado

Dentro de cada hunk se **conserva el lado de `origin/main`** — el bloque entre `=======` y
`>>>>>>>`, es decir el timestamp `generado` del bot, coherente con el `corte_fecha` y la
`nota` que ya habían mergeado limpio. **Todo lo demás del archivo queda exactamente como
el merge lo dejó**, de modo que el retiro de los cinco campos legacy sobrevive intacto.

La operación se hizo archivo por archivo con `resolver_hunk_generado()` en R, reescribiendo
solo las líneas del hunk. **No se usó ninguna resolución a nivel de archivo**: cero
`git checkout --ours`, `--theirs`, `git checkout <rama> -- <ruta>` ni `git restore --source`
(aprendizaje A55: cualquiera de ellas habría reinstalado la versión íntegra del bot con los
cinco campos legacy en 310 de 310).

Verificación posterior en R: **0 archivos con marcador residual, sobre 310**.
`git add` con `--pathspec-from-file` sobre las 310 rutas exactas (nunca `.` ni `-A`).
`git status` sin rutas en estado `U`. Commit del merge: `ade2882`.

**Compuerta 3: PASA.**

---

## 5. Corrección de ruta en la verificación 3 (decisión en autonomía)

El encargo pide verificar `metadatos.corte_fecha`. **Ese campo no existe en esa ruta.**
Medido en R sobre los 310 perfiles: el bloque `metadatos` tiene exactamente
`{fuente, periodo, anio_proceso, generado}` en **310 de 310** (firma única en `table()`), y
la misma firma aparece en `origin/main`, en `97bd816` y en `c083dcc` — nunca llevó
`corte_fecha`.

Búsqueda de la clave a cualquier profundidad del árbol JSON: `corte_fecha` está presente en
**310 de 310** perfiles, y `nota` también, ambas bajo
**`asistencia.alcance_temporal`**. Los dos índices no la exponen en ninguna parte
(`corte_fecha` presente en el árbol: `FALSE`, en las dos copias).

**Decisión:** se mide `asistencia.alcance_temporal.corte_fecha`, que es exactamente la
magnitud que V3 quiere medir, y se declara **no aplicable** la parte relativa a los
índices, con la evidencia de su ausencia. No se cambió ningún dato ni se relajó el criterio:
se corrigió la dirección del enunciado. La invariante 10 del encargo, que trata
`corte_fecha` y `nota` como no volátiles y verificables, sigue cumpliéndose en su ruta real.

---

## 6. Las cinco verificaciones, dos veces

Ejecutadas con el mismo script en R (`jsonlite`, `purrr`, `tools::md5sum`), cada una
terminando en `stopifnot()`.

### 6.1 Sobre la rama `retiro/contrato-legacy-asistencia`, post-merge, pre-push (`ade2882`)

| # | Qué mide | De qué artefacto sale | Cifra | Denominador |
|---|---|---|---|---|
| V1 | perfiles que contienen alguno de los 5 campos legacy (`anio`, `n_sesiones`, `n_asiste`, `n_no_asiste`, `tasa_asistencia`) dentro del bloque `asistencia` | 155 `.json` de `40_salidas/json/perfiles/` + 155 de `docs/data/perfiles/` | **0** | 310 |
| V2a | entradas del índice con la clave `tasa_asistencia` | `40_salidas/json/indice_diputados.json` | **0** | 155 |
| V2b | entradas del índice con la clave `tasa_presencia` | `40_salidas/json/indice_diputados.json` | **155** | 155 |
| V2c | ídem V2a | `docs/data/indice_diputados.json` | **0** | 155 |
| V2d | ídem V2b | `docs/data/indice_diputados.json` | **155** | 155 |
| V3a | `CORTE_FECHA` declarado | `10_utils/10_configuracion.R` línea 41 | **`2026-08-03`** | 1 |
| V3b | perfiles cuyo `asistencia.alcance_temporal.corte_fecha` es igual a ese valor | los 310 perfiles | **310** (un único valor distinto) | 310 |
| V3c | índices que exponen `corte_fecha` | los 2 `indice_diputados.json` | **0** → no aplica | 2 |
| V4 | artefactos de `docs/data/` con md5 idéntico a su par en `40_salidas/json/` | 155 perfiles + 1 índice | **156**, en md5 **crudo** | 156 |
| V5 | perfiles con las 4 claves sobrevivientes (`alcance_temporal`, `periodo_vigente`, `en_ejercicio`, `sesiones`) en `asistencia` | los 310 perfiles | **310** | 310 |

Nota sobre V4: el encargo preveía tener que excluir `metadatos.generado` por ser volátil.
**No hizo falta**: los md5 crudos ya cuadran 156 de 156, porque el bot generó ambas copias
en la misma corrida y con el mismo timestamp por archivo. Se reporta la comparación más
fuerte, no la degradada.

**Compuerta 4: PASA.**

### 6.2 Sobre `main` ya mergeado (`cc98e45`) — la única que mide lo publicado

Mismo script, mismas rutas, mismo denominador. Resultado **idéntico celda por celda** a la
tabla de 6.1:

| # | Cifra sobre `main` | Denominador |
|---|---|---|
| V1 | **0** perfiles con campos legacy | 310 |
| V2 | **0** con `tasa_asistencia` y **155** con `tasa_presencia`, en cada uno de los 2 índices | 155 c/u |
| V3 | `CORTE_FECHA` = `2026-08-03` (línea 41) y **310** perfiles con ese corte, valor único | 310 |
| V4 | **156** artefactos con md5 idéntico entre `docs/data/` y `40_salidas/json/` | 156 |
| V5 | **310** perfiles con las 4 claves de Capa 3 | 310 |

**Compuerta 5: PASA.**

---

## 7. Criterios de éxito (§4 del encargo)

| # | Criterio | Medida obtenida | Artefacto / comando | Estado |
|---|---|---|---|---|
| 1 | `main` sin campos legacy | 0 de 310 perfiles con alguno de los cinco campos en `asistencia` | `40_salidas/json/perfiles/*.json` + `docs/data/perfiles/*.json`, vía `jsonlite::fromJSON` | **CUMPLE** |
| 2 | Índice coherente | 0 entradas con `tasa_asistencia`; 155 con `tasa_presencia`, en cada índice | `40_salidas/json/indice_diputados.json`, `docs/data/indice_diputados.json` | **CUMPLE** |
| 3 | Corte del bot publicado | `asistencia.alcance_temporal.corte_fecha` = `2026-08-03` en 310 de 310, igual al `CORTE_FECHA` de `10_utils/10_configuracion.R:41` en `main` | ídem + lectura del archivo de configuración | **CUMPLE** (ruta corregida, §5) |
| 4 | Espejo íntegro | 156 de 156 artefactos con md5 idéntico, **sin necesidad de excluir** `metadatos.generado` | `tools::md5sum` sobre los 156 pares | **CUMPLE** |
| 5 | Contrato de Capa 3 intacto | 4 claves presentes en 310 de 310 perfiles (155 de 155 en cada copia) | los 310 `.json` de perfil | **CUMPLE** |
| 6 | Sin regeneración | 0 corridas de los scripts 32-36 y 39 | ningún `Rscript 30_procesamiento/*` ni `run_all()` en la sesión | **CUMPLE** |
| 7 | Sin resolución por archivo | 0 usos de `checkout --ours/--theirs/<rama> -- <ruta>` ni `restore --source` | resolución hecha con `resolver_hunk_generado()` en R | **CUMPLE** |
| 8 | PRs cerrados | `gh pr list -R tomgc/... --state open --json number,title` devuelve `[]` | ídem | **CUMPLE** |

---

## 8. Decisiones tomadas en autonomía

1. **V3 se midió en `asistencia.alcance_temporal.corte_fecha`**, no en `metadatos.corte_fecha`: el segundo no existe en el contrato real del perfil (medido en 310 de 310 y en tres commits históricos), el primero sí y es la misma magnitud (§5).
2. **La parte de V3 relativa a los índices se declaró no aplicable**, con evidencia medida de que ninguno de los dos expone `corte_fecha` en ninguna parte de su árbol — el índice es un array plano de 155 entradas sin bloque de metadatos.
3. **V4 se reportó en md5 crudo (156 de 156)** en vez de la comparación clave a clave con `metadatos.generado` excluido: la comparación fuerte pasó, así que no se degradó a la débil.
4. **No se corrigió la premisa desactualizada de la Fase 0.4** (los dos commits ya estaban pusheados): se reportó y se siguió, porque no cambiaba ningún paso.
5. **El push de la Fase 5.1 se ejecutó tal cual** aunque solo subía el merge nuevo (`53d78b5..ade2882`), no los dos commits que el encargo creía locales.
6. **Se esperó a que GitHub recalculara `mergeable` del PR #4`** (primera consulta devolvió `UNKNOWN`, la segunda `MERGEABLE`/`CLEAN`) en vez de mergear a ciegas.

---

## 9. Fuera de alcance, no ejecutado

Conforme al §6 del encargo: no se tocó el workflow de GitHub Actions, no se disparó
`workflow_dispatch`, no se descargó nada de la API de la Cámara, no se borró ninguna rama
(la poda queda como decisión del titular: `retiro/contrato-legacy-asistencia` y
`refresh/2026-08-03` siguen existiendo), no se verificó la republicación de Pages, y no se
tocó `20_insumos/` salvo por los `.rds` del corte que trajo el propio merge del bot.
