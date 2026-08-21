# Bitácora — Encargo A: derivar lo que ya está declarado, y una compuerta que mire el contenido

> **Encargo:** `50_documentacion/andamios/50_encargo_s24_encargo_a_derivacion_y_barrido.md`.
> **Cubre:** P-100, P-101, P-102 y P-105. **Sesión:** 24 (2026-08-20).
> **Rama:** `fix/encargo-a-derivacion-y-barrido`. **Ejecutor:** Claude Code, modo autónomo.

## 1. Resumen de la sesión

Cuatro pendientes, un PR. Los tres primeros son el mismo defecto en distintos
sitios (un dato que el programa ya tiene, vuelto a escribir a mano) y el cuarto
cierra el hueco que P-99 dejó abierto al validar rutas sin mirar contenido.

- **P-100.** `verificar_registro_pasos()` localizaba el `switch` de
  `capturas_crudas_de_paso()` con `body(...)[[2]]`, o sea por posición. Ahora lo
  **busca** en el AST con un helper nuevo, `localizar_switch()`, cuyas dos
  condiciones de contorno (ningún `switch`, más de uno) son fallos ruidosos.
- **P-101.** El mensaje que la guarda de intermedios emite *después* de regenerar
  decía `20_insumos/camara/` y no tenía de dónde derivar el subdirectorio, porque
  lo que reporta son nombres de intermedio. Se generaliza a `20_insumos/`.
- **P-102.** Seis literales de subdirectorio de crudo pasan a derivarse de dos
  constantes nominadas, `CRUDO_CAMARA` y `CRUDO_SENADO`, de las que a su vez
  deriva `DIRECTORIOS_CRUDO`. Equivalencia de rutas probada, 22 de 22.
- **P-105.** Función nueva `barrido_datos_personales()` con los cinco patrones
  calibrados en la auditoría de P-99, más un bloque en el workflow que la invoca
  sobre el crudo staged y mata el job nombrando archivo y patrón, nunca el texto.

**VEREDICTO DE LA SESION: el encargo NO se cierra.** El panel adversarial de F3
devolvio **NO PASA por los dos panelistas**, y sus cuatro defectos se reprodujeron
aqui uno por uno. El decisivo es una **regresion en el foco declarado**:
`localizar_switch()` muere con un error ajeno ante cualquier simbolo vacio en el
AST del cuerpo que audita, incluido el *fall-through* `"32" = ,` del propio
`switch` de capturas. Es el mismo modo de fallo que P-100 decia cerrar, con el
agravante de que el mensaje no nombra ni la guarda ni la causa. **No se abrio el PR
y no se toco el codigo**: F3 prohibe arreglar sobre la marcha. Detalle en §6.

**Lo que si quedo probado y sobrevive al panel:** P-101 y P-102 pasan limpios en
las dos revisiones independientes, con 28 de 28 rutas identicas sobre tres cortes;
el control conocido-bueno resiste una medicion mas dura que la mia (1 242 de 1 242
salidas con md5 identico); y el barrido de P-105 detecta senuelos que no escribi yo
y da 0 falsos positivos sobre 103 816 593 caracteres en 2,8 s.

**Lo más importante que esta corrida deja medido** es que P-100 no era teórico:
con el código de `main`, **una** sentencia antepuesta al `switch` hace que la
guarda declare huérfanos a los 6 pasos que sí están registrados y detenga
`run_all()` en su entrada, y con él, el cron. Con el código nuevo, silencio.

## 2. Inventario de commits

| Hash | Mensaje |
|---|---|
| `05f154a` | fix(p100): la guarda busca la llamada a switch en el cuerpo, no la toma por posicion (incluye el encargo) |
| `cb34726` | fix(p101): el mensaje post-regeneracion generaliza a 20_insumos/ en vez de nombrar camara |
| `25f6082` | fix(p102): los seis literales de subdirectorio de crudo derivan de constantes nominadas |
| `0551b9b` | feat(p105): barrido de dato personal sobre el crudo staged, como compuerta del job |

Cuatro archivos tocados y ningún otro, comprobado con `git diff --name-only
main...`: `10_utils/10_utils.R`, `.github/workflows/refresh-semanal.yml`,
`30_procesamiento/37_extraer_tramitacion.R` y el propio encargo.

## 3. F0 — estado y medición

### 3.1 F0.1 — punto de partida (H1 verdadera)

`main` local y `origin/main` en `0 0` tras `fetch --all --prune`, sin commits sin
publicar. Árbol con dos archivos sin trackear: el encargo de esta sesión (que
entra con el primer commit, por instrucción del titular) y
`50_documentacion/traspasos/paquete_cierre_v23.md`, que el 🔒 manda no tocar y no
se tocó. `git worktree list` en una línea.

### 3.2 F0.2 — el alcance real de P-102 (H2 **falsa**, y el número de hoy manda)

El inventario del traspaso v23 decía cinco sitios; F0.4 del encargo de P-99 había
medido dos. **Hoy son seis.** Ninguno de los dos recuentos previos era el de
hoy, y el traspaso queda corregido.

| # | Sitio (línea de hoy, antes del cambio) | Qué es |
|---|---|---|
| 1 | `10_utils/10_utils.R:239` | default `subdir = "camara"` de `ruta_cache()` |
| 2 | `10_utils/10_utils.R:470` | default `subdir = "camara"` de `con_cache()` |
| 3 | `10_utils/10_utils.R:610` | `subdir = "senado"` en la rama 37 de `capturas_crudas_de_paso()` |
| 4 | `30_procesamiento/37_extraer_tramitacion.R:246` | `ruta_insumos("senado", ...)` del `.txt` de pedidos |
| 5 | `30_procesamiento/37_extraer_tramitacion.R:280` | `subdir = "senado"` pasado a `con_cache()` |
| 6 | `30_procesamiento/37_extraer_tramitacion.R:440` | `subdir = "senado"` pasado a `ruta_cache()` |

**Lo que el traspaso contó de menos** fueron los dos defaults de `10_utils.R`
(`ruta_cache` y `con_cache`); **lo que P-99 contó de menos** fueron los tres del
paso 37 y el default de `con_cache()`. Los dos recuentos previos miraron una
parte del árbol.

**No entran** (clasificado en R, por forma del texto y no por una lista escrita a
mano): `10_configuracion.R:97` (`"2" = "senado"` es glosa del dominio «cámara de
origen» de un proyecto, no un directorio), `37:66` (`"camara"` es nombre de
columna del tibble de trámites), y dos comentarios.

**Fuera de alcance declarado:** los arneses de `50_documentacion/andamios/`
(`50_verificar_*.R`, `50_medicion_*.R`, `20260807_sondeo_fuentes.R`) tienen sus
propios literales `ruta_insumos("camara")`. Son reproductores de diagnóstico
congelados, fuera del pipeline, y tocarlos cambiaría instrumentos de medición ya
usados en decisiones anteriores. Se registra y no se toca.

### 3.3 F0.3 — los cinco patrones (H3 **falsa**, resuelta por la regla de §0.2)

El log de la auditoría de gobernanza **nombra** los cinco detectores pero **no
deja sus expresiones regulares**: la §4 imprime la tabla de resultados, no el
código. H3 es falsa, así que se aplicó la regla del encargo: no reconstruirlos de
memoria, sino extraerlos del arnés que la corrida de P-99 usó.

El arnés sobrevive en `/tmp/aud_medir2.R` (fuera del repositorio; nunca se
commiteó). **No basta con encontrarlo: se reprodujo.** Corrido hoy sobre la misma
captura, imprime byte a byte el bloque que el log §4 cita:

```
valores de texto no-NA: 1281 | caracteres barridos: 3271894
   correo           real=0 senuelo=1 delta=+1 DETECTA
   rut_con_puntos   real=0 senuelo=1 delta=+1 DETECTA
   rut_sin_puntos   real=0 senuelo=1 delta=+1 DETECTA
   telefono_cl      real=0 senuelo=1 delta=+1 DETECTA
   digitos_9mas     real=0 senuelo=1 delta=+1 DETECTA
   detectores ciegos: 0 de 5
   caracteres '@': 0 | caracteres '+': 0
   corridas de digitos: 51102 | longitud maxima: 5
   corridas de 7 a 9 digitos (rango de RUT y telefono): 0
   etiquetas XML distintas: 71 | etiquetas de contacto: 0
   <PARLAMENTARIO>: ocurrencias: 5055 | distintos: 369 | con digito: 0 | con @: 0
```

Los patrones adoptados son ésos, sin una coma de diferencia:

```r
correo         = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
rut_con_puntos = "\\b[0-9]{1,2}[.][0-9]{3}[.][0-9]{3}[-][0-9kK]\\b"
rut_sin_puntos = "\\b[0-9]{7,8}[-][0-9kK]\\b"
telefono_cl    = "\\+?56[ ]?[29][0-9]{7,8}\\b"
digitos_9mas   = "\\b[0-9]{9,}\\b"
```

**Pendiente que esto deja:** el arnés que produjo una cifra de gobernanza vivió
en `/tmp` y sobrevivió por casualidad. Si el disco se hubiera limpiado, la regla
de §0.2 habría obligado a detener el encargo.

### 3.4 F0.4 — números de línea de hoy (antes del cambio)

| Elemento | Línea |
|---|---|
| `ruta_cache()` | `10_utils.R:239` |
| `DIRECTORIOS_CRUDO` | `10_utils.R:249` |
| `rutas_versionables_crudo()` | `10_utils.R:254` |
| `reportar_estado_capturas()` | `10_utils.R:428` |
| `con_cache()` | `10_utils.R:469` |
| `capturas_crudas_de_paso()` | `10_utils.R:588` |
| `verificar_registro_pasos()` | `10_utils.R:634` |
| `regenerar_intermedios_si_desalineados()` | `10_utils.R:732` |
| `git add` del workflow | `refresh-semanal.yml:129` |

