# Encargo autónomo — P-99 v2: el refresh versiona las capturas crudas que R declara

> **Destino:** `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md`
> **Reemplaza** a la v1 del mismo día, en la misma ruta. **Sobrescribe el archivo; no crees un `_v2` en el repo.**
> **Redactor:** asistente de análisis (Claude conversacional), sesión 23.
> **Ejecutor:** Claude Code, modo autónomo.
>
> **Por qué hay v2.** La v1 fijaba `git add 20_insumos` completo. La detención de F0 lo midió y la decisión era mala: invierte el régimen de fallo (de "sólo entra lo nombrado" a "entra todo lo no excluido") y deja el rechazo del padrón del Senado sostenido por una línea de `.gitignore`, en un directorio cuyo próximo ocupante ya está declarado. Además uno de sus dos argumentos era factualmente falso: `20_insumos/senado/.gitkeep` está trackeado, así que el `checkout` siempre materializa el directorio y el `git add` no podía abortar por inexistencia. El redactor afirmó estado del repositorio sin leerlo; queda registrado.
>
> La v2 **no adopta la enumeración de dos rutas en el YAML**, porque eso deja dos listas que pueden desincronizarse y esa es exactamente la clase de defecto que P-99 arregla. El YAML deja de enumerar y le pregunta a R.

---

## §0. Contrato positivo

### 0.1 Respaldado (fuente leída o ejecutada en la sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | El paso de commit enumera rutas a mano y omite el Senado: `git add 10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data` | `.github/workflows/refresh-semanal.yml:115`, verificado literal por el ejecutor en F0 |
| R2 | `20_insumos/` trackeado tiene tres subdirectorios: `camara` (57), `senado` (3), `territorio` (2) | F0.2, conteo en R sobre `git ls-files`, esta sesión |
| R3 | `20_insumos/territorio/` **no** es captura cruda: son dos CSV de insumo estático auditado (D5), que el pipeline sólo lee (`leer_csv_territorio`, `32_extraer_diputados.R:50`) y cuya regla declarada es actualizarlos a mano con revisión del diff | F0.2, esta sesión |
| R4 | `20_insumos/senado/.gitkeep` está trackeado: el `checkout` materializa el directorio siempre | F0 del ejecutor, `git ls-tree -r --name-only HEAD -- 20_insumos/senado` |
| R5 | `.gitignore:50-56` excluye respuestas crudas de sondeo que incluyen endpoints de padrón del Senado con 157 correos y 53 teléfonos nominales; el proyecto ya deliberó y falló en contra de publicarlos | F0 del ejecutor, texto del propio `.gitignore` |
| R6 | `GET /api/parlamentarios` figura como fuente de padrón NO USADA en `50_catalogo_fuentes_senado.md:315`: el próximo ocupante de esa zona ya está declarado | F0 del ejecutor |
| R7 | La captura del SIL versionada está limpia: 3 271 894 caracteres barridos, 0 correos, 0 RUT, 0 teléfonos, con los 5 patrones calibrados (5/5 señuelos detectados) y un señuelo inyectado en la columna `xml` detectado | F0.3, esta sesión, con panel de verificación independiente |
| R8 | La única captura del SIL versionada la subió el titular a mano (`b4b0bcd`); 0 de 8 commits del bot tocaron `senado/`. El problema que P-99 ataca es real | F0 del ejecutor |
| R9 | El paso 37 corrió y escribió su intermedio en el CI del 2026-08-17, pero su captura cruda no quedó versionada | log de P-93 §4.2, esta sesión |

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Comando |
|---|---|---|
| H1 | PR #19 está mergeado y `main` local se pone al día sin conflicto | F0.1 |
| H2 | Existe en R una constante que declara los directorios de captura cruda (`DIRECTORIOS_CRUDO` u otro nombre), su contenido es exactamente `camara` y `senado`, y no incluye `territorio` | F0.2 |
| H3 | `ruta_cache()` y `capturas_crudas_de_paso()` construyen sus rutas a partir de esa misma constante, y no de literales sueltos | F0.3 |

