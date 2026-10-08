# Encargo autónomo — P-99 v3: el refresh versiona las capturas crudas que R declara

> **Destino:** `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md`
> **Reemplaza** a la v2 en la misma ruta. **Sobrescribe el archivo; no crees un `_v3` en el repo.**
> **Redactor:** asistente de análisis (Claude conversacional), sesión 24.
> **Ejecutor:** Claude Code, modo autónomo.
>
> **Por qué hay v3.** Tres cosas cambiaron y una estaba mal registrada.
>
> 1. El traspaso v23 (§11.1 y §14) remite a un "encargo v3 ya escrito" en esta ruta. No existe: el archivo en disco es la v2. El error es del redactor y queda registrado; esta v3 es la que el traspaso creía tener.
> 2. La delegación de merge de la sesión 23 (D57) caducó con ella. El titular la re-delegó en la sesión 24 **acotada a PR #19**, de modo que H1 deja de ser una hipótesis del encargo y pasa a ser un paso ejecutable. Es la corrección directa de A107: una compuerta que depende de una acción humana fuera de banda detiene todo lo que se encadene detrás.
> 3. La corrida de detención de la v2 ya produjo la auditoría de gobernanza y la commiteó. F0.0 pasa de escribir a verificar; escribir de nuevo lo que ya existe es cómo se duplican logs.
>
> **Lo que la v3 no cambia:** la decisión de metodología de §4 es la misma de la v2. El YAML no enumera rutas de captura: se las pregunta a R.

---

## §0. Contrato positivo

### 0.1 Respaldado (fuente leída o ejecutada por el ejecutor en la corrida de detención de la v2, sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | El paso de commit enumera rutas a mano y omite el Senado: `git add 10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data` | `.github/workflows/refresh-semanal.yml:115`, verificado literal por el ejecutor en F0 de la v2 |
| R2 | `20_insumos/` trackeado tiene tres subdirectorios: `camara` (57), `senado` (3), `territorio` (2) | F0.2 de la v2, conteo en R sobre `git ls-files` |
| R3 | `20_insumos/territorio/` **no** es captura cruda: son dos CSV de insumo estático auditado (D5), que el pipeline sólo lee (`leer_csv_territorio`, `32_extraer_diputados.R:50`) y cuya regla declarada es actualizarlos a mano con revisión del diff | F0.2 de la v2 |
| R4 | `20_insumos/senado/.gitkeep` está trackeado: el `checkout` materializa el directorio siempre | `git ls-tree -r --name-only HEAD -- 20_insumos/senado`, F0 de la v2 |
| R5 | `.gitignore:50-56` excluye respuestas crudas de sondeo que incluyen endpoints de padrón del Senado con 157 correos y 53 teléfonos nominales; el proyecto ya deliberó y falló en contra de publicarlos | F0 de la v2, texto del propio `.gitignore` |
| R6 | `GET /api/parlamentarios` figura como fuente de padrón NO USADA en `50_catalogo_fuentes_senado.md:315`: el próximo ocupante de esa zona ya está declarado | F0 de la v2 |
| R7 | La captura del SIL versionada está limpia: 3 271 894 caracteres barridos, 0 correos, 0 RUT, 0 teléfonos, con los 5 patrones calibrados (5/5 señuelos detectados) y un señuelo inyectado en la columna `xml` detectado | F0.3 de la v2, con panel de verificación independiente |
| R8 | La única captura del SIL versionada la subió el titular a mano (`b4b0bcd`); 0 de 8 commits del bot tocaron `senado/`. El problema que P-99 ataca es real | F0 de la v2 |
| R9 | El paso 37 corrió y escribió su intermedio en el CI del 2026-08-17, pero su captura cruda no quedó versionada | log de P-93 §4.2 |
| R10 | El titular re-delegó, en la sesión 24, el merge de **PR #19** y sólo de él, con `--merge`, sin `--squash`, sin `--rebase`, sin `--delete-branch`, y sin alcanzar a los PR que este encargo abra | instrucción explícita del titular en la sesión 24 |
| R11 | El archivo que ocupaba esta ruta antes de este encargo era la v2, no una v3 | adjunto del titular en la sesión 24, a petición de la ruta |

**Nota de higiene:** R1 a R9 vienen de la corrida anterior y **no se heredan como verdad de hoy**. Todas las que este encargo usa para decidir se re-miden en F0 y se reportan con su comando. Si alguna no se sostiene, aplica la regla de detención (b).

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Comando |
|---|---|---|
| H2 | Existe en R una constante que declara los directorios de captura cruda (`DIRECTORIOS_CRUDO` u otro nombre), su contenido es exactamente `camara` y `senado`, y no incluye `territorio` | F0.3 |
| H3 | `ruta_cache()` y `capturas_crudas_de_paso()` construyen sus rutas a partir de esa misma constante, y no de literales sueltos | F0.4 |
| H4 | Los commits documentales de la sesión 23 (entre ellos el log de auditoría de gobernanza de P-99) están en `main` **local** y sin push, y el log ya existe en su ruta | F0.0 |
| H5 | PR #19 está abierto y `mergeable` | F0.1 |

