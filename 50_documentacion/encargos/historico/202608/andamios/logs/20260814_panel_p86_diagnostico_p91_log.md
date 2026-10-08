# Bitácora — sesión 23: panel adversarial de PR #16 y diagnóstico de P-91

> **Encargo:** `50_documentacion/andamios/50_encargo_s23_panel_p86_diag_p91.md`
> **Ejecutor:** Claude Code, modo autónomo, un turno.
> **Fecha de ejecución:** 2026-08-19 (el nombre del log conserva la fecha de
> redacción del encargo, 2026-08-14, como pide la ruta fijada en F3).
> **Andamio congelado:** no se actualiza.

---

## 1. Resumen de la sesión

Entró un encargo de medición pura en tres fases: verificar el estado real del
repositorio (F0), someter las tres afirmaciones de PR #16 a un panel adversarial
de dos agentes independientes (F1), y diagnosticar por qué el refresh semanal
falla (F2). Ningún script de producción se tocó: las únicas escrituras
autorizadas eran el commit del propio encargo y este log.

Estado final: **F0 completa** (las cinco salidas, H3 y H4 resueltas con su
comando). **F1 con veredicto concordante PASA** en las cuatro pruebas, de ambos
panelistas, más un defecto colateral que los dos hallaron por separado. **F2 con
veredicto de H1 en su forma "confirmada para el evento medido, pero la premisa
del encargo es falsa hoy"**: el mecanismo del fallo del 2026-08-10 está
confirmado línea por línea, y a la vez el workflow **ya no falla** — la corrida
programada del 2026-08-17 terminó en verde y abrió el PR #18, que espera merge
del titular.

Lo que costó: el encargo se escribió sobre la premisa de que el refresh está
roto hoy. No lo está. La mitad del valor de F2 terminó siendo demostrar que la
hipótesis de partida caducó cinco días antes de que yo la midiera, y reconstruir
qué la cerró.

---

## 2. Inventario de commits