## 4. F1 — los tres refactores y sus seis verificaciones

### 4.1 Control conocido-bueno: `run_all()` completo (F1.1)

Protocolo, para que la comparación sea de estado estacionario contra estado
estacionario y no de primera corrida contra segunda: corrida de calentamiento en
`main` (regenera los intermedios al corte vigente), corrida medida en `main`,
corrida medida en la rama.

```
lineas main: 131 | lineas rama: 131
identicas linea a linea (sello y duracion de reloj neutralizados): TRUE
lineas de guarda de P-93 en main: 0 | en la rama: 0  -> SILENCIO en ambas: TRUE
'cache hit': 7 en main, 7 en la rama | 'cache miss'/'descargando'/'http': 0
```

Las tres únicas líneas que diferían antes de neutralizar la duración eran
`Paso 32 completado en 0.4s` vs `0.5s`, `Paso 39` `15.6s` vs `14.6s` y el resumen
`19.4s` vs `18.5s`: reloj, no contenido. **0 llamadas de red**, las 7 capturas
del corte resueltas por caché.

Las corridas reescribieron `40_salidas/json` y `docs/data` en el árbol. Se midió
qué cambió antes de restaurar: **2 476 líneas de diff en 1 238 archivos, las 2 476
del campo `metadatos.generado`** y ninguna otra. Restaurado con
`git checkout -- 40_salidas/json docs/data`.

### 4.2 Los cinco escenarios de fallo de P-93, re-corridos (F1.2)

Cada uno en su propio proceso, construidos pasando argumentos manipulados a
`verificar_registro_pasos()` (su firma los expone), sin editar ningún archivo.

| # | Escenario | Se detiene | Nombra |
|---|---|---|---|
| control | pipeline sano | **no** | — |
| 2 | paso 38 sólo en `PASOS` | sí | `paso 38: NO registrado en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE, capturas_crudas_de_paso` |
| 3 | intermedio `fantasma` sólo en `INTERMEDIOS_PIPELINE` | sí | `intermedio 'fantasma': esta en INTERMEDIOS_PIPELINE y ningun paso de PASOS lo declara` |
| 3bis | id 41 sólo en `PASOS_EXTRACCION` | sí | `paso 41: esta en PASOS_EXTRACCION pero no existe en PASOS` |
| 3ter | el 37 en `PASOS_SIN_INTERMEDIO` pese a estar registrado | sí | `paso 37: declarado SIN intermedio, pero esta registrado en PASOS_EXTRACCION, capturas_crudas_de_paso, el campo 'intermedios' de PASOS` |
| 3quater | excepción 99 inexistente en `PASOS` | sí | `paso 99: figura en PASOS_SIN_INTERMEDIO pero no existe en PASOS` |

5 de 5 se detienen nombrando el elemento; el control calla.

### 4.3 El escenario que P-100 arregla (F1.3) — la prueba que distingue arreglado de reescrito

En dos worktrees desechables se insertó **la misma** sentencia
(`stopifnot(length(id) == 1L)`) como primera expresión del cuerpo de
`capturas_crudas_de_paso()`, y se corrió la guarda sobre el pipeline sincronizado.

**Rama (con P-100):**

```
sentencia insertada tras la linea 598 de 10_utils/10_utils.R
ramas detectadas: 32, 33, 34, 35, 36, 37
--- veredicto de la guarda ---
SILENCIO
```

**`main` (sin P-100):**

```
sentencia insertada tras la linea 588 de 10_utils/10_utils.R
ramas detectadas: (ninguna)
--- veredicto de la guarda ---
verificar_registro_pasos: 6 incoherencia(s) en el registro de pasos.
  paso 32: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
  paso 33: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
  paso 34: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
  paso 35: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
  paso 36: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
  paso 37: NO registrado en capturas_crudas_de_paso. Si lo esta en PASOS_EXTRACCION, INTERMEDIOS_PIPELINE.
```

Una línea de más y la guarda que existe para proteger el pipeline lo detiene
entero. Ése es el modo de fallo que P-100 cierra, y en `main` está a una línea de
distancia.

### 4.4 Las dos condiciones de contorno de §4.1 (F1.4)

Fallos ruidosos, más tres controles positivos que prueban que la búsqueda no se
volvió permisiva:

| Caso | Resultado |
|---|---|
| A. cuerpo sin ningún `switch` | `STOP: no hay ninguna llamada a switch() en el cuerpo de fn_de_prueba(). La guarda del registro de pasos no puede auditar sus ramas, y no degrada a silencio` |
| B. cuerpo con **dos** `switch` | `STOP: 2 llamadas a switch() en el cuerpo de fn_de_prueba(); se esperaba exactamente una. Elegir cual auditar seria adivinar` |
| C. `switch` precedido por una sentencia | OK, ramas `32` |
| D. `switch` anidado en `if` + `local` | OK, ramas `32` |
| E. `switch` envuelto en `invisible()` | OK, ramas `32,33` |

### 4.5 La tabla de equivalencia de P-102 (F1.5)

Sonda que imprime rutas **relativas a la raíz del checkout**, corrida en la rama
y en un worktree de `main`, sobre dos cortes. Las expresiones del paso 37 las lee
**del propio archivo del checkout**, para medir la versión que tiene delante y no
una copia escrita a mano.

| clave | main (literal) | rama (derivado) | = |
|---|---|---|---|
| paso 32, corte 2026-08-20 | `20_insumos/camara/20260820_diputados.rds` | idéntica | SI |
| paso 33 (a), corte 2026-08-20 | `20_insumos/camara/20260820_periodo_legislativo.rds` | idéntica | SI |
| paso 33 (b), corte 2026-08-20 | `20_insumos/camara/20260820_asistencia_nominal_2026_tope-inf.rds` | idéntica | SI |
| paso 34, corte 2026-08-20 | `20_insumos/camara/20260820_votos_long_2026_tope-inf.rds` | idéntica | SI |
| paso 35, corte 2026-08-20 | `20_insumos/camara/20260820_proyectos_long_2026_tope-inf.rds` | idéntica | SI |
| paso 36, corte 2026-08-20 | `20_insumos/camara/20260820_detalle_proyectos_xml_2026_tope-inf.rds` | idéntica | SI |
| **paso 37, corte 2026-08-20** | `20_insumos/senado/20260820_tramitacion_sil_2026_tope-inf.rds` | idéntica | SI |
| `ruta_cache()` con default, corte 2026-08-20 | `20_insumos/camara/20260820_sonda.rds` | idéntica | SI |
| los 8 anteriores, corte 2026-07-27 | idem con prefijo `20260727` | idénticas | SI (8) |
| `37_pedidos` (`.txt` de la lista pedida) | `20_insumos/senado/20260820_tramitacion_pedidos.txt` | idéntica | SI |
| `37` subdir pasado a `con_cache()` | `"senado"` → `senado` | `CRUDO_SENADO` → `senado` | SI (mismo valor) |
| `37` subdir pasado a `ruta_cache()` | `"senado"` → `senado` | `CRUDO_SENADO` → `senado` | SI (mismo valor) |
| `37` captura vía `ruta_cache()` | `20_insumos/senado/20260820_tramitacion_sil_2026_tope-inf.rds` | idéntica | SI |
| `DIRECTORIOS_CRUDO` | `camara,senado` | `camara,senado` | SI |
| `rutas_versionables_crudo()` | `20_insumos/camara,20_insumos/senado` | idéntica | SI |

**22 filas, 22 idénticas. Veredicto: equivalencia total.** Las dos filas de
«mismo valor» son las que comparan el símbolo con su valor: el texto del programa
cambió (`"senado"` → `CRUDO_SENADO`), el valor evaluado no.

### 4.6 Los tres mensajes de P-101 (F1.6)

Worktree desechable con los intermedios copiados y el corte movido a 2026-08-12
(el único, además del vigente, con captura completa en los dos directorios). Cada
escenario aparta la captura correspondiente (la mueve, no la borra) y la restaura.

| escenario | mensaje |
|---|---|
| A: falta la del 37 | `...falta la captura cruda de ese corte en 20_insumos/senado/ (1 archivo(s)): 20260812_tramitacion_sil_2026_tope-inf.rds.` + `source("30_procesamiento/37_extraer_tramitacion.R")` |
| B: falta una de la Cámara | `...en 20_insumos/camara/ (1 archivo(s)): 20260812_proyectos_long_2026_tope-inf.rds.` + `source("30_procesamiento/35_extraer_proyectos.R")` |
| C: faltan ambas | `...en 20_insumos/camara/ y 20_insumos/senado/ (2 archivo(s)): ...` + los dos `source()` |

Sin regresión respecto de lo que P-93 dejó. Y el control estático que el encargo
pide: en el `deparse()` de `regenerar_intermedios_si_desalineados()` (140 líneas)
**no sobrevive ninguna cadena de subdirectorio escrita a mano**. Las tres
ocurrencias que quedan son `options(camara.refrescar = FALSE)` (nombre de opción),
la regex `"^.*/(20_insumos/[^/]+)$"` (la derivación de P-93) y
`"captura cruda de 20_insumos/."` (la generalización de P-101).

## 5. F2 — la compuerta de contenido (P-105)

### 5.1 La forma, y por qué

Una función en `10_utils/10_utils.R`, no un bloque en el YAML: el crudo entra al
repositorio por **dos** caminos, y hasta ayer el que se usó fue el manual
(`b4b0bcd`, la única captura del Senado antes del refresh del 2026-08-20). Una
función sirve a los dos; un bloque en el YAML sólo al bot.

`barrido_datos_personales(rutas, patrones = PATRONES_DATO_PERSONAL)` lee cada
ruta (`.rds` por `readRDS()` + recolección recursiva de texto; lo demás por
`readLines()`), aplica los cinco patrones y devuelve un `data.frame` de
`archivo`, `patron`, `coincidencias`. **Nunca devuelve el texto coincidente.** El
volumen viaja como atributos (`archivos`, `valores`, `caracteres`) porque un cero
sin volumen no es un cero: un barrido que no leyó nada también devuelve cero.

