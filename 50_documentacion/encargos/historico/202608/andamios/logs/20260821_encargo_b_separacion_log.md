# Bitácora — Encargo B: separar lo verificado de lo que no cerró, y auditar al redactor

> **Encargo:** `50_documentacion/andamios/50_encargo_s24_encargo_b_separacion_p100_p101_p102.md`.
> **Cubre:** la salida a PR de P-100, P-101 y P-102, la corrección de DE-2, y la
> verificación de los siete errores del redactor. **No cubre P-105.**
> **Rama:** `fix/p100-p101-p102-derivacion`, desde `main`. **Sesión:** 24.

## 1. Resumen

Dos rondas y dos paneles dejaron un resultado asimétrico: tres pendientes
verificados esperando a un cuarto que no cierra. Este encargo los separa **por
estado final verificado**, no por commits, porque los commits de A2 mezclan
P-100 y P-105 en el mismo archivo.

**La separación es limpia y se probó, no se supuso.** Las 10 definiciones que
cruzan son idénticas a las de la rama de A (salvo `localizar_switch`, que además
lleva la corrección de DE-2); **0 objetos de P-105** aparecen en la rama nueva;
**0 intrusos** en el inventario; y el YAML queda en **0 líneas de diff** contra
`main`.

**VEREDICTO DE LA RONDA: el encargo NO cierra con PR.** El panel devolvio **NO
PASA por los dos panelistas**, con el control negativo doble superado. La
separacion en si esta limpia —0 objetos de P-105, 0 intrusos, YAML byte a byte el
de `main`, 1 242 de 1 242 salidas identicas— pero fallan dos cosas: **se perdio una
correccion de comentario** de la rama de A, y **la correccion de DE-2 que aproveche
para meter en esta rama introdujo un falso negativo** que la rama vieja no tenia.
Detalle en §5. **No se abrio el PR y no se toco el codigo.**

**Y hay una respuesta que va arriba porque el encargo la pidió arriba: el limpio
de los 70 archivos SÍ sobrevive a la reconciliación bytes ↔ caracteres.** De los
70 trackeados bajo `20_insumos/`, 68 escanean texto y los 2 con cero caracteres
son los dos `.gitkeep`, de **0 bytes**: vacíos de verdad, no ilegibles. Ningún
archivo con contenido escapa al barrido. El corpus vigente está auditado.

## 2. Inventario de commits

| Hash | Mensaje |
|---|---|
| `2b9e19f` | fix(p101) — `cherry-pick` de `cb34726` |
| `8e295ea` | fix(p102) — `cherry-pick` de `25f6082` |
| `b68307c` | fix(p100): el localizador, estado final verificado, sin nada del barrido (incluye el encargo B) |
| `e1a694c` | fix(de-2): un símbolo pelado en `do.call` es decidible |

Tres archivos en el diff contra `main`, todos justificados en §5.11.

## 3. F0 — estado y separabilidad

**F0.1 (H1 verdadera).** `main` en `37e571c` y la rama de A en `ff71730`, las dos
en `0 0` con su remoto. Árbol con el encargo B sin trackear y
`paquete_cierre_v23.md`, que el 🔒 manda no tocar.

**F0.2 (H2 verdadera).** En un worktree desechable sobre `main`, los dos
`cherry-pick` aplican **sin conflicto**: `cb34726` toca 1 archivo (+8/−1) y
`25f6082` toca 2 (+17/−7). Líneas de P-105 arrastradas: **0**.

**F0.3 (H3 verdadera).** La rama de A agrega u 11 objetos de nivel superior en
`10_utils.R` y modifica 6. Clasificados:

| pendiente | objetos |
|---|---|
| **P-100** (3) | `argumento_vacio`, `localizar_switch`, `verificar_registro_pasos` |
| **P-101** (1) | `regenerar_intermedios_si_desalineados` |
| **P-102** (6) | `CRUDO_CAMARA`, `CRUDO_SENADO`, `ruta_cache`, `DIRECTORIOS_CRUDO`, `con_cache`, `capturas_crudas_de_paso` |
| **P-105** (7) | `PATRONES_DATO_PERSONAL`, `texto_de_objeto`, `ESTADOS_BARRIDO`, `barrido_datos_personales`, `hallazgos_del_barrido`, `ilegibles_del_barrido`, `rutas_barribles_locales` |

Y el grafo de llamadas entre ellos, medido sobre el AST:

```
  barrido_datos_personales [P-105]     -> PATRONES_DATO_PERSONAL[P-105], texto_de_objeto[P-105]
  localizar_switch [P-100]             -> argumento_vacio[P-100]
  ruta_cache [P-102]                   -> CRUDO_CAMARA[P-102]
  DIRECTORIOS_CRUDO [P-102]            -> CRUDO_CAMARA[P-102], CRUDO_SENADO[P-102]
  con_cache [P-102]                    -> CRUDO_CAMARA[P-102], ruta_cache[P-102]
  capturas_crudas_de_paso [P-102]      -> ruta_cache[P-102], CRUDO_SENADO[P-102]
  verificar_registro_pasos [P-100]     -> localizar_switch[P-100], capturas_crudas_de_paso[P-102]
  regenerar_intermedios... [P-101]     -> capturas_crudas_de_paso[P-102]

  objetos de P-100/101/102 que llaman a algo de P-105: 0
```

**El grafo es la prueba de separabilidad:** P-105 es una isla. Nada de lo que
cruza depende de él.

**F0.4 (H4 verdadera).** El YAML difiere de `main` en **un solo hunk, 42 líneas
agregadas y 0 eliminadas**, que va desde `# Compuerta de CONTENIDO (P-105...` hasta
el `'` que cierra el bloque, y que llama a `barrido_datos_personales()`,
`hallazgos_del_barrido()` e `ilegibles_del_barrido()`. P-99 ya está en `main`, así
que **el único delta del YAML es P-105** y la rama nueva no necesita tocarlo.

**F0.5 — la marca de E2.** El comentario *barrer el origen los cubre* está en la
línea 277 de la rama de A, y la siguiente definición de nivel superior hacia abajo
es `PATRONES_DATO_PERSONAL` (línea 285): **vive en la cabecera del barrido**. No
cruza. E2 se cierra por exclusión, no por corrección, y se verificó a posteriori:
`grep` sobre la rama nueva da **0 ocurrencias**.

**F0.6 — DE-2 reproducido antes de tocarlo.** Sobre `10_utils.R` de la rama de A:

```
  do.call("switch", list(...))  literal cadena     RESUELVE -> 32,37
  do.call(switch, list(...))    simbolo switch     RESUELVE -> 32,37
  do.call(rbind, piezas)        simbolo pelado     DETIENE   <-- DISCREPA
  do.call(paste, list(...))     simbolo pelado     DETIENE   <-- DISCREPA
  do.call("rbind", piezas)      literal no-switch  RESUELVE -> 32
  do.call(g, list(...))  g variable local          DETIENE
  do.call(f(), list(...)) head calculado           DETIENE
```