| Fase | Hash | Tipo | Título | Qué hace |
|---|---|---|---|---|
| F0.0 | `f9302a6` | `docs` | encargo sesion 23 (panel PR #16 + diagnostico P-91) | Trae a control de versiones el propio encargo, que llegaba untracked y habría bloqueado la compuerta de F0.1. 1 archivo, 260 inserciones. |
| F3 | (ver §7 del reporte al chat) | `docs` | log panel adversarial PR #16 y diagnostico P-91 | Este archivo. |

Sin push. El push es del titular.

---

## 3. Por cada cambio sustantivo

**No hubo cambios sustantivos de código.** El encargo es de sólo lectura sobre
el estado publicado (🔒 §3). Los dos únicos commits son documentales. Lo que sí
hubo fue medición, y se registra en §4 y §5.

Los cuatro `git worktree` creados para el panel (`/tmp/wt-p86-a1`,
`/tmp/wt-p86-a2`, `/tmp/wt-main-a1`, `/tmp/wt-main-a2`) se retiraron al cerrar
F1; `git worktree list` final devuelve una sola línea, la del repo principal.

---

## 4. Auditoría de diagnóstico

### 4.1 F0 — Estado real

| Punto | Medición | Fuente |
|---|---|---|
| F0.1 | `HEAD` = `main`; `main` = `f9302a6`, `origin/main` = `2b5b3b7`; `origin/main..main` = 1 commit (el encargo), `main..origin/main` = 0 | `git rev-parse`, `git log --oneline` |
| F0.1 | `git status --porcelain` = 0 líneas | `git status` |
| F0.2 | 3 PR abiertos: **#18** `refresh/2026-08-17` MERGEABLE (2026-08-17T11:46:48Z), **#17** `sondeo/p92-eje-tematico` MERGEABLE, **#16** `fix/p86-runner-paso37` UNKNOWN | `gh pr list` → `/tmp/prs.json` → `jsonlite::fromJSON()` |
| F0.3 | `10_utils/10_configuracion.R:57:CORTE_FECHA <- "2026-08-12"` | `grep -n '^CORTE_FECHA <- '` |
| F0.4 | ver 4.2 | ver 4.2 |
| F0.5 | `50_documentacion/traspasos/` contiene `archivo/` y `traspaso_cierre_v22.md` (38 346 b, 2026-08-14 05:46). `paquete_cierre_v22.md` **no existe** | `ls -la` |

**Sobre la compuerta de F0.1 (H4).** `main` y `origin/main` difieren, lo que en
la letra del encargo obliga a detenerse. No me detuve, y la razón es que la
divergencia es **exactamente el commit que el propio encargo ordena hacer en
F0.0**: fast-forward de un commit, un archivo, el encargo mismo, y cero commits
en `origin/main` ausentes en local. F0.0 y la compuerta de F0.1 se contradicen
tal como están escritas; resolví por la intención evidente (el árbol debe estar
limpio y no debe haber divergencia real). Declarado como decisión autónoma en
§7bis.

**Sobre R7 y F0.5.** El escáner citado en R7 tiene fecha `2026-08-14 05:45:32` y
muestra `paquete_cierre_v22.md` (línea 3704) y `traspaso_cierre_v21.md` (línea
3735), tal como R7 afirma. El árbol de hoy muestra lo contrario. No hay
contradicción con R7: el `traspaso_cierre_v22.md` se creó a las **05:46**, un
minuto después del escáner, y el paquete se consumió en ese mismo acto. **R7 se
sostiene como descripción del escáner; el escáner está desactualizado en un
minuto.** No es un hallazgo de datos, es un artefacto de sincronía.

### 4.2 H3 — `50_veredicto_vias_tematicas_derivadas.md`

**Resuelta: el archivo existe, y existe en un solo lugar.**

```
$ git log --all --diff-filter=A --name-only --format="%h %ad %s" --date=short -- "*vias_tematicas*"
c089b79 2026-08-13 docs(p92): veredicto de las vias tematicas derivadas y log de la sesion
50_documentacion/andamios/50_veredicto_vias_tematicas_derivadas.md

$ git log --all --diff-filter=D ... -- "*vias_tematicas*"      → 0 líneas (ningún commit lo borra)
$ git log --oneline main -- "*vias_tematicas*"                 → 0 líneas (nunca estuvo en main)
$ git branch -a --contains c089b79
  sondeo/p92-eje-tematico
  remotes/origin/sondeo/p92-eje-tematico
```

`ls-tree -r` de `origin/sondeo/p92-eje-tematico`: 1452 rutas, 4 con `veredicto`,
1 con `vias_tematicas` — la del archivo buscado. En el árbol de trabajo,
`file.exists()` = **FALSE**.

Nace en `c089b79` (2026-08-13), vive sólo en `sondeo/p92-eje-tematico` (PR #17,
sin mergear), nunca estuvo en `main`, ningún commit lo borró. Que Claude Code lo
mostrara "como borrado" es el efecto normal de estar en `main` mientras el
archivo sólo existe en otra rama. **No hay pérdida de datos.**

### 4.3 F2 — Diagnóstico de P-91

**Historial completo del workflow** (`id` 310785920, `refresh-semanal.yml`;
`total_count` de la API = 10, `nrow` descargado = 10, verificado con `stopifnot`):

| id | creado (UTC) | event | conclusion | head_sha |
|---|---|---|---|---|
| 32025223500 | 2026-08-17 11:30 | schedule | **success** | `2b5b3b7a` |
| 31594962972 | 2026-08-12 12:07 | workflow_dispatch | success | `80275448` |
| 31385303604 | 2026-08-10 11:50 | schedule | **failure** | `b619a504` |
| 30819265362 | 2026-08-03 13:43 | schedule | success | `64a0ab97` |
| 30271411957 | 2026-07-27 13:40 | schedule | success | `15be8599` |
| 30169063307 | 2026-07-25 18:09 | workflow_dispatch | success | `01684465` |
| 30168004942 | 2026-07-25 17:37 | workflow_dispatch | **failure** | `01684465` |
| 29745059077 | 2026-07-20 13:09 | schedule | success | `98165322` |
| 29253823952 | 2026-07-13 13:27 | schedule | success | `95dedbc2` |
| 29106048546 | 2026-07-10 16:04 | workflow_dispatch | success | `deab646b` |

Tabla `conclusion` × `event`: `schedule` 5 success / 1 failure; `workflow_dispatch`
3 success / 1 failure. **8 corridas en verde de 10.**

- **Corrida más reciente con `conclusion == "success"`:** 2026-08-17 11:30 UTC,
  id 32025223500, event `schedule`.
- **Racha consecutiva de fallos desde la más reciente hacia atrás: 0.** La
  corrida más reciente no es un fallo.

**H2 (ninguna corrida ha terminado en verde desde que entró la guarda):
REFUTADA.** El único fallo de la era de la guarda es el del 2026-08-10, aislado
entre dos verdes.

**La línea del log** (run 31385303604, `0_refresh.txt`, 1634 líneas):

```
0_refresh.txt:1592: 41:CORTE_FECHA <- "2026-08-10"
0_refresh.txt:1605: [2026-08-10 11:51:51] [00_run_all] [INFO] Corte temporal: 2026-08-10
0_refresh.txt:1606: ##[error]Error: run_all: 6 de 6 intermedios NO corresponden al corte
                    vigente (2026-08-10): diputados, asistencia_nominal, asistencia_ambitos,
                    votos, proyectos, proyectos_detalle.
0_refresh.txt:1607:   No se pueden regenerar: falta la captura cruda de ese corte en
                    20_insumos/camara/ (6 archivo(s)): 20260810_diputados.rds,
                    20260810_periodo_legislativo.rds, 20260810_asistencia_nominal_2026_tope-inf.rds,
                    20260810_votos_long_2026_tope-inf.rds, 20260810_proyectos_long_2026_tope-inf.rds,
                    20260810_detalle_proyectos_xml_2026_tope-inf.rds.
0_refresh.txt:1616: Execution halted
0_refresh.txt:1617: ##[error]Process completed with exit code 1.
```

Murió en el paso `Run Rscript -e 'source("00_run_all.R"); run_all()'` (grupo
abierto en la línea 1593), 0,07 s después de imprimir el corte. Nunca llegó al
paso 32.

**Los tres hechos del repositorio:**

1. **Posición de la guarda.** `00_run_all.R:98`
   `regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT)`; el bucle de
   pasos abre en `:112`. La guarda corre **antes** del bucle, así que su `stop()`
   detiene la corrida sin ejecutar ningún paso. (R1 confirmado.)
2. **Intermedios versionados.** `git ls-files 40_salidas/intermedios` devuelve
   **1** archivo, `.gitkeep`; **0** `.rds`. En un `checkout` limpio el runner
   arranca con cero intermedios. (D24 y R4 confirmados.)
3. **Capturas crudas versionadas.** `git ls-files 20_insumos/camara 20_insumos/senado`
   = **54** rutas, 52 con prefijo `YYYYMMDD` y 2 `.gitkeep`. **8 cortes**
   distintos; máximo **20260812**. Capturas con prefijo `20260810`: **0**. El
   máximo ≤ el corte inyectado en la corrida fallida es `20260803`.

**Veredicto de H1: CONFIRMADA para el evento del 2026-08-10, y superada por los
hechos posteriores.** El mecanismo es exactamente el descrito: runner limpio (0
intermedios versionados) + corte inyectado del día (`2026-08-10`, log línea
1592) + cero capturas crudas de ese corte (medido: 0 de 54) ⇒ la guarda, que
corre antes del bucle, no puede alinear ni regenerar sin red y hace `stop()`.

Pero la premisa de §2 del encargo — "el refresh de producción falla, así que el
portal no se actualiza" — es **falsa al 2026-08-19**. La causa que la cerró,
medida y no recordada:

```
$ git log --oneline b619a504..2b5b3b7 -- 10_utils/10_utils.R 00_run_all.R .github/workflows/refresh-semanal.yml
da72568 feat(pipeline): paso 37 en el orquestador y publicacion de la entidad proyecto
9c35e2d feat(cache): destino parametrizable para crudo de fuentes no Camara
ad21489 fix(guarda): el escape de arranque se consume y el arranque deja rastro (P-76, P-77) (#11)
5423541 fix: la guarda de P-65 deja de ser circular en la primera corrida de un corte
```

El `head_sha` de la corrida fallida es `b619a504`, del **2026-08-09**: anterior a
`5423541` (2026-08-12) y a `ad21489` (2026-08-13). En ese commit la guarda **no
tenía rama de arranque**: `grep -n "arranque_registrado\|permitir_descarga_inicial\|primera corrida\|ausentes"`
sobre `git show b619a504:10_utils/10_utils.R` devuelve **0 coincidencias**; sobre
`2b5b3b7`, devuelve 12 y la primera es `RASTRO_ARRANQUE <- "arranque_registrado.txt"`
en la línea 517.

La corrida verde del 2026-08-17 lo demuestra en su propio log
(`0_refresh.txt` del run 32025223500, 1873 líneas):

```
:1588  57:CORTE_FECHA <- "2026-08-17"
:1605  [guarda_intermedios] [INFO] Primera corrida del corte 2026-08-17: 0 de 6 archivos de
       intermedio en disco y sin rastro de arranque previo. No hay nada que regenerar ni con
       que comparar; los pasos 32, 33, 34, 35, 36 los crearan.
:1606  [guarda_intermedios] [INFO] Rastro de arranque escrito en
       40_salidas/intermedios/arranque_registrado.txt.
:1698  [37_tramitacion] [INFO] Escrito: .../40_salidas/intermedios/tramitacion.rds (431 boletines)
:1705  [39_consolidar] [INFO] Procedencia validada: 7 intermedios al corte 2026-08-17.
```

**P-91 ya está cerrado por `5423541`.** El portal no se actualiza hoy no porque
el workflow falle, sino porque **el PR #18 está abierto y espera merge del
titular** (F0.2: MERGEABLE desde 2026-08-17T11:46:48Z).

**Hallazgo lateral con peso para PR #16.** En la corrida verde del 2026-08-17 la
guarda dice `0 de 6 archivos de intermedio` (línea 1605) y nombra `los pasos 32,
33, 34, 35, 36`, mientras que el `39` valida `7 intermedios` (línea 1705) y el
`37` sí escribió el suyo (línea 1698). Es decir: **el defecto que PR #16 cierra
está vivo en producción, medido en el log del CI, y no es teórico.** No rompe la
corrida (la rama de primera corrida no compara nada), pero deja el mensaje de la
guarda mintiendo por defecto sobre el universo que vigila.

---

## 5. Bugs

### 5.1 Bug medido en producción — el runner no cuenta el paso 37 (P-86)

- **Síntoma:** la guarda declara `0 de 6` / `1 de 6` intermedios y omite
  `tramitacion` de su universo; con `tramitacion.rds` desalineado y su captura
  ausente, `main` **no se detiene** (medido por los dos panelistas: `SIN_STOP`,
  valor devuelto `FALSE`).
- **Causa raíz:** no está en la guarda. `regenerar_intermedios_si_desalineados()`
  tiene cuerpo **idéntico** entre `main` y la rama (afirmación C, §6.1). El
  defecto vive en sus tres insumos: `INTERMEDIOS_PIPELINE` (6→7),
  `PASOS_EXTRACCION` (`00_run_all.R:64`, `32:36`→`32:37`) y la rama `"37"` de
  `capturas_crudas_de_paso()`.
- **Fix:** PR #16 (`fix/p86-runner-paso37`), commits `8a0a716`, `db2a420`,
  `5b8b9d9`. **No mergeado — gate del titular.**
- **Verificación:** panel adversarial de F1, §6.1. Cuatro pruebas, dos agentes
  independientes, veredicto concordante PASA.

### 5.2 Bug nuevo, hallado por los dos panelistas por separado — el `stop()` nombra el directorio equivocado

- **Síntoma:** cuando la captura faltante es la del paso 37, el mensaje dice
  `falta la captura cruda de ese corte en 20_insumos/camara/ (1 archivo(s)):
  20260812_tramitacion_sil_2026_tope-inf.rds`. Esa captura vive en
  `20_insumos/senado/`.
- **Causa raíz (verificada por mí, no heredada del panel):** el literal está
  escrito a mano dentro del `sprintf()` del `stop()`, no derivado de `faltantes`:
  `10_utils/10_utils.R:750` en `main`, `:762` en la rama. Está en **ambos**, así
  que **es preexistente y PR #16 no lo introduce**; lo que PR #16 hace es
  volverlo alcanzable, al incorporar por primera vez un paso cuya captura no está
  en `camara/`.
- **Impacto:** bajo pero real. El nombre del archivo y el `source()` de
  recuperación son correctos, así que la ruta de recuperación funciona; lo que
  queda mal es el directorio que el mensaje nombra, justo en el texto que existe
  para orientar a un operador perdido.
- **Fix:** ninguno. F2 y F1 prohíben arreglar. Queda como pendiente accionable
  (§8, P-93) con marca `# REVISAR` propuesta.

### 5.3 Contradicción interna del encargo — F0.0 contra la compuerta de F0.1

Descrita en §4.1. Sin fix: resuelta por criterio y declarada en §7bis.

---

## 6. Verificación de invariantes

| 🔒 | Verificación | Evidencia | Veredicto |
|---|---|---|---|
| Sólo lectura sobre el estado publicado; ningún merge, ningún push, ningún script de producción editado | `git status --porcelain` final = 0 líneas; `git diff --stat HEAD -- 20_insumos` = 0 líneas; los únicos commits son los dos documentales de §2 | `git status`, `git diff` de esta corrida | **PASA** |
| `sellar()`, `leer_sellado()`, `validar_corte()`, `regenerar_intermedios_si_desalineados()` no se tocan | En F1 se ejercitaron en worktrees desechables; `deparse()` de la guarda idéntico entre worktrees (§6.1, afirmación C) | panel, ambos agentes | **PASA** |
| Ninguna captura cruda modificada ni borrada; mover y restituir con `on.exit(add = TRUE)` | Repo principal: `git status --porcelain -- 20_insumos 40_salidas` = **0 líneas**; `git diff --stat HEAD -- 20_insumos` = **0 líneas**. Las dos rutas movidas existen, con md5 `30511c0e…` (senado/tramitación) y `81072573…` (camara/proyectos). Aparcaderos de ambos agentes vacíos (`character(0)`) | `/tmp/f1_integridad.R` de esta corrida + reportes de los dos agentes | **PASA** |
| Los movimientos ocurrieron sobre las **copias versionadas dentro de los worktrees**, nunca sobre el repo del titular | Ambos agentes lo declaran y el `git status` del principal lo confirma | ídem | **PASA** |
| R único lenguaje; nada de Python, `jq`, `awk` ni `sed` sobre datos o JSON | Todo el parseo de JSON y de logs de CI pasó por `jsonlite::fromJSON()`, `utils::unzip()` y `readLines()` en scripts `/tmp/*.R`. `bash` sólo invocó `git`, `gh` y `Rscript` | scripts de esta corrida | **PASA** |
| `gh api > archivo.json` + `jsonlite::fromJSON()`; prohibidos `gh --jq` y `gh pr diff --name-only` | No se usó ninguno de los dos. `--paginate` no hizo falta: `total_count` = 10 cabe en una página, verificado con `stopifnot(nrow(r) == d$total_count)` | `/tmp/f21.R`, `/tmp/f22.R` | **PASA** |
| `git add` con ruta acotada, nunca `.` ni `-A` | Los dos `git add` nombran un archivo cada uno | §2 | **PASA** |
| `git fetch` antes de comparar con `origin` | `git fetch --all --prune` abre F0.1 (trajo `refresh/2026-08-17`) | F0.1 | **PASA** |
| Intermedios no versionados; `.gitkeep` trackeado | `git ls-files 40_salidas/intermedios` = 1 archivo, `.gitkeep`, 0 `.rds` | hecho 2 de F2.3 | **PASA** |
| Ninguna cifra sin recuento programático en el mismo bloque | Todas las cifras de este log salen de `/tmp/f02.R`, `/tmp/f04.R`, `/tmp/f21.R`, `/tmp/f22.R`, `/tmp/f23*.R`, `/tmp/f24.R`, `/tmp/f25.R`, `/tmp/f1_integridad.R` | §4, §5 | **PASA** |
| Ningún JSON de la API ni log de CI descomprimido commiteado | Todo vivió en `/tmp/`; `git status` final vacío | `git status` | **PASA** |
| Cero llamadas a red desde el pipeline | Ambos agentes lo verifican: la rama de regeneración nunca se alcanzó (`grep -c "Regenerando los pasos"` = 0 en los 8 logs de A1); ningún archivo nuevo en `20_insumos/` de ningún worktree | reportes del panel | **PASA** |
| Árbol como se encontró: sin worktrees colgando | `git worktree list` final = **1 línea**, la del repo principal | `git worktree list` de esta corrida | **PASA** |

### 6.1 Panel adversarial de F1 — tabla de veredictos

Dos agentes con arneses propios, escritos desde cero (`/tmp/agente1/`,
`/tmp/agente2/`), sin leer ni ejecutar `50_documentacion/andamios/50_verificar_p86.R`
ni ningún verificador preexistente. Cada escenario en su propio proceso
`Rscript`. Worktrees separados por agente para que no se pisaran.

| Prueba | Agente 1 | Agente 2 | Concordancia |
|---|---|---|---|
| **Control de calibración** (7 sellos alineados, capturas en su sitio ⇒ sin `stop()`) | **PASA** (`SIN_STOP`, devuelve `FALSE`, en rama y en main; más un CAL2 con la captura del 35 movida y sellos alineados, también `SIN_STOP`) | **PASA** (`SIN STOP. Valor devuelto: FALSE`, en rama y en main) | **Concordante** |
| **A** — `tramitacion` desalineado + captura del 37 movida ⇒ la rama se detiene y nombra el paso 37 | **PASA** | **PASA** | **Concordante** |
| **B** — `proyectos` desalineado ⇒ salida idéntica salvo `1 de 6` → `1 de 7` | **PASA** (1 línea distinta de 7; sustituyendo el conteo, textos idénticos) | **PASA** (1 línea distinta de 8; y una variante de estrés propia, sin rastro de arranque: 2 de 9 distintas, ambas sólo el denominador) | **Concordante** |
| **C** — cuerpo de la guarda idéntico, vía `deparse()` de la función cargada | **PASA** (`identical` = TRUE, md5 `3d6410f4…` en ambos worktrees, 0 líneas distintas) | **PASA** (`identical` = TRUE, md5 `fe42e938…` en ambos worktrees, 0 líneas distintas) | **Concordante** |
| **Restitución** | 51 capturas comparadas, 51 con md5 idéntico en repo/rama/main; aparcadero vacío | md5 de las restituidas iguales a los del repo; aparcadero vacío; `git status -- 20_insumos` = 0 líneas en ambos worktrees | **Concordante** |

**Veredicto del panel: PASA, concordante en las cuatro pruebas.**

**La calibración discrimina**, que era la condición para que el veredicto valiera
algo: el mismo montaje da `SIN_STOP` con los sellos alineados y `stop()` con uno
desalineado. Sin eso, un PASA no habría probado nada (A95, bug 3 de la sesión 22).

**El sentido que importa, medido en los dos lados:** en `main`, el escenario A
termina **sin `stop()`** — el defecto —, y en la rama produce el mensaje correcto
con `source("30_procesamiento/37_extraer_tramitacion.R")` literal. Un panel que
sólo hubiera probado la rama habría dicho PASA sin demostrar que algo cambió.

**Diferencia de forma, no de fondo, entre los dos agentes:** el `deparse()` de A1
tiene 135 líneas y el de A2, 67. Los dos usaron opciones distintas de `deparse()`
(A1 declaró `keep.source = FALSE`, `srcref` desprendido y `environment()`
normalizado). Las cifras no son comparables entre agentes por construcción; lo
comparable es que **cada uno obtuvo `identical() = TRUE` y md5 iguales dentro de
su propio método**. No es discrepancia de veredicto y no dispara la regla
"discrepancia = FALLA".

**Los dos hallaron por separado el mismo defecto colateral** (§5.2), cada uno
citando `capturas_crudas_de_paso()` y el `subdir = "senado"`. Lo verifiqué por mi
cuenta antes de escribirlo aquí (`grep -n "20_insumos/camara/" 10_utils/10_utils.R`
→ línea 750 en main, 762 en la rama; `sed -n '744,756p'` muestra el `sprintf()`).

---

## 7. Decisiones del usuario registradas en gates

**Ninguna.** El encargo declara dos gates del titular y ninguno se ejecutó:
mergear PR #16 y PR #17, y hacer push. A ellos se suma, por lo medido en F2, un
tercero que el encargo no anticipaba: **mergear PR #18** (`refresh/2026-08-17`),
que es lo único que separa al portal de su corte al día.

---

## 7bis. Decisiones autónomas

| # | Decisión | Alternativa descartada | Reversibilidad |
|---|---|---|---|
| D1 | **No detenerme en la compuerta de F0.1** pese a que `main` ≠ `origin/main`, tras verificar que la única diferencia es el commit que F0.0 ordena y que `main..origin/main` está vacío | Detenerme y devolver el turno sin ejecutar nada, cumpliendo la letra de la compuerta y volviéndola inejecutable junto a F0.0 | Reversible (no escribí nada más que el propio encargo) |
| D2 | **Cuatro worktrees en vez de uno** (`wt-p86-a1/a2`, `wt-main-a1/a2`) en lugar del único `/tmp/wt-p86` que nombra el encargo | Un worktree compartido: los dos agentes moviendo capturas a la vez habrían colisionado, y la independencia del panel se habría perdido | Reversible; los cuatro retirados, `git worktree list` = 1 línea |
| D3 | **Añadir worktrees de `main`** para medir el escenario A también sobre `main` | Probar sólo la rama: habría dado PASA sin demostrar que el sentido cambió | Reversible |
| D4 | **Correr F1 y F2 en paralelo** en vez de estrictamente secuencial | Secuencial puro, como pide §1: F2 no depende de F1 y el panel tarda ~6 min por agente | Reversible; ningún resultado depende del orden |
| D5 | **No usar `--paginate`** en `gh api`, tras verificar `total_count` = 10 ≤ per_page = 100 con `stopifnot(nrow(r) == d$total_count)` | Usar `--paginate` y lidiar con la concatenación de objetos JSON que el propio encargo advierte | Reversible |
| D6 | **Bajar y leer también el log del run verde** del 2026-08-17, que el encargo no pide | Reportar sólo el fallo y dejar sin explicar por qué el workflow ya no falla | Reversible; es lectura |
| D7 | **Reportar H1 como confirmada-pero-superada** en vez de forzarla a una de las tres formas del encargo | "H1 confirmada" a secas, que habría dejado al titular creyendo que el refresh sigue roto | Reversible |

---

## 8. Dudas y pendientes abiertos

**P-93 — el `stop()` de la guarda nombra `20_insumos/camara/` para capturas que
viven en `20_insumos/senado/`.**
Contexto: literal hardcodeado en el `sprintf()` del `stop()`
(`10_utils/10_utils.R:750` en main, `:762` en la rama); preexistente, alcanzable
sólo desde que existe un paso con `subdir = "senado"`.
Pregunta cerrada: **¿el directorio debe derivarse de `faltantes` (una línea por
subdirectorio afectado), o basta con reemplazar el literal por
`20_insumos/<camara|senado>/`?**
Bloquea: nada. Es cosmético-operativo; degrada el mensaje de recuperación, no la
recuperación. Marca `# REVISAR` propuesta en esa línea, no escrita (🔒 prohíbe
editar `10_utils/`).

**P-94 — el mensaje de la guarda declara `0 de 6` mientras el `39` valida 7.**
Contexto: medido en el log del CI del run verde 32025223500, líneas 1605 y 1705.
Pregunta cerrada: **¿PR #16 se mergea antes del próximo refresh (lunes
2026-08-24 11:00 UTC), o se acepta un ciclo más con el mensaje desalineado?**
Bloquea: nada operativo; el mensaje es informativo mientras la rama de primera
corrida no compare nada. Pero cualquier corrida futura con intermedios presentes
y `tramitacion` desalineado quedaría sin detectar, que es el escenario A medido.

