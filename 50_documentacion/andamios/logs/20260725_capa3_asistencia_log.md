# Log de sesión — Capa 3: asistencia simétrica

- **Fecha:** 2026-07-25
- **Rama:** `feat/capa3-asistencia` (renombrada desde `feat/capa3-medicion`); sin merge, sin push. Gate del titular.
- **Corte:** `CORTE_FECHA = 2026-07-20`, sin cambios.
- **Encargo:** implementar la Capa 3 sobre el veredicto de
  `50_documentacion/andamios/20260725_medicion_asistencia_capa3.md`.
- **Fuera de alcance:** `docs/index.html` (sesión de frontend aparte). No se tocó.

---

## 1. Resumen

El extractor de asistencia conservaba tres columnas y agregaba por diputado,
descartando el nodo `Justificacion` que la fuente sí entrega. Ahora persiste la
serie nominal (una fila por diputado × sesión, con fecha, tipo de sesión,
código y glosa de justificación y las dos rebajas) y dos agregados por ámbito
temporal, y el 39 los publica dentro del bloque `asistencia` **sin tocar los
cinco campos legacy**. El índice gana `tasa_presencia`.

La asimetría que motivó la capa queda cerrada: asistencia tiene ahora el mismo
tipo de contrato que votaciones (serie nominal + resumen), y además el matiz
—justificada / injustificada— que la fuente entregaba y se perdía.

Dos decisiones que el encargo dejaba abiertas y esta sesión fijó con datos:

- La **fecha de instalación del periodo vigente** no se hardcodeó: la publica
  la API (`retornarPeriodoLegislativoActual` → periodo 11, "2026-2030",
  `FechaInicio = 2026-03-11`) y se cachea por corte.
- El **caso "sesión sin fila"** existe en la fuente (5 casos) y se modeló como
  un tercer estado `sin_registro`, en vez de imputar asistencia o inasistencia.

---

## 2. Inventario de commits

| Hash | Tipo | Qué |
|---|---|---|
| `ca406a8` | medicion | Informe de medición + muestras (sesión anterior, ya en la rama) |
| `8434c6c` | feat | 33: serie nominal + agregados por ámbito (2 intermedios nuevos) |
| `c53dfa6` | feat | 39: publica los tres bloques nuevos y `tasa_presencia` en el índice |
| `11d9b0d` | feat | Regeneración de `40_salidas/json` y `docs/data` al corte vigente |
| *(este)* | docs | Este log + caché crudo del corte + muestras del periodo legislativo |

---

## 3. Cambios sustantivos, con causa raíz

### 3.1 `33_extraer_asistencia.R` — bloque nominal (nuevo)

**Causa raíz:** el parseo leía solo `@Valor` de `TipoAsistencia`
(línea 55-56 del original). El nodo `Justificacion` —código, glosa,
`RebajaAsistencia`, `RebajaQuorum`— viaja en el **mismo response** que el
script ya descargaba y nunca se leyó. La granularidad sesión × diputado existía
en el caché crudo pero se disolvía en el `summarise(.by = diputado_id)`.

**Qué se hizo:** un segundo bloque en el mismo script, con clave de caché propia
(`asistencia_nominal_<anio>`), que parsea nueve campos y persiste
`asistencia_nominal.rds` (8 718 filas) y `asistencia_ambitos.rds` (310 filas).

**Decisión de universo:** el bloque nominal filtra `Estado == Celebrada` **y**
`FechaInicio <= CORTE_FECHA`. El legacy filtra solo por `Estado` en el instante
de la descarga, que es la arista P6 de la medición: su contenido no es función
pura del corte.

### 3.2 Por qué el legacy conserva su propia descarga (lo que costó)

La opción natural era derivar el agregado legacy del barrido nominal: una sola
descarga, un solo universo. **No se pudo**, y no por elegancia: el universo
determinista incluye la sesión **4801** (nº 45, 2026-07-20 17:00), que el
snapshot legacy del corte no alcanzó a ver marcada como celebrada. Derivar el
legacy del nominal habría sumado una sesión a los 155 diputados y cambiado
`n_sesiones` y `tasa_asistencia` publicados — exactamente lo que el invariante 1
prohíbe.