**Si H2 es falsa** (no existe tal constante, o incluye `territorio`), **detente y reporta**: el diseño de §4 depende de que exista una única declaración en R, y fabricarla sobre la marcha cambiaría el alcance del encargo.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

---

## §2. Contexto mínimo suficiente

El refresh semanal enumera a mano qué rutas commitea, y esa lista se quedó en el mundo anterior al paso 37: versiona la Cámara y deja fuera el Senado. La consecuencia es que la promesa de P-65 ("regenero cualquier intermedio desalineado sin red, desde la captura ya versionada") hoy no se puede cumplir para el paso 37 en el corte vigente.

Arreglarlo tiene una trampa que la v1 pisó: ampliar la lista al directorio completo cambia el régimen de fallo. Con una enumeración, sólo entra lo que alguien nombró; con el directorio, entra todo lo que nadie excluyó, y lo que hay al otro lado de esa línea (R5, R6) es material que el proyecto decidió no publicar.

**Este encargo cambia una cosa:** de dónde saca el workflow la lista de rutas. Deja de estar escrita en el YAML y pasa a derivarse de la declaración que ya existe en R.

---

## §3. Invariantes (🔒)

- 🔒 **Un solo cambio conceptual.** Se editan `.github/workflows/refresh-semanal.yml` y, si H2 lo permite, **nada más** del lado de R que un helper de una línea que imprima las rutas. No se toca la constante, ni el pipeline, ni la guarda de P-93.
- 🔒 **El régimen de fallo es cerrado.** Ninguna ruta llega al commit sin estar declarada en R. Si el conjunto staged contiene algo fuera de lo declarado, el job **falla**; no se filtra silenciosamente ni se commitea "lo bueno".
- 🔒 `20_insumos/territorio/` **no lo commitea el bot**. Es insumo estático con revisión manual de diff (R3).
- 🔒 **No mergees ningún PR** ni hagas push a `main`.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 R es el único lenguaje para medir o contar. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`, ni en el YAML ni en tus commits.
- 🔒 **Ninguna descarga local.** La única red autorizada es **un** `gh workflow run` (F2) y las consultas de estado a la API.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.

---

## §4. La decisión de metodología (es del redactor, no tuya)

**El YAML deja de enumerar rutas de captura y le pregunta a R cuáles son.**

```bash
          RUTAS_CRUDO=$(Rscript -e 'source("10_utils/10_utils.R"); cat(rutas_versionables_crudo(), sep=" ")')
```

y luego `git add 10_utils/10_configuracion.R $RUTAS_CRUDO 40_salidas/json docs/data`.

`rutas_versionables_crudo()` es un helper nuevo que devuelve `file.path("20_insumos", DIRECTORIOS_CRUDO)` (con el nombre real que F0.2 confirme), y nada más. No inventa, no descubre, no lista el disco: **traduce la declaración que ya existe**.

**Por qué así y no la enumeración de dos rutas en el YAML:** dos listas que deben coincidir y nada que lo obligue es la definición del defecto que P-99 arregla. Con el helper hay una sola declaración, y agregar el Senado completo mañana no requiere tocar el YAML. El régimen de fallo sigue cerrado, porque el helper deriva de una constante nominada, no del contenido del directorio.

**Y la barrera se hace explícita, no implícita.** Después del `git add`, antes del `git commit`, el job valida en R que el conjunto staged esté contenido en lo declarado:

- toda ruta staged debe caer bajo `10_utils/10_configuracion.R`, `40_salidas/json`, `docs/data` o una de las rutas de `rutas_versionables_crudo()`;
- cualquier otra cosa **mata el job** con `quit(status = 1)` nombrando la ruta intrusa.

Esto es lo que convierte a `.gitignore` en la segunda línea de defensa en vez de la única (R5). Es una compuerta mecánica: no pide criterio a nadie en el momento en que el criterio estaría comprometido.

---

## §5. Fases

### F0 — Estado y compuertas

**F0.0 — El encargo y la auditoría, en su ruta y commiteados.**

1. Sobrescribe `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md` con este archivo.
2. Escribe la auditoría de gobernanza que ya produjiste en la corrida de detención (el hallazgo de `.gitignore` y el padrón, la calibración del barrido de dato personal con sus cinco patrones y el señuelo inyectado, los conteos por subdirectorio, y el hecho de que `.gitkeep` invalidaba el argumento de la v1) en `50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md`. **Es medición, no relato:** cada cifra con el comando que la produjo.
3. Commit único de los dos, con rutas acotadas. Verifica antes con `git -C ... rev-parse --abbrev-ref HEAD` que estás en `main` y no en la rama de P-93 (en la corrida anterior el commit cayó en la rama activa y hubo que moverlo).

**F0.1 — Compuerta de partida (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
gh api repos/tomgc/transparencia_legislativa_chile/pulls/19 > /tmp/pr19.json
```