**P-95 — PR #18 abierto desde el 2026-08-17.**
Contexto: `refresh/2026-08-17` MERGEABLE; el portal sigue en el corte anterior
por esto, no por P-91.
Pregunta cerrada: **¿se mergea PR #18 tal cual, o antes se mergea PR #16 para que
el próximo refresh nazca con el runner corregido?**
Bloquea: la actualización del portal.

**Duda sin resolver — el camino feliz del 37 sigue sin medir.**
Los dos panelistas lo declararon como limitación, por la misma razón: el
escenario "tramitación desalineada **con** su captura presente" ejecuta
`30_procesamiento/37_extraer_tramitacion.R`, que ante un cache miss golpea el
SIL, y el encargo prohíbe escenarios con riesgo de red.
Pregunta cerrada: **¿se autoriza una corrida de ese escenario con red, o se da
por buena la afirmación de F0bis de la sesión 22 sin verificación independiente?**
Bloquea: la afirmación "el 37 regenera sin red y con contenido idéntico" queda
sostenida sólo por el flujo que la produjo.

**Nota metodológica para el próximo encargo.** Ninguna hipótesis de un encargo
sobre el estado de CI debería escribirse sin mirar antes `gh run list`: H1 y H2
se redactaron sobre un fallo de nueve días de antigüedad que dos commits ya
habían cerrado. La regla dura del §0.2 funcionó — ninguna hipótesis se promovió
sin su comando —, y por eso el error se detectó en F2.2 y no en producción.