Se optó por mantener los dos caminos separados. **Costo asumido y declarado:**
mientras el portal consuma el contrato legacy, cada refresh descarga la
asistencia dos veces (una por clave de caché). Marcado `# REVISAR` en el
script. La deuda se paga sola cuando el frontend migre a los campos nuevos y el
agregado legacy pueda retirarse.

### 3.3 Fecha de instalación del periodo — camino (1) del encargo

`WSLegislativo.asmx` publica **14 operaciones**, entre ellas
`retornarPeriodoLegislativoActual`. No hubo que derivar la fecha del dato. La
respuesta (versionada en `muestras/legislativo_retornarPeriodoLegislativoActual.xml`):
periodo `Id 11`, `Nombre 2026-2030`, `FechaInicio 2026-03-11T00:00:00`.

**Evidencia convergente:** el dato coincide exactamente con el salto observado
en la cobertura del roster. Hasta el 2026-03-05 solo 71 de los 155 vigentes
tienen registro (son los reelectos); el 2026-03-11, primera sesión del periodo,
saltan a 154. La API y el dato dicen lo mismo.

### 3.4 Los dos ámbitos

| Ámbito | Universo | n_sesiones |
|---|---|---|
| `periodo_vigente` | las 48 sesiones desde 2026-03-11 hasta el corte, **iguales para todos** | 48 en los 155 |
| `en_ejercicio` | por diputado, las sesiones del alcance desde su primer registro | 48 (84 dip.) o 66 (71 dip.) |

`periodo_vigente` es el comparable entre diputados; `en_ejercicio` no lo es y
por eso no se publica solo.

**Supuesto del encargo verificado — REFUTADO EN PARTE.** El encargo suponía que
`n_sesiones` legacy ya es de facto un "en ejercicio". Leído `33:76-87`, el
agregado legacy hace `n()` sobre las filas del propio diputado: la *forma* es la
misma (denominador propio), pero el *universo* no coincide, porque el legacy
opera sobre 65 sesiones (su snapshot) y `en_ejercicio` sobre 66. Además
`en_ejercicio` cuenta las sesiones del universo aunque falte la fila, y el
legacy no puede: no sabe que la sesión existió. No son intercambiables.

### 3.5 Tercer estado `sin_registro`

**Causa raíz:** la matriz no es densa. Cinco (diputado, sesión) del periodo no
tienen fila en la fuente: `1074` en las sesiones 4755, 4756, 4757 y 4758
(11–23 de marzo) y `1193` en la 4800 (15 de julio, pese a tener fila en la 4805
del mismo día).

El encargo pedía verificar `n_asiste + n_no_asiste == n_sesiones`. Con un
denominador común eso **no se cumple** para esos 2 diputados, y forzarlo exigía
o bien imputar (fabricar dato) o bien romper el denominador común. Se añadió
`n_sin_registro` y la identidad verificada es
`n_asiste + n_no_asiste + n_sin_registro == n_sesiones`, que sí se cumple
155/155 en ambos ámbitos. La discrepancia con el encargo está reportada, no
escondida.

### 3.6 `39_consolidar_json.R`

`alcance_temporal` (con nota legible), `periodo_vigente`, `en_ejercicio` y
`sesiones[]` se **añaden** al bloque `asistencia`, después de los cinco campos
legacy. `sesiones[]` es el espejo de `votaciones.votos[]`: una entrada por
sesión del ámbito `en_ejercicio`, ordenada por fecha, con `justificacion`
anidada o `null`. El índice gana `tasa_presencia` **como último campo**, para no
alterar el orden que el cliente ya recorre.

El alcance temporal viaja como atributo del intermedio (lo fija el 33 con el
dato de la API); el 39 no lo re-deriva ni lo hardcodea, y hace `stop()`
diagnóstico si falta.

---

## 4. Bugs y tropiezos

