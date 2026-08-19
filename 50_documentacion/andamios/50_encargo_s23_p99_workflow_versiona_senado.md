# Encargo autónomo — P-99: el refresh semanal versiona todas las capturas crudas

> **Destino:** `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 23.
> **Ejecutor:** Claude Code, modo autónomo.
> **Antecede:** `50_encargo_s23_p93_guarda_registro_pasos.md` (mismo día, ejecutado, PR #19).

---

## §0. Contrato positivo

### 0.1 Respaldado (fuente leída o ejecutada en la sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | El paso de commit del workflow enumera rutas a mano: `git add 10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data`. `20_insumos/senado` **no aparece** | `.github/workflows/refresh-semanal.yml`, paso "Commit en rama y apertura del PR", leído por el redactor en esta sesión |
| R2 | De 9 cortes con captura versionada, sólo `20260812` tiene captura en `senado/` (1 archivo); el corte vigente `20260817` tiene 6 en `camara/` y 0 en `senado/` | log de P-93 §4.2, conteo en R sobre `git ls-files`, ejecutado en esta sesión |
| R3 | El paso 37 sí corrió y escribió su intermedio en el CI del 2026-08-17 (`[37_tramitacion] Escrito: .../tramitacion.rds (431 boletines)`), o sea que la captura existió en el runner y no se commiteó | log de P-93 §4.2, citando el log de la corrida verde |
| R4 | En el árbol al corte vigente, `run_all()` se detiene con `falta la captura cruda de ese corte en 20_insumos/senado/ (1 archivo(s)): 20260817_tramitacion_sil_2026_tope-inf.rds`, igual en `main` y en la rama de P-93 | log de P-93 §4.2 y §6.1, medido en esta sesión |
| R5 | El defecto es una enumeración que no se actualizó cuando P-66 agregó el paso 37, no una exclusión deliberada: el YAML no declara ninguna razón de tamaño ni de licencia para excluir el SIL | `refresh-semanal.yml` completo, leído en esta sesión |

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Comando |
|---|---|---|
| H1 | PR #19 está mergeado y `main` local se pone al día sin conflicto | F0.1 |
| H2 | `20_insumos/` contiene **sólo** directorios de captura cruda, de modo que versionarlo entero no arrastra nada ajeno | F0.2 |
| H3 | La captura del SIL no contiene datos personales que obliguen a auditoría previa (A101) | F0.3 |

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

---

## §2. Contexto mínimo suficiente

El refresh semanal corre en CI, recalcula el corpus y commitea el resultado en una rama `refresh/<corte>`. Enumera a mano qué rutas commitea, y esa lista se quedó en el mundo anterior al paso 37: versiona las capturas de la Cámara y deja fuera las del Senado.

La consecuencia no es cosmética. La guarda de P-65 promete regenerar cualquier intermedio desalineado **sin red**, a partir de la captura cruda ya versionada. Para el paso 37 esa promesa hoy no se puede cumplir en el corte vigente: la captura nunca llega al repositorio (R2, R4).

**Este encargo cambia una cosa y sólo una:** qué rutas commitea el workflow. No toca R, no toca la guarda, no toca el pipeline.

---

## §3. Invariantes (🔒)

- 🔒 **Un solo cambio conceptual.** El único archivo de código que se edita es `.github/workflows/refresh-semanal.yml`, y dentro de él sólo la lista de rutas del `git add` y el comentario que la explica. Si te dan ganas de arreglar otra cosa del YAML, no.
- 🔒 **No mergees ningún PR** ni hagas push a `main`. Se abre el PR y se reporta.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 R es el único lenguaje para cualquier medición o conteo. `bash` sólo para `git`, `gh` y `Rscript`. YAML es el archivo que se edita, no una herramienta de análisis.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`, ni en el YAML ni en tus propios commits.
- 🔒 **Ninguna descarga local.** La única actividad de red autorizada es **un** `gh workflow run` (F2) y las consultas de estado a la API. No corras `run_all()` con red en la máquina del titular.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.