Cero dependencias de paquete: `library`/`require` en `10_utils.R` sigue en 0 y el
bloque nuevo no usa `::`.

**El alcance está declarado en el comentario de la función**, no sólo aquí: barre
las rutas que recibe, y el llamador del workflow le pasa sólo las que caen bajo
`rutas_versionables_crudo()`. `40_salidas/json` y `docs/data` son derivados de ese
mismo crudo, así que barrer el origen los cubre; barrer 1 242 derivados en cada
corrida compraría tiempo de CI sin comprar garantía.

### 5.2 Calibración y pruebas

**F2.1 — cinco señuelos sintéticos, uno por patrón.** 5 de 5 detectados por su
propio patrón, **0 detectores ciegos**, sobre 102 caracteres en 5 archivos. El
señuelo de `telefono_cl` dispara además `digitos_9mas`: solapamiento esperado
entre dos patrones que cubren el mismo rango de dígitos, no un defecto.

**F2.2 — señuelo en copia desechable de un archivo real.**

```
el ORIGINAL, sin tocar: hallazgos = 0 | caracteres = 3271894
la COPIA con señuelo:   hallazgos = 5
  correo 1 | rut_con_puntos 1 | rut_sin_puntos 1 | telefono_cl 1 | digitos_9mas 1
los 5 patrones disparan: TRUE
copia borrada: TRUE | md5 del original intacto: TRUE
```

**F2.3 — el cero, con volumen y tiempo.**

```
archivos de crudo en disco: 68 | trackeados por git: 68
HALLAZGOS: 0
VOLUMEN barrido: 103816593 caracteres en 10186627 valores de texto, sobre 68 archivos
TIEMPO: 2.82 s
```

**103,8 millones de caracteres, 0 hallazgos, 2,82 segundos.** El tiempo es
compatible con un paso de CI: la corrida real del refresh del 2026-08-20 tardó
18,5 minutos, así que esto es el 0,25 % de un job.

**F2.4 — la compuerta mata el job cuando debe.** Bloque extraído literal del YAML
(líneas 157-175, por marcadores), corrido con `bash` en un worktree desechable:

```
Barrido de dato personal: 2 archivo(s) de crudo, 3271945 caracteres, 3 hallazgo(s).

### DATO PERSONAL EN EL CRUDO STAGED -> NO se publica ###
  - 20_insumos/senado/20260821_tramitacion_sil_2026_tope-inf.rds : patron correo (1 coincidencia(s))
  - 20_insumos/senado/20260821_tramitacion_sil_2026_tope-inf.rds : patron telefono_cl (1 coincidencia(s))
  - 20_insumos/senado/20260821_tramitacion_sil_2026_tope-inf.rds : patron digitos_9mas (1 coincidencia(s))
El texto coincidente NO se imprime: el log de este job es publico.
  EXIT_CONTENIDO=1
```

**F2.5 — calla cuando debe.**

```
Validacion del staged: 4 rutas, 4 declaradas.        (compuerta de rutas, P-99)
  EXIT_RUTAS=0
Barrido de dato personal: 2 archivo(s) de crudo, 3271902 caracteres, 0 hallazgo(s).
  EXIT_CONTENIDO=0
```

**F2.6 — interacción: ruta intrusa Y contenido sucio.** Con las dos condiciones a
la vez, **habla primero la compuerta de rutas** y el job muere ahí; la de
contenido no llega a correr.

```
Validacion del staged: 5 rutas, 4 declaradas.
### RUTA INTRUSA EN EL STAGED -> NO se publica ###
  - 20_insumos/territorio/20260821_intruso.csv
  EXIT_RUTAS=1
  >>> hablo PRIMERO la compuerta de RUTAS; el job muere aqui y la de contenido no llega a correr.
```

Es el orden correcto y es deliberado: una ruta que no debería estar es un fallo
más barato de diagnosticar, y detenerse ahí evita barrer un archivo que de todos
modos no puede entrar. Ninguna de las dos tapa a la otra: son bloques
independientes y el segundo sólo se alcanza si el primero pasa.

## 6. F3 — panel adversarial. Veredicto: **NO PASA, por concordancia**

Dos panelistas independientes, en worktrees separados, sin acceso a este log ni a
mis arneses: recibieron el diff y las preguntas. Foco declarado: P-100.

| | Panelista 1 | Panelista 2 |
|---|---|---|
| **Veredicto** | **NO PASA** | **NO PASA** |
| Calibración (control negativo) | supera: falso positivo con el código viejo, silencio con el nuevo | supera: idem, cuatro variantes A/B/C/D |
| Silencio y control conocido-bueno | 133/133 líneas idénticas, **1 242 de 1 242 salidas con md5 idéntico**, 7 cache hits, 0 cache miss | no aplicaba a su rol |
| P-101 y P-102 | pasan limpios | pasan limpios: 28 de 28 rutas idénticas, 3 cortes |
| P-100 | **regresión** | **regresión neta: cierra un caso y abre dos** |
| P-105 | detecta señuelos ajenos, pero **falla abierto** ante `.rds` ilegible | idem, más un fallo no capturado que mata el job |

**No hay discordancia: los dos concluyen lo mismo.** Y los dos localizaron, por
caminos distintos, el mismo defecto en el foco.

### 6.1 Los cuatro defectos, reproducidos por el ejecutor

Ninguno se acepta por reporte: los cuatro se volvieron a medir aquí.

**D1 — `localizar_switch()` muere ante un símbolo vacío en el AST. Regresión.**
`10_utils/10_utils.R:738-739`. El `tryCatch` protege la *extracción*, que no falla:
`nodo[[k]]` devuelve el símbolo vacío sin error y el fallo se dispara después, al
forzarlo en `is.null(hijo)`.

```
la funcion es valida y despacha: f(32) = a
localizar_switch (rama): ERROR: el argumento "hijo" está ausente, sin valor por omisión
con m[, 1] en el cuerpo: ERROR: el argumento "hijo" está ausente, sin valor por omisión
```

Alcanza a cualquier indexado con argumento vacío en el cuerpo auditado y, peor, al
*fall-through* `"32" = ,` del propio `switch` de capturas, que es la forma
idiomática de que dos pasos compartan una captura. El mensaje no nombra ni la
guarda, ni la función auditada, ni el archivo. **Es exactamente el modo de fallo
que P-100 decía cerrar**: `run_all()` se detiene en su entrada con el registro
sano, y con él el cron. La construcción disparadora ya vive en el repositorio:
`30_procesamiento/37_extraer_tramitacion.R:190`, `tramites[!fuera, , drop = FALSE]`.

**D2 — `base::switch()` no se reconoce, y el mensaje es específicamente falso.
Regresión.** `10_utils.R:735`: `identical(nodo[[1L]], as.name("switch"))` no cubre
`` `::`(base, switch) ``, cuyo `nodo[[1L]]` es una llamada, no un símbolo.

```
rama, localizar_switch:   ERROR: no hay ninguna llamada a switch() en el cuerpo de f_ns()...
main, names(body(f)[[2]]):  "" | "" | 32
```

`main` audita ese cuerpo sin problema. Y el texto que la rama emite —«revisa si
esa funcion dejo de declarar sus capturas con un switch»— manda a investigar algo
que no ocurrió: es la falta que P-101 corrige en otro sitio, cometida aquí.

**D3 — UTF-8 inválido: el barrido aborta, y si no abortara, no escanearía.**
`10_utils.R:322`.

```
nchar() sobre la cadena:           ERROR: invalid multibyte string, element 1
grepl(perl=TRUE) sobre la cadena:  WARNING: input string 1 is invalid UTF-8
```

Falla cerrado (el job muere), que es preferible a pasar, pero con un mensaje que
no nombra el archivo. Y el agravante que midió el panelista 2: aun arreglando
`nchar`, `grepl(perl = TRUE)` sobre una cadena inválida **devuelve `FALSE`**, es
decir, no la escanea. Falso negativo silencioso. El corpus vigente está limpio
(0 cadenas inválidas), así que es latente, pero la entrada es XML de una API
externa.

**D4 — Un `.rds` ilegible pasa la compuerta en verde y sin aviso.**

```
.rds corrupto -> hallazgos=0 archivos(attr)=1 valores=0 caracteres=0
```

`readRDS()` falla, `tryCatch` devuelve `NULL`, `texto_de_objeto(NULL)` devuelve
`character(0)` y el archivo se cuenta como barrido. **En una compuerta de
gobernanza, «no pude leerlo» no puede ser indistinguible de «está limpio».** Y
contradice el criterio que el propio comentario de la función declara: el volumen
se agrega, así que un archivo ilegible entre 67 legibles queda invisible.

**Corolario (R6):** `attr(out, "archivos")` cuenta rutas **ofrecidas**, no leídas.

```
2 rutas inexistentes -> archivos(attr)=2 caracteres=0 hallazgos=0
```

`git diff --cached --name-only` lista también los borrados, así que la cifra que
el log del job presenta como cobertura sobrestima sistemáticamente.

### 6.2 El hallazgo de alcance, también reproducido

Los dos panelistas señalaron que el comentario que escribí en el YAML
—«`40_salidas/json` y `docs/data` son derivados de ese mismo crudo, así que barrer
el origen los cubre»— **no es exacto**:

```
campos del indice: id, nombre, sexo, partido, ..., distrito, region, tendencia, ...
distrito no-NA: 155 de 155 | region no-NA: 155
20_insumos/territorio/ esta en rutas_versionables_crudo()? FALSE
```