1. **`sellar()` cambia los bytes del `.rds` aunque el dato sea idéntico.** El
   sello lleva `escrito_en` (timestamp), así que comparar `asistencia.rds` por
   md5 da falso positivo. Se comparó con `identical()` sobre el data.frame sin
   el atributo. Mismo efecto en los JSON: `metadatos.generado` cambia siempre, y
   por eso la comparación legacy se hizo bloque a bloque, no por hash de archivo.
2. **Primer `39` sin el atributo `alcance`.** El primer diseño derivaba el
   alcance en el 39 a partir de la serie, lo que habría dado la fecha de la
   primera *sesión* del periodo en vez de la fecha de *instalación*. Coinciden
   en este corte (ambas 2026-03-11) pero no tienen por qué. Se movió el dato al
   33 como atributo y hubo que re-ejecutar el 33 antes del 39.
3. **El peso real superó la estimación de la medición.** La medición proyectaba
   +3,6 % en `docs/data`; el resultado es **+5,85 %**. Causa: la simulación no
   modelaba `sesion_numero`, `tipo_sesion` ni `en_periodo_vigente` en cada
   entrada, ni el bloque `alcance_temporal` con su nota, que se repite en los
   155 perfiles. La estimación no era mala de orden de magnitud, pero no era el
   dato: el dato es el recuento posterior.
4. **Ningún bug de encoding**, pero sí una precaución que costó verificar: las
   glosas traen tildes y se marcan `Encoding() <- "UTF-8"` en el 33 (A36). Se
   comprobó con `nchar(chars)` vs `nchar(bytes)` —no con `validUTF8()`, que no
   discrimina— y con una búsqueda de mojibake en el JSON publicado.

---

## 5. Verificación de invariantes, uno por uno

| # | Invariante | Evidencia |
|---|---|---|
| 1 | Campos publicados sin cambio de nombre, fórmula ni valor | `identical()` sobre los 5 campos legacy de `asistencia` y sobre los bloques `perfil`, `votaciones` y `proyectos` completos, en **155/155** perfiles, contra la versión extraída de `git show ac177be:` — 0 diferencias. Índice: los 11 campos previos conservan orden y valor en 155/155. Único cambio no aditivo: `metadatos.generado` (timestamp). Confirmado además por agente adversarial independiente. |
| 2 | Sello y `validar_corte()` intactos | No se modificó `sellar()`, `leer_sellado()` ni `validar_corte()`. Los dos intermedios nuevos usan el mismo mecanismo. `validar_corte()` pasa sobre **7** intermedios, todos declarando `2026-07-20`. |
| 3 | `CORTE_FECHA` sin default silencioso | `10_configuracion.R:41` sin cambios; `corte_para_clave()` sin cambios. `run_all()` sigue validándolo al inicio. |
| 4 | Territorio 155/155 | Índice: 155 filas, 155 con distrito, 155 con región, 28 distritos. Perfiles: 155/155 con `distrito` y `region` no nulos. |
| 5 | Las rebajas se persisten pero no entran en ninguna fórmula | Auditoría de código: todas las apariciones son extracción, transporte o comentario; ninguna en fórmula, filtro, condición u orden. Prueba empírica: `n_justificadas` coincide 155/155 con el conteo **sin** filtrar por rebaja y **no** coincide con el filtrado; los dos conteos difieren de verdad en 24/155 (periodo vigente) y 32/155 (en ejercicio), así que la prueba discrimina. Las rebajas sí llegan al JSON: 447 entradas con justificación, 382 `true` / 65 `false`. |
| 6 | Sin `DOMINIO_JUSTIFICACION` cerrado | No se declaró ningún dominio cerrado. El 33 compara contra los 13 códigos observados y, si aparece uno nuevo, emite `warning()` con el código y su glosa y **continúa**. No hay `stop()` por este motivo. La glosa se toma del propio nodo. |
| 7 | Sin llamadas de más a la API | El bloque nominal reutiliza el response que el 33 ya descargaba. La regeneración completa (`run_all()`, pasos 32-36 y 39) corrió con **cache hit en todos los pasos: 0 llamadas**. |
| 8 | `docs/index.html` sin tocar | `git log --stat` de los tres commits de código y datos: el archivo no aparece. |

