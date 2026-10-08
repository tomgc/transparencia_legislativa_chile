# P-74, acto (a) — log de medición del contrato temporal

**Fecha:** 2026-08-08 · **Sesión:** 18 · **Encargo:**
`50_documentacion/andamios/50_encargo_p74_medicion_contrato_temporal.md`
**Script de medición:** `50_documentacion/andamios/50_medir_p74_contrato_temporal.R`
(una sola corrida produce todo lo que sigue; `Rscript` desde la raíz).

Medición **read-only**. No se implementó ningún filtro, no se editó el paso 36 y
no se tocaron `sellar()`, `leer_sellado()` ni `validar_corte()`.

**Procedencia de las cifras de este log.** Ninguna se hereda del traspaso v17.
Cada una viene de una de tres fuentes, y el log dice cuál en cada caso:
(1) el stdout de la corrida del script — la mayoría;
(2) un comando `git` ejecutado aparte, citado con el comando exacto (el script R
no invoca `git`, así que C7 y C9 no podían salir de su stdout);
(3) una lectura directa de archivo, citada con `archivo:línea`.
Esta distinción se agregó tras el hallazgo 3 del agente 1 del panel, que objetó
—con razón— que la versión anterior de este párrafo afirmaba que *toda* cifra
venía del stdout.

---

## §1. Compuertas de precondición

### G1. Forma real del intermedio del paso 36

Ruta absoluta:
`/Users/tomgc/Projects/transparencia_legislativa_chile/40_salidas/intermedios/proyectos_detalle.rds`

```
class()  : tbl_df, tbl, data.frame
nrow()   : 381
ncol()   : 7
names()  : boletin, nombre, tipo_iniciativa, n_materias, materias, n_votaciones, votaciones
```

List-cols de data.frame **descubiertas por contenido** (no por nombre): 2 de 7
columnas → `materias` (2 columnas) y `votaciones` (20 columnas). Ambas con **1
solo esquema** medido sobre los **381** elementos, no sobre uno.

La list-col de votaciones se identificó por traer el id de votación en su
esquema. Sus campos, **contados: 20**. `nrow()` agregado del list-col: **723**
eventos.

| campo | class | no-NA / 723 | únicos |
|---|---|---|---|
| votacion_id | character | 723 | 723 |
| descripcion | character | 723 | 115 |
| fecha | character | 723 | 723 |
| total_si | character | 723 | 119 |
| total_no | character | 723 | 101 |
| total_abstencion | character | 723 | 42 |
| total_dispensado | character | 723 | 4 |
| articulo | character | **619** | 618 |
| quorum_valor | character | 723 | 5 |
| quorum_glosa | character | 723 | 5 |
| resultado_valor | character | 723 | 2 |
| resultado_glosa | character | 723 | 2 |
| tipo_valor | character | 723 | 1 |
| tipo_glosa | character | 723 | 1 |
| tipo_votacion_valor | character | 723 | 3 |
| tipo_votacion_glosa | character | 723 | 3 |
| tramite_constitucional_id | character | 723 | 4 |
| tramite_constitucional_glosa | character | 723 | 4 |
| tramite_reglamentario_id | character | 723 | 3 |
| tramite_reglamentario_glosa | character | 723 | 3 |

`articulo` es el único campo con huecos: **619 de 723**. Los otros 19 vienen
completos.

### G2. Campos de fecha del nodo

Campos evaluados: **20 de 20** (ninguno excluido a priori). Campos con al menos
un valor con prefijo ISO `AAAA-MM-DD`: **1 de 20** → `fecha`.

```
campo            : fecha
class()          : character          <- NO es Date ni POSIXct
no-NA            : 723 de 723 valores
con prefijo ISO  : 723 de 723 valores no-NA
anchos distintos : 19                 <- un solo ancho, formato estable
5 valores reales : 2026-03-25T13:17:37 | 2026-03-25T13:16:35 | 2026-03-25T13:15:33 |
                   2026-03-25T13:14:31 | 2026-03-25T13:13:26
```

Es `character`, pero **con formato estable**: ancho único de 19 y prefijo ISO en
723 de 723 valores. La comparación lexicográfica sobre los primeros 10
caracteres es cronológicamente correcta y no requiere coerción a `Date`. Esto
importa para la vía de filtrado: no hay que reparar el tipo antes de acotar.

Campos NO clasificados como fecha (listados para que el descarte sea auditable):
`votacion_id, descripcion, total_si, total_no, total_abstencion,
total_dispensado, articulo, quorum_valor, quorum_glosa, resultado_valor,
resultado_glosa, tipo_valor, tipo_glosa, tipo_votacion_valor,
tipo_votacion_glosa, tramite_constitucional_id, tramite_constitucional_glosa,
tramite_reglamentario_id, tramite_reglamentario_glosa`.