El paso 32 puebla distrito y región por join contra `20_insumos/territorio/`
(`32_extraer_diputados.R:50`), que el barrido nunca lee. El riesgo material es
bajo (crosswalk público de la BCN), pero **el argumento de cobertura escrito es más
ancho que la cobertura real**, que es la falta que P-101 existe para no cometer.

### 6.3 Lo que el panel sí confirmó

- **La calibración de los dos arneses supera su propio control**: los dos
  reproducen el falso positivo de P-100 en `main` y lo ven cerrado en la rama.
  Sus veredictos sobre el resto valen.
- **P-102 pasa limpio en las dos revisiones**: el panelista 2 midió 28 de 28 rutas
  idénticas sobre tres cortes, extrayendo las expresiones reales del paso 37 de
  cada checkout por recorrido del AST, y confirmó **cero** literales construyendo
  ruta de crudo.
- **P-101 pasa**: el mensaje nuevo es cierto en 28 de 28 casos y el viejo era
  falso en 4 (las cuatro del paso 37).
- **El control conocido-bueno resiste una medición más dura que la mía**: el
  panelista 1 comparó además el md5 de las 1 242 salidas con `metadatos.generado`
  neutralizado, **1 242 de 1 242 iguales**.
- **El barrido no está sintonizado a los señuelos de su autor**: los dos
  construyeron señuelos propios, con formas que no aparecen en el código ni en el
  diff, y el barrido los detectó, incluido uno inyectado en un list-col real.
- **0 falsos positivos sobre el corpus real** en las dos mediciones
  independientes, con el mismo volumen (103 816 593 caracteres, 2,8 s).

### 6.4 Los desacuerdos entre panelistas

Son de énfasis, no de veredicto:

- El panelista 1 clasifica como **falso positivo** que un `switch` anidado dentro
  de una rama del propio `switch`, uno dentro de una función anónima del cuerpo o
  uno *citado* en `quote()` disparen la condición «más de uno». El panelista 2
  clasifica los mismos casos (`switch` en función anónima interna) como
  **CORRECTO — CALLA**. Los dos midieron; miden variantes distintas del mismo
  cuerpo. **Queda como divergencia declarada y sin resolver**, porque resolverla
  exige tocar el código y eso está prohibido tras un veredicto adverso.
- El panelista 1 consiguió **un** falso negativo (reemplazar el `switch` real por
  un señuelo con las seis ramas nominales); el panelista 2 no consiguió ninguno.
  Los dos coinciden en que ese límite —la guarda audita `names()`, no el contenido
  de las ramas— **ya está en `main`** y P-100 no lo abre, sólo lo extiende de «la
  segunda expresión» a «cualquier lugar del cuerpo».

### 6.5 Consecuencia: no se abre el PR

F3 declara el panel obligatorio **antes** de abrir el PR y prohíbe arreglar sobre
la marcha. Con dos NO PASA concordantes y cuatro defectos reproducidos —uno de
ellos una regresión en el foco declarado del panel— **el PR no se abre y el código
no se toca**. La rama queda publicada con sus cuatro commits y este log, para que
el titular decida.

## 7. Verificación de invariantes (§6 del encargo)

1. **Toda cifra viene de un bloque de R de esta corrida.** Los seis literales, la
   tabla de equivalencia, las 131 líneas del control conocido-bueno, los 103,8
   millones de caracteres barridos y el conteo de 68 archivos de crudo se
   calcularon con `Rscript` en el mismo turno en que se reportan.
2. **El `git diff` no contiene líneas fuera de §3 y §4.** Cuatro archivos, los
   autorizados y ninguno más (`setequal` verdadero). `git add .` o `-A` en el
   YAML: **0**. `sellar()`, `leer_sellado()` y `validar_corte()` sin tocar.
   `DIRECTORIOS_CRUDO` conserva su contenido (`camara,senado`, comprobado en la
   tabla de equivalencia). `10_utils.R` no adquiere dependencias: `library` /
   `require` sigue en 0 y el bloque nuevo no usa `::`.
3. **¿Queda alguna cadena `"camara"` o `"senado"` construyendo una ruta de crudo?**
   Con el `grep` de hoy sobre `10_utils/`, `30_procesamiento/` y `00_run_all.R`:
   6 ocurrencias, **0 construyen ruta**. Dos son las constantes nominadas
   (`10_utils.R:232-233`), dos son comentarios (`10_utils.R:245`, `37:254`), una
   es nombre de columna (`37:66`) y una es glosa del dominio de cámara de origen
   (`10_configuracion.R:97`). La clasificación se deriva de la forma del texto, no
   de una lista escrita a mano.
4. **Si mañana alguien deja un archivo con datos personales bajo
   `20_insumos/senado/` con nombre plausible, ¿qué lo detiene?** La compuerta de
   contenido de P-105, que corre entre el `git add` y el `git commit` del job y
   barre con cinco patrones todo lo staged que caiga bajo
   `rutas_versionables_crudo()`. La prueba que lo demuestra es F2.4: un `.rds`
   staged bajo `20_insumos/senado/` con correo y teléfono inyectados produjo
   `EXIT_CONTENIDO=1` y tres líneas nombrando archivo y patrón, sin imprimir el
   texto. Antes de este encargo ese archivo pasaba las dos barreras existentes.
5. **¿Qué NO cubre el barrido?** Es la pregunta que P-105 existía para contestar y
   su respuesta nueva no puede quedar implícita:
   - **No cubre lo que los cinco patrones no ven.** Detecta correo, RUT en dos
     formas, teléfono chileno y corridas de 9+ dígitos. No detecta direcciones
     domiciliarias, nombres de persona privada sin identificador, RUT sin dígito
     verificador, correos ofuscados (`nombre [arroba] dominio`), ni teléfonos en
     formatos que no empiecen por 56.
   - **No cubre `40_salidas/json` ni `docs/data`.** El argumento es que son
     derivados del crudo barrido, y es un argumento, no una medición: si un paso
     del pipeline **inventara** dato personal que no está en el crudo, el barrido
     no lo vería. Hoy ningún paso hace eso.
   - **No cubre el camino manual.** La función existe para que un humano pueda
     llamarla antes de commitear a mano, pero nada le obliga: no hay hook de
     `pre-commit`. La compuerta automática es sólo la del bot.
   - **No cubre archivos que no sean `.rds` ni texto legible.** Un binario bajo
     una ruta de crudo aporta 0 caracteres al volumen, y el volumen se imprime en
     el log justamente para que ese caso sea visible en vez de silencioso.

## 8. Decisiones autónomas

1. **El alcance de P-102 lo fija la medición de hoy: seis, no dos ni cinco.** Los
   dos recuentos previos miraron partes distintas del árbol. Se cerraron los seis
   porque cerrar cuatro habría dejado el defecto vivo con el pendiente marcado
   como resuelto, que es peor que no tocarlo.
2. **Los arneses de `50_documentacion/andamios/` quedan fuera.** Son reproductores
   congelados que sustentan decisiones anteriores; cambiarles la ruta cambia el
   instrumento. Se registra como alcance declarado, no como olvido.
3. **Constantes nominadas nuevas en vez de nombrar el vector.** `DIRECTORIOS_CRUDO`
   con nombres (`c(camara = "camara", ...)`) habría cambiado el objeto que el 🔒
   manda no cambiar, y `DIRECTORIOS_CRUDO[1]` era exactamente la fragilidad que
   §4.3 prohíbe. `CRUDO_CAMARA`/`CRUDO_SENADO` dejan el vector idéntico y lo hacen
   derivar de ellas.
4. **El control conocido-bueno se hizo estacionario contra estacionario.** Comparar
   la primera corrida de una rama con la segunda de otra habría medido la guarda
   de P-65 regenerando, no el cambio.
5. **El bloque de validación se extrajo literal del YAML por marcadores**, en las
   dos compuertas. Una réplica escrita a mano prueba la réplica.
6. **El orden de las dos compuertas es rutas primero, contenido después**, y se
   midió cuál habla primero en vez de suponerlo (F2.6).

## 9. Bugs

### 10.1 El bug que P-100 cierra (clase, no caso)

No es «`[[2]]` estaba mal». Es que **la guarda leía el código que audita por
posición sintáctica**, de modo que cualquier edición inocente aguas arriba
—un log, un `stopifnot`, una validación de argumento— la convertía en un
detector de huérfanos que declara huérfano a todo. Y como corre la primera de
todas en `run_all()`, su falso positivo no degrada una parte: detiene el
pipeline entero y el cron con él. Medido en §4.3: una línea.

### 10.2 Bug propio del arnés: `on.exit` fuera de una función

La primera versión del arnés de los tres mensajes de P-101 registraba la
restauración con `on.exit()` **en el cuerpo del script**, no dentro de una
función. En `Rscript` eso no dispara: el escenario A dejó su captura movida a un
`tempdir()` que el proceso borró al salir, y los escenarios B y C corrieron con
dos capturas ausentes en vez de una, produciendo el mismo mensaje los tres y
dando una falsa impresión de consistencia. **Se detectó porque los tres
escenarios dieron salidas sospechosamente iguales**, se restauró el worktree con
`git checkout --`, se comprobó que el repositorio real seguía intacto (2 963 de
2 963 md5) y se rehízo el arnés con la restauración dentro de una función. La
lección es la de A106: un arnés que no distingue sus propios escenarios no está
midiendo lo que dice medir.

### 10.3 Un error de clasificación evitado

La primera versión del inventario de §6.3 clasificaba las seis ocurrencias con un
vector de etiquetas escrito a mano y emparejado **por posición**. Se desalineó y
etiquetó `CRUDO_SENADO <- "senado"` como comentario. Se rehízo derivando la clase
de la forma del texto. Es, en pequeño, el mismo defecto que P-100.

## 10. Estado de cifras y datos críticos

- **Ninguna captura cruda se modificó ni se borró.** md5 de los 2 963 archivos
  bajo `20_insumos/` del repositorio real: **2 963 de 2 963 idénticos** al abrir y
  al cerrar. `git diff --stat HEAD -- 20_insumos`: 0 líneas.