---

## 6. Cifras finales (recontadas el 2026-07-25 tras la regeneración)

- Alcance: **66 sesiones**, 2026-01-05 a 2026-07-20. Periodo vigente:
  **48 sesiones** desde 2026-03-11.
- Caché nominal: **10 225** items, 66 sesiones, 239 ids.
- Serie publicada (solo roster): **8 718** entradas — 8 236 `asiste`,
  477 `no_asiste`, 5 `sin_registro`.
- Justificaciones en la serie: **447**, con **12** códigos distintos. De ellas,
  434 acompañan una inasistencia en el ámbito `en_ejercicio`: las 13 restantes
  van sobre sesiones con **asistencia registrada** (P3 de la medición, sin
  explicación en la fuente).
- `periodo_vigente`: denominador **48** para los 155; 356 inasistencias
  (328 justificadas, 28 injustificadas); `tasa_presencia` mediana 0,9792
  (rango 0,0417–1); `tasa_presencia_o_justificada` mediana 1 (mínimo 0,8958).
- `en_ejercicio`: denominador 48 u 66; 477 inasistencias (434 / 43).
- Peso: `docs/data` **40 024,6 KB → 42 367,6 KB** (+2 343,0 KB, **+5,85 %**).
  Perfil `1017.json`: 337,3 → 354,4 KB (+17,1 KB, +5,1 %). Perfiles: mínimo
  198,6 KB, mediana 204,4 KB, máximo 365,7 KB.

---

## 7. Pendientes y `# REVISAR` abiertos

### Marcados en el código

- `33_extraer_asistencia.R`, cabecera del bloque 1: **doble descarga de
  asistencia por refresh** mientras el portal consuma el contrato legacy.
  Unificar cuando el frontend migre.
- `39_consolidar_json.R`, bloque de justificación: `rebaja_asistencia` /
  `rebaja_quorum` se publican **sin uso**, a la espera de que se establezca su
  semántica reglamentaria.

### Heredados de la medición, que esta capa NO cierra

- **P1** — la fuente no publica catálogo de justificaciones; los 13 códigos son
  observados, con huecos (falta 20, 22, 24, 26, 27 y todo lo previo a 12).
- **P2** — semántica de `RebajaAsistencia` / `RebajaQuorum` sin documentar. Es
  la razón por la que no existe una "tasa oficial" que replique la de la Cámara.
- **P3** — 13 justificaciones sobre sesiones con asistencia registrada, sin
  explicación en la fuente.
- **P4** — simetría con el Senado: no medida, fuera del alcance de esta sesión.
- **P5** — `TipoTitularAsistencia`: declarado en el WSDL, vacío en los 10 225
  items. No se extrae.
- **P7** — **cuál de las tasas es "la" tasa del portal es decisión metodológica
  del titular.** Esta capa publica las dos con denominador compartido y no
  elige. El frontend tendrá que decidir cuál muestra por defecto y cómo explica
  la diferencia.

### Nuevos de esta sesión

- **Sesión 4801 y el universo del legacy.** El agregado legacy vive sobre 65
  sesiones y el nominal sobre 66. Es visible: un perfil puede mostrar
  `n_sesiones` legacy y `en_ejercicio.n_sesiones` con un punto de diferencia.
  Se resuelve solo cuando el legacy se retire.
- **Los 5 `sin_registro`.** No se sabe si son un vacío de publicación de la
  Cámara o una situación reglamentaria (el caso de `1193`, ausente del registro
  de una sesión y presente en otra del mismo día, sugiere lo primero). No se
  imputó nada. Vale la pena vigilar si el número crece entre cortes.

---

## 8. Estado de la rama

`feat/capa3-asistencia`, cuatro commits sobre `ac177be`. Sin push, sin merge.
`docs/index.html` intacto: el portal en vivo sigue leyendo los campos legacy,
que no cambiaron, así que la rama es segura de mergear sin tocar el frontend —
los campos nuevos quedan disponibles y sin consumir hasta la sesión de interfaz.