**Si H2 es falsa** (no existe tal constante, o incluye `territorio`), **detente y reporta**: el diseño de §4 depende de que exista una única declaración en R, y fabricarla sobre la marcha cambiaría el alcance del encargo.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`, que no acepta `-R`.

---

## §2. Contexto mínimo suficiente

El refresh semanal enumera a mano qué rutas commitea, y esa lista se quedó en el mundo anterior al paso 37: versiona la Cámara y deja fuera el Senado. La consecuencia es que la promesa de P-65 ("regenero cualquier intermedio desalineado sin red, desde la captura ya versionada") hoy no se puede cumplir para el paso 37 en el corte vigente.

Arreglarlo tiene una trampa que la v1 pisó: ampliar la lista al directorio completo cambia el régimen de fallo. Con una enumeración, sólo entra lo que alguien nombró; con el directorio, entra todo lo que nadie excluyó, y lo que hay al otro lado de esa línea (R5, R6) es material que el proyecto decidió no publicar.

**Este encargo cambia una cosa:** de dónde saca el workflow la lista de rutas. Deja de estar escrita en el YAML y pasa a derivarse de la declaración que ya existe en R.

**Y trae una segunda medición de regalo.** Al mergear #19, la guarda de P-93 entra en producción, y la corrida de F2 es la **primera vez que corre en el runner** (hasta ahora sólo se probó en macOS local). Lo que esa guarda diga en el log del job es un resultado de este encargo, no un detalle.

---

## §3. Invariantes (🔒)

- 🔒 **Un solo cambio conceptual.** Se editan `.github/workflows/refresh-semanal.yml` y, si H2 lo permite, **nada más** del lado de R que un helper de una línea que imprima las rutas. No se toca la constante, ni el pipeline, ni la guarda de P-93.
- 🔒 **El régimen de fallo es cerrado.** Ninguna ruta llega al commit sin estar declarada en R. Si el conjunto staged contiene algo fuera de lo declarado, el job **falla**; no se filtra silenciosamente ni se commitea "lo bueno".
- 🔒 `20_insumos/territorio/` **no lo commitea el bot**. Es insumo estático con revisión manual de diff (R3).
- 🔒 **Merge autorizado: sólo PR #19**, con `--merge`, sin `--squash`, sin `--rebase`, sin `--delete-branch` (R10). Ningún otro PR se mergea, incluidos los que este encargo abra.
- 🔒 **Push a `main` autorizado sólo para los commits documentales de la sesión 23 que ya existen en local** (H4), y sólo después de que F0.1 los haya listado uno por uno en el reporte. Ningún commit nuevo de este encargo va a `main`: el cambio de §4 vive en su rama y llega por PR.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 R es el único lenguaje para medir o contar. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`, ni en el YAML ni en tus commits.
- 🔒 **Ninguna descarga local.** La única red autorizada es **un** `gh workflow run` (F2), el merge de #19, y las consultas de estado a la API.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.

---

## §4. La decisión de metodología (es del redactor, no tuya)

**El YAML deja de enumerar rutas de captura y le pregunta a R cuáles son.**

```bash
          RUTAS_CRUDO=$(Rscript -e 'source("10_utils/10_utils.R"); cat(rutas_versionables_crudo(), sep=" ")')
```

y luego `git add 10_utils/10_configuracion.R $RUTAS_CRUDO 40_salidas/json docs/data`.

`rutas_versionables_crudo()` es un helper nuevo que devuelve `file.path("20_insumos", DIRECTORIOS_CRUDO)` (con el nombre real que F0.3 confirme), y nada más. No inventa, no descubre, no lista el disco: **traduce la declaración que ya existe**.

**Por qué así y no la enumeración de dos rutas en el YAML:** dos listas que deben coincidir y nada que lo obligue es la definición del defecto que P-99 arregla. Con el helper hay una sola declaración, y agregar el Senado completo mañana no requiere tocar el YAML. El régimen de fallo sigue cerrado, porque el helper deriva de una constante nominada, no del contenido del directorio.

**Y la barrera se hace explícita, no implícita.** Después del `git add`, antes del `git commit`, el job valida en R que el conjunto staged esté contenido en lo declarado:

- toda ruta staged debe caer bajo `10_utils/10_configuracion.R`, `40_salidas/json`, `docs/data` o una de las rutas de `rutas_versionables_crudo()`;
- cualquier otra cosa **mata el job** con `quit(status = 1)` nombrando la ruta intrusa.

