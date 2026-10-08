# Bitácora — P-93: guarda de sincronía del registro de pasos

> **Encargo:** `50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md` (v2).
> **Ejecutor:** Claude Code, modo autónomo, un turno.
> **Fecha de ejecución:** 2026-08-19.
> **Andamio congelado:** no se actualiza.

---

## 1. Resumen de la sesión

Entró la v2 del encargo P-93, que reemplaza en la misma ruta a una v1 que no
pudo ejecutarse: su compuerta exigía los PR #16, #17 y #18 mergeados, y no lo
estaban. La v2 delega el merge de esos tres y revisa las compuertas.

Cinco fases, todas completadas: **F0** (encargo commiteado, tres merges, rebase
local, cuatro estructuras releídas), **F1** (la guarda nueva), **F2** (el
directorio del mensaje deja de estar escrito a mano), **F3** (panel adversarial
de dos agentes), **F4** (este log y el PR).

Estado final: **PR abierto, sin mergear**, con dos commits de código y el panel
concordante en PASA sobre las cuatro afirmaciones.

Lo que costó: tres arneses de verificación míos salieron mal antes de salir
bien, todos por la misma causa — `source("00_run_all.R")` re-resuelve la raíz del
proyecto, así que un arnés lanzado desde el repo mide el repo aunque uno crea
estar midiendo un worktree. Lo detecté porque un resultado no cuadró (§5.3), no
porque lo previera; y advertí de la trampa a los dos panelistas, que la
esquivaron desde el primer intento. Un cuarto arnés midió el worktree
equivocado por estar en el commit de F1 y no tener aún el cambio de F2, y lo
delató una FALLA que resultó ser del arnés (§5.4).

---

## 2. Inventario de commits

| Fase | Hash | Tipo | Título | Qué hace |
|---|---|---|---|---|
| F0.0 | `9a5d115` | `docs` | encargo P-93 v2 (merges delegados y compuertas revisadas) | Sobrescribe la v1 en la misma ruta (94 inserciones, 59 borrados). El `_v2` entregado no queda en el repo. |
| F1 | `61bc1b6` | `fix` | guarda de sincronia del registro de pasos (P-93) | `verificar_registro_pasos()` en `10_utils/10_utils.R`; campo `intermedios` en `PASOS`, `PASOS_SIN_INTERMEDIO` y la invocación, en `00_run_all.R`. 2 archivos, 134 inserciones, 6 borrados. |
| F2 | `182661d` | `fix` | el directorio del stop de la guarda se deriva de la captura, no se escribe a mano | 1 archivo, 11 inserciones, 1 borrado. |
| F4 | (ver §7 del reporte) | `docs` | log de P-93 | Este archivo. |

**Los tres merges delegados** (§0.2 del encargo), verificados uno a uno con
`gh api repos/.../pulls/<N>`, no con `gh pr list`:

| PR | rama | merged | merged_at | merge commit |
|---|---|---|---|---|
| #18 | `refresh/2026-08-17` | TRUE | 2026-08-19T14:28:07Z | `77894647af` |
| #16 | `fix/p86-runner-paso37` | TRUE | 2026-08-19T14:28:27Z | `968a2368c2` |
| #17 | `sondeo/p92-eje-tematico` | TRUE | 2026-08-19T14:28:37Z | `31ebafd69b` |

En el orden que el encargo fija: #18 primero (dato fresco a producción), #16
segundo (precondición sustantiva de P-93), #17 tercero. Ninguno dio conflicto.

**Rebase de F0.1ter.** Los cuatro commits documentales locales sin push se
rebasaron sobre `origin/main`. Hashes nuevos, porque el traspaso los citará:

| antes | después | commit |
|---|---|---|
| `f9302a6` | `5b8b73c` | docs: encargo sesion 23 (panel PR #16 + diagnostico P-91) |
| `5e655c1` | `14d2ca4` | docs: log panel adversarial PR #16 y diagnostico P-91 |
| `ab4b7fc` | `e80c9d1` | docs: encargo P-93 (guarda de registro de pasos) |
| `deafe4d` | `9a5d115` | docs: encargo P-93 v2 (merges delegados y compuertas revisadas) |

El contenido no cambió; sólo el hash, por reescritura de base. El rebase fue
limpio (4/4, sin conflicto).

---

## 3. Por cada cambio sustantivo

### 3.1 `verificar_registro_pasos()` (F1, `61bc1b6`)

**Qué.** Una guarda estructural y estática en `10_utils/10_utils.R:608-708`,
invocada desde `run_all()` en `00_run_all.R`, **antes** de
`regenerar_intermedios_si_desalineados()`. Compara cuatro estructuras y se
detiene nombrando al paso huérfano y la estructura que le falta. Con todo
sincronizado devuelve `invisible(TRUE)` y no imprime nada.

**Por qué (causa raíz, no síntoma).** El defecto que costó P-86 no fue que el
paso 37 faltara en tal o cual lista: fue que **nada obligaba a que las listas
concordaran**, así que un paso nuevo podía quedar registrado a medias y el
síntoma aparecía dos sesiones después, en un mensaje de recuperación que mandaba
a correr los pasos equivocados. P-93 no arregla el caso (lo hizo PR #16): cierra
la clase.

**Archivos.** `10_utils/10_utils.R` (la función), `00_run_all.R` (el campo
`intermedios` en `PASOS`, la constante `PASOS_SIN_INTERMEDIO` y la invocación).

**Tensiones resueltas, y la decisión que no estaba en el encargo.** El encargo
pide comprobar que cada paso "tenga entrada en `INTERMEDIOS_PIPELINE`", pero esa
constante es un vector de **nombres** (`"tramitacion"`), no de ids, y no existía
ninguna correspondencia paso → intermedio de la que derivarla. Tampoco es
1:1: el paso 33 produce dos intermedios, así que ni siquiera contar sirve. Sin
un mapa, dos de las tres membresías eran verificables y la tercera no.

Resolví declarando el mapa **dentro de `PASOS`**, como un campo `intermedios`
por paso, en vez de crear una quinta lista paralela. La razón es la misma que
sostiene todo P-93: una lista aparte es una estructura más que se puede
desincronizar; un campo en la entrada del paso hace que agregar un paso y
registrar su intermedio sean el mismo acto. El mapa se derivó del fuente, no de
memoria: `grep` de `ruta_salidas("intermedios", ...)` sobre los siete scripts de
`30_procesamiento/`, comprobando que el 33 **lee** `diputados.rds`
(`33_extraer_asistencia.R:197`, vía `leer_sellado`) y **escribe** los dos de
asistencia (`:301` y `:319`).

Segunda desviación menor: la firma quedó con cuatro parámetros
(`pasos`, `excepciones`, `extraccion`, `intermedios`), los dos primeros
exactamente como el encargo los fija y los otros dos con default. Así la llamada
del control conocido-bueno, `verificar_registro_pasos(PASOS)`, es la que el
encargo especifica, y la función es **pura de verdad**: todo lo que lee entra por
argumento. Sin eso, una función de `10_utils.R` dependería de una global definida
en `00_run_all.R`, que es el acoplamiento que P-93 combate.

**Verificación.** §6.1 y §6.2.

### 3.2 El directorio del mensaje se deriva (F2, `182661d`)

**Qué.** En el `stop()` de `regenerar_intermedios_si_desalineados()`, el literal
`"20_insumos/camara/"` se sustituye por un `%s` alimentado por `etiqueta_dirs`,
derivado con `dirname()` sobre las rutas que `capturas_crudas_de_paso()` ya
devolvió en `faltantes`. Tres líneas nuevas y dos cambios en el `sprintf()`.

**Por qué.** El literal mentía desde que existe el paso 37, cuya captura vive en
`20_insumos/senado/` porque el SIL está en otro host. El nombre del archivo y el
`source()` de recuperación siempre fueron correctos; lo que mandaba a mirar la
carpeta equivocada era esa línea.

**Autorización.** F0.4 la exigía: 7 coincidencias de `20_insumos/camara` en el
archivo, de las cuales **2 en código** (líneas 762 y 813 tras el merge), ambas
dentro de `regenerar_intermedios_si_desalineados()` y **0 dentro de `sellar()`
(:65), `leer_sellado()` (:89) o `validar_corte()` (:104)**. La asignación
función-por-línea se hizo en R por offsets de las definiciones, no a ojo.

**Lo que NO se tocó, y por qué.** La segunda coincidencia en código (la del
mensaje "tras regenerar, siguen desalineados") quedó con el literal. No es
descuido: a esa rama sólo se llega cuando `faltantes` está **vacío** por
construcción (si hubiera faltantes, la función se habría detenido antes), así que
no hay ninguna ruta de la que derivar el directorio. Cambiarla exigiría inventar
un criterio, y 🔒 manda cambio mínimo. Queda como pendiente en §8.

**Verificación.** §6.3.

---

## 4. Auditoría de diagnóstico

### 4.1 F0 — compuertas y estado real

| Punto | Medición | Veredicto |
|---|---|---|
| F0.1 | árbol limpio (0 líneas), `main..origin/main` vacío, `main` adelantado sólo por los commits documentales | compuerta abierta |
| F0.1bis | los tres PR `merged = TRUE`, con su `merged_at` y merge commit (§2) | H1 confirmada |
| F0.1ter | rebase limpio 4/4, hashes nuevos en §2 | al día |
| F0.3 | `INTERMEDIOS_PIPELINE` = **7** (con `tramitacion`); `PASOS` = 7 ids (32-37, 39); `PASOS_EXTRACCION` = **6** ids (32-37); `capturas_crudas_de_paso(37)` → **OK**, devuelve `20260817_tramitacion_sil_2026_tope-inf.rds` | **H2 confirmada**: el 37 registrado en las tres |
| F0.3 | `capturas_crudas_de_paso(39)` → `stop()` | por eso el 39 necesita la excepción |
| F0.4 | 2 coincidencias en código, ambas en la guarda, 0 en las funciones protegidas | **H3 confirmada, F2 autorizada** |
| F0.2 | `CORTE_FECHA` pasó a `2026-08-17` con el merge de #18 | contexto de F1.4 |

### 4.2 Hallazgo no previsto: el refresh no versiona la captura del paso 37

Medido al montar F1.4, contando en R sobre `git ls-files`:

```
          subdir
corte      camara senado
  20260706      5      0
  20260710      5      0
  20260713      5      0
  20260720      7      0
  20260725      7      0
  20260727      7      0
  20260803      8      0
  20260812      6      1
  20260817      6      0
```

El refresh del 2026-08-17 (PR #18, ya mergeado) versionó **6 capturas, todas en
`camara/`**. El paso 37 corrió en ese CI y escribió su intermedio — el log de la
corrida verde lo dice, `[37_tramitacion] Escrito: .../tramitacion.rds (431
boletines)` —, pero **su captura cruda no quedó versionada**. De 9 cortes con
captura, sólo uno (`20260812`, creado a mano en la sesión de P-66) tiene la del
`senado/`.

**Consecuencia medida, no inferida:** en el árbol al corte vigente, `run_all()`
se detiene con `falta la captura cruda de ese corte en 20_insumos/senado/ (1
archivo(s)): 20260817_tramitacion_sil_2026_tope-inf.rds`, y esa detención ocurre
**igual en `main` y en la rama** (§6.2, control conocido-bueno). Es decir: la
promesa de P-65 — "regenero sin red desde la captura ya versionada" — hoy **no
se puede cumplir para el paso 37 en el corte vigente**. El defecto es del
workflow, no de P-93, y es anterior a este encargo.

No lo arreglé: 🔒 prohíbe tocar `.github/workflows/` y el encargo no lo pide.
Queda en §8 como el pendiente de mayor severidad de la sesión.

---

## 5. Bugs

### 5.1 El bug que P-93 previene (clase, no caso)

- **Síntoma histórico:** un paso nuevo registrado a medias; la guarda de P-65 no
  lo vigila, el desalineamiento aparece recién en `validar_corte()` dentro del
  39, y el mensaje manda a regenerar los pasos equivocados.
- **Causa raíz:** el registro estaba repartido en estructuras que nada obligaba a
  sincronizar, y la omisión era **silenciosa**.
- **Fix:** `verificar_registro_pasos()`, con el registro obligatorio por defecto
  y las exclusiones nominadas en `PASOS_SIN_INTERMEDIO`.
- **Verificación decisiva (§6 del encargo, pregunta 3): ¿habría atrapado el paso
  37 en la sesión de P-66?** Contestado con la prueba corrida, no con un
  razonamiento: reconstruí el estado real pre-#16 (`10_utils.R` de `2b5b3b7`, con
  `INTERMEDIOS_PIPELINE` de 6 y el switch sin la rama `"37"`) y le apliqué la
  guarda nueva:

```
Estado PRE-#16 efectivamente cargado:
  length(INTERMEDIOS_PIPELINE) = 6
  ramas del switch = 32, 33, 34, 35, 36
  'tramitacion' en INTERMEDIOS_PIPELINE: FALSE
  ids de PASOS_EXTRACCION (filtro de P-66) = 32, 33, 34, 35, 36

SI. STOP en la primera corrida:

verificar_registro_pasos: 1 incoherencia(s) en el registro de pasos.
  paso 37: NO registrado en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE,
  capturas_crudas_de_paso. No lo esta en ninguna de las tres. declara
  tramitacion, que no esta en INTERMEDIOS_PIPELINE.
```

  **Sí, en la primera corrida.** El defecto se habría pagado ese día en vez de
  dos sesiones después.

### 5.2 El bug de F2 — el directorio escrito a mano

Descrito en §3.2. **Fix:** `182661d`. **Verificación:** §6.3, tres escenarios.
Los dos panelistas lo confirmaron por separado, y el agente 2 lo midió además
**sin editar un solo archivo**, con el `CORTE_FECHA` real del repo: main dice
`camara/` y la rama dice `senado/` para el mismo archivo faltante.

### 5.3 Bug propio: tres arneses que midieron el repo creyendo medir un worktree

- **Síntoma:** el arnés de la auto-auditoría §6.3 reportó que el paso 37 "sí
  está en `INTERMEDIOS_PIPELINE` y en `capturas_crudas_de_paso`" mientras
  imprimía, tres líneas antes, que `INTERMEDIOS_PIPELINE` tenía 6 elementos y el
  switch iba de 32 a 36. La contradicción interna fue lo que me hizo mirar.
- **Causa raíz:** `00_run_all.R` hace `source()` de `10_utils/10_configuracion.R`
  y de `10_utils.R`, y `source()` evalúa en `globalenv()` **sin importar** el
  `envir` que uno le pase al `eval()` exterior. Así que evaluar `00_run_all.R`
  para extraer `PASOS` recargaba silenciosamente el `10_utils.R` **actual** sobre
  el estado pre-#16 que yo acababa de cargar.
- **Fix:** reordenar el arnés (extraer `PASOS` y el texto de la guarda primero,
  cargar el estado pre-#16 después, sin nada que vuelva a tocar `globalenv()`), y
  para los escenarios de F2, un proceso `Rscript` por escenario que arranque con
  `setwd(<worktree>)` e imprima `ROOT` para comprobar dónde está.
- **Verificación:** los arneses corregidos imprimen `ROOT = /private/tmp/wt-f2` y
  `CORTE_FECHA = 2026-08-12`, y ambos panelistas confirmaron la trampa por su
  cuenta (el agente 2 la elevó a control de calibración explícito, comprobando
  que sus dos procesos midieron worktrees distintos).
- **Consecuencia para el revisor:** ninguna cifra de este log proviene de los
  arneses defectuosos. Los tres se rehicieron y se reportan sólo los resultados
  de la versión corregida.

### 5.4 Bug propio: un worktree en el commit equivocado dio una FALLA falsa

- **Síntoma:** el escenario C de F2 (faltan capturas de ambos directorios)
  reportó `camara/` solamente, cuando debía decir `camara/ y senado/`.
- **Causa raíz:** el worktree se creó desde `HEAD`, que era el commit de F1
  (`61bc1b6`), y el cambio de F2 estaba sin commitear en el árbol principal. El
  worktree corría código previo al cambio que yo estaba probando.
- **Fix:** copiar el `10_utils.R` vigente al worktree y repetir. Los tres
  escenarios pasaron.
- **Regla aprendida:** un worktree creado desde `HEAD` no ve los cambios sin
  commitear. Si la prueba es de un cambio en curso, o se commitea primero o se
  copia el archivo.

---

## 6. Verificación de invariantes

| 🔒 | Verificación | Evidencia | Veredicto |
|---|---|---|---|
| Autoridad de merge acotada a #18, #16, #17 con `--merge` | Tres `gh pr merge --merge`, en ese orden. Sin `--squash`, `--rebase`, `--admin` ni `--delete-branch`. Ningún otro PR tocado | §2 | **PASA** |
| El PR que se abre en F4 no se mergea | Abierto y dejado abierto | §7 del reporte | **PASA** |
| No hacer push a `main` | Los merges los ejecutó GitHub del lado del servidor; el `main` local se puso al día con `rebase`, leyendo. `git push` sólo sobre la rama nueva | F0.1ter, F4 | **PASA** |
| `sellar()`, `leer_sellado()`, `validar_corte()` no se tocan | F0.4 midió 0 coincidencias del literal dentro de esas tres; el diff de la rama no las incluye | F0.4, `git diff` | **PASA** |
| La lógica de detección y regeneración no cambia | `deparse()` en dos procesos: toda la divergencia en un bloque contiguo de construcción del mensaje. Agente 1 lo probó **constructivamente**: borrando las 3 sentencias nuevas y deshaciendo los 2 cambios del `sprintf`, `rama reducida == main byte a byte: TRUE` | §6.3 | **PASA** |
| La guarda nueva es estructural y estática | Sólo lee objetos en memoria: `PASOS`, `PASOS_EXTRACCION`, `INTERMEDIOS_PIPELINE` y `body(capturas_crudas_de_paso)`. Ni una llamada a `file.exists()`, `readRDS()` ni red. Las ramas del `switch` se enumeran desde el AST, no leyendo el archivo | código en §6.5 | **PASA** |
| `10_utils/10_utils.R` no adquiere dependencias de paquetes | La función usa sólo `base`: `vapply`, `setdiff`, `intersect`, `lapply`, `body`, `names`, `sprintf`, `paste` | ídem | **PASA** |
| R único lenguaje; `bash` sólo para `git`, `gh`, `Rscript` | Todo el análisis, parseo de JSON y comparación de salidas en R. Ni Python, ni `jq`, ni `awk`, ni `sed` sobre datos | scripts de la corrida | **PASA** |
| `git add` con ruta acotada | Los tres `git add` nombran rutas explícitas; nunca `.` ni `-A` | §2 | **PASA** |
| Ninguna captura cruda se borra; mover y restituir con `on.exit(add = TRUE)` | Repo principal: `git status --porcelain` = **0 líneas**, `git diff --stat HEAD -- 20_insumos` = **0 líneas**. Las 3 rutas movidas existen con su tamaño original. Aparcaderos de ambos agentes vacíos. **60 archivos trackeados en `20_insumos`, 57 `.rds`** | `/tmp/p93_integridad.R` | **PASA** |
| Ninguna cifra sin recuento programático | Todas las de este log salen de scripts R de esta corrida | §4, §6 | **PASA** |
| Los intermedios no se versionan (D24) | `git ls-files 40_salidas/intermedios` = 1 archivo (`.gitkeep`), 0 `.rds`. Los 8 de producción conservan mtime `2026-08-13 22:11` / `18:02` | §9 | **PASA** |
| Árbol como se encontró | `git worktree list` final = **1 línea**. `git status --porcelain` = 0 | §9 | **PASA** |

### 6.1 Control conocido-bueno (A95)

```
=== CONTROL CONOCIDO-BUENO ===
PASOS_SIN_INTERMEDIO = 39
RESULTADO: sin stop(). Valor devuelto: TRUE
visible: FALSE
lineas impresas en stdout: 0
lineas impresas en stderr: 0
SILENCIO TOTAL: TRUE
```

Y `run_all(only = 39)` con el **mismo estado de disco** en `main` y en la rama
(los intermedios reales copiados al worktree de main, porque están gitignored):

```
lineas main: 12 | lineas rama: 12
identical(main, rama): TRUE
```

Las 12 líneas son idénticas, incluido el `stop()` de la guarda de P-65 que el
estado del árbol provoca (§4.2). **El control conocido-bueno pasa: la guarda
nueva no altera nada y no tiene falso rojo.**

### 6.2 Las pruebas que pueden fallar

Cinco escenarios, cada uno con su `stop()` literal. El primero es el que el
encargo pide; los otros cuatro los agregué para cubrir el sentido inverso y la
coherencia de las excepciones:

| # | Escenario | Se detiene | Nombra |
|---|---|---|---|
| 2 | paso 38 sólo en `PASOS` | sí | `paso 38` + las tres estructuras |
| 3 | intermedio `fantasma` sólo en `INTERMEDIOS_PIPELINE` | sí | `intermedio 'fantasma'` |
| 3bis | id 41 sólo en `PASOS_EXTRACCION` | sí | `paso 41: esta en PASOS_EXTRACCION pero no existe en PASOS` |
| 3ter | el 37 en `PASOS_SIN_INTERMEDIO` pese a estar registrado | sí | `paso 37: declarado SIN intermedio, pero esta registrado en...` |
| 3quater | excepción 99 inexistente en `PASOS` | sí | `paso 99: figura en PASOS_SIN_INTERMEDIO pero no existe en PASOS` |

`stop()` literal de la prueba 2, end-to-end (paso 38 escrito de verdad en el
`00_run_all.R` de una copia en `/tmp`, con `run_all()` completo):

```
verificar_registro_pasos: 1 incoherencia(s) en el registro de pasos.
  paso 38: NO registrado en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE,
  capturas_crudas_de_paso. No lo esta en ninguna de las tres. su entrada de
  PASOS no declara el campo `intermedios`.
  El registro es obligatorio por defecto: un paso nuevo debe entrar en
  PASOS (con su campo `intermedios`) y en PASOS_EXTRACCION, ambos en
  00_run_all.R, y en INTERMEDIOS_PIPELINE y capturas_crudas_de_paso(),
  ambos en 10_utils/10_utils.R. Si el paso no produce intermedio sellado,
  la exclusion es explicita: sumalo a PASOS_SIN_INTERMEDIO (00_run_all.R).
```

Ese `stop()` sale **antes** que el de la guarda de P-65, aun con el árbol en
estado hostil a las dos: el agente 1 lo midió con `menciona
verificar_registro_pasos: TRUE` y `menciona 'falta la captura cruda' (P-65):
FALSE`. El orden de invocación es el correcto.

**Idempotencia (F1.4).** `run_all()` completo no es ejecutable sin red al corte
vigente, por la captura ausente de §4.2, y eso vale igual en `main`. Lo corrí en
un arnés al corte `2026-08-12`, el único con las 7 capturas completas, montado
como copia en `/tmp` (el repo no se tocó), y contra los ficheros de `main` con
el mismo arnés:

```
RAMA: RESUMEN: 7 pasos ejecutados, 0 saltados, 16.6s en total.   exit=0
MAIN: RESUMEN: 7 pasos ejecutados, 0 saltados, 17.3s en total.   exit=0
lineas MAIN: 117 | lineas RAMA: 117 | identical: TRUE
menciones a 'verificar_registro_pasos' en la salida: 0
lineas con señal de red: 0
```

117 líneas idénticas. `git status --porcelain -- 40_salidas docs` en el repo:
**0 líneas** — porque las corridas fueron en arneses de `/tmp`, no en el repo.

### 6.3 F2 — los tres escenarios del directorio

| escenario | RAMA | MAIN |
|---|---|---|
| falta sólo la del 37 (`senado/`) | `...en 20_insumos/senado/ (1 archivo(s)): 20260817_tramitacion_sil_2026_tope-inf.rds.` | `...en 20_insumos/camara/ (...)` ← mentía |
| falta sólo una de `camara/` | `...en 20_insumos/camara/ (1 archivo(s)): 20260812_proyectos_long_2026_tope-inf.rds.` | idéntica, sin regresión |
| faltan de ambos | `...en 20_insumos/camara/ y 20_insumos/senado/ (2 archivo(s)): ...` | `...en 20_insumos/camara/ (2 archivo(s)): ...` ← mentía sobre la mitad |

En los tres, el `source()` de recuperación fue correcto en ambas ramas: lo único
roto en `main` era esa línea.

**Diff de `deparse()`** (mío, luego reproducido por los dos agentes):

```
lineas MAIN: 115 | lineas RAMA: 118
--- lineas SOLO en la rama (5) ---
  dirs_faltantes <- unique(dirname(unlist(faltantes, use.names = FALSE)))
  dirs_faltantes <- sub("^.*/(20_insumos/[^/]+)$", "\\1", dirs_faltantes)
  etiqueta_dirs <- paste0(paste(sort(dirs_faltantes), collapse = "/ y "), "/")
  "%s (%d archivo(s)): %s.\n", ...
  etiqueta_dirs, length(unlist(faltantes, ...
--- lineas SOLO en main (2) ---
  "20_insumos/camara/ (%d archivo(s)): %s.\n", ...
  length(unlist(faltantes, ...
```

Ninguna línea de detección ni de regeneración participa de la diferencia.

### 6.4 Panel adversarial (F3)

Dos agentes, arneses propios desde cero (`/tmp/p93_agente1/`,
`/tmp/p93_agente2/`), worktrees separados por agente, sin acceso a mi código de
verificación.

| Prueba | Agente 1 | Agente 2 | Concordancia |
|---|---|---|---|
| **Control de calibración** | **PASA** (4 controles: instrumento de silencio, guarda bueno/malo, comparador línea a línea, fusible de red con `exit 97`) | **PASA** (4 controles: fusible por dos vías, guarda bueno/malo, `ROOT` distinto en los dos procesos, comparador que sí detecta diferencias en D) | **Concordante** |
| **A** — silencio + `run_all()` completo | **PASA** (stdout 0, stderr 0, `visible=FALSE`; 7 pasos, 584 JSON, 0 disparos del fusible) | **PASA** (0 líneas con `sink()` doble; 7 pasos, 155 perfiles + 427 proyectos, cache hit en los 7) | **Concordante** |
| **B** — paso huérfano nombrado | **PASA** (+ sentido inverso: borrar el 37 de `PASOS` da 3 incoherencias) | **PASA** (+ batería de 5 sentidos inversos, todos nombrando el elemento) | **Concordante** |
| **C** — detección/regeneración idéntica | **PASA** (0 de 64 líneas discrepantes; prueba constructiva: rama reducida == main byte a byte) | **PASA** (0 de 68 líneas discrepantes; md5 del conjunto de intermedios idéntico entre worktrees) | **Concordante** |
| **D** — directorio correcto en ambos sentidos | **PASA** (3 escenarios) | **PASA** (3 escenarios + la prueba sin editar ningún archivo, al corte real) | **Concordante** |
| **Restitución** | 4/4 capturas restituidas, aparcaderos vacíos, worktrees con porcelain vacío | 4/4 con md5 idéntico al repo, aparcadero vacío | **Concordante** |

**Veredicto del panel: PASA, concordante en las cinco filas.**

Ninguna discrepancia entre agentes. Las cifras de líneas difieren entre ellos
(64 vs 68 en C, 70/67 vs 140/135 en `deparse`) porque cada uno usó sus propias
opciones de `deparse()` y su propia normalización; no son comparables entre
agentes por construcción, y lo comparable — el número de líneas **discrepantes**,
0 en ambos — coincide.

**Los dos hallaron por separado la misma fragilidad**, que yo verifiqué después
por mi cuenta: ver §8.

### 6.5 La función, tal como quedó

`10_utils/10_utils.R:608-708` (101 líneas con su comentario). La reproduzco
completa en el reporte al chat; aquí van las decisiones que un revisor debe
poder juzgar sin leerla entera:

- Firma `verificar_registro_pasos(pasos, excepciones, extraccion, intermedios)`,
  los cuatro con default salvo el primero.
- `esperados <- setdiff(ids_pasos, excepciones)`: el registro es obligatorio por
  defecto (§4 del encargo).
- Ramas del `switch` leídas del AST:
  `names(body(capturas_crudas_de_paso)[[2]])`.
- Tres comprobaciones directas por paso esperado, tres inversas (id en
  `extraccion` ausente de `PASOS`, rama del switch ausente de `PASOS`, intermedio
  que ningún paso declara) y dos de coherencia de las excepciones.
- `stop()` con una línea por incoherencia más el bloque que dice qué archivo y
  qué estructura editar; `invisible(TRUE)` en silencio si todo está sincronizado.

---

## 7. Decisiones del usuario registradas en gates

**Delegación de merge (§0.2 del encargo v2).** El titular delegó la autoridad de
merge sobre **#16, #17 y #18**, acotada: esos tres números, con `--merge`, en
esta sesión, y **sin alcanzar al PR que este encargo abre**. La delegación llegó
por dos vías concordantes: el mensaje del titular en la sesión y el §0.2 del
encargo v2 que la formaliza. Se ejecutó tal cual (§2) y no se extendió: el PR de
P-93 queda abierto.

**Gates no ejecutados:** mergear el PR nuevo, y el `push` de `main` (los cuatro
commits documentales siguen sin llegar a `origin/main`; viajan en la rama del PR,
§8).

---

## 7bis. Decisiones autónomas

| # | Decisión | Alternativa descartada | Reversibilidad |
|---|---|---|---|
| D1 | **Declarar el mapa paso→intermedio como campo `intermedios` dentro de `PASOS`** | Una constante `INTERMEDIOS_POR_PASO` aparte: sería una quinta estructura desincronizable, justo el problema que P-93 ataca. O renunciar a la tercera membresía, que el encargo pide explícitamente | Reversible (es aditivo; ningún consumidor previo lee ese campo) |
| D2 | **Firma de cuatro parámetros** en vez de dos | Leer `PASOS_EXTRACCION` como global desde `10_utils.R`: acopla el archivo de utilidades a una global de `00_run_all.R` y hace la función no testeable sin editar archivos | Reversible |
| D3 | **Enumerar las ramas del `switch` desde `body()`** | Parsear el archivo fuente: violaría 🔒 (la guarda no toca el filesystem). O renunciar a la comprobación inversa | Reversible |
| D4 | **No tocar la segunda coincidencia del literal** (línea 813) | Derivar también ahí: imposible sin inventar criterio, porque `faltantes` está vacío en esa rama por construcción | Reversible; declarado en §8 |
| D5 | **F1.4 medida en un arnés al corte 2026-08-12**, no en el repo al corte vigente | Correr `run_all()` completo en el repo al corte 2026-08-17: exigiría descargar del SIL (la captura del 37 no está versionada) y reescribiría `docs/` y `40_salidas/json/` en la rama del PR | Reversible; el repo no se tocó |
| D6 | **Cuatro worktrees para el panel** en vez de uno | Uno compartido: los dos agentes moviendo capturas a la vez habrían colisionado | Reversible; los cuatro retirados |
| D7 | **No arreglar la fragilidad del AST hallada por el panel** | Arreglarla ahora: dejaría el veredicto del panel emitido sobre código distinto al que se mergea | Reversible; declarado en §8 |
| D8 | **Cuatro pruebas de fallo adicionales** a las dos que el encargo pide | Quedarme en las dos: el sentido inverso y la coherencia de excepciones habrían quedado sin cubrir | Reversible |

---

## 8. Dudas y pendientes abiertos

*(Sin numerar como P-NN: la numeración la asigna el asistente en el cierre.)*

**Pendiente A — el refresh semanal no versiona la captura cruda del paso 37.**
Contexto: 9 cortes con captura versionada, sólo `20260812` tiene la del
`senado/`; el corte vigente `20260817` no (§4.2), así que `run_all()` no puede
regenerar sin red al corte vigente, ni en `main` ni en la rama.
Pregunta cerrada: **¿el workflow debe versionar `20_insumos/senado/` junto con
`20_insumos/camara/`, o la captura del SIL se excluye a propósito por tamaño o
licencia?**
Bloquea: la promesa de P-65 ("regenero sin red desde la captura ya versionada")
para el paso 37. **Es el pendiente de mayor severidad de la sesión.** No lo
toqué: 🔒 prohíbe editar `.github/workflows/`.

**Pendiente B — la guarda depende de la forma sintáctica de
`capturas_crudas_de_paso()`.**
Contexto: lee las ramas con `names(body(capturas_crudas_de_paso)[[2]])`, o sea
asume que el `switch` es la segunda expresión del cuerpo. Los dos panelistas lo
hallaron por separado; lo verifiqué yo mismo anteponiendo una sentencia inocua:
`b[[2]] es switch: FALSE` y `names()` devuelve vacío.
Modo de falla: **ruidoso, no silencioso** — la guarda acusa a los 6 pasos de no
estar registrados (falso positivo), nunca deja pasar un huérfano.
Pregunta cerrada: **¿se busca la llamada a `switch` recorriendo el cuerpo (dos
líneas más, robusto a inserciones), o se acepta la dependencia sintáctica dado
que el modo de falla es seguro?**
Bloquea: nada. Marca `# REVISAR` propuesta en la línea de `ramas <- names(...)`,
no escrita (el panel auditó el código tal como está, §7bis D7).

**Pendiente C — la segunda coincidencia del literal `20_insumos/camara/`.**
Contexto: `10_utils/10_utils.R:813` aprox., mensaje "tras regenerar, siguen
desalineados". No se derivó porque `faltantes` está vacío en esa rama.
Pregunta cerrada: **¿se deja el literal, se generaliza a "las capturas crudas de
`20_insumos/`", o se deriva de `DIRECTORIOS_CRUDO`?**
Bloquea: nada.

**Pendiente D — los cuatro commits documentales viajan en la rama del PR.**
Contexto: 🔒 prohíbe `push` a `main`, así que los commits `5b8b73c`, `14d2ca4`,
`e80c9d1` y `9a5d115` (encargos y log de la sesión anterior) no están en
`origin/main` y quedan incluidos en el PR de P-93, junto a los dos de código.
Pregunta cerrada: **¿se mergea el PR con los seis commits, o prefieres que los
documentales lleguen a `main` por su cuenta antes?**
Bloquea: la limpieza del historial, nada funcional.

**Duda sin resolver — `run_all()` completo nunca se corrió en el repo real.**
Se midió en arneses de `/tmp` (D5). La equivalencia byte a byte de `docs/data/`
entre rama y main no se midió; el agente 2 lo declaró también como limitación.
Pregunta cerrada: **¿se exige esa medición antes de mergear, o basta con las 117
líneas idénticas de la corrida completa y el hecho de que la rama no toca ningún
script de `30_procesamiento/`?**

---

## 9. Estado de cifras y datos críticos

| Objeto | Medición | Estado |
|---|---|---|
| Repo principal | `git status --porcelain` = **0 líneas** | **Limpio** |
| `20_insumos/` | `git diff --stat HEAD -- 20_insumos` = **0 líneas**; 60 archivos trackeados, 57 `.rds` | **Intacto** |
| Rutas movidas por el panel | `20260812_tramitacion_sil…` (275 006 b), `20260812_diputados.rds` (8 358 b), `20260812_proyectos_long…` (28 993 b) — las tres presentes | **Restituidas** |
| `40_salidas/intermedios/` | 8 archivos; los 7 `.rds` con mtime `2026-08-13 22:11` y el rastro con `18:02`, ambos anteriores a esta sesión | **Sin tocar** |
| Intermedios versionados | `git ls-files 40_salidas/intermedios` = 1 (`.gitkeep`), 0 `.rds` | **D24 respetado** |
| `docs/` y `40_salidas/json/` | `git status --porcelain -- 40_salidas docs` = 0 líneas; las corridas de `run_all()` fueron en arneses de `/tmp` | **Sin tocar** |
| Worktrees | 6 creados a lo largo de la sesión, 6 retirados; `git worktree list` = 1 línea | **Limpio** |
| `main` local | Al día con `origin/main` más los 4 commits documentales sin push | **Declarado en §8** |

---

## 10. Notas para el revisor

**Mira con ojo crítico:**

1. **La decisión D1** — el campo `intermedios` dentro de `PASOS`. Es la única
   parte del diseño que el encargo no fijó y que yo resolví solo, y toca la lista
   maestra del orquestador. Si prefieres una constante aparte, la guarda no
   cambia: sólo cambia de dónde lee `declarados`.
2. **El pendiente A** (captura del 37 sin versionar) es más grave que todo lo que
   este encargo arregla. P-93 impide que un paso nuevo quede huérfano; no impide
   que la captura de un paso registrado no llegue al repo. Son defectos hermanos
   y sólo el primero está cerrado.
3. **F1.4 no se midió en el repo real** (D5). Las 117 líneas idénticas entre main
   y rama son de un arnés al corte 2026-08-12. Si quieres la prueba en
   condiciones de producción, hay que resolver antes el pendiente A.
4. **El panel no midió** el camino de primera corrida, el escape
   `camara.permitir_descarga_inicial`, el intermedio ilegible, ni el JSON
   publicado. El agente 1 argumenta que la prueba constructiva de C los cubre por
   construcción (fuera de las 3 sentencias nuevas el cuerpo es byte a byte el de
   main); es un argumento fuerte, pero es un argumento, no una medición.
5. **Mis dos bugs de arnés** (§5.3 y §5.4) los detecté por contradicciones
   internas de la salida, no por diseño. En ambos casos el arnés defectuoso
   producía un resultado *plausible*. Si algo de este log te parece raro, el
   primer sospechoso debería ser el arnés que lo produjo.

**Audita después:** que el primer refresh tras mergear este PR imprima el
silencio de la guarda nueva y no una lista de incoherencias, y que la línea de
`falta la captura cruda` — si aparece — nombre `senado/` cuando el archivo sea el
del 37.
