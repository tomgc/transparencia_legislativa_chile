# Bitácora — P-99: el refresh versiona las capturas crudas que R declara

> **Encargo:** `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md` (v3).
> **Sesión:** 24 (2026-08-19/20). **Ejecutor:** Claude Code, modo autónomo.
> **Rama:** `fix/p99-rutas-crudo-desde-r`.

## 1. Resumen de la sesión

El paso «Commit en rama y apertura del PR» del refresh semanal enumeraba a mano
las rutas que commitea (`.github/workflows/refresh-semanal.yml:115`), y esa lista
se quedó en el mundo previo al paso 37: versionaba `20_insumos/camara` y dejaba
fuera `20_insumos/senado`. Consecuencia medida: la promesa de P-65 («regenero
cualquier intermedio desalineado sin red, desde la captura ya versionada») no se
podía cumplir para el paso 37 en el corte vigente.

El cambio es uno solo: **el YAML deja de enumerar rutas y se las pregunta a R**.
`rutas_versionables_crudo()` traduce `DIRECTORIOS_CRUDO` (que ya existía) a
`file.path("20_insumos", DIRECTORIOS_CRUDO)`. Con eso hay una sola declaración en
vez de dos listas que deben coincidir sin que nada lo obligue, que es la forma
exacta del defecto.

Ampliar la lista al directorio completo (lo que proponía la v1 del encargo) se
descartó por lo que la auditoría de gobernanza midió: invertía el régimen de
fallo. Con enumeración sólo entra lo que alguien nombró; con el directorio entra
todo lo que nadie excluyó, y al otro lado de esa línea hay respuestas crudas de
sondeo con padrón nominal del Senado (157 correos y 53 teléfonos) que el proyecto
ya deliberó y falló en contra de publicar. Por eso el helper deriva de una
**constante nominada**, no del contenido del disco, y por eso se agrega una
compuerta mecánica: entre el `git add` y el `git commit`, un bloque en R exige
que todo lo staged caiga bajo lo declarado y mata el job nombrando la ruta
intrusa. `.gitignore` pasa a ser la segunda línea de defensa en vez de la única.

## 2. Inventario de commits

| Hash | Rama | Mensaje |
|---|---|---|
| `c050dfb` | `main` (local, **sin push**) | docs: encargo P-99 v3 |
| `de320c8` | `fix/p99-rutas-crudo-desde-r` | feat(p99): helper `rutas_versionables_crudo()` |
| `3bbfdbd` | `fix/p99-rutas-crudo-desde-r` | fix(p99): el refresh deriva de R las rutas y valida el staged |