### G3. Inventario de intermedios

Directorio barrido:
`/Users/tomgc/Projects/transparencia_legislativa_chile/40_salidas/intermedios`
Archivos `.rds` encontrados: **6** (resultado del barrido, no dato de entrada).

| intermedio | nrow | ncol | sello.corte | names() |
|---|---|---|---|---|
| asistencia_ambitos | 310 | 10 | 2026-08-03 | diputado_id, ambito, n_sesiones, n_asiste, n_no_asiste, n_sin_registro, n_justificadas, n_injustificadas, tasa_presencia, tasa_presencia_o_justificada |
| asistencia_nominal | 9183 | 11 | 2026-08-03 | diputado_id, sesion_id, sesion_numero, fecha, tipo_sesion, en_periodo_vigente, asistencia, justificacion_codigo, justificacion_glosa, rebaja_asistencia, rebaja_quorum |
| diputados | 155 | 10 | 2026-08-03 | diputado_id, nombre, sexo, fecha_nacimiento, partido_id, partido_nombre, partido_alias, distrito, region, tendencia |
| proyectos_detalle | 381 | 7 | 2026-08-03 | boletin, nombre, tipo_iniciativa, n_materias, materias, n_votaciones, votaciones |
| proyectos | 1705 | 7 | 2026-08-03 | boletin, diputado_id, orden, nombre, fecha_ingreso, admisible, rol |
| votos | 122605 | 9 | 2026-08-03 | votacion_id, boletin, descripcion, fecha, resultado, tipo, diputado_id, opcion_valor, sentido |

Sellados: **6 de 6** archivos barridos. Con `corte == CORTE_FECHA (2026-08-03)`:
**6 de 6** sellados.

### G4. Universo y denominadores

| magnitud | valor | denominador |
|---|---|---|
| Boletines en el intermedio del 36 | **381** | filas de `proyectos_detalle.rds` |
| Eventos de votación en el nodo | **723** | suma de filas de las 381 list-cols `votaciones` |
| Boletines con nodo NO vacío | **115** | de 381 boletines |
| Boletines con nodo vacío | **266** | de 381 boletines |
| Boletines votados (denominador propio, de `votos.rds`) | **115** | — |
| … de ellos presentes en el detalle del 36 | **115** | de 115 |

Control cruzado: el escalar `n_votaciones` que persiste el 36 cuadra con las
filas del list-col, **723 == 723**. Los dos denominadores independientes
(115 boletines con nodo no vacío; 115 boletines votados según `votos.rds`)
coinciden.

### G5. Alcance temporal del XML crudo

Ruta absoluta (construida con `ruta_cache()`, no escrita a mano):
`/Users/tomgc/Projects/transparencia_legislativa_chile/20_insumos/camara/20260803_detalle_proyectos_xml_2026_tope-inf.rds`

```
nrow()  : 381
names() : boletin, xml, estado, estado_detalle
estados : resuelto=381          <- 0 no_reconocido, 0 error_red
```

Barrido de **381 de 381** documentos XML con contenido. Rutas de nodo con texto
de fecha (todas, no una muestra) — **2 rutas distintas**:

| ruta_nodo | n | n posteriores al corte | fecha_max |
|---|---|---|---|
| `/ProyectoLey/FechaIngreso` | 381 | **0** | 2026-07-20 |
| `/ProyectoLey/Votaciones/VotacionProyectoLey/Fecha` | 723 | **1** | **2026-08-04** |

Valores de ejemplo: `FechaIngreso` → `2016-05-02T00:00:00 | 2016-07-06T00:00:00
| 2016-11-23T00:00:00`; `Fecha` → `2026-03-25T13:17:37 | 2026-03-25T13:16:35 |
2026-03-25T13:15:33`.

**Respuesta sí/no:** sí, el XML crudo contiene una fecha que el parser descarta
(`/ProyectoLey/FechaIngreso`, 381 valores, ninguno posterior al corte), pero esa
no es la que produce el exceso. **El exceso temporal nace en la CAPTURA, no en
la derivación:** el único evento posterior al corte ya está en el XML persistido
(`n_post = 1` medido sobre el crudo), y la derivación lo copia sin agregarlo ni
inventarlo. Consecuencia para el acto (b): la vía "filtrar al derivar" es
posible sin red, porque el dato a descartar ya está en disco; la vía "no
capturarlo" no lo es sin volver a la fuente, y la captura es dato crudo inmutable.