Dos discrepancias, con el mensaje *do.call con funcion no literal, imposible
decidir si despacha: do.call(rbind, list(1))* sobre un símbolo que **sí** es
literal y **sí** es decidible.

## 4. F1 — la rama nueva y sus once verificaciones

### 4.1 Equivalencia de definiciones (§4.1)

Comparación en R, definición por definición, por `deparse()` normalizado. No se
comparó ningún archivo a ojo.

| objeto | pendiente | en rama A | en rama nueva | idéntica |
|---|---|---|---|---|
| `CRUDO_CAMARA` | P-102 | sí | sí | **SI** |
| `CRUDO_SENADO` | P-102 | sí | sí | **SI** |
| `ruta_cache` | P-102 | sí | sí | **SI** |
| `DIRECTORIOS_CRUDO` | P-102 | sí | sí | **SI** |
| `con_cache` | P-102 | sí | sí | **SI** |
| `capturas_crudas_de_paso` | P-102 | sí | sí | **SI** |
| `argumento_vacio` | P-100 | sí | sí | **SI** |
| `localizar_switch` | P-100 | sí | sí | **SI** (en el momento del transporte) |
| `verificar_registro_pasos` | P-100 | sí | sí | **SI** |
| `regenerar_intermedios_si_desalineados` | P-101 | sí | sí | **SI** |

**10 de 10 idénticas.** La medición se tomó tras el transporte y antes de corregir
DE-2; el commit siguiente (`e1a694c`) modifica `localizar_switch` **a propósito**, y
esa diferencia es exactamente la corrección de §4.2, verificada en §4.3 de este log.

Y el control inverso, objeto por objeto:

```
  PATRONES_DATO_PERSONAL       en A: TRUE  en nueva: FALSE
  texto_de_objeto              en A: TRUE  en nueva: FALSE
  ESTADOS_BARRIDO              en A: TRUE  en nueva: FALSE
  barrido_datos_personales     en A: TRUE  en nueva: FALSE
  hallazgos_del_barrido        en A: TRUE  en nueva: FALSE
  ilegibles_del_barrido        en A: TRUE  en nueva: FALSE
  rutas_barribles_locales      en A: TRUE  en nueva: FALSE
  objetos de P-105 presentes en la rama nueva: 0
```

### 4.2 Inventario de lo que cruza, clasificado

```
  CRUDO_CAMARA                  [agrega] P-102
  CRUDO_SENADO                  [agrega] P-102
  argumento_vacio               [agrega] P-100
  localizar_switch              [agrega] P-100
  ruta_cache                    [modif ] P-102
  DIRECTORIOS_CRUDO             [modif ] P-102
  con_cache                     [modif ] P-102
  capturas_crudas_de_paso       [modif ] P-102
  verificar_registro_pasos      [modif ] P-100
  regenerar_intermedios_si_desalineados [modif ] P-101

  total tocados: 10 | intrusos: 0
```

### 4.3 DE-2 muerto, con el antes al lado

| caso | antes (rama A) | después (rama nueva) |
|---|---|---|
| `do.call("switch", list(...))` | RESUELVE `32,37` | RESUELVE `32,37` |
| `do.call(switch, list(...))` | RESUELVE `32,37` | RESUELVE `32,37` |
| **`do.call(rbind, piezas)`** | **DETIENE** | **RESUELVE `32`** |
| **`do.call(paste, list(...))`** | **DETIENE** | **RESUELVE `32`** |
| `do.call("rbind", piezas)` | RESUELVE `32` | RESUELVE `32` |
| `do.call(g, ...)` con `g` variable local | DETIENE | DETIENE |
| `do.call(f(), ...)` head calculado | DETIENE | DETIENE |

**El discriminador es sintáctico y no adivina:** una pasada previa recoge los
símbolos que reciben una asignación (`<-`, `=`, `<<-`) en el cuerpo auditado. Un
símbolo **libre** nombra una función del entorno y es decidiblemente no-`switch`;
un símbolo **asignado en el cuerpo** es una variable cuyo valor no se determina
sintácticamente. Los dos se escriben igual; la asignación los separa.

Y el mensaje nombra sólo lo que midió:

```
localizar_switch: la guarda del registro de pasos audita f_dcv() y encontro 1 construccion(es) que NO puede decidir:
    - do.call cuya funcion es la variable `g`, asignada en este mismo cuerpo: do.call(g, list(as.character(id), `32` = "a"))
  Ademas encontro 0 llamada(s) de despacho reconocible(s). No se elige entre lo reconocido y lo no decidido: se detiene.
```

Comparado con el de la rama A (*do.call con funcion no literal, imposible decidir
si despacha*), el nuevo **no afirma que la función no sea literal**: dice cuál es
el símbolo y dónde se asignó.

### 4.4 Las `function` anidadas, en las dos direcciones (§4.3, E6)

| caso | resultado |
|---|---|
| declaración de primer nivel + una anónima con `switch` | **RECONOCE** la declaración: ramas `32,37` |
| **sólo** una anónima con `switch` | **GRITA**: «NO encontro ninguna llamada de despacho en su cuerpo… los cuerpos de `function` anidadas no se inspeccionan» |

La gravedad queda resuelta como manda §4.3: el segundo caso **no es un falso
negativo tolerado**, es un fallo ruidoso.

### 4.5 Los cuatro defectos originales, sobre la rama nueva

| defecto | resultado |
|---|---|
| **D1** fall-through `"32" = ,` | ramas `32,33,37` |
| **D1** `m[!f, , drop = FALSE]` (forma de `37:190`) | ramas `32,37` |
| **D2** `base::switch(...)` | ramas `32,37` |
| **D2** `do.call("switch", list(...))` | ramas `32,37` |
| **D3** y **D4** | **NO APLICAN**: `barrido_datos_personales` y `PATRONES_DATO_PERSONAL` no existen en esta rama |

Y sobre las funciones **reales**, en worktree:

```
--- CASO: fallthrough ---   (rama "38" = , insertada en el switch real)
  ramas localizadas: 38, 32, 33, 34, 35, 36, 37
  guarda: SE DETIENE: paso 38: tiene rama en capturas_crudas_de_paso() pero no existe en PASOS.
--- CASO: indexado ---      (matrix(...)[!f, , drop = FALSE] en el cuerpo auditado)
  ramas localizadas: 32, 33, 34, 35, 36, 37
  guarda: SILENCIO
```

### 4.6 Las 19 formas de AST, re-corridas

**19 de 19** se comportan como el encargo manda, y **0 ramas del localizador
pueden terminar en silencio sin devolver una llamada**.

### 4.7 Control conocido-bueno

```
lineas main: 131 | rama nueva: 131 | identicas (sello y duracion neutralizados): TRUE
guarda en main: 0 | en rama nueva: 0 -> SILENCIO en ambas: TRUE
cache hit: 7 | cache miss/http/descargando: 0
md5 de salidas (sello de generacion neutralizado): comparables 1242 | IDENTICOS 1242
```

### 4.8 Los cinco escenarios de P-93 y los tres mensajes de P-101