- Las alteraciones de captura de las pruebas ocurrieron en worktrees desechables
  (movidas y restauradas) o en copias en el scratchpad (borradas).
- `40_salidas/json` y `docs/data` volvieron a su estado de `HEAD` tras las
  corridas de verificación; la única diferencia que hubo fue `metadatos.generado`.
- **0 descargas.** Las 7 capturas del corte se resolvieron por caché en las tres
  corridas de `run_all()`. Ninguna corrida del workflow, ningún `gh workflow run`.
- **0 merges y 0 pushes a `main`.** Todo vive en `fix/encargo-a-derivacion-y-barrido`.

## 11. Notas para el revisor

**Lo primero que conviene mirar** es §4.3: la diferencia entre `SILENCIO` y seis
huérfanos con la misma línea insertada. Es lo que distingue «P-100 arreglado» de
«P-100 reescrito», y sin esa prueba el cambio sería indistinguible de un refactor
cosmético.

**Sobre `localizar_switch()`, el modo de fallo es hacia el ruido.** Si no
encuentra ninguna llamada a `switch` —porque alguien escribió `base::switch()`,
`do.call("switch", ...)` o cambió a `if`/`else`— **se detiene nombrando la
función** en vez de callar. Es deliberado: una guarda que no puede auditar no
está diciendo que todo esté bien. El costo es que esas tres formas, todas
legítimas en R, romperían el arranque hasta que alguien ajuste la guarda.

**Sobre la compuerta de contenido, lo que no cubre está en §7.5 y no es poco.**
La respuesta corta: cierra el caso de un archivo con datos personales *de las
formas que la fuente ya usa* depositado bajo una ruta legítima. No convierte el
repositorio en uno auditado por contenido.

**Sobre el barrido y su procedencia:** los cinco patrones no se escribieron aquí.
Se extrajeron del arnés de la auditoría de P-99 y se **reprodujeron** contra las
cifras que el log de esa auditoría cita, antes de adoptarlos (§3.3). Ese arnés
vivía en `/tmp` y no en el repositorio, lo que es un pendiente en sí mismo.

## 12. Pendientes abiertos

1. **El arnés de los cinco patrones vivía en `/tmp`.** Una cifra de gobernanza
   —«cero datos personales en la captura del SIL»— dependía de un script fuera del
   repositorio. Sobrevivió por casualidad; si el disco se hubiera limpiado, la
   regla de §0.2 del encargo habría obligado a detenerse. Ahora los patrones sí
   están versionados, en `PATRONES_DATO_PERSONAL`, pero el arnés de calibración
   (los señuelos, los controles estructurales) sigue sin estarlo.
2. **`localizar_switch()` no reconoce `base::switch()` ni `do.call("switch", ...)`.**
   Falla ruidosamente, que es el modo correcto, pero significa que esas dos formas
   romperían el arranque del pipeline. Si alguien las necesita, la guarda hay que
   ampliarla, no rodearla.
3. **No hay hook de `pre-commit`** que corra el barrido en el camino manual. La
   función existe y se puede llamar a mano; nada obliga a hacerlo.
4. **El barrido no cubre `40_salidas/json` ni `docs/data`** por argumento de
   derivación, no por medición. Ver §7.5.
5. **Los arneses de `50_documentacion/andamios/`** conservan literales
   `ruta_insumos("camara")`. Fuera del alcance de este encargo por decisión
   declarada (§8.2), no por olvido.
6. **El comentario de `10_utils.R:245`** todavía dice `# Default "camara"` cuando
   el código ya dice `subdir = CRUDO_CAMARA`. Sigue siendo cierto en sustancia
   (el valor por defecto es el de la Cámara) y se dejó como está para no ampliar
   el diff, pero es una cadena escrita a mano en un comentario que describe una
   línea que ya no la tiene.

7. **Los cuatro defectos del panel, sin arreglar** (§6.1): el simbolo vacio en el
   AST, `base::switch()`, el UTF-8 invalido y el `.rds` ilegible que pasa en verde.
   Los tres primeros afectan a P-100 y a P-105 en su nucleo; el cuarto contradice
   el criterio que la propia funcion declara. Ninguno se toco: F3 lo prohibe tras
   un veredicto adverso, y arreglarlos exige rehacer el panel sobre el codigo nuevo.
8. **El argumento de cobertura de P-105 es mas ancho que la cobertura** (§6.2):
   distrito y region llegan al JSON publicado desde `20_insumos/territorio/`, que el
   barrido nunca lee. O se corrige el comentario, o se amplia el alcance; las dos
   son decision del titular porque §4.4 fijo el alcance.
9. **Divergencia del panel sin resolver** (§6.4): los dos panelistas clasifican de
   forma distinta si un `switch` dentro de una funcion anonima del cuerpo es falso
   positivo o comportamiento correcto. Resolverlo exige tocar el codigo.

**Marcas `# REVISAR` nuevas introducidas por la rama: 0.**

---

# Ronda A2 — corrección de los cuatro defectos del panel

> **Encargo:** `50_documentacion/andamios/50_encargo_s24_encargo_a2_correccion_panel.md`.
> **Misma rama que A:** `fix/encargo-a-derivacion-y-barrido`. **Sesión:** 24 (2026-08-20).
> Esta sección amplía el log del encargo A; no lo reemplaza. Lo de arriba queda
> tal cual, incluido su veredicto NO PASA, porque es el estado del que parte esto.

## A2.1 Resumen

El panel de A devolvió NO PASA concordante con cuatro defectos, dos de ellos
regresiones frente a `main`. Los cuatro comparten una raíz: **código que, ante una
entrada que no sabe interpretar, elige adivinar o callar en vez de detenerse.**
Esta ronda cambia eso en los dos sitios.

- **D1 y D2 — el localizador.** El símbolo vacío del AST se detecta ahora por
  identidad contra `quote(expr = )` y **sin bindearlo**, que era el paso que
  disparaba el error. Se reconocen las **tres** formas escribibles de `switch`
  (pelado, `base::switch`, `do.call("switch", list(...))`). Lo irresoluble —un
  `do.call` con función no literal, un `switch` calificado con un namespace que no
  es `base`— **grita nombrando la construcción literal**, y ningún mensaje afirma
  ya una causa que no se midió.
- **La divergencia del panel, resuelta por el encargo:** el localizador **no entra
  en cuerpos de `function`**. Un `switch` en una anónima anidada no es la
  declaración de capturas; si es el único que hay, eso cuenta como cero llamadas y
  falla ruidosamente.
- **D3 y D4 — el barrido.** Pasa de dos estados de hecho a **tres declarados**:
  `limpio`, `hallazgos`, `ilegible`. `ilegible` cubre la ruta que no existe, el
  directorio, el `.rds` que no deserializa, el archivo que no se lee como texto y
  **la cadena con UTF-8 inválido**, que `grepl(perl = TRUE)` no escanea (devuelve
  `FALSE` con warning: falso negativo mudo). El paso del job **trata `ilegible`
  como fallo**, igual que un hallazgo.
- **El comentario de cobertura del YAML**, que era mío y era falso, se corrigió a
  lo que las pruebas demuestran.
- **El arnés de calibración se versiona**, en
  `50_documentacion/andamios/50_verificar_barrido_p105.R`. Que una cifra de
  gobernanza dependiera de que nadie limpiara `/tmp` era el hallazgo, no el detalle.

**P-101 y P-102 no se tocaron:** pasaron las dos revisiones de A. Medido en §A2.7.

## A2.2 Inventario de commits de esta ronda

| Hash | Mensaje |
|---|---|
| `5e460bc` | fix(a2): el localizador reconoce las tres formas de switch, no entra en function anidadas y grita lo irresoluble (incluye el encargo A2) |
| `9b19cec` | fix(a2): el barrido tiene tres estados y el job trata ilegible como fallo |
| `abb86f1` | chore(a2): el arnes de calibracion del barrido se versiona y separa trackeado de ignorado |

Archivos tocados por A2, medido con `git diff --numstat b897ec4..abb86f1`:
`.github/workflows/refresh-semanal.yml` (+30/−14), `10_utils/10_utils.R`
(+187/−37), el encargo A2 (+194) y el arnés nuevo (+166).
**`30_procesamiento/37_extraer_tramitacion.R` no se tocó**, que es donde viven
tres de los seis sitios de P-102.

## A2.3 F0 — los cuatro defectos, reproducidos ANTES de tocar código

Es el control negativo de las correcciones: sin él no se puede demostrar después
que algo se arregló. Salida literal del arnés sobre `b897ec4`:

```
== D1: simbolo vacio en el AST ==
  f_ft(32) despacha:                       20260820_compartida.rds
  localizar_switch(f_ft):                  ERROR: el argumento "hijo" está ausente, sin valor por omisión
  localizar_switch(f_idx) [37:190]:        ERROR: el argumento "hijo" está ausente, sin valor por omisión

== D2: switch calificado y do.call ==
  localizar_switch(base::switch):          ERROR: ...no hay ninguna llamada a switch() en el cuerpo de f_ns()...
    main lo auditaba: names(body[[2]]):     |  | 32 | 37
  localizar_switch(do.call literal):       ERROR: ...no hay ninguna llamada a switch()...
  localizar_switch(do.call variable):      ERROR: ...no hay ninguna llamada a switch()...

== divergencia del panel: switch dentro de una function anidada ==
  declaracion + anonima con switch:        ERROR: ...2 llamadas a switch()...
  SOLO una anonima con switch:              |  | a | b

== D3: UTF-8 invalido ==
  validUTF8(cadena):                       FALSE
  nchar(cadena):                           ERROR: invalid multibyte string, element 1
  grepl(perl=TRUE) sobre la cadena:        WARNING: input string 1 is invalid UTF-8
  barrido sobre .rds con UTF-8 invalido:   ERROR: invalid multibyte string, element 1

== D4: .rds ilegible ==
  .rds corrupto:                           hallazgos=0 archivos=1 valores=0 caracteres=0  [sin estado 'ilegible']
  ruta inexistente:                        hallazgos=0 archivos=1 caracteres=0
```