### G6. Fecha de corte efectiva

Leída de `10_utils/10_configuracion.R` en el momento de la corrida:

```
CORTE_FECHA   : 2026-08-03      <- coincide con el valor que el encargo daba por respaldado
ANIO_PROCESO  : 2026
REFRESCAR_API : FALSE (getOption camara.refrescar = FALSE)
```

---

## §2. Objetivos de medición

### M1. Exceso temporal en el nodo

Único campo de fecha (G2), por lo tanto un solo bloque de conteos:

| magnitud | valor | denominador |
|---|---|---|
| Eventos posteriores a 2026-08-03 | **1** | de **723** eventos del nodo |
| Fecha máxima observada | **2026-08-04** (crudo `2026-08-04T13:05:07`) | — |
| Fecha mínima observada | 2016-12-21 | — |
| Boletines afectados | **1** | de **115** con nodo no vacío (**1** de **381** del intermedio) |

Evento en exceso, identificado: boletín `16569-25`, `votacion_id = 89587`,
`fecha = 2026-08-04T13:05:07`, descripción `Boletín N°16569-25`.

**Hallazgo lateral, medido y no pedido por M1.** El corte superior no es el
único límite que el nodo no respeta. Contra `ANIO_PROCESO = 2026`, que sí acota
a los otros extractores:

| magnitud | valor | denominador |
|---|---|---|
| Eventos anteriores a 2026-01-01 | **176** | de **723** eventos del nodo |
| Boletines afectados por el borde inferior | **29** | de **115** con nodo no vacío |
| Años distintos presentes en el nodo | 2016, 2018, 2021, 2024, 2025, 2026 | — |

El desajuste del borde inferior es **176 veces** el del superior. Se reporta
como medición; qué hacer con él es del acto (b).

### M2. Barrido de los seis intermedios (tres estados, sin colapsar)

Se evaluaron columnas planas **y** columnas anidadas dentro de list-cols de
data.frame (por eso `proyectos_detalle` aporta 27 campos y no 7). La
clasificación de cada columna se imprime con su `class()` en el stdout de la
corrida, para que el descarte sea auditable campo por campo.

| intermedio | campos con fecha | estado | posteriores al corte | denominador (valores con fecha) | rango observado |
|---|---|---|---|---|---|
| asistencia_ambitos | 0 de 10 | **(i) sin ningún campo de fecha** | — | — | — |
| asistencia_nominal | 1 de 11 (`fecha`) | **(ii) con campo de fecha, cero excesos** | 0 | 9183 | 2026-01-05 → 2026-07-22 |
| diputados | 1 de 10 (`fecha_nacimiento`) | **(ii) con campo de fecha, cero excesos** | 0 | 155 | 1947-01-31 → 1999-06-08 |
| proyectos_detalle | 1 de 27 (`votaciones$fecha`) | **(iii) con eventos posteriores al corte** | **1** | 723 | 2016-12-21 → **2026-08-04** |
| proyectos | 1 de 7 (`fecha_ingreso`) | **(ii) con campo de fecha, cero excesos** | 0 | 1705 | 2026-01-05 → 2026-07-20 |
| votos | 1 de 9 (`fecha`) | **(ii) con campo de fecha, cero excesos** | 0 | 122605 | 2026-01-05 → 2026-07-22 |

`asistencia_ambitos` es agregado por diputado × ámbito y **no tiene ninguna
columna de fecha**: su cero no es "cero excesos", es "no medible por fecha". No
se colapsa con los cuatro que sí tienen campo y sí dan cero.

### M3. Veredicto de generalidad

**Veredicto: el defecto NO es general. Es exclusivo del nodo rescatado en la
sesión 17.**

Evidencia a favor de "defecto general": **1 de 6** intermedios con exceso
(`proyectos_detalle`). Es el único.

Evidencia en contra: **4 de 6** intermedios tienen campo de fecha y **cero**
valores posteriores al corte, sobre denominadores grandes y contados —
`votos` 0 de 122605, `asistencia_nominal` 0 de 9183, `proyectos` 0 de 1705,
`diputados` 0 de 155. El quinto (`asistencia_ambitos`) no tiene campo de fecha,
así que no puede confirmar ni desmentir.

Contraste explícito en ambos sentidos: si el sello dejara pasar contenido
posterior al corte *como regla*, los 4 intermedios con fecha lo mostrarían, y
`votos.rds` —**122.605** valores de fecha, la misma familia de eventos que el
nodo— sería el primer candidato. Su máximo es **2026-07-22**, doce días antes
del corte.