Los cinco se detienen nombrando el elemento (paso 38, intermedio `fantasma`, paso
41, paso 37 en `PASOS_SIN_INTERMEDIO`, paso 99) y el control calla. Los tres
mensajes salen exactos: `20_insumos/senado/`, `20_insumos/camara/`, y
`20_insumos/camara/ y 20_insumos/senado/`, cada uno con su `source()` de
recuperación correcto.

### 4.9 Equivalencia de rutas de P-102

22 filas, **22 idénticas**, sobre dos cortes. Las dos filas que comparan símbolo
contra literal comparan el **valor**:

```
  37_subdir_con_cache|"senado"|senado   ->   37_subdir_con_cache|CRUDO_SENADO|senado
  37_subdir_ruta_cache|"senado"|senado  ->   37_subdir_ruta_cache|CRUDO_SENADO|senado
```

### 4.10 El YAML en cero

```
  lineas de diff del YAML contra main: 0
```

### 4.11 El diff completo, enumerado y justificado

| archivo | por qué está |
|---|---|
| `10_utils/10_utils.R` | P-100 (`localizar_switch`, `argumento_vacio`, `verificar_registro_pasos`), P-101 (el mensaje) y P-102 (constantes y defaults). Ningún objeto de P-105 |
| `30_procesamiento/37_extraer_tramitacion.R` | P-102: los tres literales del paso 37 pasan a `CRUDO_SENADO` |
| `50_documentacion/andamios/50_encargo_s24_encargo_b_separacion_p100_p101_p102.md` | el encargo B, commiteado con el primer commit de la rama |

**Archivos sin justificar: 0.** Y sobre las 319 líneas cambiadas: 5 mencionan
objetos o patrones del barrido, **las cinco dentro del propio encargo en
markdown**, que cita el trabajo previo. Restringido al código (`10_utils/` y
`30_procesamiento/`): **0 líneas del barrido**.

## 5. F2 — panel adversarial. Veredicto: **NO PASA, por concordancia**

Dos panelistas independientes, en worktrees separados, sin este log. **Los dos
superaron el control negativo doble** —4/4 defectos originales sobre `b897ec4` y
DE-2 sobre `ff71730`—, así que sus veredictos cuentan.

| | Panelista 1 | Panelista 2 |
|---|---|---|
| **Veredicto** | **NO PASA** | **NO PASA** |
| Control negativo doble | superado | superado |
| ¿Cruzó algo de P-105? | **no**: 0 de 7 objetos, `git grep` en cero, YAML **mismo blob que `main`** | **no**: 0 objetos, 0 patrones regex, 0 en el YAML |
| ¿Hay intrusos? | **no** | **no** |
| ¿Se perdió algo? | **sí, una cosa** | **sí, la misma** |
| No regresión | 1242/1242 salidas y **7/7 intermedios** idénticos, 0 red con fusible | rutas 32–37 6/6, guarda en silencio, P-101 3/3 |
| Defecto en la corrección de DE-2 | **sí, con falso negativo medido** | **sí, tres instancias más de la misma clase** |

### 5.1 El defecto que los dos encontraron: se perdió una corrección

`10_utils/10_utils.R:245` de la rama nueva dice `# Default "camara":` mientras la
línea 249 ya dice `subdir = CRUDO_CAMARA`. La rama de A lo tenía corregido.

```
  rama nueva: 1 ocurrencia de 'Default "camara"'
  rama A:     0
```

Medido en sentido inverso, línea a línea sobre los dos `git diff` contra `main`:
**es la única pérdida.** `30_procesamiento/37_extraer_tramitacion.R` es el **mismo
blob** en las dos ramas. Todo lo demás que la rama de A tiene y la nueva no es
cuerpo de P-105 o el código de DE-2 que se reemplazó a propósito.

Es, además, el literal que P-102 existe para desterrar sobreviviendo en la única
forma que ningún `grep` de código detecta: la prosa que describe la definición que
lo eliminó.

### 5.2 El defecto grave: mi corrección de DE-2 introdujo un falso negativo

Reproducido por el ejecutor. `disp <- switch` a nivel de archivo, y en el cuerpo
auditado un `do.call(disp, ...)` que despacha 32–36, junto a un `switch` señuelo
que declara 32–37:

```
######## RAMA A (antes de mi correccion) ########
   DETIENE -> ... encontro 1 construccion(es) que NO puede interpretar
######## RAMA NUEVA (con mi correccion de DE-2) ########
   RESUELVE -> ramas: 32,33,34,35,36,37
   el despacho REAL declara: 32,33,34,35,36  (NO el 37)
```

**La guarda calla y audita el conjunto equivocado**, dando por registrado el paso
37 cuando no lo está. La rama vieja se detenía.

**Y el comentario que escribí es falso por la misma razón que el mensaje viejo lo
era.** Puse *«Símbolo libre: nombra una función del entorno y no es `switch`.
Decidiblemente no despacha»*. No es decidible: el binding de un símbolo libre no
se determina sintácticamente. Cambié un mensaje falso por un comentario falso.

**El balance lo cierra una medición que no hice y sí hizo el panel:**
`capturas_crudas_de_paso()` —la única función que la guarda audita— contiene
**0 `do.call`**, y el `do.call(rbind, …)` que motivó DE-2 vivía en
`barrido_datos_personales()`, que **no cruza**. Las tres ocurrencias de
`do.call(rbind` que quedan en la rama nueva son **comentarios míos**, no código.
Es decir: **pagué un falso negativo alcanzable por un falso positivo que el propio
código auditado no puede disparar.**

### 5.3 Las otras cinco instancias de la misma clase

Todas reproducidas por el ejecutor, todas en `localizar_switch`:

| # | forma | resultado | por qué está mal |
|---|---|---|---|
| DF-2 | `k` asignada **sólo dentro de una anónima**; `do.call(k, …)` | **DETIENE** diciendo «asignada en este mismo cuerpo» | la pasada previa **sí entra** en cuerpos de `function`, y el recorrido **no**: el comentario de la propia función declara lo contrario, y el mensaje afirma una causa que no midió |
| DF-3 | `do.call(base::rbind, …)` | **DETIENE** como «expresión calculada» | `base::rbind` es tan decidible como `rbind`, y la rama (2) ya sabe descomponer `ns::name` |
| DF-4 | `do.call(quote = TRUE, "switch", list(…))` | **DETIENE** | el respaldo posicional toma `nodo[[2]]`, que es el valor de `quote=`, no la función |
| DF-5 | `for`, `assign()`, formal de la función | **IGNORA** | por la regla que el propio código enuncia deberían detener |
| DF-6 | `quote(switch(…))` inerte | **DETIENE** («2 llamadas»); y si el despacho real es `if/else`, **SILENCIO** auditando 97/98/99 | no distingue código de dato |

Control, medido: ninguna de esas formas existe hoy en la función real. Son
latentes. Pero el modo de fallo que producen es el `stop()` en la entrada de
`run_all()` que el propio comentario de P-100 declara inaceptable.

### 5.4 Lo que el panel sí confirmó

- **La separación, en lo esencial, está limpia**: 0 objetos de P-105, 0 intrusos,
  y el YAML es el **mismo blob** que `main` (`da52e90…` en las dos).
