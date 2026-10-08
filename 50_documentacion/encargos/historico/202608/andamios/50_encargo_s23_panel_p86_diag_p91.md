# Encargo autónomo — sesión 23: panel adversarial de PR #16 y diagnóstico de P-91

> **Destino:** `50_documentacion/andamios/50_encargo_s23_panel_p86_diag_p91.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 23.
> **Ejecutor:** Claude Code, modo autónomo.

---

## §0. Contrato positivo: qué está respaldado y qué es hipótesis

Ninguna premisa de este encargo se afirma de memoria. Se separan antes de ejecutar.

### 0.1 Respaldado (fuente leída por el redactor en la sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | `regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT)` se invoca en la entrada de `run_all()`, después de validar rutas y **antes** del bucle que ejecuta los pasos | `00_run_all.R:91-98` y `:112`, leído en la sesión |
| R2 | En la versión de `00_run_all.R` que el titular adjuntó, `PASOS_EXTRACCION <- Filter(function(p) p$id %in% 32:36, PASOS)`, con la deuda de P-66 declarada en comentario | `00_run_all.R:54-64`, leído en la sesión |
| R3 | El workflow calcula `CORTE=$(date +%Y-%m-%d)` y lo inyecta con `sed` sobre `10_utils/10_configuracion.R` antes de correr `run_all()` | `refresh-semanal.yml`, paso "Calcular corte, respaldar JSON previo e inyectar CORTE_FECHA", leído en la sesión |
| R4 | El workflow corre sobre un `actions/checkout@v4` limpio, sin estado heredado entre corridas | `refresh-semanal.yml`, paso "Checkout del repo", leído en la sesión |
| R5 | `50_veredicto_vias_tematicas_derivadas.md` **no aparece en ninguna ruta** del escáner del 2026-08-14 05:45 (0 coincidencias de `vias_tematicas` en el árbol completo) | `estructura_actual.md`, búsqueda ejecutada en la sesión |
| R6 | En `50_documentacion/activa/` existen tres veredictos: `50_veredicto_contrato_simetrico_senado.md`, `50_veredicto_eje_tematico.md`, `50_veredicto_fuentes_tematicas_bcn.md` | `estructura_actual.md`, sección `50_documentacion/activa/` |
| R7 | El escáner del 2026-08-14 05:45 muestra `50_documentacion/traspasos/traspaso_cierre_v21.md` a la vista y **no** muestra `traspaso_cierre_v22.md`; `50_documentacion/andamios/paquete_cierre_v22.md` sigue presente | `estructura_actual.md`, secciones `traspasos/` y `andamios/` |

### 0.2 Hipótesis (se verifican en F0/F2 antes de usarse)

| # | Hipótesis | Comando que la resuelve |
|---|---|---|
| H1 | El refresh falla porque, en un runner limpio, no existe ningún intermedio ni la captura cruda del corte del día, así que la guarda no puede alinear ni regenerar sin red y detiene la corrida antes del paso 32 | F2.3 |
| H2 | El fallo no empezó el 2026-08-10: **ninguna** corrida programada del workflow ha terminado en verde desde que la guarda entró | F2.2 |
| H3 | `50_veredicto_vias_tematicas_derivadas.md` existe sólo en la rama `sondeo/p92-eje-tematico` (PR #17, sin mergear) y por eso no está en el árbol de trabajo | F0.4 |
| H4 | El commit de cierre `2b5b3b7` está en `origin/main` y el árbol local está limpio | F0.2 |
| H5 | El panel adversarial de F3 del encargo P-86 nunca corrió, así que las dos afirmaciones críticas de PR #16 están verificadas sólo por el flujo que produjo el cambio | F1 |

**Regla dura:** ninguna hipótesis se promueve a afirmación sin la salida del comando que la resuelve, en el mismo reporte.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno. No pidas confirmación entre fases.

**Regla de detención (los únicos tres casos):**
1. Un invariante 🔒 te obligaría a violarlo.
2. Un dato real contradice una premisa de §0.1 (no una hipótesis: una premisa respaldada).
3. Un gate marcado en el encargo como decisión del titular.

En cualquiera de los tres: reporta y espera. No improvises metodología.

**ENTORNO:** filesystem local del titular vía Claude Code. Raíz del proyecto:
`/Users/tomgc/Projects/transparencia_legislativa_chile` (fuente: encabezado de `estructura_actual.md`; si `git -C` falla sobre esa ruta, **detente y reporta**, no busques la raíz por tu cuenta).

**INSUMOS:** todos viven en el repo, en las rutas citadas dentro de cada fase. No hay ningún archivo que llegue "aparte".

**POSICIÓN:** ningún comando asume `cd` previo. `git` siempre con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`. `gh` siempre con `-R tomgc/transparencia_legislativa_chile`, salvo `gh api`. Toda ruta de R, absoluta o vía `here::here()`.