**La causa de la asimetría, medida (no la que este log afirmaba antes).** La
primera versión atribuía la diferencia a la forma del endpoint: `votos` por año
y congelado, el nodo por entidad y por lo tanto "al momento de la llamada". El
agente 4 del panel la refutó leyendo el código: `34_extraer_votaciones.R:51`
llama `retornarVotacionDetalle` **una vez por `votacion_id`**, que es exactamente
el patrón "por entidad" que se atribuía en exclusiva al nodo (lo mismo en
`35_extraer_proyectos.R`). La explicación era falsa y se retira.

Lo que sí distingue a los dos casos está medido, y es la **fecha de descarga de
la captura**, no la forma del endpoint. Fecha del commit que trajo cada captura
cruda del corte `20260803` (fuente: `git log -1 --format=%ad -- <archivo>` por
cada una, ejecutado en la sesión 18):

| captura cruda | commit |
|---|---|
| `20260803_diputados.rds` | 2026-08-03 13:53 |
| `20260803_periodo_legislativo.rds` | 2026-08-03 13:53 |
| `20260803_asistencia_long_2026_tope-inf.rds` | 2026-08-03 13:53 |
| `20260803_asistencia_nominal_2026_tope-inf.rds` | 2026-08-03 13:53 |
| `20260803_votos_long_2026_tope-inf.rds` | 2026-08-03 13:53 |
| `20260803_proyectos_long_2026_tope-inf.rds` | 2026-08-03 13:53 |
| `20260803_detalle_proyectos_2026_tope-inf.rds` | 2026-08-03 13:53 |
| **`20260803_detalle_proyectos_xml_2026_tope-inf.rds`** | **2026-08-08 13:07** |

**7 de 8** capturas del corte se bajaron el día del corte. La octava —la única
que P-63 creó en la sesión 17, y la única fuente del intermedio en exceso— se
bajó **cinco días después**, bajo una clave que sigue declarando
`corte = 2026-08-03`, porque `corte_para_clave()` (`10_utils.R:196-207`)
construye la clave desde `CORTE_FECHA` y **deliberadamente no desde `Sys.Date()`**
(su comentario en `10_utils.R:191-194` lo declara como decisión de diseño). En
esos cinco días la API acumuló la votación del 2026-08-04, y la captura la
recogió.

Es decir: el exceso no lo produce la forma del endpoint ni el sello, sino
**capturar después del corte que la clave declara**. Cualquier captura futura que
se genere fuera del día de su corte puede reproducirlo, use el endpoint que use.

**Advertencia sobre el alcance del veredicto:** vale para el corte 2026-08-03 y
para los 6 intermedios que existen hoy. No se midió qué pasa si una captura de
otro paso se regenera fuera del día de su corte; por la evidencia de arriba, ese
es el escenario que reproduciría el defecto en otro intermedio.

### M4. Costo de la vía "filtrar al derivar"

Filtrando `fecha <= 2026-08-03` en el paso 36:

| efecto | valor | denominador |
|---|---|---|
| Eventos que quedarían fuera | **1** | de **723** eventos del nodo |
| Eventos que quedarían dentro | **722** | de **723** eventos del nodo |
| Boletines con conteo alterado | **1** | de **115** con nodo no vacío |
| **Boletines que quedarían vacíos y hoy no lo están** | **0** | de **115** con nodo no vacío |
| Boletines con nodo no vacío después del filtro | **115** | de **115** |

El efecto secundario que podía cambiar la decisión **no se materializa**: ningún
boletín pierde su nodo entero. El boletín afectado (`16569-25`) conserva sus
demás votaciones. El costo del filtro, en el corte actual, es un evento.

Este costo es del corte 2026-08-03 y **no es extrapolable**: depende de cuántos
días medien entre la descarga y el corte declarado, que varía en cada refresh.

### M5. Superficie de consumo actual

Archivos `.R` del pipeline barridos: **11** (`00_escanear_proyecto.R`,
`00_run_all.R`, `10_configuracion.R`, `10_diff_conteos.R`, `10_utils.R`, `32`,
`33`, `34`, `35`, `36`, `39`). El barrido lista la raíz y los dos directorios de
código con `list.files()`; no nombra archivos a mano. La versión anterior sí los
nombraba y dejaba fuera `00_escanear_proyecto.R` (hallazgo 4 del agente 2 del
panel); incluirlo no cambió ninguna cifra.

**Probe 1 — ambigüedad de los nombres, medida.** Contra las **40** columnas de
los otros 5 intermedios: **3 de 20** nombres del nodo son ambiguos
(`votacion_id`, `descripcion`, `fecha` — también son columnas de `votos.rds`) y
**17 de 20** son exclusivos del nodo. Sin esta medición, buscar el token `fecha`
contaría como consumo del nodo algo que viene de `votos.rds`.