---

## §4. La decisión de metodología (es del redactor, no tuya)

La lista pasa de enumerar subdirectorios a versionar `20_insumos` completo:

```
git add 10_utils/10_configuracion.R 20_insumos 40_salidas/json docs/data
```

**Por qué así y no `20_insumos/camara 20_insumos/senado`:** sustituir una enumeración de un elemento por una de dos repite la clase de defecto y garantiza que el próximo origen de datos (el Senado completo, cuando llegue) vuelva a quedarse fuera en silencio. Además, `20_insumos/senado` puede no existir en el runner si el paso 37 no escribió, y `git add` sobre una ruta inexistente aborta el step: la enumeración es también más frágil.

`20_insumos` sigue siendo una ruta acotada. La compuerta que hace segura esta decisión es H2: si el directorio contiene algo que no sea captura cruda, la decisión se cae y **te detienes** en vez de ampliarla.

---

## §5. Fases

### F0 — Estado y compuertas

**F0.0 — Commit del propio encargo** (llega untracked):

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "docs: encargo P-99 (el refresh versiona las capturas del Senado)"
```

**F0.1 — Compuerta de partida (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
gh api repos/tomgc/transparencia_legislativa_chile/pulls/19 > /tmp/pr19.json
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rebase origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -6
```

Lee `/tmp/pr19.json` en R y reporta `state`, `merged`, `merged_at`. **Detente si #19 no está mergeado.** Los cuatro commits documentales viajaban en #19: al rebasar, `git` debería descartarlos por equivalencia de parche. Reporta cuáles sobrevivieron y cuáles no; si el rebase entra en conflicto, **detente** y no lo resuelvas.

**F0.2 — Compuerta de alcance (H2).** En R, sobre la salida de `git -C ... ls-files 20_insumos`, reporta: número de archivos, tabla de subdirectorios de primer nivel con su conteo, y **cualquier archivo que no cuelgue de un subdirectorio de captura**. Lista además los archivos presentes en disco y no trackeados (`git ls-files --others --exclude-standard 20_insumos`). **Detente si aparece cualquier cosa que no sea captura cruda:** la decisión de §4 dejaría de ser segura y la elección vuelve al titular.

**F0.3 — Auditoría de dato personal (H3, A101).** Antes de aceptar que el SIL se versione semanalmente, abre en R la captura del SIL ya versionada (`20260812_tramitacion_sil_*.rds`) e informa: `dim()`, `names()`, y si alguna columna de texto contiene correos, teléfonos o RUT (búsqueda por patrón en R sobre las columnas de tipo carácter, reportando conteos, **no** los valores). **Detente y reporta si aparece cualquiera de los tres:** versionar semanalmente un dato personal es decisión del titular, no tuya.

**Criterio de éxito de F0:** H1, H2 y H3 resueltas con su salida.

---

### F1 — El cambio

Rama desde `main` al día:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/p99-workflow-versiona-senado main
```

En `.github/workflows/refresh-semanal.yml`, sustituye la lista de rutas del `git add` por la de §4 y **reemplaza el comentario que la precede** por uno que diga por qué es el directorio y no la enumeración (el argumento de §4, en dos líneas). Un cambio que no deja escrito su porqué es el mismo defecto con otra fecha.

Agrega, inmediatamente después del `git add` y antes del `git diff --cached --quiet`, una línea que deje el inventario en el log del job:

```bash
          git diff --cached --name-only | sed 's/^/  staged: /'