- **Sin regresión en ningún eje medido**: el panelista 1 corrió `run_all()` dos
  veces por rama con el fusible de red del proyecto y obtuvo **1 242 de 1 242**
  salidas idénticas y **7 de 7** intermedios idénticos tras neutralizar el sello
  de reloj; el panelista 2 verificó rutas 32–37 6/6, guarda en silencio y los tres
  mensajes de P-101.
- **P-102 completo**: literales de `"camara"`/`"senado"` **en el AST**, 5 en `main`
  y 2 en las dos ramas (sólo las declaraciones).
- **Ningún acoplamiento oculto**: `localizar_switch` sólo llama a `argumento_vacio`
  y a base.

### 5.5 Desacuerdos

Ninguno sobre el veredicto ni sobre los dos defectos centrales. Difieren en la
gravedad de los falsos negativos con señuelo: el panelista 1 subraya que **los
tres exigen código deliberadamente engañoso** y que la promesa «no degrada a
silencio» se sostiene para código no adversarial; el panelista 2 los cuenta como
huecos de diseño del prepase. **Los dos coinciden en que el caso G es nuevo y lo
introdujo esta ronda.**

### 5.6 Consecuencia: no se abre el PR

F2 dice literal: **discordancia o NO PASA ⇒ detente y reporta, sin arreglar sobre
la marcha**. Con dos NO PASA concordantes, una pérdida real en la separación y un
falso negativo que introduje al corregir DE-2, **el PR no se abre y el código no se
toca**. La rama queda publicada para que el titular decida.

## 6. Las siete dudas de §6, contestadas con medición

### Q1 — ¿bytes NUL en los `.txt` trackeados de `20_insumos/senado/`?

```
   20_insumos/senado/20260812_tramitacion_pedidos.txt   bytes=3843   NUL=0
   20_insumos/senado/20260820_tramitacion_pedidos.txt   bytes=4176   NUL=0
   -> archivos con al menos un NUL: 0
```

**No.** El panel de A2 dijo que «el caso del NUL está vivo hoy» porque existe esa
*clase* de archivo, no porque haya NULs en ellos. La distinción importa: la
vulnerabilidad de `readLines()` truncando en NUL es real y sigue abierta en el
barrido, pero **hoy ningún archivo trackeado la ejercita**.

### Q2 — ¿sobrevive el limpio de los 70 a la reconciliación bytes ↔ caracteres?

**Sí.** Es la duda que el encargo pidió reportar arriba, y la respuesta es la buena.

```
  archivos trackeados bajo 20_insumos/: 70 | por estado: limpio=70
  bytes totales: 2747746 | caracteres escaneados: 103827065
  ARCHIVOS CON VOLUMEN ESCANEADO SOSPECHOSO (0 caracteres o razon < 0.01): 2
   20_insumos/camara/.gitkeep     bytes=0  chars=0  estado=limpio
   20_insumos/senado/.gitkeep     bytes=0  chars=0  estado=limpio
  distribucion de la razon caracteres/bytes (los que escanean algo):
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
  0.129   2.984  16.285  23.750  25.020  83.217
```

Los únicos dos archivos con 0 caracteres son los `.gitkeep`, de **0 bytes**:
vacíos de verdad, no ilegibles. La razón mediana es 16,3 porque los `.rds` están
comprimidos, así que hay muchos más caracteres que bytes. El extremo bajo (0,129)
son los `periodo_legislativo.rds`, y el control lo cierra: son listas de **4
elementos `character`**, y el barrido escaneó **los 4** (31 caracteres, 4
valores). La razón baja es overhead de gzip sobre un objeto minúsculo, **no
lectura parcial**.

**Ningún archivo con contenido escapa al barrido. El corpus vigente está
auditado**, y el defecto del `limpio` de volumen cero —que es real y sigue abierto
en P-105— **no está materializado en el corpus de hoy**.

### Q3 — ¿marcaría `validUTF8()` ilegible alguna cadena latin1 declarada del corpus?

```
  valores de texto examinados: 10186843
  con Encoding()=='latin1': 0
  con validUTF8()==FALSE: 0
  -> archivos que el chequeo marcaria ilegible hoy: 0
```

**No hoy.** Cero cadenas latin1 declaradas en 10,2 millones de valores. El riesgo
que el panel señaló es de diseño, no un incidente en curso, y el candidato que
temía —las capturas del Senado— está limpio.

### Q4 — ¿es divisible el arnés versionado de A2?

**No hay nada que dividir.** Sus cuatro fases (`calib`, `copia`, `estado`,
`corpus`) son todas del barrido: usa `barrido_datos_personales` (5),
`hallazgos_del_barrido` (4), `ilegibles_del_barrido` (2),
`PATRONES_DATO_PERSONAL` (1) y `rutas_barribles_locales` (1), y **0 ocurrencias**
de `localizar_switch`, `argumento_vacio` o `verificar_registro_pasos`. **Se queda
con P-105 y no cruza**, que es lo que §4.4 pedía decidir y reportar.

### Q5 — ¿queda otro comentario que afirme una cobertura no medida?

El de E2 (*barrer el origen los cubre*): **0 ocurrencias en la rama nueva**. De 15
comentarios candidatos que el `grep` de verbos de cobertura devolvió, **13
afirman un comportamiento interno del propio código** («nunca NULL», «nunca a
mitad de pipeline», «nunca fabricado»), verificables leyendo la función. Los dos
que sí afirman cobertura de un alcance externo se midieron:

- `10_utils.R:430` «barre TODOS los directorios de crudo»: el default de `subdirs`
  es `DIRECTORIOS_CRUDO`, 2 declarados y 2 barridos. **Verdadera por construcción.**
- `10_utils.R:1108` «`20_insumos/`, cierto para todos los casos» (P-101): 7 de 7
  rutas de captura caen bajo `20_insumos/`, en `camara` y `senado`. **Verdadera.**

### Q6 — ¿queda el workflow coherente con P-100 dentro y P-105 fuera?

**Sí.** El YAML de `main` invoca `rutas_versionables_crudo()` (4 veces) y
`run_all()` (5), las dos presentes en la rama nueva, y **no invoca nada del
barrido**, porque el paso de contenido nunca se mergeó. P-100 mejora una guarda
que corre **dentro** de `run_all()`: no agrega ni quita ningún paso del job.

### Q7 — `digitos_9mas` con 102 falsos positivos, ¿patrón o alcance?

```
  archivos derivados barridos: 621 | caracteres: 53994130
  correo           archivos=0    coincidencias=0
  rut_con_puntos   archivos=0    coincidencias=0
  rut_sin_puntos   archivos=0    coincidencias=0
  telefono_cl      archivos=0    coincidencias=0
  digitos_9mas     archivos=102  coincidencias=282
  longitud de las corridas: 14, 15, 16 | claves JSON en que caen: tasa_presencia
```

**Del patrón aplicado a ese alcance, no del alcance.** Cuatro de los cinco
detectores dan **0** sobre los derivados; el único que dispara lo hace sobre la
mantisa de `tasa_presencia`, que el proyecto publica como decimal sin redondear
por convención declarada. Extender el barrido a los derivados exige recalibrar
`digitos_9mas` primero (o excluir las claves numéricas del JSON), y ése es el dato
que el encargo de P-105 necesitaba.