**Probe 2 — los 17 campos exclusivos, buscados como token.** **39** apariciones
en código, con desglose por archivo **contado en la corrida** (Probe 2b), no
derivado a mano: **34 de 39** en `10_utils.R` y **5 de 39** en
`33_extraer_asistencia.R`. Las 34 caen en las líneas `451-455` (el vector
`VOTACIONES_COLUMNAS`) y `472-488` (el parser), es decir la **definición del
esquema y el productor**. Las 5 restantes son `tipo_valor` (líneas 116, 153, 219)
y `tipo_glosa` (118, 145) en el 33: homónimos que ese script construye desde
nodos de asistencia y valida contra `DOMINIO_ASISTENCIA` — y `asistencia_nominal.rds`
no tiene ninguna columna con esos nombres (ver G3), así que no son el nodo.
**Consumidores reales entre los 17 campos exclusivos: 0.**

**Probe 3 — accesos a la columna `votaciones` por nombre.** 7 en código: 5 en
`36_extraer_detalle_proyectos.R` (176, 177, 197, 204, 206 — el productor y sus
propias validaciones) y 2 en `10_diff_conteos.R` (40, 42). Estas 2 operan sobre
`p`, que es un **perfil JSON ya parseado**: `10_diff_conteos.R:39` hace
`p <- jsonlite::fromJSON(f, simplifyVector = FALSE)` (lectura directa del
archivo, no salida de la corrida). No son un acceso al intermedio. Ningún acceso
desde un consumidor del `.rds`.

**Probe 4 — quién lee el intermedio.** `39_consolidar_json.R:54` lo lee y
`39:82-86` construye `det_map` con exactamente **4** campos: `boletin`,
`nombre`, `tipo_iniciativa`, `materias`. `votaciones` y `n_votaciones` **no
aparecen** en esa extracción.

**Claves reales del JSON publicado.** 156 archivos barridos, **106** claves
distintas. Campos del nodo que aparecen como clave: **3 de 20**
(`votacion_id`, `descripcion`, `fecha`) — y son **exactamente los 3 ambiguos**.
Campos **exclusivos** del nodo presentes en el JSON: **0 de 17** (intersección
calculada en la corrida, no a ojo). Las tres claves viven bajo
`votaciones.votos.*`, que `39_consolidar_json.R:292-326` construye desde
`votos.rds` — `v <- votos[votos$diputado_id == did, ]` en la línea 292 (lectura
directa del archivo). El bloque `votaciones.votos.proyecto.*` publica `boletin`,
`nombre`, `tipo_iniciativa`, `materias`: los mismos 4 campos de `det_map`.

**Respuesta a M5: ninguno.** Ni un script del pipeline ni una clave de
`40_salidas/json/` consume hoy los campos del nodo. Por eso P-74 todavía es
barato: el contenido en exceso está en un intermedio, no en el dato publicado,
y ninguna cifra del portal cambia si se acota. La evidencia es la coincidencia
de cuatro barridos independientes (17 campos exclusivos sin consumidor, la
list-col sin acceso fuera del productor, el 39 tomando 4 campos que no la
incluyen, y 0 de 17 exclusivos en 106 claves de JSON).

### M6. Comportamiento del sello ante el exceso

Sin modificar nada, se llamó `validar_corte()` con los **6 de 6** sellos leídos
en G3:

```
validar_corte(sellos, '2026-08-03') devuelve: TRUE   (SIN error, con el exceso de M1 presente)
```

Qué compara, medido sobre el cuerpo real de la función: el único campo del sello
que `validar_corte()` referencia con `$` es **`$corte_fecha`** (la corrida
imprime `campos referenciados con $ en el cuerpo: $corte_fecha`). Leyendo el
cuerpo en `10_utils.R:104-124`, sus tres `stop()` cubren (a) sello sin
`corte_fecha`, (b) `corte_fecha != CORTE_FECHA`, (c) hermanos con cortes
distintos entre sí. **Ninguna de las tres mira el contenido del objeto.**

Y qué se escribe, del cuerpo real de `sellar()` (`10_utils.R:65-77`, impreso por
la corrida): `corte_fecha` sale de la global `CORTE_FECHA`, más `anio_proceso`,
`hash_origen` y `escrito_en`. Es decir, el sello **declara** el corte al que el
intermedio dice pertenecer; no lo verifica contra las fechas que contiene.

