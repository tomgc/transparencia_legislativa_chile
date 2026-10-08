# Encargo — P-58: resolver los dos PRs abiertos, por hunk

- **Destino en el repo:** `50_documentacion/andamios/50_encargo_p58_resolucion_prs.md`
- **Proyecto:** `transparencia_legislativa_chile`
- **Raíz absoluta:** `/Users/tomgc/Projects/transparencia_legislativa_chile`
- **Repo:** `tomgc/transparencia_legislativa_chile`
- **Sesión:** 16. **Pendiente:** P-58 (bloqueante de publicación).
- **Modo:** ejecución autónoma con compuertas. Te detienes SOLO donde el encargo lo dice.

---

## 1. Meta

Dejar `main` publicando el contrato de asistencia ya retirado, con el dato del corte más
reciente del bot, sin regenerar el pipeline y sin resucitar ningún campo legacy.

Hay dos PRs abiertos que tocan los mismos 310 archivos de datos (155 perfiles en
`40_salidas/json/perfiles/` y sus 155 espejos en `docs/data/perfiles/`) y conflictan en
ambos órdenes:

- **PR #4** — rama `retiro/contrato-legacy-asistencia`: retira del bloque `asistencia` de
  cada perfil los campos `anio`, `n_sesiones`, `n_asiste`, `n_no_asiste` y
  `tasa_asistencia`, y retira `tasa_asistencia` del índice.
- **PR #3** — rama del bot semanal (`refresh/<corte>`): refresco de datos del corte
  siguiente.

El conflicto ya fue medido en la sesión 15: **un solo hunk por archivo, y ese hunk es la
línea `metadatos.generado`, en 310 de 310**. Todo lo demás mergea limpio. Esa medición es
la premisa del encargo y **se vuelve a comprobar en la Fase 2 antes de usarse**; no se da
por cierta porque esté escrita aquí.

---

## 2. Invariantes (violarlos invalida el encargo)

1. **Prohibida la resolución a nivel de archivo.** Nada de `git checkout --ours`,
   `git checkout --theirs`, `git checkout <rama> -- <ruta>` ni `git restore --source`
   sobre los archivos en conflicto. Reinstala la versión íntegra del bot con los cinco
   campos legacy en 310 de 310 y deja el índice incoherente (aprendizaje A55).
2. **R es el único lenguaje para inspeccionar artefactos de datos.** Sin `jq`, `awk`,
   `python`, ni `grep`/`sed` sobre JSON. `git` y `gh` sí se usan como herramientas de
   repositorio.
3. **Todo comando de git lleva `git -C /Users/tomgc/Projects/transparencia_legislativa_chile`.**
   Nunca dependas del directorio heredado.
4. **Todo subcomando `gh pr` lleva `-R tomgc/transparencia_legislativa_chile`.**
   `gh api` es la excepción (el repo va en el endpoint).
5. **Prohibido `gh pr diff --name-only`**: devuelve HTTP 406 en PRs grandes y deja el
   check contando sobre vacío. Para listar archivos de un PR, `gh api` paginado sobre
   `/repos/tomgc/transparencia_legislativa_chile/pulls/<n>/files` y **declara el
   denominador**.
6. **`git add` siempre con ruta acotada.** Nunca `git add .` ni `git add -A`.
7. **`main` no recibe push directo.** Todo entra por merge de PR.
8. **No dispares el workflow** (`workflow_dispatch`) por ninguna razón.
9. **No regeneres el pipeline.** Este encargo no corre 32-36 ni 39. Si crees necesitarlo,
   detente y repórtalo: significa que la premisa del hunk único falló.
10. **`metadatos.generado` es volátil por construcción** (timestamp de reloj): queda
    excluido de toda comparación de igualdad entre artefactos, y esa exclusión se declara
    en el mismo enunciado de cada gate que la use. `corte_fecha` y `nota` **no** son
    volátiles y sí se verifican.