Y el estado de lo que sobrevive (F0.3): 6 ocurrencias de los literales en el
pipeline, **0 construyendo ruta de crudo**; más el comentario obsoleto
`# Default "camara"` en `10_utils.R:245`, que se corrigió con el resto.

## A2.4 F1 — las correcciones y sus diez verificaciones

### 1. Los cuatro defectos, muertos (antes y después)

| defecto | antes (`b897ec4`) | después (`abb86f1`) |
|---|---|---|
| **D1** fall-through `"32" = ,` | `ERROR: el argumento "hijo" está ausente` | ramas `32, 33` |
| **D1** `m[!f, , drop = FALSE]` (forma de `37:190`) | `ERROR: el argumento "hijo" está ausente` | ramas `32, 37` |
| **D2** `base::switch(...)` | `ERROR: no hay ninguna llamada a switch()` | ramas `32, 37` |
| **D2** `do.call("switch", list(...))` | `ERROR: no hay ninguna llamada a switch()` | ramas `32, 37` |
| **D3** `.rds` con UTF-8 inválido | `ERROR: invalid multibyte string, element 1` | `estado=ilegible, motivo=contiene cadenas con UTF-8 invalido, no escaneables` |
| **D4** `.rds` corrupto | `hallazgos=0 archivos=1 caracteres=0` (indistinguible de limpio) | `estado=ilegible, motivo=el .rds no deserializa` |
| **D4** ruta inexistente | `hallazgos=0 archivos=1 caracteres=0` | `estado=ilegible, motivo=la ruta no existe en disco` |

### 2 y 3. Sobre las funciones REALES, no sobre casos de juguete

En un worktree desechable se insertó una rama `"38" = ,` en fall-through en el
`switch` real de `capturas_crudas_de_paso()`, y por separado la construcción de
`37:190` en su cuerpo. Los mismos dos casos, en los dos estados:

```
### ANTES (b897ec4) — CASO: fallthrough ###
  ramas localizadas: ERROR: el argumento "hijo" está ausente, sin valor por omisión
  guarda: SE DETIENE: el argumento "hijo" está ausente, sin valor por omisión
### ANTES (b897ec4) — CASO: indexado ###
  ramas localizadas: ERROR: el argumento "hijo" está ausente, sin valor por omisión
  guarda: SE DETIENE: el argumento "hijo" está ausente, sin valor por omisión

### CASO: fallthrough ###   (abb86f1)
  ramas localizadas: 38, 32, 33, 34, 35, 36, 37
  guarda: SE DETIENE: verificar_registro_pasos: 1 incoherencia(s)...
          paso 38: tiene rama en capturas_crudas_de_paso() pero no existe en PASOS.
### CASO: indexado ###      (abb86f1)
  ramas localizadas: 32, 33, 34, 35, 36, 37
  guarda: SILENCIO
```

La diferencia del caso `fallthrough` es la que importa: antes la guarda moría con
un error que no era suyo; ahora **lee las siete ramas y hace su trabajo**, que es
avisar de que el paso 38 tiene rama y no existe en `PASOS`. El caso `indexado`
pasa de matar el arranque a silencio.

### 4 y 5. Las tres formas, las cuatro irresolubles y la anónima en las dos direcciones

19 casos, uno por línea, con el resultado que el encargo manda:

| caso | esperado | obtenido |
|---|---|---|
| `switch(...)` pelado | RECONOCE | ramas `32,37` |
| `base::switch(...)` | RECONOCE | ramas `32,37` |
| `base:::switch(...)` | RECONOCE | ramas `32,37` |
| `do.call("switch", list(...))` | RECONOCE | ramas `32,37` |
| `do.call(switch, list(...))` | RECONOCE | ramas `32,37` |
| precedido por sentencias | RECONOCE | ramas `32` |
| anidado en `if` + `local` | RECONOCE | ramas `32` |
| envuelto en `invisible()` | RECONOCE | ramas `32` |
| con fall-through `"32" = ,` | RECONOCE | ramas `32,33,37` |
| con indexado de argumento vacío | RECONOCE | ramas `32` |
| **cero llamadas** (cadena `if`/`else`) | GRITA | stop, «NO encontro ninguna llamada de despacho» |
| **más de una** (dos hermanas) | GRITA | stop, «encontro 2 llamadas de despacho» |
| **`do.call` con variable** | GRITA | stop, nombra la construcción con `deparse` |
| **`do.call("switch", args no literal)`** | GRITA | stop, nombra la construcción |
| **`otro::switch` (ns ≠ base)** | GRITA | stop, nombra el namespace |
| declaración + anónima con `switch` | RECONOCE | ramas `32,37` (toma la declaración) |
| **SOLO una anónima con `switch`** | GRITA | stop, «NO encontro ninguna llamada» |
| anónima con lambda `\(x)` + declaración | RECONOCE | ramas `32` |
| `'switch('` dentro de un string | RECONOCE | ramas `32` |

**19 de 19 se comportan como el encargo manda.**

### 6. Los tres estados del barrido, y que cuadren

```
  corrupto.rds     ilegible   el .rds no deserializa
  limpio.rds       limpio     patron=NA
  sucio.rds        hallazgos  patron=correo
  sucio.rds        hallazgos  patron=rut_sin_puntos
  utf8_malo.rds    ilegible   contiene cadenas con UTF-8 invalido, no escaneables
  no_existe.rds    ilegible   la ruta no existe en disco

  por_estado: limpio=1 hallazgos=1 ilegible=3 | suman=5 | total de entrada=5 | CUADRAN=TRUE
  volumen: 3 valores, 69 caracteres
```

### 7. La compuerta mata el job ante `ilegible`

Bloque extraído **literal** del YAML (líneas 165-191, por marcadores) y ejecutado
bajo `bash` en un worktree desechable, sobre cuatro conjuntos staged:

```
escenario limpio    -> limpio=1 hallazgos=0 ilegible=0   EXIT_CONTENIDO=0
escenario ilegible  -> limpio=1 hallazgos=0 ilegible=1   EXIT_CONTENIDO=1
                       ILEGIBLE  20_insumos/camara/20260821_corrupto.rds : el .rds no deserializa
escenario utf8      -> limpio=1 hallazgos=0 ilegible=1   EXIT_CONTENIDO=1
                       ILEGIBLE  20_insumos/camara/20260821_utf8malo.rds : contiene cadenas con UTF-8 invalido, no escaneables
escenario hallazgo  -> limpio=1 hallazgos=1 ilegible=0   EXIT_CONTENIDO=1
                       HALLAZGO  20_insumos/camara/20260821_sucio.rds : patron correo (1 coincidencia(s))
```

En los cuatro, la compuerta de rutas de P-99 salió en 0 antes: las dos conviven.

### 8. No regresión

```
lineas main: 131 | rama: 131 | identicas (sello y duracion neutralizados): TRUE
guarda en main: 0 | en rama: 0 -> SILENCIO en ambas: TRUE
cache hit: 7 | cache miss/http/descargando: 0
md5 de las salidas, sello de generacion neutralizado: 1242 de 1242 IDENTICOS
```

Los **cinco escenarios de P-93** siguen deteniéndose nombrando el elemento (paso
38, intermedio `fantasma`, paso 41, paso 37 en `PASOS_SIN_INTERMEDIO`, paso 99), y
el control calla. Los **tres mensajes de P-101** salen exactos: `20_insumos/senado/`
cuando falta la del 37, `20_insumos/camara/` cuando falta una de la Cámara, y
`20_insumos/camara/ y 20_insumos/senado/` cuando faltan ambas.

### 9. P-101 y P-102 intactos

`30_procesamiento/37_extraer_tramitacion.R` **no aparece en el diff de A2**, y en
`10_utils/10_utils.R` las líneas cambiadas que tocan P-101 o P-102 son **una**, y
es un comentario: `# Default "camara"` → `# Default CRUDO_CAMARA`, la corrección
del comentario obsoleto que F0.3 mandaba hacer. Las declaraciones siguen siendo
las de A:

```
CRUDO_CAMARA <- "camara"
CRUDO_SENADO <- "senado"
DIRECTORIOS_CRUDO <- c(CRUDO_CAMARA, CRUDO_SENADO)
"captura cruda de 20_insumos/."),
```

### 10. El corpus vigente, con volumen y estados

```
[trackeado] 70 archivo(s) | limpio=70 hallazgos=0 ilegible=0 | suman=70 | CUADRAN=TRUE
[trackeado] VOLUMEN: 103827065 caracteres en 10186843 valores | TIEMPO: 2.93 s
  0 hallazgos y 0 ilegibles sobre lo que el repositorio publica.
```

Los 70 incluyen **territorio**, como el encargo pedía: `camara=63, senado=5,
territorio=2`.

**Y un hallazgo que sí apareció, con su explicación medida.** Con el alcance local
de `rutas_barribles_locales()` (todo `20_insumos/`, la decisión de §4.3), el
barrido marca 40 archivos:

```
[todo 20_insumos/] 2967 archivo(s) | limpio=2927 hallazgos=38 ilegible=2 | suman=2967 | CUADRAN=TRUE
[todo 20_insumos/] VOLUMEN: 149450764 caracteres en 10936190 valores | TIEMPO: 4.82 s
archivos marcados en el conjunto amplio: 40 | de ellos NO trackeados: 40
subdirectorios de los no trackeados: exploracion=40
```