Lee `state`, `merged`, `merged_at` en R. **Detente si #19 no está mergeado.** Con él mergeado:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rebase origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -8
```

Reporta qué commits sobrevivieron al rebase y cuáles descartó por equivalencia de parche. Si hay conflicto, **detente**.

**F0.2 — La declaración en R (H2).** Localiza en `10_utils/10_utils.R` la constante que declara los directorios de captura cruda (`grep -n 'DIRECTORIOS_CRUDO\|subdir'`). Reporta su definición literal con número de línea y su contenido evaluado en R. **Detente si no existe, si incluye `territorio`, o si hay más de una declaración compitiendo.**

**F0.3 — Quién más la usa (H3).** Reporta, con número de línea, si `ruta_cache()` y `capturas_crudas_de_paso()` derivan sus rutas de esa constante o de literales sueltos. Es un hallazgo, no un obstáculo: si hay literales, se registra como pendiente y se sigue.

**Criterio de éxito de F0:** H1, H2 y H3 resueltas con su salida, y la auditoría de gobernanza commiteada.

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
4. **Auditoría heredada (nota 10 del log de P-93):** ¿la guarda de P-93 emitió silencio o una lista de incoherencias? Cita la línea. Si habló, va arriba en el reporte.
5. Que la validación de §4 no haya matado el job por un falso positivo. Si lo hizo, el diseño está mal y hay que reportarlo, no aflojar la validación.

---

### F3 — Log, PR y cierre

Log en `50_documentacion/andamios/logs/20260819_p99_rutas_crudo_desde_r_log.md`, plantilla de `encargo_autonomo_claude_code_v1.md` §4. Commit acotado, push a la rama.

PR contra `main` citando la medición 3 de F2 y el estado de la guarda de P-93 en esa corrida. **No mergees:** quedan dos gates del titular (este PR y el PR de refresh que la corrida abra).

Árbol como lo encontraste: `git status --porcelain` en cero, `git worktree list` en una línea, `git diff --stat HEAD -- 20_insumos` en cero.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. El `git diff` no contiene ninguna línea no autorizada por §3 y §4.
3. Si mañana alguien deja un archivo con datos personales bajo `20_insumos/`, ¿qué lo detiene? Contéstalo nombrando la compuerta y la prueba de F1 que demuestra que funciona, no de memoria.

---

## §7. Reporte final al chat

1. F0.1 a F0.3, crudas.
2. `git diff` completo de los dos archivos.
3. Las dos pruebas de la validación (falla cuando debe, calla cuando debe), con salida literal.
4. Resultado de F2: `conclusion`, inventario de staged, conteo por subdirectorio en la rama de refresh, y qué dijo la guarda de P-93.
5. Hashes, número del PR de P-99, número del PR de refresh, rutas de los dos logs.
6. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