**Reglas canónicas heredadas:** POLITICA v5.6 (autonomía 0.3, commits atómicos §3, principios técnicos §5); `encargo_autonomo_claude_code_v1.md` §2.1.

---

## §2. Contexto mínimo suficiente

`transparencia_legislativa_chile` publica datos legislativos como JSON estático servido por GitHub Pages desde `docs/`. El pipeline es R puro, orquestado por `00_run_all.R`, con siete pasos (32-37, 39). Un workflow semanal (`.github/workflows/refresh-semanal.yml`, lunes 11:00 UTC) recalcula el corpus en CI, commitea en una rama `refresh/<corte>` y abre un PR contra `main`, que el titular mergea a mano.

Dos cosas quedaron abiertas al cierre de la sesión 22:

- **PR #16** (`fix/p86-runner-paso37`): registra el paso 37 en las tres estructuras que arman el mensaje de recuperación de la guarda. Su panel adversarial no alcanzó a correr.
- **PR #17** (`sondeo/p92-eje-tematico`): el sondeo del eje temático, sólo bajo `50_documentacion/andamios/`.

Y apareció **P-91**: el refresh de producción falla con
`run_all: 6 de 6 intermedios NO corresponden al corte vigente (2026-08-10)`, así que el portal no se actualiza. La causa raíz no está establecida.

**Este encargo no arregla P-91.** Mide, prueba y reporta. El diseño del arreglo es del asistente y del titular.

---

## §3. Invariantes (🔒)

- 🔒 **El encargo es de sólo lectura sobre el estado publicado.** No mergees ni cierres ningún PR. No hagas push a `main`. No edites ningún script de `10_utils/`, `30_procesamiento/`, `00_run_all.R` ni `.github/workflows/`. Las únicas escrituras autorizadas son: el commit del propio encargo (F0.0) y el log de F3.
- 🔒 `sellar()`, `leer_sellado()`, `validar_corte()` y `regenerar_intermedios_si_desalineados()` **no se tocan**. En F1 se ejercitan, no se modifican.
- 🔒 **Ninguna captura cruda ya escrita se modifica ni se borra.** Para forzar el escenario de F1 se **mueve** a un temporal y se restituye en un `on.exit(add = TRUE)` que corra pase lo que pase.
- 🔒 R es el único lenguaje, en todo contexto, incluidas las tareas de sólo lectura. Nada de Python, `jq`, `awk` ni `sed` sobre datos o JSON. `bash` sólo para invocar `git`, `gh` y `Rscript`.
- 🔒 `gh api <ruta> > archivo.json` y luego `jsonlite::fromJSON()` en R. **Prohibidos** `gh --jq` y `gh pr diff --name-only` (PAT-02: devuelve HTTP 406 en PR grandes y deja el conteo corriendo sobre vacío).
- 🔒 `git add` siempre con ruta acotada. Nunca `git add .` ni `git add -A`.
- 🔒 `git fetch` dentro de toda compuerta de divergencia, antes de comparar con `origin`.
- 🔒 Los intermedios no se versionan (D24); `40_salidas/intermedios/.gitkeep` sigue trackeado.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta. La aritmética manual y la cifra heredada de un documento no son fuente.
- 🔒 **No commitees ningún JSON descargado de la API de GitHub** ni ningún log de CI descomprimido. Viven en `/tmp` y mueren ahí. En el log va la cifra y la línea citada, no el volcado.

---

## §4. Fases, en orden estricto

### F0 — Estado real (lectura; ninguna decisión antes de esta fase)

**F0.0 — Commit del propio encargo.** Este archivo llega untracked y bloquearía la compuerta de F0.2. Antes de nada:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 50_documentacion/andamios/50_encargo_s23_panel_p86_diag_p91.md
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "docs: encargo sesion 23 (panel PR #16 + diagnostico P-91)"
```

**F0.1 — Rama y sincronía.**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rev-parse --abbrev-ref HEAD
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rev-parse main origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
```

**Compuerta (H4):** si `main` y `origin/main` difieren, o si `status --porcelain` devuelve cualquier línea que no sea el encargo ya commiteado, **detente y reporta**. No hagas `stash`, no commitees lo ajeno, no "limpies".

**F0.2 — PR abiertos.**

```bash
gh pr list -R tomgc/transparencia_legislativa_chile --state open --json number,title,headRefName,baseRefName,mergeable,updatedAt > /tmp/prs.json
```

Léelo en R con `jsonlite::fromJSON()` e informa una fila por PR. Si `#16` o `#17` ya no están abiertos, **detente y reporta**: el encargo asume que lo están.