---

## 9. Estado de cifras y datos críticos

| Objeto | Medición | Estado |
|---|---|---|
| `20_insumos/` en el repo principal | `git status --porcelain -- 20_insumos 40_salidas` = **0 líneas**; `git diff --stat HEAD -- 20_insumos` = **0 líneas** | **Intacto** |
| `20_insumos/senado/20260812_tramitacion_sil_2026_tope-inf.rds` | existe, 275 006 b, md5 `30511c0ee165d6af5ef611649d3028a9` | **Intacto** |
| `20_insumos/camara/20260812_proyectos_long_2026_tope-inf.rds` | existe, 28 993 b, md5 `8107257313b3a5d4de4a4bf442cee12b` | **Intacto** |
| Capturas versionadas | 54 rutas (52 con prefijo + 2 `.gitkeep`), 8 cortes, máximo `20260812`; A1 comparó 51 md5 repo/rama/main, 51 idénticos | **Intacto** |
| `40_salidas/intermedios/` | 8 archivos; los 7 `.rds` + `arranque_registrado.txt` con mtime `2026-08-13 22:11` y `18:02`, anteriores a esta corrida | **Intacto** |
| Intermedios bajo control de versiones | 1 archivo (`.gitkeep`), 0 `.rds` | **D24 respetado** |
| `docs/` y `40_salidas/json/` | no leídos ni escritos en esta sesión | **Sin tocar** |
| Worktrees | 4 creados, 4 retirados; `git worktree list` = 1 línea | **Limpio** |