## 7. Los siete errores del redactor (§2bis), y qué los cerró

| # | Error | Estado | Qué lo cerró, medido |
|---|---|---|---|
| **E1** | Agrupó P-105 con tres refactores de derivación | **CERRADO** | La rama nueva sale sin P-105: 0 de sus 7 objetos presentes, 0 intrusos, YAML en 0 |
| **E2** | Afirmó que barrer el origen cubre los derivados | **CERRADO por exclusión** | El comentario vive en la cabecera de `PATRONES_DATO_PERSONAL` (F0.5) y no cruza: 0 ocurrencias en la rama nueva. Sigue vivo en la rama de A, y es deuda de P-105 |
| **E3** | Pidió tres estados sin exigir la reconciliación bytes ↔ caracteres | **NO APLICA aquí, verificado** | Ninguna función que cruza tiene una rama que reporte resultado sin examinar su entrada: las 4 salidas de `localizar_switch` y las 2 de `verificar_registro_pasos`, enumeradas en §7.3. El defecto sigue abierto en el barrido |
| **E4** | Redactó «lo irresoluble se detiene» tan ancho que produjo DE-2 | **CERRADO con corrección y prueba** | §4.3: los 7 casos, con el antes al lado, y el mensaje que ya no afirma «función no literal» |
| **E5** | No exigió que el arnés ejercitara la clase del defecto central ni corriera en CI | **RESUELTO por reparto** | Q4: el arnés no contiene ninguna prueba de P-100; se queda con P-105. La exigencia sigue pendiente, en ese encargo |
| **E6** | Resolvió la clasificación de las `function` anidadas pero no su gravedad | **CERRADO** | §4.4: las dos direcciones probadas; el caso de la anónima única **grita**, no calla |
| **E7** | Diseñó un alcance dinámico que con crudo sin cambios da 0 y EXIT=0 | **NO CRUZA, verificado** | F0.4 y §4.10: el alcance dinámico vive en el paso del YAML, y el YAML queda en 0 líneas de diff. DE-3 se queda íntegro con P-105 |

## 8. Bugs de esta ronda

### 9.1 El bug que la separación cierra (clase, no caso)

Tres pendientes verificados por dos paneles no podían llegar a `main` porque
compartían rama con un cuarto que no cerraba. **La causa no era técnica: era del
redactor, al agrupar cuatro superficies de prueba distintas en un encargo.** Los
tres primeros se prueban por equivalencia de rutas; el barrido se prueba contra un
adversario. Agrupados, el más lento gobierna a los tres.

### 9.2 Bug propio: la tabla de equivalencia era ciega a los comentarios

El encargo pidió que la equivalencia se probara «definición por definición, en R,
con la tabla completa», y lo hice: `deparse()` de cada asignación de nivel
superior, 10 de 10 idénticas. **`deparse()` descarta los comentarios por
construcción**, así que la tabla no podía ver lo único que efectivamente se perdió
(§9.3). La prueba que el encargo exigía no era suficiente para la pregunta que el
encargo hacía, y no lo noté hasta que lo midió el panel.

La medición que sí lo habría encontrado —comparar los dos `git diff` contra `main`
línea a línea, clasificando cada línea que está en uno y no en el otro— la corrí
**después** del panel, no antes.

## 9. Estado de cifras y datos críticos

- **La rama de A quedó intacta:** `fix/encargo-a-derivacion-y-barrido` en
  `ff71730`, idéntica en local y remoto. No se rebaseó, no se borró, no se tocó.
- **Ninguna captura cruda se modificó ni se borró.** `git diff --stat HEAD --
  20_insumos` en cero; los dos panelistas verificaron lo mismo en sus worktrees.
- **0 descargas**, 0 corridas del workflow. Las corridas de `run_all()`
  resolvieron las 7 capturas por caché; el panelista 1 lo verificó además con el
  fusible de red del propio proyecto, que no se disparó en 4 corridas.
- **0 merges, 0 pushes a `main`, 0 PR abiertos.**

## 10. Pendientes abiertos al cerrar B

1. **La corrección de comentario perdida** (§5.1): `10_utils.R:245` dice
   `# Default "camara"` sobre una definición que ya usa `CRUDO_CAMARA`.
2. **El falso negativo que introdujo la corrección de DE-2** (§5.2): un símbolo
   libre ligado a `switch` hace que la guarda audite el conjunto equivocado en
   silencio. La rama vieja se detenía.
3. **El comentario falso que lo acompaña**: «Decidiblemente no despacha» no es
   decidible.
4. **Las cinco instancias de §5.3**: la pasada previa entra en cuerpos de
   `function` mientras el recorrido no; `base::rbind` rechazado como expresión
   calculada; el respaldo posicional de `do.call` con argumentos nombrados; `for`,
   `assign` y formales invisibles al prepase; y `quote()` contado como despacho.
5. **`localizar_switch()` llegaría a `main` sin ningún arnés versionado.** Los dos
   panelistas lo señalan: son las ~190 líneas más intrincadas del cambio, no hay
   ningún `.R` en `andamios/` que las ejercite, y el arnés de A2 —que
   correctamente se queda con P-105— nunca contuvo pruebas de P-100. La única
   prueba viva es que `run_all()` no se detiene, que sólo cubre el camino feliz.
6. **`37_extraer_tramitacion.R:254`** conserva el comentario `# subdir = "senado"`
   con el literal. Igual en las dos ramas, así que no es regresión de la
   separación, pero es el mismo hueco del pendiente 1.
7. **`formals()` pasa de literal a símbolo** en `ruta_cache` y `con_cache`.
   Funciona en toda la ruta medida; cambiaría de comportamiento para código que
   inspeccione `formals()` esperando una cadena. No se halló ningún consumidor así.
8. **Todo lo de P-105 sigue fuera**, por diseño: el barrido con sus tres defectos
   (el `limpio` de volumen cero, la compuerta con crudo vacío y el comentario de
   E2), su arnés, y el paso del YAML.

**Marcas `# REVISAR` nuevas introducidas por B: 0.**

## 11. Notas para el revisor

**Lo primero que conviene mirar** es §5.2: la corrección de DE-2 cambió un falso
positivo **que el código auditado no puede disparar** por un falso negativo que sí
es alcanzable. El dato que lo decide —`capturas_crudas_de_paso()` tiene 0
`do.call`— no lo medí yo; lo midió el panel, y cambia el signo de la corrección.

**Lo segundo es §8.2**, porque es sobre el método y no sobre el código: la tabla de
equivalencia que el encargo exigió, y que dio 10 de 10, no podía ver lo único que
se perdió, porque `deparse()` descarta comentarios. Una prueba que pasa no es lo
mismo que una prueba suficiente.

**Lo tercero es que la separación, en lo que se propuso, funcionó:** 0 objetos de
P-105 cruzaron, 0 intrusos, el YAML es el mismo blob que `main`, y la salida
publicada es idéntica en 1 242 de 1 242 archivos. Lo que falla no es la separación:
es el arreglo que aproveché para meter en la misma rama.

