# Reparación de la guarda circular del bot semanal — log

**Fecha:** 2026-08-12 · **Sesión:** 18 · **Rama:** `fix/guarda-bot-primera-corrida`
**Base:** `main` con el PR #8 ya mergeado (`b619a50`), verificado en la precondición.
**Encargo:** `50_documentacion/andamios/50_encargo_reparacion_guarda_bot.md`
**Verificación:** `50_documentacion/andamios/50_verificar_guarda_bot.R`
**Fusible:** `50_documentacion/andamios/50_fusible_red.R`

---

## §1. Compuertas

### G1. Anatomía de la guarda

`10_utils/10_utils.R`, `regenerar_intermedios_si_desalineados()` en las líneas
**494-566** del archivo tal como estaba al abrir (73 líneas). Firma:

```
regenerar_intermedios_si_desalineados <- function(pasos, root, corte = CORTE_FECHA) {
```

Invocada en `00_run_all.R:84`. El orquestador tiene **dos** bucles sobre `PASOS`:
el de validación de rutas (línea 73) y el que ejecuta los pasos (línea 98). La
guarda está entre ambos: después de validar rutas y **antes de ejecutar ningún
paso**, que es por lo que su `stop()` deja 0 de 6.

**Ramas que pueden terminar en detención: 3**, en las líneas 509, 549 y 557. La
que importa es la 509 (capturas ausentes); las otras dos son fallo de un paso
durante la regeneración y desalineamiento persistente después de regenerar.

**Qué devuelve `corte_declarado_por()` cuando el intermedio no existe**, medido:

```
  ruta consultada : .../40_salidas/intermedios/no_existe_este_intermedio_p74.rds
  file.exists()   : FALSE
  valor devuelto  : NA_character_   | is.na(): TRUE | clase: character
  is.na(v) | v != corte  ->  TRUE   (con corte = '2026-08-03')
```

**Consecuencia medida:** "ausente" y "presente con otro corte" caen en la misma
rama. Ese colapso es el defecto.

### G2. Resolución de corte

`capturas_crudas_de_paso()` en las líneas **460-477**. Firma:
`capturas_crudas_de_paso <- function(id) {` — **no recibe `corte`**. Menciona el
argumento `corte` en su cuerpo: **FALSE**. Llama a `ruta_cache()` **6 veces**, y
`ruta_cache()` resuelve por `corte_para_clave()`, que menciona `CORTE_FECHA`
(la global): **TRUE**.

Caso construido donde argumento y global difieren:

```
  global CORTE_FECHA            : 2026-08-03
  argumento 'corte' de la guarda: 2026-08-10
  ruta devuelta para el paso 36 : 20260803_detalle_proyectos_xml_2026_tope-inf.rds
  -> lleva el corte 20260803 (la GLOBAL), no 20260810 (el ARGUMENTO)
```

Con `corte='2026-08-10'` la guarda medía desalineamiento contra 2026-08-10 y
existencia de capturas contra 2026-08-03. Dos cortes distintos, sin ruido.

### G3. Lo que el workflow escribe

`refresh-semanal.yml` (144 líneas), único workflow del repositorio.

| acción | línea | contenido |
|---|---|---|
| `cp -r` | 72 | `cp -r 40_salidas/json "$JSON_PREVIO"` |
| `sed -i` | 75 | inyecta `CORTE_FECHA` |
| `git add` | 115 | `10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data` |
| `git commit` | 128 | — |
| `git push` | 130 | `--force` acotado por refspec a `refresh/*` |

Rutas del `git add`: **4 de 4** existen en el repo. **Commitea `40_salidas/`: SÍ.
Commitea `docs/`: SÍ.** Es decir, "estado limpio tras una corrida del bot" incluye
dato publicado regenerado, no solo capturas.

### G4. Línea base de comportamiento, ANTES de tocar nada

Condición del runner reproducida: 6 intermedios movidos fuera con `mv`,
`CORTE_FECHA` inyectado con el mismo `sed` de la línea 75, sin red.