**F0.3 — Corte vigente.** Lee `10_utils/10_configuracion.R` y reporta la línea completa de `CORTE_FECHA` con su número de línea (`grep -n '^CORTE_FECHA <- '`). No lo tomes de ningún documento.

**F0.4 — Localizar `50_veredicto_vias_tematicas_derivadas.md` (H3).** El titular no lo encuentra y Claude Code se lo muestra como borrado. Resuélvelo con evidencia, en este orden:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --all --diff-filter=A --name-only --format="%h %ad %s" --date=short -- "*vias_tematicas*"
git -C /Users/tomgc/Projects/transparencia_legislativa_chile ls-tree -r --name-only origin/sondeo/p92-eje-tematico
```

Del segundo comando, filtra en R las rutas que contengan `veredicto`. Reporta: en qué rama y commit nace el archivo, si alguna vez estuvo en `main`, y si algún commit lo borró (`--diff-filter=D`). Si **no** existe en ninguna rama ni en el reflog, dilo tal cual: no existe. No lo reconstruyas ni lo describas de memoria.

**F0.5 — Distribución del cierre v22 (R7).** Reporta la salida cruda de:

```bash
ls -la /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/traspasos/
ls -la /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/paquete_cierre_v22.md
```

Sin corregir nada: sólo el hecho observado.

**Criterio de éxito de F0:** las cinco salidas están en el reporte y H3 y H4 quedan resueltas con su comando.

---

### F1 — Panel adversarial sobre PR #16 (H5)

Lanza **dos agentes de sólo lectura, con código propio e independiente**, sin acceso a los scripts de verificación de la sesión 22 ni al arnés que produjo el cambio. Cada uno reconstruye desde cero las tres afirmaciones. Un check escrito por el mismo flujo que hizo el cambio hereda sus puntos ciegos.

**Escenario base.** Trabaja sobre un `git worktree` de `origin/fix/p86-runner-paso37` (así `main` no se mueve y no hay `checkout` que ensucie el árbol del titular):

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile worktree add /tmp/wt-p86 origin/fix/p86-runner-paso37
```

Al terminar la fase, retíralo con `git worktree remove /tmp/wt-p86` en un `on.exit(add = TRUE)` o su equivalente.

**Afirmación A (el sentido que debe cambiar).** Con `tramitacion.rds` desalineado y su captura cruda del SIL **movida** a un temporal, la guarda se detiene y su mensaje nombra el paso 37, imprimiendo `source("30_procesamiento/37_extraer_tramitacion.R")`.

**Afirmación B (el sentido que no debe cambiar).** Con `proyectos.rds` desalineado, la salida de la guarda es idéntica a la de `main` **salvo** la línea de conteo, que pasa de `1 de 6` a `1 de 7`. Compara texto contra texto y reporta el diff completo: si aparece cualquier otra línea distinta, es FALLA.

**Afirmación C (invariante de cuerpo).** `regenerar_intermedios_si_desalineados()` tiene cuerpo idéntico entre `main` y la rama. Compara con `deparse()` sobre la función cargada en dos entornos de R distintos, **no** con el diff del archivo.

**Control de calibración, obligatorio antes de emitir veredicto (A95 y el bug 3 de la sesión 22).** Con los siete sellos alineados y todas las capturas en su sitio, el mismo escenario debe terminar **sin** `stop()`. Si el control no distingue, la prueba no prueba nada y el veredicto es FALLA por diseño, no PASA.

**Reglas del panel:**
- Ninguna captura se borra. Mover y restituir, con la restitución en `on.exit(add = TRUE)`.
- Cada agente emite PASA/FALLA por afirmación **con la salida literal** que lo respalda.
- **Discrepancia entre los dos agentes = FALLA**, y se reporta la discrepancia, no se arbitra.

**Criterio de éxito de F1:** las tres afirmaciones y el control de calibración tienen veredicto concordante de ambos agentes, cada uno con su evidencia citada. F1 **no** mergea nada: el merge es del titular.

---

### F2 — Diagnóstico de P-91 (sólo medición; prohibido arreglar)

**F2.1 — Bajar el historial de corridas.**

```bash
gh api "repos/tomgc/transparencia_legislativa_chile/actions/workflows" > /tmp/wf.json
```

En R, identifica el `id` del workflow cuyo `path` termina en `refresh-semanal.yml`. Luego:

```bash
gh api "repos/tomgc/transparencia_legislativa_chile/actions/workflows/<ID>/runs?per_page=100" --paginate > /tmp/runs.json
```

**Aviso de forma:** `--paginate` sobre `gh api` concatena objetos JSON; si `fromJSON()` falla, usa `jsonlite::stream_in()` o lee página por página a archivos separados y únelos en R. **No** lo resuelvas con `jq` ni con `sed`.