---

# Ronda B2 — revertir DE-2, restaurar lo perdido, versionar el arnés de P-100

> **Encargo:** `50_documentacion/andamios/50_encargo_s24_encargo_b2_revertir_de2_y_arnes.md`.
> **Misma rama que B:** `fix/p100-p101-p102-derivacion`. **Sesión:** 24.
> Esta sección amplía el log del encargo B; no lo reemplaza.

## B2.1 Resumen

El panel de B devolvió NO PASA por dos cosas, y las dos se corrigen aquí sin
diseñar nada nuevo: **revertir** y **restaurar**. Más lo que faltaba desde el
principio: **un arnés versionado para P-100**.

**Un resultado de F0 cambia el encargo y hay que decirlo arriba: H3 es falsa.** El
encargo daba por hecho que revertir mataría las seis instancias «porque las seis
nacieron del prepase». **Sólo dos nacieron ahí.** Medido en las dos ramas en la
misma corrida: las instancias 1 y 5 difieren entre la rama A y la rama B (son
consecuencia de la corrección de B, y la reversión las mata); las otras cuatro,
más el caso silencioso, **se comportan igual en las dos** y por tanto son
defectos heredados de A2, no de B. Se reportan por separado, como el propio
encargo manda cuando H3 resulta falsa.

## B2.2 Inventario de commits de esta ronda

| Hash | Mensaje |
|---|---|
| `1d46a23` | revert(de-2): `localizar_switch` vuelve byte a byte al estado de `ff71730` (incluye el encargo B2) |
| `4a44d13` | chore(p100): arnés versionado del localizador, con los siete casos de regresión del panel |

## B2.3 F0 — estado y reproducción

**F0.1 (H1 verdadera).** `main` en `37e571c`, la rama en `885fc55`, la rama A en
`ff71730`, las tres en `0 0` con su remoto.

**F0.2 (H2 verdadera).** `localizar_switch()` en la rama A son 88 líneas con **0
referencias a objetos de P-105**: transportable byte a byte.

**F0.3 (H3 FALSA) — las seis instancias, antes de tocar nada.**

| instancia | rama A (`ff71730`) | rama B (`885fc55`) | ¿difiere? |
|---|---|---|---|
| 1 (R2) símbolo libre ligado a `switch` | DETIENE | **RESUELVE[32,33,34,35,36,37]** | **sí — consecuencia de B** |
| 2 (R3a) símbolo asignado sólo en una anónima | DETIENE | DETIENE | no — heredada de A2 |
| 3 (R3b) `do.call(base::rbind, …)` | DETIENE | DETIENE | no — heredada de A2 |
| 4 (R3c) `do.call(quote=TRUE, "switch", …)` | DETIENE | DETIENE | no — heredada de A2 |
| 5 (R3d) `assign("h",…)` ; `do.call(h, …)` | DETIENE | **RESUELVE[32]** | **sí — consecuencia de B** |
| 6 (R3e) `quote(switch(…))` + el `switch` real | DETIENE | DETIENE | no — heredada de A2 |
| 6bis el caso **silencioso** | RESUELVE[97,98,99] | RESUELVE[97,98,99] | no — heredada de A2 |

**2 de 7.** El caso 6bis merece subrayado: es un **falso negativo**, la guarda
audita 97/98/99 mientras el despacho real declara 32/33, **y existe en la rama A
desde A2**. No lo introdujo B y la reversión no lo toca.

**F0.4 (H4 verdadera).** Método sensible a comentarios sobre el archivo completo:
461 tokens `COMMENT` en la rama A y 426 en la B; 45 sólo en A y 13 sólo en B. De
los 45, todos menos 2 están dentro del bloque de P-105; los 2 restantes son
exactamente el par `# Default CRUDO_CAMARA` de R4. Los 13 de B son el par
revertido más el comentario del prepase.

## B2.4 F1 — la reversión, la restauración y el arnés

### 1. Las seis instancias, antes y después

| instancia | B antes (`885fc55`) | B2 después | |
|---|---|---|---|
| 1 símbolo libre ligado a `switch` | RESUELVE[32,…,37] | **DETIENE** | revertida |
| 5 `assign("h",…)` ; `do.call(h, …)` | RESUELVE[32] | **DETIENE** | revertida |
| 2, 3, 4, 6, 6bis | sin cambio | sin cambio | heredadas de A2 |

Y contra la rama A, que es la referencia: **0 de 7 difieren**.

### 2. `localizar_switch()` idéntico byte a byte

```
  lineas: 88 y 88 | identicas linea a linea: TRUE
  md5 del texto fuente: 0d8936e92295ddf0d16c588a91dde282  (los dos)
  tokens COMMENT dentro de la funcion: 6 y 6 | identicos: TRUE
```

### 3. El método nuevo al lado del viejo, sobre el par que el panel usó

```
== EQUIVALENCIA: rama A vs rama B (885fc55) ==
  METODO NUEVO (texto fuente, ve comentarios): difieren 2 de 48
     ruta_cache
     localizar_switch
  METODO VIEJO (deparse, ciego a comentarios): difieren 1 de 48
     localizar_switch
  objetos que SOLO el metodo nuevo ve distintos: ruta_cache
```

**Ésa es la demostración**: el método que el encargo B exigió no podía ver
`ruta_cache`, que era exactamente donde estaba la pérdida. Y tras revertir y
restaurar, sobre el par rama A / rama B2:

```
  METODO NUEVO: difieren 0 de 48   |   METODO VIEJO: difieren 0 de 48
  comentarios solo en la rama B2: 0
  comentarios solo en la rama A: 43, los 43 dentro del bloque de P-105
```

### 4. Diferencias de comentario en cero

Ningún comentario existe en la rama B2 que no exista en la rama A, y los 43 que
sólo están en A son P-105 íntegro.

### 5. Los cuatro defectos originales, todavía muertos

`D1` fall-through → `32,33,37`; `D1` indexado (37:190) → `32,37`; `D2`
`base::switch` → `32,37`; `D2` `do.call("switch", …)` → `32,37`. `D3` y `D4` **no
aplican**: `barrido_datos_personales` no existe en esta rama.

### 6. Las 19 formas de AST, ahora desde el arnés versionado

19 de 19 `[ok]`, más 3 casos sobre la función **real** y 3 de contorno. El arnés
lee el texto de `capturas_crudas_de_paso()` **del archivo** e inserta las formas
ahí, para que la prueba mida la función que hay hoy y no una copia que se
desincroniza.

### 7. El arnés falla cuando debe

Roto a propósito un caso esperado del bloque `ast`:

```
ARNES DEL LOCALIZADOR: 1 caso(s) NO dieron lo esperado.
  - ast / switch(...) pelado: esperado DETIENE, obtenido RESUELVE[32,37]
EXIT_REAL=1
```

Y con todo en orden, `EXIT_REAL=0`.

### 8. Control conocido-bueno