```
[00_run_all] [INFO] Corte temporal: 2026-08-09

STOP: run_all: 6 de 6 intermedios NO corresponden al corte vigente (2026-08-09):
  diputados, asistencia_nominal, asistencia_ambitos, votos, proyectos, proyectos_detalle.
  No se pueden regenerar: falta la captura cruda de ese corte en 20_insumos/camara/
  (6 archivo(s)): 20260809_diputados.rds, 20260809_periodo_legislativo.rds, …

Llamadas HTTP intentadas hasta el stop: 0
Intermedios presentes al terminar: 0
Capturas en 20_insumos/camara al terminar: 44
```

**0 de 6 pasos ejecutados.** Es la línea base contra la que se compara todo lo
demás.

### G5. Línea base de integridad

| directorio | archivos | md5 distintos |
|---|---|---|
| `20_insumos/camara/` | **44** | 23 |
| `40_salidas/intermedios/` | **6** | 6 |
| `40_salidas/json/` | **156** | 156 |
| `docs/data/` | **156** | 156 |

---

## §2. Qué se cambió

Todo en `10_utils/10_utils.R`. `00_run_all.R` **no se tocó**.

**Los tres estados, separados.** `regenerar_intermedios_si_desalineados()` pasa de
73 a 115 líneas:

- **(0) Primera corrida** — nueva. Se dispara cuando **0 de 6 archivos** de
  intermedio existen en disco, medido con `file.exists()` sobre las 6 rutas.
  Registra el hecho y devuelve sin hacer nada: no hay desalineamiento posible
  cuando no hay con qué comparar.
- **(1) Alineados** — sin cambios.
- **(2) Desalineado con capturas presentes** — sin cambios en el comportamiento;
  lo único distinto es que ahora la existencia de capturas se evalúa contra el
  mismo corte que el desalineamiento.
- **(3) Desalineado con capturas ausentes** — sigue el `stop()`, salvo
  autorización explícita `options(camara.permitir_descarga_inicial = TRUE)`
  (`OPCION_DESCARGA_INICIAL`, default FALSE, leída solo por `getOption()`, nunca
  de `Sys.getenv()` ni deducida de estar en CI). El mensaje del `stop()` ahora
  nombra esa opción como salida.

**Aviso nuevo:** los intermedios presentes pero sin sello o ilegibles se nombran
en un `WARN` propio y se tratan como desalineados, para que "desalineado" no tape
"roto".

**Resolución de corte (G2), corregida:** `corte_para_clave(corte = NULL)` y
`ruta_cache(nombre_cache, tope = NULL, corte = NULL)` aceptan un corte explícito
con default a la global, y `capturas_crudas_de_paso(id, corte = NULL)` lo propaga.
La guarda le pasa su propio `corte`. `con_cache()` sigue llamando
`ruta_cache(nombre_cache, tope)` sin corte y por lo tanto no cambia.

---

## §3. El fusible de red

`50_documentacion/andamios/50_fusible_red.R`. Arma `trace()` sobre `httr::GET`,
`httr::POST`, `httr::RETRY` y `curl::curl_fetch_memory` con un tracer que
**mata el proceso** (`quit(status = 99)`) en la primera invocación, imprimiendo la
pila de llamadas.

**Por qué `quit()` y no `stop()`:** un `stop()` en el tracer es una condición de
clase `error`, y el pipeline la atrapa — `descargar_xml_camara()` la reintenta 4
veces y `capturar_xml_detalle()` del 36 la convierte en una fila con
`estado = error_red` y **sigue**. Un fusible con `stop()` no detiene la corrida:
la degrada en silencio.

Verificado con una llamada deliberada por cada vía, cada una envuelta en
`tryCatch(error = ...)`:

| vía | exit code | ¿imprimió "NO SE DETUVO"? |
|---|---|---|
| `httr::GET` | **99** | 0 veces |
| `curl::curl_fetch_memory` | **99** | 0 veces |
| `httr::RETRY` | **99** | 0 veces |

La línea `*** NO SE DETUVO ***` está después del `tryCatch` y no se imprimió
nunca: el fusible no es atrapable.

---

## §4. Criterios