Esto es lo que convierte a `.gitignore` en la segunda línea de defensa en vez de la única (R5). Es una compuerta mecánica: no pide criterio a nadie en el momento en que el criterio estaría comprometido.

---

## §5. Fases

### F0 — Estado y compuertas

**F0.0 — Qué hay ya escrito (H4).** No escribas nada antes de medir.

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rev-parse --abbrev-ref HEAD
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline origin/main..main
ls -la /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/
```

1. Reporta en qué rama estás, cuántos commits tiene `main` local por delante de `origin/main` y cuáles son.
2. Reporta si `20260819_auditoria_gobernanza_p99_log.md` existe, con qué tamaño y en qué commit entró (`git log --oneline -1 -- <ruta>`). **Si existe, no lo reescribas.** Si falta algo de lo que la corrida de detención midió (los conteos por subdirectorio, la calibración del barrido con sus cinco patrones y el señuelo inyectado, el hallazgo de `.gitignore` y el padrón, y que `.gitkeep` invalidaba el argumento de la v1), agrégalo como sección nueva al final, con el comando que produjo cada cifra.
3. Sobrescribe `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md` con **este archivo** (reemplaza la v2).
4. Commit único y acotado de lo que hayas tocado en este paso, **en `main`**, verificando antes que estás en `main` y no en una rama de trabajo.

**F0.1 — El gate del titular, ya resuelto: mergear #19 (R10, H5).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
gh api repos/tomgc/transparencia_legislativa_chile/pulls/19 > /tmp/pr19_previo.json
```

Lee en R `state`, `merged`, `mergeable`, `mergeable_state`. Tres casos:

- **`merged = TRUE`:** ya estaba dentro. Sigue.
- **`state = "open"` y `mergeable = TRUE`:** mergea, y **sólo** así:

```bash
gh pr merge 19 -R tomgc/transparencia_legislativa_chile --merge
gh api repos/tomgc/transparencia_legislativa_chile/pulls/19 > /tmp/pr19_post.json
```

  Verifica el resultado en el endpoint propio, nunca con `gh pr list`: `merged`, `merged_at`, `merge_commit_sha`.
- **`mergeable = FALSE` o `mergeable_state` conflictivo:** **detente y reporta**. Resolver un conflicto de merge no está delegado.

Con #19 dentro, pon `main` al día y publica los commits documentales pendientes:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rebase origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline origin/main..main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile push origin main
```

Antes del `push`, **lista uno por uno** los commits que va a publicar y comprueba en R que ninguno toca código: `git diff --name-only origin/main..main` debe caer entero bajo `50_documentacion/`. Si toca cualquier otra cosa, **detente**: el push de `main` está autorizado sólo para documentación (§3). Reporta también qué commits descartó el rebase por equivalencia de parche, y detente ante cualquier conflicto.

**F0.2 — Que el defecto siga ahí.** Con `main` al día, re-mide R1 y R2 en este turno: la línea literal del `git add` del workflow con su número de línea, y el conteo de archivos trackeados por subdirectorio de `20_insumos/` (en R, sobre `git ls-files`). Si el defecto ya no existe, **detente**: el encargo perdió su objeto.

**F0.3 — La declaración en R (H2).** Localiza en `10_utils/10_utils.R` la constante que declara los directorios de captura cruda (`grep -n 'DIRECTORIOS_CRUDO\|subdir'`). Reporta su definición literal con número de línea y su contenido evaluado en R. **Detente si no existe, si incluye `territorio`, o si hay más de una declaración compitiendo.**

**F0.4 — Quién más la usa (H3).** Reporta, con número de línea, si `ruta_cache()` y `capturas_crudas_de_paso()` derivan sus rutas de esa constante o de literales sueltos. Es un hallazgo, no un obstáculo: si hay literales, se registra como pendiente y se sigue (ya inventariado como P-102; confirma o corrige su alcance con números de línea de hoy).

**Criterio de éxito de F0:** H2 a H5 resueltas con su salida, #19 dentro, `main` publicado y limpio, y el defecto de P-99 re-medido en este turno.

---

### F1 — El cambio

Rama desde `main` al día:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/p99-rutas-crudo-desde-r main
```

**En `10_utils/10_utils.R`:** el helper `rutas_versionables_crudo()`, de cuerpo mínimo, devolviendo `file.path("20_insumos", <constante>)`. Documenta en dos líneas de comentario que el YAML depende de él y que ampliar la constante amplía lo que el bot versiona.