11. **Ningún `grep` de verificación con metacaracteres sin `-F`** (o `fixed = TRUE` en R).
    Un vacío por patrón es indistinguible de un vacío por ausencia.
12. **No afirmes `CORTE_FECHA` sin leer `10_utils/10_configuracion.R`** en el momento de
    afirmarlo.

---

## 3. Fases y compuertas

### Fase 0 — Estado real

Sin escrituras. Produce y muestra:

1. `git -C <raíz> fetch --all --prune` y luego `git -C <raíz> status`,
   `git -C <raíz> branch -vv`, `git -C <raíz> log --oneline -5 origin/main`.
2. La lista de PRs abiertos con su rama base y head:
   `gh pr list -R tomgc/transparencia_legislativa_chile --state open --json number,title,headRefName,baseRefName,mergeable`.
3. El valor vigente de `CORTE_FECHA`, leyendo el archivo:
   `git -C <raíz> show HEAD:10_utils/10_configuracion.R` o lectura directa del archivo en
   disco. Declara el valor con la ruta y la línea.
4. El estado de los dos commits que la sesión 15 dejó sin pushear en
   `retiro/contrato-legacy-asistencia` (`25a579f`, `53d78b5`): ¿siguen locales?

**Compuerta 0.** Si el número de PRs abiertos no es 2, o si sus ramas no son las
esperadas, o si el árbol de trabajo tiene cambios sin commitear que no reconozcas:
**detente y reporta**. No improvises una limpieza.

---

### Fase 1 — Merge del PR del bot a `main`

1. **Lee el cuerpo del PR del bot completo** antes de tocarlo:
   `gh pr view <n> -R tomgc/transparencia_legislativa_chile --json body,title,headRefName`.
   Reproduce en tu informe su **resumen de conteos**. El gate del bot detecta caídas de
   volumen, no cambios de sentido: la lectura es tuya, no del gate.
2. Si el resumen de conteos muestra una caída inexplicada o un cambio de sentido,
   **detente y reporta**. No mergees.
3. Si es conforme, mergea el PR del bot:
   `gh pr merge <n> -R tomgc/transparencia_legislativa_chile --merge`.
4. `git -C <raíz> fetch origin` y verifica que `origin/main` avanzó.

**Compuerta 1.** `origin/main` contiene el commit del bot y `CORTE_FECHA` en
`origin/main:10_utils/10_configuracion.R` es el corte nuevo, leído (no supuesto).

---

### Fase 2 — Medir el conflicto ANTES de resolver

Sitúate en la rama del retiro y trae `main`:

```
git -C <raíz> checkout retiro/contrato-legacy-asistencia
git -C <raíz> merge origin/main
```

El merge va a fallar con conflictos. **No resuelvas nada todavía.** Mide, en R:

```r
# Medir la forma del conflicto ANTES de resolverlo (A55).
# Devuelve una fila por archivo en conflicto.
medir_conflicto <- function(rutas) {
  purrr::map_dfr(rutas, function(r) {
    lineas <- readLines(r, warn = FALSE)
    ini <- grep("^<<<<<<<", lineas)
    sep <- grep("^=======$", lineas)
    fin <- grep("^>>>>>>>", lineas)
    ok_forma <- length(ini) == 1L && length(sep) == 1L && length(fin) == 1L
    # Contenido del hunk: TODAS las lineas no marcador deben ser "generado".
    solo_generado <- FALSE
    if (ok_forma) {
      cuerpo <- lineas[(ini + 1L):(fin - 1L)]
      cuerpo <- cuerpo[!grepl("^=======$", cuerpo)]
      cuerpo <- trimws(cuerpo)
      cuerpo <- cuerpo[nzchar(cuerpo)]
      solo_generado <- length(cuerpo) > 0L &&
        all(grepl('"generado"', cuerpo, fixed = TRUE))
    }
    data.frame(ruta = r, n_hunks = length(ini), ok_forma = ok_forma,
               solo_generado = solo_generado, stringsAsFactors = FALSE)
  })
}

resumen <- medir_conflicto(rutas_en_conflicto)
stopifnot(
  nrow(resumen) > 0L,
  all(resumen$n_hunks == 1L),
  all(resumen$ok_forma),
  all(resumen$solo_generado)
)
```