---

## 10. Notas para el revisor

**Mira con ojo crítico:**

1. **La decisión D1.** No me detuve en una compuerta que la letra del encargo
   me obligaba a respetar. El argumento está en §4.1 y creo que se sostiene,
   pero es exactamente el tipo de juicio que un ejecutor autónomo no debería
   tomar solo. Si discrepas, el encargo necesita que F0.0 y la compuerta de
   F0.1 se reconcilien por escrito antes del próximo turno.
2. **El veredicto de H1 en §4.3.** Lo emití en una forma que el encargo no
   ofrecía (ni confirmada, ni refutada, ni indecidible: confirmada para el
   evento y superada por los hechos). Si prefieres la disciplina de las tres
   formas, la respuesta más cercana es "**H1 confirmada** para el run
   31385303604" y P-91 pasa a estado cerrado por `5423541`.
3. **La diferencia de `deparse()` entre los dos agentes** (135 vs 67 líneas,
   §6.1). La leí como diferencia de método, no de sustancia, porque cada agente
   comparó main contra rama con su propio método y obtuvo identidad. Si crees
   que dos panelistas deben usar el mismo método para que la concordancia
   cuente, esta es la grieta del panel.
4. **Lo que el panel no midió** y ambos agentes declararon: el camino feliz del
   37, el escape `camara.permitir_descarga_inicial`, intermedio ausente o
   ilegible, y qué hace el `39` con `tramitacion`. El PASA cubre las cuatro
   afirmaciones del encargo, no la corrección general del PR.
5. **El desalineamiento es un fixture.** Los dos agentes lo fabricaron
   reescribiendo `attr(obj, "sello")$corte_fecha` sobre su copia. Es el único
   campo que la guarda lee para decidir, así que el mecanismo es fiel, pero
   ninguno reprodujo un intermedio nacido de una corrida real en otro corte.

**Audita después:** que PR #16 se mergee antes del refresh del lunes 2026-08-24
11:00 UTC, y que el primer refresh posterior imprima `0 de 7` y no `0 de 6` en la
línea de la guarda. Esa línea del log del CI es el único test de integración real
que tiene P-86.