**En `.github/workflows/refresh-semanal.yml`:**
1. El `RUTAS_CRUDO=$(Rscript ...)` antes del `git add`, con comprobación de que no volvió vacío (vacío ⇒ `exit 1`, porque un `git add` con la variable vacía degradaría el conjunto en silencio).
2. El `git add` usando la variable.
3. La validación del staged de §4, en R, entre el `git add` y el `git diff --cached --quiet`, con `quit(status = 1)` y el nombre de la ruta intrusa.
4. El inventario de staged al log del job (`git diff --cached --name-only`, prefijado).
5. El comentario de cabecera del paso, reescrito para decir por qué la lista vive en R y no ahí.

**Verificación local, antes de commitear:**
1. `Rscript -e 'source("10_utils/10_utils.R"); cat(rutas_versionables_crudo(), sep=" ")'` devuelve exactamente las rutas esperadas.
2. **La validación falla cuando debe:** en un worktree desechable, `git add` una ruta intrusa (por ejemplo un archivo temporal bajo `20_insumos/territorio/`) y comprueba que el bloque de validación la nombra y sale con estado 1. Sin esta prueba la compuerta es decorativa.
3. **La validación calla cuando debe:** con el conjunto legítimo staged, sale en cero y no imprime alarma.
4. `git diff` completo de los dos archivos en el reporte.
5. **Control de no regresión de la guarda de P-93:** `run_all(only = 39)` desde la rama, comparado con `main`. El helper nuevo no debe alterar nada del pipeline; si la salida difiere, el helper hizo más de lo que declara.

Commits atómicos separados (helper de R; workflow), push de la rama.

---

### F2 — La prueba decisiva: una corrida real desde la rama

```bash
gh workflow run refresh-semanal.yml -R tomgc/transparencia_legislativa_chile --ref fix/p99-rutas-crudo-desde-r
```

**Consecuencias asumidas, decláralas:** descargas reales desde el runner, creación de la rama `refresh/<corte de hoy>` y apertura de su PR contra `main`, que **no se mergea**. Es **una** corrida; si falla, se diagnostica y se reporta, no se relanza en bucle.

Mide, todo leído en R desde archivos de `gh api`:
1. `conclusion` y duración.
2. El inventario de staged en el log del job (`gh api .../logs`, `utils::unzip()`, `readLines()`): ¿aparece un archivo bajo `20_insumos/senado/`? ¿aparece algo bajo `territorio/`? Lo segundo debería ser **no**.
3. Sobre `git ls-tree -r --name-only origin/refresh/<corte>`, el conteo de archivos por subdirectorio de `20_insumos/` para el corte de hoy. **Ésta es la medición que cierra P-99.**
4. **La guarda de P-93 en su primera corrida en el runner.** ¿Emitió silencio o una lista de incoherencias? Cita la línea literal del log, y si habló, va arriba en el reporte. Si detuvo el job, la causa candidata declarada es P-100 (`body(...)[[2]]` indexa por posición y degrada a falso positivo si el cuerpo de `capturas_crudas_de_paso()` cambió de forma): compruébalo antes de atribuirlo a otra cosa, y **no toques la guarda** para desbloquear la corrida.
5. Que la validación de §4 no haya matado el job por un falso positivo. Si lo hizo, el diseño está mal y hay que reportarlo, no aflojar la validación.

---

### F3 — Log, PR y cierre

Log en `50_documentacion/andamios/logs/20260819_p99_rutas_crudo_desde_r_log.md`, plantilla de `encargo_autonomo_claude_code_v1.md` §4. Commit acotado, push a la rama.

PR contra `main` citando la medición 3 de F2 y el estado de la guarda de P-93 en esa corrida. **No mergees:** quedan dos gates del titular (este PR y el PR de refresh que la corrida abra). La delegación de R10 se agotó con #19.

Árbol como lo encontraste: `git status --porcelain` en cero, `git worktree list` en una línea, `git diff --stat HEAD -- 20_insumos` en cero.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. El `git diff` no contiene ninguna línea no autorizada por §3 y §4.
3. Si mañana alguien deja un archivo con datos personales bajo `20_insumos/`, ¿qué lo detiene? Contéstalo nombrando la compuerta y la prueba de F1 que demuestra que funciona, no de memoria.
4. ¿Qué commits llegaron a `main` en esta corrida y por qué estaba autorizado cada uno? Si alguno no cae bajo `50_documentacion/`, el push violó §3.

---

## §7. Reporte final al chat

1. F0.0 a F0.4, crudas, incluido el resultado del merge de #19 leído de su endpoint propio.
2. `git diff` completo de los dos archivos.
3. Las dos pruebas de la validación (falla cuando debe, calla cuando debe), con salida literal.
4. Resultado de F2: `conclusion`, inventario de staged, conteo por subdirectorio en la rama de refresh, y qué dijo la guarda de P-93 en su primera corrida en el runner.
5. Hashes, número del PR de P-99, número del PR de refresh, rutas de los dos logs.
6. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