`rutas_en_conflicto` sale de `git -C <raíz> diff --name-only --diff-filter=U`, leída en R.

**Compuerta 2.** Reporta `nrow(resumen)` como denominador explícito y la tabla de
frecuencias de `n_hunks`. Si el `stopifnot()` falla por cualquier motivo (más de un hunk,
forma inesperada, contenido distinto de `generado`), **detente, aborta el merge con
`git -C <raíz> merge --abort` y reporta**. La premisa del encargo cayó: no se resuelve a
ciegas y no se compensa regenerando.

---

### Fase 3 — Resolver por hunk

Solo si la Compuerta 2 pasó. Para cada archivo en conflicto, en R, conserva el lado de
`main` (el del bot) dentro del hunk y **todo lo demás tal como el merge ya lo dejó**:

```r
resolver_hunk_generado <- function(ruta) {
  lineas <- readLines(ruta, warn = FALSE)
  ini <- grep("^<<<<<<<", lineas)
  sep <- grep("^=======$", lineas)
  fin <- grep("^>>>>>>>", lineas)
  stopifnot(length(ini) == 1L, length(sep) == 1L, length(fin) == 1L, ini < sep, sep < fin)
  # Se conserva el lado de origin/main (entre ======= y >>>>>>>): el timestamp del bot,
  # coherente con el corte_fecha y la nota que ya mergearon limpio.
  salida <- c(
    if (ini > 1L) lineas[1:(ini - 1L)] else character(0),
    lineas[(sep + 1L):(fin - 1L)],
    if (fin < length(lineas)) lineas[(fin + 1L):length(lineas)] else character(0)
  )
  writeLines(salida, ruta, useBytes = TRUE)
  invisible(TRUE)
}
```

Después de resolver los N archivos, **verifica que no quede ningún marcador**, en R:

```r
quedan <- purrr::map_lgl(rutas_en_conflicto, function(r) {
  any(grepl("^(<<<<<<<|=======$|>>>>>>>)", readLines(r, warn = FALSE)))
})
stopifnot(!any(quedan))
```

Luego `git -C <raíz> add` **con rutas acotadas** (los archivos resueltos, nunca `.`) y
commitea el merge con un mensaje que declare el criterio de resolución.

**Compuerta 3.** Cero marcadores residuales sobre el denominador completo de archivos en
conflicto, y `git -C <raíz> status` sin rutas en estado `U`.

---

### Fase 4 — Verificación de contenido sobre la rama, antes de publicar

En R, sobre el árbol de trabajo ya resuelto, con `jsonlite`. Los cinco campos legacy son
`anio`, `n_sesiones`, `n_asiste`, `n_no_asiste`, `tasa_asistencia`, dentro del bloque
`asistencia` de cada perfil.

Verifica y declara el denominador de cada afirmación:

1. **Perfiles sin campos legacy:** sobre los 155 de `40_salidas/json/perfiles/` y los 155
   de `docs/data/perfiles/`, **0 de 310** contienen cualquiera de los cinco campos dentro
   de `asistencia`.
2. **Índice sin `tasa_asistencia`:** en `40_salidas/json/indice_diputados.json` y en
   `docs/data/indice_diputados.json`, **0** entradas con esa clave, y `tasa_presencia`
   presente en todas.
3. **Corte homogéneo:** `metadatos.corte_fecha` es idéntico en los 310 perfiles y en los
   dos índices, e igual al `CORTE_FECHA` leído de `origin/main:10_utils/10_configuracion.R`.