```
lineas main: 131 | rama B2: 131 | identicas: TRUE
guarda en main: 0 | en rama B2: 0 -> SILENCIO en ambas: TRUE
cache hit: 7 | cache miss/http/descargando: 0
md5 de salidas: comparables 1242 | IDENTICOS 1242
```

### 9. Los cinco escenarios de P-93 y los tres mensajes de P-101

Los cinco se detienen nombrando el elemento y el control calla. Los tres mensajes
salen exactos: `20_insumos/senado/`, `20_insumos/camara/`, y
`20_insumos/camara/ y 20_insumos/senado/`.

### 10. Equivalencia de rutas de P-102

22 filas, **22 idénticas**. Las dos que comparan símbolo contra literal comparan
el valor.

### 11. El YAML en cero y el diff enumerado

`git diff main -- .github/workflows/refresh-semanal.yml`: **0 líneas**. Seis
archivos en el diff contra `main`, los seis justificados (§B2.7), **0 sin
justificar**, y **0 líneas** que mencionen objetos o patrones del barrido en
código o en el arnés, sobre 305 líneas cambiadas.

## B2.5 F2 — panel de tercera vuelta. Veredicto: **PASA, por concordancia**

Dos panelistas independientes, sin este log. **Los dos superaron el control
negativo triple**, así que sus veredictos cuentan.

| | Panelista 1 | Panelista 2 |
|---|---|---|
| **Veredicto** | **PASA** | **PASA** |
| D1–D4 sobre `b897ec4` | logrado | logrado |
| Falso negativo sobre `885fc55` | logrado | logrado |
| Ceguera de `deparse()` | logrado | logrado |
| ¿Queda diferencia en `localizar_switch()`? | **ninguna**: idéntico en bytes crudos (74 / 4053 / 3929 en las tres funciones), token stream igual, 6 COMMENT iguales, 0 CR, 0 espacios finales | **ninguna**: 4 052 bytes en las dos, md5 `0d8936e92295`, 641 tokens y 6 COMMENT iguales |
| ¿Se perdió algo? | 48/48 unidades comunes idénticas, 0 comentarios exclusivos de la rama | `git diff ff71730 rama` = **0 inserciones / 136 supresiones**, todas de P-105; **0 líneas de P-100/101/102 perdidas** |
| Defectos de código | **ninguno** | ninguno de esta ronda |
| No regresión | 6/6 rutas, guarda en silencio, 6/6 escenarios, 621/621 JSON idénticos, 7 intermedios iguales | 12 rutas, 6 escenarios, 619+619 JSON con `"generado"` como única diferencia, 0 red con fusible |

**Nota de proceso:** los dos panelistas cayeron por errores de API (uno de ellos
porque la máquina se suspendió) y se reanudaron pidiéndoles el informe con lo que
ya tenían medido, declarando explícitamente qué bloques quedaban sin medir. **Los
dos respondieron «ninguno».**

### B2.5.1 Lo que el panel confirmó

- **La reversión está completa y es exacta.** Los dos midieron `localizar_switch`
  byte a byte contra `ff71730` y no encontraron diferencia de ninguna naturaleza,
  incluidos comentarios, retornos de carro y espacios finales. La única
  diferencia es de **posición** en el archivo (líneas 820-907 → 684-771), por las
  136 líneas de P-105 que no están.
- **0 huellas del prepase**: `asignados`, `es_asig` y `rec` dan 0 ocurrencias.
- **Los dos casos del control negativo 2 vuelven a detener** en la rama.
- **El arnés hace su trabajo**: `EXIT=0` con 25/25 casos en la rama; `EXIT=1`
  contra `885fc55` nombrando las dos regresiones; y contra `b897ec4`, 16 casos.
  El panelista 1 lo sometió además a mutación deliberada y 4 de sus 5 mutantes
  murieron; el panelista 2 corrió 7 y mataron 5.
- **Ningún comentario nuevo afirma inalcanzabilidad**: el panelista 2 lo verificó
  con `grep` de `inalcanzab|imposible|nunca|jamas` sobre el arnés → 0.
- **P-105 ausente**: 0 apariciones de los 7 nombres del barrido, YAML idéntico a
  `main`, y sólo 6 archivos cambian.

### B2.5.2 Los cuatro defectos que el panel sí encontró, y qué se hizo

**Ninguno es de código de esta ronda.** Reproducidos por el ejecutor:

**(a) El conteo de un comentario que escribí en el arnés era falso.** Decía
«Cuatro de ellos son FALSOS POSITIVOS» cuando por su propia definición son
**seis**: los casos 1 a 6 son todos código sano ante el que la guarda se detiene.
Es exactamente la clase que el 🔒 de este encargo prohíbe. **Corregido en
`1fbaf49`, después del panel**, y se declara aquí que el artefacto que los
panelistas revisaron llevaba el conteo malo. Es una línea de comentario en el
arnés, no en el código auditado, y el arnés sigue en `EXIT=0`.

**(b) `argumento_vacio()` es inerte hoy.** El panelista 2 midió que borrar
`if (argumento_vacio(nodo, k)) next` **no rompe nada**: el arnés sigue en
`EXIT=0` y el fall-through sigue resolviendo `32,33,37`. Reproducido:

```
  linea eliminada: 738 -> if (argumento_vacio(nodo, k)) next
  EXIT_REAL del arnes con la guarda de D1 borrada = 0
  fall-through sin la guarda de D1: RESUELVE[32,33,37]
```

La razón es que `recorrer(nodo[[k]])` pasa el símbolo vacío **como argumento**,
sin bindearlo, y `is.call()` sobre él devuelve `FALSE` sin error. Lo que arregló
D1 fue **quitar el binding** (`hijo <- nodo[[k]]` seguido de `is.null(hijo)`), no
el salto. El salto es defensa redundante, y **el arnés no la fija**. Se registra
como pendiente; no se toca, porque cambiarlo sería rediseñar lo que §4.1 manda
revertir.

**(c) `base::do.call("switch", list(...))` es un falso negativo silencioso** no
cubierto por el arnés, y `(switch)(...)` con señuelo también: la guarda resuelve
el conjunto equivocado. **Heredados de `b897ec4`**, idénticos en las cuatro
versiones: no son regresión de esta ronda ni de B.

**(d) Documentación desactualizada**: `CLAUDE.md` sigue declarando P-102 como
pendiente abierto y no tiene entrada para P-100/101/102, y
`37_extraer_tramitacion.R:254` conserva `# subdir = "senado"` sobre una línea que
ya usa `CRUDO_SENADO`. El segundo estaba ya declarado como pendiente 6 del log de
B y excluido a propósito. `CLAUDE.md` se actualiza al mergear, como se hizo con
P-99.

### B2.5.3 Desacuerdos

Ninguno sobre el veredicto ni sobre la reversión. El panelista 1 clasifica el
`(switch)(...)` con señuelo como falso negativo no cubierto; el panelista 2 lo
clasifica como **falso positivo ruidoso** y reserva el falso negativo para
`base::do.call("switch", ...)`. Medido por el ejecutor: `(switch)(...)` **solo**
detiene, y **con señuelo** resuelve `32,33,34,35,36,37` mientras el despacho real
declara `32,33`. **Los dos tienen razón en su caso**: el comportamiento depende de
si hay señuelo. Queda declarado.