**Por qué el exceso no produce ruido.** El sello afirma la *procedencia* del
archivo, y esa afirmación es verdadera en el sentido literal:
`proyectos_detalle.rds` sí fue derivado de la captura cuya clave declara
`corte = 2026-08-03`. Lo que el sello no dice —y nadie más comprueba— es que esa
captura se haya bajado el 2026-08-03. **No fue así:** se bajó el 2026-08-08 (ver
la tabla de fechas de commit en M3), cinco días después. El evento del
2026-08-04 entró por esa ventana.

*Corrección registrada:* la primera versión de este párrafo afirmaba que "la API
lo entregó dentro de la respuesta que se capturó ese día". Es falso, y era
comprobable sin salir del repositorio: una captura del 2026-08-03 no puede
contener un evento del 2026-08-04. Lo detectó el agente 4 del panel.

Con eso, `validar_corte()` responde correctamente la pregunta que le hicieron
("¿este archivo declara el corte vigente?"). Las preguntas que hoy nadie hace
son dos, no una: "¿su contenido cabe dentro del corte que declara?" y "¿la
captura de la que proviene se tomó dentro de ese corte?". La segunda es la que
produjo este caso, y ninguna de las dos vías que el encargo plantea para el acto
(b) la aborda.

---

## §3. Criterios de éxito

| # | Criterio | Resultado | Cifra que lo sostiene |
|---|---|---|---|
| C1 | Seis compuertas respondidas con lectura directa | **CUMPLE** | 6 de 6 respondidas con ruta absoluta y salida literal; 0 respondidas citando el traspaso v17 |
| C2 | Todo campo de fecha del nodo con conteo de exceso y denominador | **CUMPLE** | 20 de 20 campos evaluados; 1 clasificado como fecha; 1 de 1 medido (1 de 723 eventos) |
| C3 | Intermedios clasificados en los tres estados, sin colapsar | **CUMPLE** | 1 en (i), 4 en (ii), 1 en (iii); suma 6 de 6 |
| C4 | Veredicto de M3 afirmado en ambos sentidos | **CUMPLE** | a favor: 1 de 6 con exceso; en contra: 4 de 6 con fecha y 0 excesos, el mayor con 0 de 122605 |
| C5 | M4 con denominador y boletines vaciados contados aparte | **CUMPLE** | 1 de 723 eventos fuera; **0 de 115** boletines quedarían vacíos, contado por separado |
| C6 | M5 resuelto leyendo scripts y claves reales del JSON | **CUMPLE** | 11 archivos `.R` y 156 JSON barridos; 106 claves; 0 de 17 campos exclusivos consumidos |
| C7 | Cero escrituras fuera de `andamios/` y `andamios/logs/` | **CUMPLE con limitación declarada** | tres evidencias, abajo |
| C8 | Cero llamadas HTTP, contadas | **CUMPLE con limitación declarada** | contador sobre `httr::GET/POST/RETRY` y `curl::curl_fetch_memory`: **0**; paquetes ausentes al inicio: **0 de 7** |
| C9 | `sellar()`, `leer_sellado()`, `validar_corte()` idénticos a HEAD | **CUMPLE** | `git -C <raíz> diff HEAD --stat -- 10_utils/10_utils.R` → 0 líneas, exit 0 |

**C7, con sus tres evidencias y su límite.** `git status --porcelain` es **ciego
a los intermedios**, que están gitignorados (`.gitignore:42`), así que por sí
solo no puede sostener el criterio (hallazgo 6 del agente 2 del panel). Las tres
evidencias juntas sí:
1. `git -C <raíz> status --porcelain` al cerrar → 3 rutas, **todas** bajo
   `50_documentacion/andamios/` (el encargo, el script y este log).
2. Autoauditoría del propio script en la corrida: **0** llamadas capaces de
   escribir en disco, contadas sobre 14 patrones (`saveRDS`, `writeLines`,
   `write.*`, `file.create`, `file.remove`, `unlink`, `fs::file_*`,
   `fs::dir_create`, `escribir_atomico`, `sink`, …) sobre 600 de 649 líneas —
   el bloque auditor se excluye a sí mismo para no contarse.
3. `mtime` de los 6 intermedios y de la captura cruda, impreso al final de la
   corrida: todos **2026-08-08 14:49**, que es cuando los escribió el pipeline,
   horas antes de esta medición. Ninguno fue tocado.

Las menciones a las funciones protegidas quedan declaradas en la misma
autoauditoría: `sellar` 2 (ambas `deparse()`, es decir lectura del cuerpo),
`leer_sellado` 0, `validar_corte` 6 (la llamada de M6 y sus etiquetas). Ninguna
las modifica, y C9 lo confirma por diff.