**F2.2 — Contar (H2).** En R, sobre el objeto ya leído, y todo en el mismo bloque que reporta las cifras:
- total de corridas del workflow;
- tabla de `conclusion` por `event` (`schedule` vs `workflow_dispatch`);
- fecha de la corrida **más reciente con `conclusion == "success"`**, o la declaración explícita de que no existe ninguna;
- **racha consecutiva de fallos** contada desde la corrida más reciente hacia atrás;
- fecha de la primera corrida fallida de esa racha.

**F2.3 — La línea del log (H1).** Del run fallido más reciente, baja el log y busca en él, en R:

```bash
gh api "repos/tomgc/transparencia_legislativa_chile/actions/runs/<RUN_ID>/logs" > /tmp/run_logs.zip
```

Descomprime con `utils::unzip()` en R, lee los `.txt` con `readLines()` y extrae **con su número de línea y su archivo**: la línea del `stop()` de la guarda, las líneas inmediatamente anteriores (para saber en qué paso del workflow murió) y la línea que imprime el corte inyectado.

Luego contrasta H1 con tres hechos del repositorio, cada uno con su comando:
1. Posición de la guarda respecto al bucle de pasos (`grep -n` sobre `00_run_all.R`, y cita las líneas).
2. Qué hay de `40_salidas/intermedios/` bajo control de versiones: `git -C ... ls-files 40_salidas/intermedios` y su conteo en R.
3. Fecha máxima de las capturas crudas versionadas: `git -C ... ls-files 20_insumos/camara 20_insumos/senado`, y en R extrae el prefijo `YYYYMMDD` y reporta el máximo. Compáralo con el corte que el workflow habría inyectado en la corrida fallida (el que leíste del log en F2.3, no el de tu reloj).

**Veredicto de F2:** una de estas tres formas, y ninguna otra:
- **H1 confirmada**, con la línea del log y los tres hechos que la sostienen;
- **H1 refutada**, con la evidencia que la contradice y la causa alternativa que los datos sí sostienen;
- **H1 no decidible con lo medido**, nombrando exactamente qué falta y qué comando lo conseguiría.

**Prohibido en F2:** proponer o escribir el arreglo, tocar la guarda, editar el workflow, relanzar el workflow. Medir y reportar.

**Criterio de éxito de F2:** la racha de fallos está contada programáticamente, existe respuesta explícita a "¿alguna corrida terminó en verde alguna vez, y cuándo?", y el veredicto de H1 cita la línea de log que lo respalda.

---

### F3 — Log y cierre

Escribe el log en
`/Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/20260814_panel_p86_diagnostico_p91_log.md`,
con la plantilla fija de `encargo_autonomo_claude_code_v1.md` §4 (diez secciones), honesto sobre lo que costó.

Verifica antes de commitear (`wc -l` del log y `git -C ... status --porcelain` acotado a esa ruta) y commitea sólo el log:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 50_documentacion/andamios/logs/20260814_panel_p86_diagnostico_p91_log.md
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "docs: log panel adversarial PR #16 y diagnostico P-91"
```

**No hagas push.** El push es del titular.

Deja el árbol como lo encontraste: sin worktrees colgando (`git worktree list` en el reporte), sin capturas movidas (comprueba y reporta que las tres rutas tocadas en F1 volvieron a su sitio, con `file.exists()` en R).

---

## §5. Auto-auditoría antes de reportar

El panel adversarial de F1 es el mecanismo para las afirmaciones de PR #16. Para F2, antes de reportar, comprueba tú mismo dos cosas:
1. Que cada cifra del reporte proviene de un bloque de R ejecutado en esta corrida, y no de una lectura tuya del log.
2. Que ninguna afirmación sobre el estado del repositorio o del workflow se apoya en este encargo en vez de en un comando: este documento es la hipótesis, no la fuente.

---

## §6. Reporte final al chat

1. Las salidas de F0.1 a F0.5, crudas.
2. Veredicto del panel: tabla afirmación × agente 1 × agente 2 × PASA/FALLA, más el resultado del control de calibración.
3. Cifras de F2.2 en una tabla, con el bloque de R que las produjo.
4. La línea del log de CI, citada literal, con archivo y número de línea.
5. Veredicto de H1 en una de sus tres formas.
6. Respuesta a H3: dónde vive `50_veredicto_vias_tematicas_derivadas.md`, o la declaración de que no existe.
7. Hashes de los dos commits (encargo y log) y ruta del log.
8. Pendientes abiertos y marcas `# REVISAR`.

**Gate del titular, no tuyo:** mergear PR #16 y PR #17, y hacer push. No los ejecutes.