## B2.6 Verificación de invariantes (§6 del encargo B2)

1. **Toda cifra viene de un bloque de R de esta corrida.** Las 7 instancias en las
   dos ramas, los 88 renglones y el md5 del bloque, los 461/426/415 tokens
   `COMMENT`, las 131 líneas, los 1 242 md5 y las 22 rutas se calcularon con
   `Rscript` en el mismo turno.

2. **¿Queda alguna diferencia en `localizar_switch()`?** Por el método de §4.3, no
   por `deparse()`: 88 líneas contra 88, **idénticas línea a línea**, mismo md5 del
   texto fuente (`0d8936e9…`), y **6 tokens `COMMENT` idénticos** dentro de la
   función. **Ninguna.**

3. **¿Algún comentario que B2 escribe afirma una propiedad que no midió?** B2
   agrega **69 líneas de comentario**; las que afirman inalcanzabilidad o
   imposibilidad: **0**. Las únicas que hablan de `do.call` o de DE-2 en código son
   la descripción del bloque `regresion` del arnés, que dice *«los siete casos que
   el panel de la sesión 24 usó para medir una corrección de `do.call` que después
   se revirtió»* — un hecho sobre la historia, no una propiedad del código. **El
   código calla sobre DE-2, como manda §4.2.**

4. **¿Cubre el arnés las seis instancias revertidas?** Caso por caso, los **siete**
   están en el bloque `regresion`, cada uno con su esperado y su nota: dos marcados
   `contrato: sin esto vuelve el falso negativo` (las que la reversión mata), cuatro
   `falso positivo vigente`, y uno `FALSO NEGATIVO conocido, documentado`.

5. **¿Qué encuentra el arnés si mañana vuelve el prepase?** Corrido contra
   `885fc55`, no de memoria:

   ```
   ARNES DEL LOCALIZADOR: 2 caso(s) NO dieron lo esperado.
     - regresion / simbolo libre ligado a switch: esperado DETIENE, obtenido RESUELVE[32,33,34,35,36,37]
     - regresion / assign("h",...) ; do.call(h, ...): esperado DETIENE, obtenido RESUELVE[32]
   estado de salida: 1
   ```

   **Nombra exactamente las dos que la reversión mató, y sale en 1.**

## B2.7 El diff contra `main`, archivo por archivo

| archivo | por qué está |
|---|---|
| `10_utils/10_utils.R` | P-100, P-101 y P-102. 0 objetos de P-105 |
| `30_procesamiento/37_extraer_tramitacion.R` | P-102: los tres literales del paso 37 |
| `50_documentacion/andamios/50_verificar_localizador_p100.R` | el arnés versionado que exige §4.4 |
| `50_documentacion/andamios/50_encargo_s24_encargo_b_separacion_p100_p101_p102.md` | el encargo B |
| `50_documentacion/andamios/50_encargo_s24_encargo_b2_revertir_de2_y_arnes.md` | el encargo B2 |
| `50_documentacion/andamios/logs/20260821_encargo_b_separacion_log.md` | este log |

**Archivos sin justificar: 0. Líneas de barrido en código y en el arnés: 0.**

## B2.8 Decisiones autónomas de esta ronda

1. **Se reportó H3 como falsa en vez de forzarla.** El encargo daba por hecho que
   las seis instancias nacían del prepase; la medición dice que sólo dos. Las otras
   cuatro se registran como heredadas de A2, que es lo que §0.2 manda cuando H3 no
   se sostiene.
2. **El arnés declara el caso 6bis como `FALSO NEGATIVO conocido, documentado`.**
   Aserta el comportamiento vigente para que un cambio no pase inadvertido, y la
   nota deja explícito que no es el comportamiento deseable. Un arnés que aserta un
   defecto sin decir que lo es lo convierte en contrato.
3. **El arnés lee la función real del archivo** en vez de copiar su texto. Una copia
   se desincroniza en cuanto alguien toque el pipeline, y entonces la prueba mide
   una función que ya no existe.
4. **No se tocó ninguna de las cuatro instancias heredadas.** Están fuera del
   alcance de B2, y arreglarlas sería diseñar la tercera versión que §4.1 prohíbe.

## B2.9 Pendientes que viajan con el PR

1. **DE-2 sigue vivo como falso positivo ruidoso.** `do.call(rbind, piezas)` con
   símbolo pelado detiene la guarda. Hoy `capturas_crudas_de_paso()` —la única
   función auditada— tiene **0 `do.call`** (medido), pero eso depende de código que
   nadie ha escrito: el árbol tiene 6 usos de esa forma en otros archivos. Se
   registra; el código no lo afirma en ningún comentario.
2. **`argumento_vacio()` es redundante hoy** (§B2.5.2b) y el arnés no lo fija.
3. **`base::do.call("switch", …)` y `(switch)(…)` con señuelo** son falsos
   negativos heredados de `b897ec4`, no cubiertos por el arnés.
4. **El arnés no corre en CI.** El encargo dice explícitamente que eso no se decide
   aquí; queda registrado.
5. **`30_procesamiento/37_extraer_tramitacion.R:254`**: `# subdir = "senado"` sobre
   una línea que ya usa `CRUDO_SENADO`. Misma clase que el comentario restaurado.
6. **`formals()` pasa de literal a símbolo** en `ruta_cache` y `con_cache`.
7. **`CLAUDE.md` no se actualizó**: sigue declarando P-102 como pendiente abierto y
   no tiene entrada para P-100/101/102. Corresponde al mergear, igual que en P-99.
8. **Las cuatro instancias heredadas de A2** (§B2.3, F0.3): la anónima, `base::rbind`,
   el argumento nombrado de `do.call` y `quote()` contado como despacho, con su
   caso silencioso.
9. **Todo P-105 sigue fuera**, por diseño.

**Marcas `# REVISAR` nuevas introducidas por B2: 0.**

## B2.10 Notas para el revisor

**Lo primero es que esta ronda no diseñó nada.** Revirtió `localizar_switch()` a un
estado que dos paneles habían verificado —byte a byte, comprobado por dos
panelistas independientes— y restauró dos líneas de comentario. Lo único nuevo es
el arnés.

**Lo segundo es lo que la medición de F0 corrigió del propio encargo:** H3 daba por
hecho que las seis instancias nacían del prepase, y sólo dos lo hacían. Las otras
cuatro son de A2 y siguen abiertas. Un encargo que hubiera «cerrado las seis» sin
medir habría declarado resueltos cuatro defectos vivos.

**Lo tercero es el hallazgo del panel sobre el arnés (§B2.5.2b):** `argumento_vacio()`
—el helper con nombre que A2 introdujo para arreglar D1— **no es lo que arregla
D1**. Lo que lo arregla es la ausencia del binding. El arnés que este encargo
agrega no distingue las dos cosas, y por eso un mutante que borra el helper
sobrevive. Es la clase de cosa que sólo aparece cuando alguien ataca el arnés en
vez de leerlo.