**C8, con su límite.** El contador se instala en las líneas 37-42 del script,
pero `instalar_si_falta()` corre en la línea 28, **antes**, y su
`utils::install.packages()` no pasa por `httr` ni por `curl::curl_fetch_memory`
(hallazgo 1 del agente 2 del panel). Por eso la corrida reporta también que los
**7 de 7** paquetes requeridos ya estaban instalados al inicio: sin paquetes
faltantes, esa vía no se activa y el cero es interpretable. Declarado, no
tapado.

Los nueve podían fallar, y dos casi lo hacen: C2 habría fallado si un campo
quedaba sin medir (se evaluaron los 20, no los que "parecían" fecha); C3 si
`asistencia_ambitos` se reportaba como "0"; C5 si el filtro vaciaba algún
boletín; C8 y C7 se degradaron de "CUMPLE" a "CUMPLE con limitación declarada"
por los hallazgos del panel. Ninguno se aprobó por ausencia de hallazgos.

**Límite conocido de C2 y C3.** La detección de "campo de fecha" exige prefijo
ISO `AAAA-MM-DD`. Un campo temporal en otro formato (`DD-MM-AAAA`, epoch
numérico) caería en "no es fecha" sin ruido, indistinguible de un campo
categórico, y ambos criterios seguirían marcando CUMPLE (hallazgos 2 y 3 del
agente 2). Hoy no ocurre —los 20 campos del nodo y los 40 de los otros
intermedios están listados con su `class()` en la corrida, y los 5 clasificados
como fecha traen prefijo ISO en el 100 % de sus valores no-NA—, pero la garantía
es de esta corrida, no del método.

---

## §4. Panel adversarial

Los cuatro agentes corrieron sobre la **primera versión** de este log, no sobre
una versión ya limpia. Encontraron 15 hallazgos entre los tres auditores; 11 se
aceptaron y produjeron cambios en el log o en el script, 4 se rebatieron. Lo que
sigue es el resultado, no una autoafirmación.

**1. El que duda del denominador — 6 hallazgos, 6 aceptados.**
- *Aceptado y corregido:* el log decía "133 mil valores de fecha" para
  `votos.rds`. La cifra real, en la corrida, es **122.605**. Era el número que
  sostenía el contraste "en contra" del veredicto de M3, y estaba mal.
- *Aceptado y corregido:* el log citaba `10_utils.R` "líneas 449-455 y 469-488"
  como sede de las 34 apariciones; los hits reales de la corrida están en
  **451-455 y 472-488**. Las líneas 449, 450 y 469-471 corresponden a los tres
  campos *ambiguos*, que Probe 2 no busca.
- *Aceptado y corregido (4 hallazgos de la misma familia):* el encabezado
  afirmaba que toda cifra venía del stdout de la corrida, pero C7, C9, el
  desglose de los tres `stop()` de `validar_corte()` y las citas de
  `10_diff_conteos.R:39` y `39:292-326` vienen de comandos `git` o de lecturas
  de archivo. El auditor verificó que **el contenido de las cuatro es correcto**;
  lo que estaba mal era la certificación de procedencia. El encabezado ahora
  distingue tres fuentes y cada afirmación dice cuál usa.

**2. El que busca el falso verde — 6 hallazgos, 5 aceptados, 1 rebatido.**
- *Aceptado, C8:* `instalar_si_falta()` corre antes del `trace()` y su
  `install.packages()` no pasa por `httr` ni `curl`. El script ahora reporta
  cuántos paquetes faltaban al inicio (0 de 7) y C8 quedó como "CUMPLE con
  limitación declarada".
- *Aceptado, C2 y C3:* la heurística de prefijo ISO no detectaría un campo de
  fecha en otro formato, y ambos criterios seguirían en verde. Registrado como
  límite del método en §3.
- *Aceptado, C6:* el barrido de `.R` nombraba archivos a mano y dejaba fuera
  `00_escanear_proyecto.R`. El script ahora usa `list.files()` sobre la raíz;
  el archivo entró al barrido (11 en vez de 10) y ninguna cifra cambió.
- *Aceptado, C7:* `git status --porcelain` es ciego a los intermedios
  gitignorados. C7 ahora se sostiene en tres evidencias, no en git solo:
  autoauditoría de escritura del script (0 sobre 14 patrones) y `mtime` intacto
  de los 7 artefactos.
- *Rebatido, C9:* el auditor planteó que un `git diff` desde el directorio
  equivocado daría stdout vacío igual que "sin diferencias". El comando se
  ejecutó con `-C <ruta absoluta>` como exige el invariante 7 y devolvió
  **exit 0**; un repositorio inexistente habría dado exit 128. El log ahora cita
  el comando completo y su código de salida.