```

(Es `sed` sobre nombres de archivo dentro del YAML, no análisis de datos: la restricción de R no lo alcanza.)

**Verificación local, antes de commitear:**
1. El YAML sigue siendo YAML válido: `Rscript -e 'yaml::read_yaml(...)'` si `yaml` está instalado; si no lo está, **no lo instales**: usa `gh workflow view refresh-semanal.yml -R tomgc/transparencia_legislativa_chile` tras el push (F2) y reporta que la validación fue remota.
2. `git diff` del archivo, completo, en el reporte. Deben ser el `git add`, su comentario y la línea del inventario. Nada más.

**Commit atómico:**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add .github/workflows/refresh-semanal.yml
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "fix: el refresh versiona 20_insumos completo, no solo camara (P-99)"
git -C /Users/tomgc/Projects/transparencia_legislativa_chile push -u origin fix/p99-workflow-versiona-senado
```

---

### F2 — La prueba decisiva: una corrida real desde la rama

Un cambio en CI que no se probó en CI no está probado. `workflow_dispatch` acepta un `ref`, así que se prueba **sin** mergear:

```bash
gh workflow run refresh-semanal.yml -R tomgc/transparencia_legislativa_chile --ref fix/p99-workflow-versiona-senado
```

**Consecuencias asumidas, decláralas en el reporte:** la corrida hace descargas reales desde el runner (no desde la máquina del titular), crea la rama `refresh/<corte de hoy>` y abre su PR contra `main`. Ese PR **no se mergea**: es del titular. Es **una** corrida; si falla, se diagnostica y se reporta, no se relanza en bucle.

Espera y mide, todo leído en R desde archivos de `gh api`:
1. Estado final de la corrida (`conclusion`) y su duración.
2. **El inventario de staged**, del log del job (baja el zip con `gh api .../logs`, descomprime con `utils::unzip()`, lee con `readLines()`): ¿aparece un archivo bajo `20_insumos/senado/`?
3. Los archivos de la rama `refresh/<corte>`: `git -C ... fetch origin` y luego, en R, sobre `git ls-tree -r --name-only origin/refresh/<corte>`, el conteo de capturas por subdirectorio para el corte de hoy. **Ésta es la medición que cierra P-99:** el corte de hoy debe tener al menos una captura en `senado/`.
4. **Bonus obligatorio de auditoría (nota 10 del log de P-93):** en el mismo log del job, comprueba si la guarda nueva de P-93 emitió silencio o una lista de incoherencias, y cita la línea. Si habló, es un hallazgo de primer orden y va arriba en el reporte.

**Si la corrida falla:** cita la línea del log que la mata, di si el fallo es del cambio de P-99 o preexistente, y **detente**. No arregles el pipeline dentro de este encargo.

---

### F3 — Log, PR y cierre

Log en
`/Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/20260819_p99_workflow_versiona_senado_log.md`,
plantilla de `encargo_autonomo_claude_code_v1.md` §4 (diez secciones). Commitea sólo el log, con ruta acotada, y púshalo a la rama.

Abre el PR contra `main` citando en el cuerpo: la medición 3 de F2 (capturas por subdirectorio en la rama de refresh) y el estado de la guarda de P-93 en esa corrida.

**No mergees.** Quedan dos gates del titular: este PR y el PR de refresh que la corrida de F2 haya abierto.

Deja el árbol como lo encontraste: `git status --porcelain` en cero, `git worktree list` en una línea, `git diff --stat HEAD -- 20_insumos` en cero.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. El `git diff` del YAML no contiene ninguna línea que no esté autorizada por §3 y §4.
3. Si el próximo origen de datos llegara mañana con su propio subdirectorio en `20_insumos/`, ¿quedaría versionado sin que nadie edite el YAML? Contéstalo mirando el diff, no de memoria.

---

## §7. Reporte final al chat

1. F0.1 a F0.3, crudas, incluida la auditoría de dato personal.
2. `git diff` completo del YAML.
3. Resultado de la corrida de F2: `conclusion`, duración, inventario de staged, y el conteo de capturas por subdirectorio en la rama de refresh del corte de hoy.
4. Qué dijo la guarda de P-93 en esa corrida, citando la línea.
5. Hashes de los commits, número del PR de P-99, número del PR de refresh que la corrida abrió, ruta del log.
6. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