**40 de 40 están en `20_insumos/exploracion/`, 0 trackeados por git, 40 de 40
ignorados por `.gitignore:57`.** Es exactamente el material de sondeo con padrón
nominal del Senado que el proyecto ya deliberó y falló en no publicar (R5 de
P-99). Que el barrido los encuentre es **la prueba de que funciona**, no una
brecha: nada de eso está en el repositorio. Por eso no se aplicó la regla de
detención de F1.10, que habla del corpus vigente, y ese da 0.

Para que la próxima lectura no confunda las dos cifras, la fase `corpus` del arnés
versionado **separa el conjunto trackeado del amplio** y nombra el subdirectorio
de los no trackeados. Mezclarlos en una sola cifra entrenaría al lector a ignorar
la salida.

## A2.5 F2 — panel de segunda vuelta. Veredicto: **NO PASA, por concordancia**

Dos panelistas independientes, en worktrees separados, sin este log ni mis
arneses. **Los dos superaron su control negativo**: reprodujeron los cuatro
defectos sobre `b897ec4` antes de medir nada, así que sus veredictos cuentan.

| | Panelista 1 | Panelista 2 |
|---|---|---|
| **Veredicto** | **NO PASA** | **NO PASA** |
| Calibración sobre `b897ec4` | 4 de 4 reproducidos | 4 de 4 reproducidos |
| Los cuatro defectos declarados | **muertos** | **muertos** |
| No regresión | rutas 32–37 idénticas byte a byte, guarda en silencio, 5 escenarios detienen | idem, y el arnés versionado pasa |
| Defecto central | **DE-1**: `limpio` de volumen cero | **A2-1**: la misma clase, misma conclusión |
| Defectos adicionales | DE-2 (`do.call` con símbolo), DE-3 (compuerta pasa con 0 crudo staged) | A2-2 y A2-3 (comentarios de alcance) |

**No hay discordancia sobre lo que importa.** Los dos llegaron por caminos
distintos —uno con `07_nul.txt`, otro con `entorno.rds`— a la misma frase: hay
entradas que el barrido **no puede mirar y reporta `limpio`**. Es D4 revivido, con
el criterio literal que el propio encargo A2 fijó.

### A2.5.1 El defecto central, reproducido por el ejecutor

Siete archivos con **el mismo señuelo de dato personal adentro**, medidos contra
los bytes que ocupan en disco:

```
  atributo.rds   bytes=177    caracteres_escaneados=0      estado=limpio
  names.rds      bytes=130    caracteres_escaneados=0      estado=limpio
  nul.bin        bytes=59     caracteres_escaneados=2      estado=limpio
  prof9.rds      bytes=108    caracteres_escaneados=0      estado=limpio
  raw.rds        bytes=97     caracteres_escaneados=0      estado=limpio
  sano.rds       bytes=163    caracteres_escaneados=56     estado=hallazgos

  -> archivos con dato personal declarados LIMPIO: 6 de 7
```

**El diagnóstico del panelista 2 es exacto y hay que citarlo entero:** la
corrección de A2 «añadió estado por archivo pero nunca añadió la única
comprobación que distingue los dos ceros: caracteres escaneados frente a bytes en
disco». El comentario que escribí declara los tres estados «exhaustivos y
excluyentes» y define `ilegible` como «NO se pudo mirar». Un archivo que
deserializa sin error pero del que se extraen 0 caracteres **no se miró**, y cae
en `limpio`. Peor: la versión anterior al menos hacía `if (length(tx) == 0L) next`.

Las vías medidas: `.rds` que deserializa a entorno, a `raw`, a numérico; texto en
`names()`, en `row.names()` o en un atributo; anidamiento más allá del tope
`prof > 6L`; y por el lado de texto, `readLines()` truncando en un NUL embebido
(77 bytes en disco, 8 caracteres leídos). **El caso del NUL está vivo hoy**: hay
dos `.txt` trackeados en `20_insumos/senado/`.

Y el panelista 1 lo llevó hasta el final: sus tres formas silenciosas
**atraviesan la compuerta del workflow** y el job habría commiteado y publicado.

### A2.5.2 DE-2 — la clase de D2, reintroducida por mí

```
  do.call("rbind", piezas)  [string]     DEVUELVE 32
  do.call(rbind, piezas)    [simbolo]    DETIENE
  el mensaje: "do.call con funcion no literal, imposible decidir si despacha: do.call(rbind, list(1))"
```

`rbind` es un símbolo pelado: **es tan literal y tan decidible como el string**, y
decididamente no es `switch`. Mi condición lo trata como irresoluble y emite un
mensaje que **afirma una causa que no midió**, que es la definición exacta de D2.
La escribí al revés: un símbolo que no es `switch` debe ignorarse, no marcarse.
Consecuencia: un `do.call(f, ...)` cualquiera en el cuerpo auditado mata
`run_all()` en su entrada.

### A2.5.3 DE-3 — la compuerta pasa con volumen cero

El escenario realista: el crudo no cambia respecto del commit previo y solo
cambian los derivados.

```
--- inventario staged ---
  staged: 40_salidas/json/indice_diputados.json
--- compuerta de rutas (P-99) ---
Validacion del staged: 1 rutas, 1 declaradas.
--- compuerta de contenido (P-105) ---
Barrido de dato personal: 0 archivo(s) de crudo staged, 0 caracteres en 0 valores | limpio=0 hallazgos=0 ilegible=0
  EXIT=0
  >>> HAY CAMBIOS STAGED: el job COMMITEA Y PUBLICA
--- lo que se publicaria ---
+  "contacto": "j.perez@senado.cl",
```

Cero archivos, cero caracteres, la compuerta pasa y se publica un JSON con un
correo. **Es «un cero sin volumen no es un cero» ocurriendo dentro de la compuerta
que existe para hacer cumplir esa regla.**

### A2.5.4 A2-3 — un comentario mío, medible y falso, vivo en el `.R`

El YAML se corrigió en esta ronda; `10_utils/10_utils.R:276-277` conservó la frase
vieja: json y docs «son derivados de ese mismo crudo (barrer el origen los
cubre)». Medido:

```
  crudo    : 68 archivos, 103816593 caracteres -> archivos con hallazgo: 0
  derivados: 621 archivos, 53994130 caracteres -> archivos con hallazgo: 102
  patrones que disparan en el derivado: digitos_9mas | coincidencias: 282
  ejemplo de la corrida larga: 0.98387096774193505
```

El derivado dispara un detector que el origen no dispara, 102 contra 0. Son
decimales de `tasa_presencia` (falsos positivos benignos, y consecuencia de la
convención de publicar tasas sin redondear), pero **la regla enunciada queda
refutada**: barrer el origen no cubre el derivado. Hay ahora dos comentarios sobre
el mismo alcance y uno es falso.

### A2.5.5 Lo que el panel sí confirmó

- **Los cuatro defectos de la primera vuelta están muertos**, verificado por los
  dos de forma independiente, incluido el fall-through en el `switch` **real**:
  `chr [1:10] "" "" "38" "32" "33" "34" "35" "36" "37" ""`.
- **Sin regresión**: rutas de captura 32–37 idénticas byte a byte entre `b897ec4`
  y `abb86f1` (6/6), guarda en silencio sobre el pipeline sincronizado, y los
  escenarios de registro roto siguen deteniéndose.
- **El log del job no imprime texto detectado** en ninguno de los escenarios que
  los dos construyeron.
- **Ningún falso positivo del localizador** con `switch` dentro de un string, ni
  con `do.call("paste", ...)`.
- **Los ilegibles declarados sí se cierran**: permisos 000, symlink roto, symlink
  a directorio, truncado, gzip corrupto y vacío caen los seis en `ilegible`.
- El corpus trackeado da **0 hallazgos y 0 ilegibles** en las dos mediciones
  independientes, con el mismo volumen.

### A2.5.6 Desacuerdos entre panelistas

De énfasis, no de veredicto. El panelista 1 clasifica como **falso negativo** el
caso en que un `switch` decorativo de primer nivel convive con el despacho real
delegado a un helper local (la contracara de la decisión de §4.1 de no entrar en
`function` anidadas); el panelista 2 encuentra seis formas análogas (alias local,
`getFromNamespace`, `match.fun`, default de la firma, `(switch)(...)`,
`eval(as.call(...))`) y las clasifica como **no bloqueantes** porque fallan
cerrado salvo que convivan con un `switch` reconocible. Los dos coinciden en el
hecho medido y difieren en la gravedad. **Queda declarado y sin resolver**: la
decisión de §4.1 es del encargo, y tocarla tras un veredicto adverso está
prohibido.

### A2.5.7 Consecuencia: no se abre el PR

F2 declara el panel obligatorio y dice, literal: **discordancia o NO PASA ⇒
detente y reporta, sin arreglar sobre la marcha**. Con dos NO PASA concordantes y
tres defectos reproducidos por el ejecutor —uno de ellos la misma clase que este
encargo venía a cerrar, y otro escrito por mí en esta misma ronda— **el PR no se
abre y el código no se toca**. La rama queda publicada para que el titular decida.

## A2.6 Verificación de invariantes (§6 del encargo A2)

1. **Toda cifra viene de un bloque de R de esta corrida.** Los 19 casos del
   localizador, los tres estados, las 131 líneas del control, los 1 242 md5, los
   103 827 065 caracteres del corpus trackeado y el 40/40 de `exploracion/` se
   calcularon con `Rscript` en el mismo turno en que se reportan.

2. **¿Queda alguna rama del localizador que pueda terminar en silencio o afirmar
   una causa no medida?** Por enumeración, no de memoria. La función tiene
   **cuatro salidas y sólo cuatro**:

   | # | condición | salida |
   |---|---|---|
   | 1 | `length(irresolubles) > 0` | `stop()` nombrando cada construcción con `deparse()` |
   | 2 | `length(hallazgos) == 0` | `stop()` diciendo que no encontró ninguna |
   | 3 | `length(hallazgos) > 1` | `stop()` con el conteo medido |
   | 4 | `length(hallazgos) == 1` | devuelve la llamada |

   **Ramas que terminan en silencio sin devolver una llamada: 0.** Y ningún
   mensaje afirma una causa no medida: el de «cero llamadas» enumera lo que buscó
   y declara que no entra en cuerpos de `function` (las dos son afirmaciones sobre
   lo que el código hizo); el de irresolubles **cita la construcción literal** en
   vez de interpretarla; el de «más de una» reporta el conteo.