| # | Criterio | Resultado | Cifra |
|---|---|---|---|
| C1 | Cinco compuertas con lectura directa | **CUMPLE** | 5 de 5 con archivo, línea y salida literal; G4 registrada antes de tocar código |
| C2 | Estado (1): supera la guarda y alcanza el paso 32 | **CUMPLE** | log `Primera corrida … 0 de 6 archivos`; cabecera `PASO 32` impresa; exit 99 por el fusible |
| C3 | La detención posterior es por ausencia de red | **CUMPLE** | muere en `*** FUSIBLE DE RED DISPARADO ***` dentro del paso 32, no en la función de G1 |
| C4 | Estado (2) intacto: regenera sin red | **CUMPLE** | exit **0**, fusible no disparó, 6 de 6 `cache hit`, `Intermedios regenerados: 6 de 6 al corte 2026-08-03` |
| C5 | Estado (3) conservado sin autorización | **CUMPLE** | `stop()` con mensaje accionable que nombra la opción |
| C5b | La autorización explícita funciona | **CUMPLE** | log `descarga inicial esta AUTORIZADA`, alcanza `PASO 32`, exit 99 |
| C6 | La distinción se decide en disco | **CUMPLE** | `sum(file.exists(rutas_intermedios)) == 0`; 0 referencias a `Sys.getenv("CI")` |
| C7 | Corte resuelto de una sola forma | **CUMPLE** | con argumento: **6 de 6** rutas llevan el prefijo del argumento; **0 de 6** siguen resolviendo por la global |
| C8 | Capturas e intermedios intactos | **CUMPLE** | **44 de 44** y **6 de 6** md5 idénticos, `identical: TRUE`, 0 sobrantes |
| C9 | Neutralidad del artefacto público | **CUMPLE** | **156 de 156** en `40_salidas/json` y **156 de 156** en `docs/data`, `identical: TRUE` |
| C10 | Cero HTTP en el mismo proceso de cada escenario | **CUMPLE** | fusible armado dentro del proceso; C4 y C5 terminan con exit 0 sin dispararlo; C2 y C5b mueren en él antes de que salga tráfico |
| C11 | Funciones protegidas idénticas a HEAD | **CUMPLE** | **9 de 9** idénticas: `sellar`, `leer_sellado`, `validar_corte` y las 6 de P-74 incluido `con_cache` |
| C12 | PR abierto y sin merge, conteo por `gh api` | ver §7 | — |

---

## §5. Panel adversarial

Los cuatro pases se ejecutaron **como pases propios con comandos de verificación,
no como subagentes independientes**: el intento de lanzarlos agotó el límite
semanal de la cuenta. Es una diferencia real de independencia y queda declarada.

**1. El que duda del denominador.** Revisó los `log_msg` que la guarda emite. El
de primera corrida declara "0 de 6 archivos de intermedio en disco"; el de
ilegibles, "%d de %d"; el de autorización, "%d de %d intermedios" y "%d captura(s)".
Sin hallazgos abiertos.

**2. El que busca el falso verde — 1 hallazgo, aceptado y corregido.**
La condición de primera corrida era `all(is.na(declarados))`. Medido en esta
corrida, `corte_declarado_por()` devuelve `NA` por **tres** causas distintas:

```
(a) archivo AUSENTE          -> NA
(b) presente pero SIN SELLO  -> NA | file.exists: TRUE
(c) presente pero CORRUPTO   -> NA | file.exists: TRUE
```

Solo (a) es primera corrida. Con la versión anterior, un repositorio con 6
intermedios presentes pero sin sello habría entrado por esa rama y, sin capturas
del corte, se habría puesto a descargar. La condición pasó a
`sum(file.exists(rutas_intermedios)) == 0`. Probado con **C2b**: 6 archivos sin
sello → `WARN` nombrándolos → `stop()`, sin entrar por la rama nueva.

**3. El que ataca la guarda aflojada — 2 caminos, ambos declarados.**
- Un operador local que borre `40_salidas/intermedios/` y no tenga capturas del
  corte vigente ahora **descarga** en vez de recibir el `stop()` útil. Es la
  semántica buscada de "primera corrida" y el contrato de P-74 sigue validando la
  fecha, pero es un aflojamiento real para el caso de borrado accidental.