4. **Espejo intacto:** `docs/data/` reproduce `40_salidas/json/` en los 155 md5 de perfil
   más el del índice. **Si esta comparación falla solo por `metadatos.generado`**, rehazla
   comparando clave a clave con ese campo excluido y declara la exclusión en el resultado;
   `generado` es volátil por construcción y no es evidencia de divergencia.
5. **Las cuatro claves sobrevivientes** (`alcance_temporal`, `periodo_vigente`,
   `en_ejercicio`, `sesiones`) están presentes en el bloque `asistencia` de los 155
   perfiles.

Cada verificación termina en un `stopifnot()`, no en un mensaje.

**Compuerta 4.** Las cinco pasan con su denominador declarado. Si alguna falla,
**detente y reporta**: no publiques.

---

### Fase 5 — Publicar

1. `git -C <raíz> push origin retiro/contrato-legacy-asistencia` (esto sube también los
   dos commits que la sesión 15 dejó locales).
2. Confirma que el PR #4 quedó `MERGEABLE`:
   `gh pr view 4 -R tomgc/transparencia_legislativa_chile --json mergeable,mergeStateStatus`.
3. Mergea: `gh pr merge 4 -R tomgc/transparencia_legislativa_chile --merge`.
4. `git -C <raíz> checkout main && git -C <raíz> pull origin main`.
5. **Repite íntegras las cinco verificaciones de la Fase 4 sobre `main` ya mergeado.**
   Esta repetición no es redundante: es la única que mide lo que quedó publicado.

**Compuerta 5.** Las cinco verificaciones pasan sobre `main`. Reporta cada una con su
denominador.

---

## 4. Criterios de éxito (contrastables)

Marca cada uno como CUMPLE / NO CUMPLE con la cifra y el artefacto del que sale (no la
familia de la fuente: la ruta concreta).

| # | Criterio | Medida |
|---|---|---|
| 1 | `main` sin campos legacy | 0 de 310 perfiles con alguno de los cinco campos en `asistencia` |
| 2 | Índice coherente | 0 entradas con `tasa_asistencia` y 155 con `tasa_presencia`, en los dos índices |
| 3 | Corte del bot publicado | `metadatos.corte_fecha` idéntico en 310 de 310 e igual al `CORTE_FECHA` leído de `main` |
| 4 | Espejo íntegro | `docs/data/` reproduce `40_salidas/json/` en 156 de 156 artefactos, excluido `metadatos.generado` |
| 5 | Contrato de Capa 3 intacto | las 4 claves sobrevivientes presentes en 155 de 155 perfiles |
| 6 | Sin regeneración | 0 corridas de los scripts 32-36 y 39 durante el encargo |
| 7 | Sin resolución por archivo | 0 usos de `checkout --ours/--theirs/<rama> -- <ruta>` |
| 8 | PRs cerrados | `gh pr list --state open` devuelve 0 PRs |

---

## 5. Entregable

Un log en `50_documentacion/andamios/logs/<AAAAMMDD>_p58_resolucion_prs_log.md` con:

1. Estado inicial de la Fase 0, incluido el `CORTE_FECHA` leído con su ruta y línea.
2. El resumen de conteos del PR del bot, reproducido.
3. La tabla de medición del conflicto con su denominador.
4. El criterio de resolución del hunk, declarado.
5. Las cinco verificaciones, dos veces (rama y `main`), cada cifra con **qué mide y de qué
   artefacto sale**, en columnas separadas.
6. La tabla de criterios de éxito de §4.
7. Cualquier decisión tomada en autonomía, en una línea cada una.

Commitea el log con ruta acotada. No abras PR nuevo para él si `main` ya está mergeado:
va directo en un commit de documentación.

---

## 6. Qué NO hace este encargo

- No toca el workflow de GitHub Actions.
- No regenera datos ni descarga nada de la API de la Cámara.
- No borra ramas (la poda es decisión posterior del titular).
- No verifica la republicación de Pages (se comprueba después, por identidad de md5).
- No toca `20_insumos/`.