3. **¿Queda alguna entrada que el barrido no pueda leer y reporte como limpia?**
   Por enumeración, con las siete formas de entrada ejecutadas:

   ```
   no_existe.rds      -> ilegible   la ruta no existe en disco
   undir              -> ilegible   es un directorio, no un archivo
   corrupto.rds       -> ilegible   el .rds no deserializa
   utf8.rds           -> ilegible   contiene cadenas con UTF-8 invalido, no escaneables
   limpio.rds         -> limpio
   sucio.rds          -> hallazgos
   vacio.txt          -> limpio
   suman 7 de 7 entradas: CUADRAN=TRUE
   ```

   **Entradas ilegibles reportadas como limpias: 0.** El archivo vacío es el único
   caso que merece nota: se lee bien y no tiene texto, así que es limpio de
   verdad, no ilegible. La distinción está en si el barrido **pudo mirar**, no en
   si encontró algo.

4. **El comentario del YAML, ¿describe la cobertura que las pruebas demuestran?**
   Dice literalmente que barre «exactamente los archivos staged que caen bajo
   `rutas_versionables_crudo()`, es decir `20_insumos/camara` y
   `20_insumos/senado`» y que **no** barre `20_insumos/territorio/`, con el aviso
   de que territorio sí llega a producción. La medición: el paso barrería **68 de
   70** archivos trackeados, y los 2 que no son exactamente los dos CSV de
   territorio; `distrito` y `region` del JSON publicado son 155/155 no-NA y salen
   de ahí; `rutas_barribles_locales()` sí alcanza territorio. **Ni más ancho ni
   más angosto que lo medido.**

5. **¿Se tocó P-101 o P-102?** `git diff`: `37_extraer_tramitacion.R` no aparece;
   en `10_utils.R` la única línea cambiada que los roza es el comentario
   `# Default "camara"` → `# Default CRUDO_CAMARA`. **0 líneas de código.**

## A2.7 Decisiones autónomas de esta ronda

1. **El arnés de la fase `corpus` separa trackeado de ignorado.** El encargo pedía
   barrer el corpus vigente; la función local alcanza además `exploracion/`, que
   `.gitignore` excluye a propósito. Reportar una sola cifra mezclada habría hecho
   que la salida pareciera una brecha y habría entrenado al lector a ignorarla. La
   separación es una mejora dentro de la decisión de §4.3, no un cambio de alcance.
2. **`do.call(switch, ...)` con el símbolo pelado se acepta**, además del literal
   `"switch"` que el encargo nombra: es la misma construcción escrita sin comillas
   y decidirla no requiere adivinar nada.
3. **`base:::switch` se acepta igual que `base::switch`**: mismo namespace, misma
   función, y rechazarlo habría sido una distinción sin diferencia.
4. **Un namespace que no es `base` se marca irresoluble en vez de rechazarse en
   silencio.** `utils::switch` no existe hoy, pero decidir que *no* despacha sería
   una afirmación no medida.
5. **El comentario obsoleto `# Default "camara"`** se corrigió aquí, en la misma
   ronda, porque F0.3 lo señaló y dejarlo habría sido una cadena escrita a mano
   describiendo una línea que ya no la tiene.

## A2.8 Bugs de esta ronda

### A2.8.1 El bug que A2 cierra (clase, no caso)

Los cuatro defectos de la primera vuelta eran la misma cosa: **código que, ante
una entrada que no sabe interpretar, adivina o calla en vez de detenerse.** El
localizador moría con el error de otro; el barrido informaba «cero» sobre un
archivo que no había podido leer. A2 cierra esa clase en los dos sitios, y las
pruebas lo demuestran. Lo que el panel encontró es que **la cerré incompleta en
los dos**, por el mismo descuido: creí que el estado bastaba, y el estado sin
volumen es otra vez el mismo cero ambiguo.

### A2.8.2 Bug propio: la condición de `do.call` escrita al revés (DE-2)

```r
} else if (no_decidible || (is.symbol(que) && !es_simbolo(que, "switch"))) {
```

La segunda cláusula marca como irresoluble justo el caso **decidible**: un símbolo
que no es `switch`. Debía ignorarse. El resultado es un mensaje que afirma
«función no literal, imposible decidir» sobre `do.call(rbind, ...)`, donde la
función es literal y la decisión es trivial. Escribí, en la ronda que corregía D2,
un caso nuevo de D2.

### A2.8.3 Bug propio: la compuerta que exime al conjunto vacío (DE-3)

El bloque del YAML sale en 0 cuando no hay crudo staged, sin comparar ese cero
contra nada. El panelista 2 de la primera vuelta ya lo había señalado como riesgo
R5 y yo lo descarté por estar fuera de las cuatro decisiones de §4. **Estaba
dentro**: es la regla A108, que el propio encargo cita, aplicada a la compuerta.

### A2.8.4 Un error de arnés detectado a tiempo

Mi arnés de reproducción de defectos seguía leyendo la API vieja del barrido
(`nrow()` sobre el data.frame) después de que la API cambiara a tres estados, y
por eso reportó `hallazgos=1` donde lo correcto era `estado=ilegible`. Se detectó
porque la cifra no tenía sentido para un archivo corrupto, y se rehízo con un
lector agnóstico que sirve a las dos APIs. Sin eso, el «después» habría sido
ilegible en el peor momento.

## A2.9 Estado de cifras y datos críticos

- **Ninguna captura cruda se modificó ni se borró.** `git diff --stat HEAD --
  20_insumos`: 0 líneas. Las alteraciones ocurrieron en worktrees desechables (con
  restauración verificada) o en copias en `tempdir()`.
- **0 descargas.** Las tres corridas de `run_all()` resolvieron las 7 capturas por
  caché; 0 líneas de `cache miss`, `http` o `descargando`.
- `40_salidas/json` y `docs/data` volvieron a `HEAD` tras las corridas de control.
- **0 merges, 0 pushes a `main`, 0 PR abiertos.**

## A2.10 Pendientes abiertos al cerrar A2

1. **DE-1 / A2-1 — `limpio` de volumen cero.** El defecto central, confirmado por
   los dos panelistas y reproducido aquí: 6 de 7 archivos con dato personal dentro
   se declaran limpios. La corrección que los dos proponen es la misma y es
   pequeña —comparar caracteres escaneados contra bytes en disco, y mandar a
   `ilegible` el archivo no vacío del que se extraen 0 caracteres— pero **no se
   aplica**: F2 lo prohíbe tras un veredicto adverso, y aplicarla exige una tercera
   vuelta de panel sobre el código nuevo.
2. **DE-2 — la asimetría de `do.call`.** Un símbolo pelado distinto de `switch` es
   decidible y hoy se marca irresoluble, con un mensaje falso.
3. **DE-3 — la compuerta pasa con crudo staged vacío** y el job publica los
   derivados igual.
4. **A2-3 — el comentario de `10_utils.R:276-277`** conserva la afirmación
   «barrer el origen los cubre», medida falsa (102 derivados disparan
   `digitos_9mas`, 0 del crudo).
5. **A2-2 — el comentario del YAML no enumera `10_utils/10_configuracion.R`** entre
   lo que se stagea y no se barre.
6. **La divergencia del panel sobre las `function` anidadas** sigue sin resolver
   (§A2.5.6), y con ella la única salida silenciosa y equivocada que se encontró.
7. **`digitos_9mas` daría 102 falsos positivos** el día que se extienda el barrido
   a los derivados: las tasas se publican como decimal sin redondear, que es
   invariante del proyecto. Extender el alcance exige recalibrar ese detector
   primero.
8. **El arnés versionado no ejercita la clase de DE-1** ni corre en CI: prueba los
   tres caminos que el código ya cubre. Un arnés que sólo prueba lo cubierto
   declara sano justo el hueco que queda.
9. **`validUTF8()` marca `ilegible` cadenas latin1 correctamente declaradas** que
   `grepl(perl = TRUE)` sí escanea. Falla del lado seguro, pero el comentario que
   justifica el chequeo es inexacto para ese caso. 0 casos en el corpus actual.
10. **Pendientes heredados de A que siguen abiertos:** no hay hook de `pre-commit`
    para el camino manual; los arneses de `andamios/` conservan sus literales de
    subdirectorio; los cinco patrones no ven nombres de persona, y el padrón
    nominal es la amenaza declarada del proyecto.

**Marcas `# REVISAR` nuevas introducidas por A2: 0.**

## A2.11 Notas para el revisor

**Lo primero que conviene mirar** es §A2.5.1: seis archivos con el mismo dato
personal adentro, declarados limpios, contra los bytes que ocupan. La corrección
de A2 es correcta en su dirección —los tres estados son la forma buena— y está
incompleta en un punto concreto y barato de cerrar.

**Lo segundo es §A2.8.2**, porque dice algo sobre el proceso y no sobre el código:
en la ronda dedicada a corregir «un mensaje que afirma una causa que no midió»,
escribí otro. La revisión adversarial no es un trámite de cierre; es lo que
encontró las dos veces lo que yo no vi.

**Lo tercero es que los cuatro defectos originales sí están muertos**, verificados
por dos panelistas calibrados de forma independiente, y que no hay regresión: las
rutas de captura son idénticas byte a byte y las salidas publicadas también
(1 242 de 1 242). Lo que queda no es una vuelta atrás sobre A2, es un tercer
tramo corto sobre el mismo diseño.