- `camara.permitir_descarga_inicial` **no se consume al usarse**, a diferencia del
  escape de P-74 (`camara.permitir_captura_fuera_de_corte`, que sí). Se evalúa una
  vez por `run_all()`, así que no se propaga dentro de una corrida, pero sí queda
  encendida entre corridas de la misma sesión. Declarado, no cerrado.

**4. El que revisa el §0.** Las cuatro hipótesis del encargo quedaron medidas y no
citadas: la guarda vive donde se dijo (medido en G1), `corte_declarado_por()`
devuelve `NA` para el ausente (medido, y también para dos casos más que el encargo
no anticipaba), el `stop()` **no** es una sola rama sino **3** (contadas en G1), y
el workflow **sí** commitea `40_salidas/` y `docs/` (medido en G3).

---

## §6. Errores de esta corrida

**El invariante 3 del encargo era una salvaguarda de juicio, no una compuerta, y
el juicio falló.** Decía: *"Cero red … Si una prueba fuera a descargar, no se
corre."* Al probar C2 no anticipé que arreglar la guarda es exactamente lo que
permite al pipeline alcanzar los extractores. La prueba corrió con un **contador**
de llamadas —un instrumento de medición, no una barrera— y completó una extracción
real: **3230 llamadas HTTP**, 329 segundos, 6 capturas nuevas del corte 2026-08-09
escritas en `20_insumos/camara/` (44 → 50), y los 6 intermedios más los 312
artefactos publicados sobrescritos.

Nada de eso se perdió: las 44 capturas originales nunca se modificaron (44 de 44
md5 idénticos), lo publicado se restauró desde git (156 de 156 en ambos destinos),
los intermedios se restauraron desde el respaldo (6 de 6) y las 6 capturas nuevas
se movieron con `mv` a cuarentena fuera del repo, nunca con `rm`.

**El fusible es el reemplazo estructural de ese invariante.** Un contador reporta
después de que el daño ocurrió; el fusible mata el proceso en la primera llamada,
antes de que salga tráfico, y no depende de que alguien se acuerde de la regla.
La diferencia no es de grado: un invariante escrito en un documento se cumple si
quien lo lee juzga bien, y aquí no lo hice.

**Efecto colateral útil:** esa corrida dejó la primera evidencia real del contrato
temporal de P-74 en producción, sobre las 6 capturas antes de cuarentenarlas.
Registro literal de `20260809_diputados.rds`, que además es un `character` y no un
data.frame:

```
List of 6
 $ descarga_fecha : chr "2026-08-09"
 $ descarga_inicio: chr "2026-08-09"
 $ descarga_fin   : chr "2026-08-09"
 $ corte_fecha    : chr "2026-08-09"
 $ escape         : logi FALSE
 $ registrado_por : chr "con_cache"

  estado_temporal_captura() -> dentro_de_corte
```

**6 de 6** con registro, **6 de 6** `dentro_de_corte`, escape `FALSE` en todas.

---

## §7. PR

Ver la sección de cierre de la corrida. Conteo por `gh api` paginado sobre
`/repos/tomgc/transparencia_legislativa_chile/pulls/<n>/files` contra
`changed_files`, con denominador declarado. Sin merge.

---

## §8. Lo que este encargo NO puede probar

No puede probar que el workflow real funcione de punta a punta: eso exige una
corrida contra la API **en el runner**, con checkout fresco, `sed` real y descarga
real, y aquí todo se probó en local con el fusible impidiendo precisamente esa
descarga. Lo que sí está probado es que la guarda deja pasar el estado del runner
(C2), que la detención posterior es la red y no la guarda (C3), y que el caso que
P-65 protegía sigue funcionando (C4).

La evidencia que falta la daría **la corrida del lunes**: si el job llega al paso
32 y descarga, la reparación funcionó; si vuelve a morir en `00_run_all.R:84`, no.
Un `workflow_dispatch` manual la adelanta sin esperar al cron.

Queda indeterminado si `camara.permitir_descarga_inicial` debería consumirse al
usarse como el escape de P-74, y queda abierto el aflojamiento para el operador
que borre sus intermedios por accidente sin tener capturas del corte.