**3. El que defiende la vía contraria.** Argumentó a favor de (B) —el corte como
propiedad del contenido validado por el sello— con cuatro razones que quedan en
pie: (a) filtrar al derivar deja el exceso en la captura cruda, así que oculta
aguas abajo un problema que sigue en disco; (b) el borde inferior de M1 (176 de
723) muestra que el nodo desobedece **dos** límites y un filtro superior no toca
el inferior; (c) filtrar en el 36 es un descarte silencioso, justo lo que el
invariante 6 del encargo prohíbe, mientras que una compuerta puede fallar
ruidosamente; (d) M5 mide cero consumidores, o sea que **no hay urgencia**, y la
urgencia falsa es lo que empuja a la vía barata.

Argumentó en contra de su propia posición con tres costos concretos: (i) no
existe un mapeo intermedio → campo temporal, y M2 muestra que no puede ser
genérico (`diputados$fecha_nacimiento`, 1947-1999, es fecha y no tiene relación
con el corte); (ii) el campo problemático vive **dentro de una list-col**, no
como columna plana, y `validar_corte()` hoy recibe solo `sellos` —nunca los
objetos— con un único call site en `39_consolidar_json.R:65`, así que (B) exige
ensanchar su firma; (iii) (B) concentra riesgo en el único gate que comparten los
6 intermedios, mientras que un filtro mal calibrado queda contenido en un script.

*Su objeción (c) contra el filtro descansaba en que el nodo usa "endpoint por
entidad" y `votos` no. El agente 4 refutó esa premisa (ver M3); la razón (c)
sobrevive igual, porque no depende de ella.* **La decisión queda abierta.**

**4. El que revisa el §0 — 3 hallazgos, 3 aceptados.**
- *Aceptado, el más grave:* el log afirmaba que "la API lo entregó dentro de la
  respuesta que se capturó ese día". Es imposible —una captura del 2026-08-03 no
  puede traer un evento del 2026-08-04— y el auditor lo probó con `git log` sobre
  la captura: se bajó el **2026-08-08**. M6 corregido, y el hallazgo pasó a ser
  la explicación central de M3.
- *Aceptado:* la causa estructural que el log daba para la asimetría de M3
  (endpoint por año vs. por entidad) está contradicha por
  `34_extraer_votaciones.R:51`, que llama `retornarVotacionDetalle` por
  `votacion_id`. La explicación se retiró y se reemplazó por la fecha de captura,
  que sí está medida.
- *Aceptado:* C7 y C9 sin comando citado (misma familia que el hallazgo 3 del
  agente 1). Corregido.

Sobre el §0 propiamente tal: las hipótesis heredadas quedaron medidas y no
citadas — 14 campos → medidos **20**; 20 columnas y una fila por boletín →
barrido de los 381 elementos; 381 boletines y 723 nodos → contados con
denominador propio; 6 intermedios sellados → 6 de 6 por barrido de directorio;
"existe al menos un evento posterior al corte" → cuantificado en 1 de 723.
**Discrepancia registrada:** el traspaso v17 hablaba de **14 campos** y la
medición encuentra **20**; el log usa 20, que es lo contado sobre el artefacto.

---

## §5. Qué queda habilitado y qué queda indeterminado

La decisión del acto (b) queda habilitada: un solo campo de fecha (`fecha`,
formato estable), un solo intermedio afectado (1 de 6), un costo de filtrado
medido (1 de 723 eventos, 0 boletines vaciados) y cero consumidores aguas abajo,
así que cualquiera de las dos vías se puede tomar hoy sin alterar el dato
publicado.

Queda indeterminado el **origen real del exceso frente a las dos vías del
encargo**: se midió que la captura del 36 se bajó cinco días después del corte
que su clave declara, y ni filtrar al derivar ni validar contenido impide que
vuelva a ocurrir en otro paso.

Queda indeterminado el borde **inferior**: 176 de 723 eventos anteriores a
`ANIO_PROCESO 2026`, 176 veces el exceso superior, que ninguna de las dos vías
aborda.

Queda indeterminado si el contrato se expresa por intermedio o por campo: M2
muestra que no todo campo de fecha es comparable con el corte
(`diputados$fecha_nacimiento`), así que (B) exige antes un mapeo explícito
intermedio → campo temporal, con exclusiones declaradas, que hoy no existe.

*Opinión, marcada como tal y sin más desarrollo:* que la captura se haya bajado
fuera de su corte sugiere que la pregunta del acto (b) es más amplia que las dos
vías que el encargo plantea.