`f5b3869` (merge del PR #19) llegó a `origin/main` por el merge delegado, no por
un commit de esta corrida.

## 3. F0 — estado y compuertas

### 3.1 F0.0 — qué había ya escrito (H4)

Rama al abrir: `main`. Árbol: el encargo v3 modificado sin stagear y
`50_documentacion/traspasos/paquete_cierre_v23.md` sin trackear (no se tocó: no
es de este encargo).

**H4 es FALSA.** Los 7 commits documentales de la sesión 23 ya estaban en
`origin/main` antes de esta corrida; `git log --oneline origin/main..main`
devolvió vacío tras `git fetch --all --prune`, y una verificación por commit con
`git branch -r --contains` dio 7 de 7 en `origin/main`. La autorización de push a
`main` del encargo se quedó sin objeto.

El log de auditoría de gobernanza **ya existía**:
`50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md`, 12 463
bytes, entrado en `8d9e74f`. Se verificó que contiene las cuatro cosas que el
encargo exigía comprobar antes de decidir si agregaba una sección: los conteos por
subdirectorio (§2), la calibración del barrido con sus cinco patrones y el señuelo
inyectado en la columna `xml` (§4), el hallazgo de `.gitignore` y el padrón (§5) y
que `.gitkeep` invalidaba el argumento de la v1 (§6). **No se reescribió ni se le
agregó nada.**

### 3.2 F0.1 — merge de PR #19

Estado previo, leído del endpoint propio del PR: `state=open`, `merged=FALSE`,
`mergeable=TRUE`, `mergeable_state=clean`, 7 commits, 6 archivos. Mergeado con
`gh pr merge 19 --merge`, sin `--squash`, sin `--rebase`, sin `--delete-branch`.

Estado posterior, leído otra vez del endpoint propio (nunca de `gh pr list`):

```
state: closed | merged: TRUE
merged_at: 2026-08-20T01:56:08Z
merge_commit_sha: f5b3869332342eededd4994f32a881bdfd38a8e2
```

Con la guarda de P-93 dentro, `main` local se rebaseó sobre `origin/main`: 1
commit replantado, **0 descartados por equivalencia de parche**, sin conflictos.

### 3.3 La decisión de no pushear `c050dfb`

El único commit que `main` local tiene por delante de `origin/main` es
`c050dfb`, el encargo v3. Cae entero bajo `50_documentacion/`, así que pasa la
comprobación mecánica de F0.1, **pero no es uno de «los commits documentales de
la sesión 23 que ya existen en local»**, que es la redacción literal del 🔒 de §3.
Como H4 resultó falsa, esa autorización no cubre ningún commit real. Se optó por
la lectura estricta: **no se pusheó**. El encargo v3 viaja en el PR de P-99 junto
al cambio, y llega a `main` por revisión del titular en vez de por push directo.

Esto deja `main` local 1 commit por delante de `origin/main` al cerrar, que es la
única desviación respecto del criterio de éxito «main publicado y limpio» de F0.
Queda declarada, no disimulada.

### 3.4 F0.2 — el defecto sigue ahí (R1 y R2 re-medidos hoy)

`grep -n 'git add' .github/workflows/refresh-semanal.yml`:

```
115:          git add 10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data
```

Literal idéntico al de R1, con el Senado omitido. Conteo en R sobre
`git ls-files 20_insumos` (62 archivos trackeados):

| subdir | archivos | csv | gitkeep | rds | txt |
|---|---|---|---|---|---|
| `camara` | 57 | 0 | 1 | 56 | 0 |
| `senado` | 3 | 0 | 1 | 1 | 1 |
| `territorio` | 2 | 2 | 0 | 0 | 0 |

R2 se sostiene (57/3/2) y R4 también: `20_insumos/senado/.gitkeep` está trackeado.

### 3.5 F0.3 — la declaración en R (H2 verdadera)

```
10_utils/10_utils.R:249: DIRECTORIOS_CRUDO <- c("camara", "senado")
```

Evaluada en R: `camara, senado`, largo 2, `"territorio" %in% DIRECTORIOS_CRUDO`
es `FALSE`. **Una sola declaración**: las otras tres ocurrencias del identificador
en el repo son un comentario (`10_utils.R:419`), un default de argumento
(`10_utils.R:422`) y un arnés (`50_verificar_p66_acto_b.R:117`). H2 se cumple en
los tres términos y el diseño de §4 procede.

### 3.6 F0.4 — quién más la usa (H3 **falsa**)

| Función | Línea | Deriva de `DIRECTORIOS_CRUDO` |
|---|---|---|
| `reportar_estado_capturas()` | `10_utils.R:422` | **Sí** (`subdirs = DIRECTORIOS_CRUDO`) |
| `ruta_cache()` | `10_utils.R:239` | **No**: `subdir = "camara"`, literal |
| `capturas_crudas_de_paso()` | `10_utils.R:581` | **No**: hereda el default literal de `ruta_cache()` en las ramas 32–36, y escribe `subdir = "senado"` a mano en la rama 37 (`10_utils.R:603`) |

Dos literales sueltos, entonces: `10_utils.R:239` y `10_utils.R:603`. Es el
alcance de **P-102**, confirmado con números de línea de hoy. Se registra como
hallazgo y no se toca: 🔒 «un solo cambio conceptual».

## 4. F1 — el cambio

### 4.1 El helper (`de320c8`)

```r
# Traduce la declaracion de arriba a las rutas que el bot del refresh versiona.
# El paso "Commit en rama" de .github/workflows/refresh-semanal.yml depende de
# esta funcion: ampliar DIRECTORIOS_CRUDO amplia lo que el bot commitea (P-99).
rutas_versionables_crudo <- function() {
  file.path("20_insumos", DIRECTORIOS_CRUDO)
}
```

Cuerpo mínimo, sin descubrimiento ni listado de disco: traduce la declaración que
ya existe. Devuelve rutas relativas a la raíz del repo, que es desde donde el
runner corre `git add`.

Verificación 1 de F1:

```
$ Rscript -e 'source("10_utils/10_utils.R"); cat(rutas_versionables_crudo(), sep=" ")'
20_insumos/camara 20_insumos/senado
```

### 4.2 El workflow (`3bbfdbd`)

Cinco piezas, todas dentro del mismo paso: la variable `RUTAS_CRUDO` derivada de
R con fusible de vacío (`exit 1`, porque un `git add` con la variable vacía
degradaría el conjunto en silencio), el `git add` usando la variable, el
inventario de staged al log del job, la compuerta de validación en R, y el
comentario de cabecera reescrito.

### 4.3 Las dos pruebas de la compuerta

El bloque de validación se **extrajo literal del YAML ya escrito** (líneas
134–149, por marcadores, no copiado a mano) y se ejecutó en un worktree
desechable sobre la rama, para que lo probado sea el código que va a correr y no
una réplica.

**Calla cuando debe.** Con un refresh legítimo simulado (corte nuevo, un alta por
directorio de crudo, un JSON publicado; ninguna captura existente tocada):

```
Rutas de crudo declaradas en R: 20_insumos/camara 20_insumos/senado
--- inventario staged ---
  staged: 10_utils/10_configuracion.R
  staged: 20_insumos/camara/20260819_prueba_p99_sim.rds
  staged: 20_insumos/senado/20260819_prueba_p99_sim.rds
  staged: 40_salidas/json/prueba_p99_sim.json
  staged: docs/data/prueba_p99_sim.json
Validacion del staged: 5 rutas, 5 declaradas.
EXIT_VALIDACION=0
```

La tercera línea es P-99 cerrado en miniatura: la captura del Senado entra al
staged, cosa que con la enumeración a mano no ocurría.

**Falla cuando debe.** Sobre ese mismo staged se cuela un archivo bajo
`20_insumos/territorio/`, que R no declara:

```
--- inventario staged ---
  staged: 10_utils/10_configuracion.R
  staged: 20_insumos/camara/20260819_prueba_p99_sim.rds
  staged: 20_insumos/senado/20260819_prueba_p99_sim.rds
  staged: 20_insumos/territorio/20260819_intruso_p99.csv
  staged: 40_salidas/json/prueba_p99_sim.json
  staged: docs/data/prueba_p99_sim.json
Validacion del staged: 6 rutas, 5 declaradas.

### RUTA INTRUSA EN EL STAGED -> NO se publica ###
  - 20_insumos/territorio/20260819_intruso_p99.csv

Declaradas: 10_utils/10_configuracion.R, 40_salidas/json, docs/data, 20_insumos/camara, 20_insumos/senado
EXIT_VALIDACION=1
```

El worktree se eliminó (`git worktree remove --force`); `git worktree list` quedó
en una línea.

### 4.4 Un hallazgo del arnés: zsh no divide en palabras

El primer intento de la prueba falló con `fatal: pathspec '20_insumos/camara
20_insumos/senado' did not match any files`. La causa no era el YAML: era el
shell local. **zsh no hace word splitting** en expansiones sin comillas; bash sí.
El runner de GitHub Actions corre `run:` con `bash -e {0}`, así que `git add
... $RUTAS_CRUDO ...` se divide como corresponde allá. Las pruebas se rehicieron
invocando `bash` explícitamente. El dato queda registrado porque cualquier arnés
futuro que pruebe este YAML en macOS va a pisar la misma piedra.

### 4.5 Control de no regresión (verificación 5 de F1)

`run_all(only = 39)` **no puede completarse en local**, y por una razón que es el
propio P-99: los 7 intermedios están desalineados respecto del corte vigente
(2026-08-17) y la guarda de P-65 no puede regenerarlos porque falta
`20_insumos/senado/20260817_tramitacion_sil_2026_tope-inf.rds`, es decir, la
captura que el refresh **no versionó**. Es R9 materializado en la máquina del
titular, no un defecto introducido por el cambio.

El control se hizo igual, y por comparación: la misma invocación se corrió en la
rama y en `main`, y las dos salidas son **idénticas línea a línea** (12 y 12) una
vez neutralizado el sello de tiempo del log. El helper no altera nada del
pipeline. Como subproducto, la guarda de P-93 corrió en ambas y quedó en
silencio.

## 5. F2 — la corrida real desde la rama

**Consecuencias asumidas y consumadas:** descargas reales desde el runner
(18,5 min de `run_all()` completo), creación de la rama `refresh/2026-08-20` y
apertura de su PR contra `main`, el **#20**, que **no se mergea**. Una sola
corrida; no hubo relanzamiento.

Corrida [32323119488](https://github.com/tomgc/transparencia_legislativa_chile/actions/runs/32323119488),
`head_branch = fix/p99-rutas-crudo-desde-r`, `conclusion = success`, **9 de 9
pasos en verde**, incluido «Commit en rama y apertura del PR», que es el que este
encargo cambió.

### 5.1 Lo que R le dijo al YAML en el runner

```
Rutas de crudo declaradas en R: 20_insumos/camara 20_insumos/senado
```

Word splitting de bash mediante (§4.4), el `git add` recibió dos pathspecs.

### 5.2 Inventario de staged (leído del log del job)

1 251 rutas staged. Desglose contado en R sobre las líneas `staged:` del paso 8
del log:

| prefijo | rutas |
|---|---|
| `10_utils` | 1 |
| `20_insumos/camara` | 6 |
| **`20_insumos/senado`** | **2** |
| `40_salidas` | 621 |
| `docs` | 621 |

Las dos del Senado, literales:

```
  staged: 20_insumos/senado/20260820_tramitacion_pedidos.txt
  staged: 20_insumos/senado/20260820_tramitacion_sil_2026_tope-inf.rds
```

**Bajo `territorio/`: 0 rutas**, que es lo que el 🔒 exigía.

### 5.3 La validación de §4 no mató el job

```
Validacion del staged: 1251 rutas, 1251 declaradas.
```

0 líneas con `RUTA INTRUSA`. La compuerta calló en la corrida real, igual que en
la prueba local, y el job siguió a commit y push.

### 5.4 La medición que cierra P-99

`git ls-tree -r --name-only origin/refresh/2026-08-20 -- 20_insumos`, contado en R:

| subdir | `origin/main` | `refresh/2026-08-20` | delta |
|---|---|---|---|
| `camara` | 57 | 63 | +6 |
| **`senado`** | **3** | **5** | **+2** |
| `territorio` | 2 | 2 | 0 |
| **total** | **62** | **70** | **+8** |

Altas, las 8: las 6 capturas del corte de la Cámara y **las 2 del Senado**. Bajas:
ninguna. Antes de este cambio las dos últimas no existían en ninguna rama que el
bot produjera: eran exactamente el agujero de P-99. La promesa de P-65 ahora sí
alcanza al paso 37.

### 5.5 La guarda de P-93 en su primera corrida en el runner

**Silencio.** 0 líneas del paso `run_all` mencionan `verificar_registro_pasos`,
`incoherencia`, `registro de pasos` o `PASOS_SIN_INTERMEDIO`. La guarda sólo
habla cuando falla, así que el silencio es el veredicto: el registro de pasos está
sincronizado en las cuatro estructuras, medido en Ubuntu y no sólo en macOS local.

No hubo que investigar P-100: `body(capturas_crudas_de_paso)[[2]]` no degradó a
falso positivo, porque de haberlo hecho la guarda habría abortado el job antes de
la primera descarga y el job terminó en verde con las 7 capturas escritas.

La guarda de P-65 sí habló, y lo correcto: el runner parte de un checkout limpio,
así que declaró primera corrida del corte con 0 de 7 intermedios en disco y sin
rastro de arranque previo, y dejó que los pasos 32–37 los crearan.

**Un dato que la corrida deja para el titular** (no es de este encargo): el paso
37 avisó que descartó 1 de 5 078 trámites por año implausible (`25/05/2626` en el
boletín `18232-25`), fecha errónea de la fuente, no evento futuro.

## 5bis. Bugs

### 5bis.1 El bug que P-99 cierra (clase, no caso)

No es «faltaba `20_insumos/senado` en una línea». Es que **dos listas tenían que
coincidir y nada las obligaba**: la declaración de fuentes de crudo en R y la
enumeración de rutas en el YAML. El paso 37 se sumó a la primera en su momento y
nadie tocó la segunda, porque nada falla cuando se olvida. El síntoma tardó una
corrida entera del bot en aparecer, y apareció lejos: en la copia local del
titular, como un `run_all()` que no arranca. La clase se cierra derivando una de
la otra; el caso se cerró de paso.

### 5bis.2 Bug propio del arnés: zsh no divide en palabras

Descrito en §4.4. La primera prueba de la compuerta falló por el shell local, no
por el código probado. Costó una iteración y quedó registrado porque volverá a
pasarle a quien pruebe este YAML en macOS.

### 5bis.3 Un error de medición evitado: el zip de logs duplica

El zip que devuelve `gh api .../logs` trae 12 archivos: el log del job **y** cada
paso por separado. Contar `staged:` sobre la concatenación de todos daba 2 508
rutas, exactamente el doble de las 1 251 reales. La medición reportada toma un
solo archivo (`8_Commit en rama y apertura del PR.txt`). Vale para cualquier
medición futura sobre logs de Actions.

## 6. Verificación de invariantes (§6 del encargo)

1. **Toda cifra viene de un bloque de R de esta corrida.** Los conteos por
   subdirectorio, el largo de `DIRECTORIOS_CRUDO`, la comparación de las dos
   salidas de `only = 39`, el inventario de staged del log del job y el conteo en
   la rama de refresh se calcularon con `Rscript` en el mismo turno en que se
   reportan. Ninguna se heredó de la corrida de detención de la v2.
2. **El `git diff` no contiene líneas fuera de §3 y §4.** La rama toca exactamente
   dos archivos respecto de `main` (`10_utils/10_utils.R` y
   `.github/workflows/refresh-semanal.yml`), verificado con
   `git diff --name-only main...`. Ocurrencias de `git add .` o `git add -A` en el
   YAML: **0**. La constante, el pipeline y la guarda de P-93 no se tocaron.
3. **Si mañana alguien deja un archivo con datos personales bajo `20_insumos/`,
   ¿qué lo detiene?** Dos cosas, en este orden. Primero, el `git add` sólo alcanza
   `20_insumos/camara` y `20_insumos/senado`, porque son las que
   `rutas_versionables_crudo()` devuelve; un archivo en cualquier otro
   subdirectorio no se stagea siquiera. Segundo, si algo lo stagea de todos modos
   (otro paso, un `git add` futuro, un merge), la compuerta de validación entre el
   `git add` y el `git commit` lo nombra y mata el job con `quit(status = 1)`. Eso
   no es una afirmación de memoria: es la prueba de §4.3, donde un archivo bajo
   `20_insumos/territorio/` produjo `EXIT_VALIDACION=1` y la línea
   `### RUTA INTRUSA EN EL STAGED -> NO se publica ###`. Lo que **no** detiene
   nada es un archivo con datos personales depositado dentro de `camara/` o
   `senado/` con nombre plausible: esas dos rutas están declaradas, y la compuerta
   valida rutas, no contenido. `.gitignore` cubre los patrones de sondeo conocidos
   (`.gitignore:49-57`) y queda como segunda línea. El hueco se registra en §8.
4. **Qué llegó a `main` en esta corrida y por qué.** A `origin/main` llegó
   `f5b3869`, el merge de PR #19, autorizado nominalmente por R10 y por el
   titular. Nada más: `c050dfb` se quedó sin publicar por decisión de §3.3. No
   hubo push de ningún commit de este encargo.

## 7. Decisiones del titular registradas en gates

| Gate | Decisión | Efecto |
|---|---|---|
| Merge de PR #19 | Delegado en la sesión 24, **acotado a #19**, con `--merge` y sin `--delete-branch` | Ejecutado. La guarda de P-93 entró en producción |
| Merge del PR de P-99 | **No delegado** | El PR queda abierto |
| Merge del PR de refresh que esta corrida abre | **No delegado** | El PR queda abierto |
| Push a `main` | Autorizado sólo para los commits documentales de la sesión 23 ya existentes en local | Sin objeto: H4 resultó falsa. No se pusheó nada |

## 7bis. Decisiones autónomas

1. **No pushear `c050dfb`.** Fundamento y consecuencia en §3.3.
2. **Comparar `only = 39` entre rama y `main` en vez de exigir que complete.**
   Completar era imposible sin red y la red local está prohibida por 🔒. La
   igualdad línea a línea de las dos salidas prueba lo que el control pedía —que
   el helper no altere el pipeline— sin violar el invariante.
3. **Extraer el bloque de validación del YAML por marcadores** en vez de
   reescribirlo en el arnés. Una réplica escrita a mano prueba la réplica.
4. **No tocar `50_documentacion/traspasos/paquete_cierre_v23.md`**, que estaba sin
   trackear al abrir. No es de este encargo; queda como lo encontré.
5. **Dejar el `git add` dependiendo del word splitting de bash.** Es correcto en el
   runner (§4.4) y es la forma idiomática; envolverlo en un arreglo o en `xargs`
   habría sido más código por un escenario que no ocurre.

## 8. Dudas y pendientes abiertos

1. **La compuerta valida rutas, no contenido.** Un archivo con datos personales
   depositado dentro de `20_insumos/camara/` o `20_insumos/senado/` con nombre
   plausible pasa las dos barreras. El barrido de datos personales que la
   auditoría de gobernanza hizo sobre la captura del SIL fue manual y de una vez;
   no hay nada que lo repita en cada corrida. Convertirlo en compuerta del job es
   otro encargo.
2. **Dos literales sueltos de subdirectorio** (`10_utils.R:239` con `"camara"`,
   `10_utils.R:603` con `"senado"`) no derivan de `DIRECTORIOS_CRUDO`. Es P-102,
   confirmado con números de línea de hoy en §3.6. El helper de este encargo no lo
   resuelve ni lo empeora: agrega un tercer consumidor de la constante, que sí
   deriva.
3. **`main` local queda 1 commit por delante de `origin/main`** (`c050dfb`).
   Se resuelve mergeando el PR de P-99 o pusheándolo, decisión del titular.
4. **La captura del SIL del corte 2026-08-17 sigue sin versionar** y por eso
   `run_all()` en la copia local del titular no arranca (§4.5). Lo resuelve la
   primera corrida del refresh que se mergee con este cambio dentro, no el cambio
   por sí solo.
5. **El PR de refresh que esta corrida abrió no se mergea** por instrucción
   explícita: la delegación se agotó con #19.

## 9. Estado de cifras y datos críticos

- Ninguna captura cruda ya escrita se modificó ni se borró. Las altas de las
  pruebas ocurrieron en un worktree desechable, ya eliminado.
- `git diff --stat HEAD -- 20_insumos` en el repo real: vacío.
- El árbol quedó con el mismo archivo sin trackear con que se abrió
  (`50_documentacion/traspasos/paquete_cierre_v23.md`).
- Descargas locales: **0**. La única red fue el merge de #19, la corrida del
  workflow y las consultas de estado a la API de GitHub.

## 10. Notas para el revisor

Tres cosas que conviene mirar antes de mergear el PR de P-99.

**El régimen de fallo sigue cerrado, y esa es la pregunta central.** El helper
devuelve `file.path("20_insumos", DIRECTORIOS_CRUDO)`: deriva de una constante
nominada, no del contenido del disco. Un directorio nuevo bajo `20_insumos/` no
entra al commit del bot hasta que alguien lo escriba en `DIRECTORIOS_CRUDO`, que
es una línea de R con historial y revisión. Es lo mismo que garantizaba la
enumeración a mano, con una lista en vez de dos.

**Ampliar `DIRECTORIOS_CRUDO` ahora tiene un efecto que antes no tenía.** Hasta
este cambio, esa constante sólo decidía qué vigilaba el contrato temporal de P-74.
Desde este cambio decide, además, qué publica el bot. El comentario del helper lo
dice en la línea siguiente a la constante, que es donde lo va a leer quien la
edite.

**El PR trae tres archivos, no dos.** Los dos del cambio más el encargo v3
(`c050dfb`), que no se pusheó a `main` por lo dicho en §3.3 y viaja aquí.

Y una cuarta, sobre la corrida: el PR #20 (`refresh/2026-08-20`) quedó abierto a
propósito. Mergearlo publica el corte del 2026-08-20 **y** deja versionada por
primera vez la captura del SIL, con lo que `run_all()` vuelve a arrancar en la
copia local del titular sin red. Es la decisión que la delegación de esta sesión
no cubría.
