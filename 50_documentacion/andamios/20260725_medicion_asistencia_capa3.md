# Medición de solo lectura — Capa 3 (asistencia simétrica)

- **Fecha de la medición:** 2026-07-25
- **Corte de referencia:** `CORTE_FECHA = 2026-07-20` (10_configuracion.R:41)
- **Rama:** `feat/capa3-medicion` (medición; no toca pipeline ni datos publicados)
- **Alcance:** solo lectura. No se modificó ningún script del pipeline, no se
  generó JSON, no se tocó `main` ni `docs/data/`.
- **Muestras crudas de respaldo:** `50_documentacion/andamios/muestras/`
- **Reproducibilidad:** todas las cifras de peso y volumen de este informe se
  recontaron programáticamente en R el 2026-07-25 sobre las muestras
  versionadas y sobre `docs/data/` real; ninguna se derivó de memoria ni a mano.

---

## PASO 0 — Estado real del código

### Qué sobrevive hoy al `33_extraer_asistencia.R`

La extracción cruda arma una tabla long con **exactamente tres columnas**
(`33_extraer_asistencia.R:51-57`):

| Columna | Origen en el XML | Línea |
|---|---|---|
| `sesion_id` | el `Id` de la lista de sesiones (no se re-lee del detalle) | 52 |
| `diputado_id` | `Asistencia/Diputado/Id`, pasado por `como_llave()` | 53-54 |
| `tipo_valor` | atributo `Valor` de `Asistencia/TipoAsistencia` | 55-56 |

Esa tabla long **no se persiste como intermedio**: existe solo dentro del caché
crudo (`20_insumos/camara/<corte>_asistencia_long_2026_tope-inf.rds`,
línea 25-26, 61). Lo que se persiste en `40_salidas/intermedios/asistencia.rds`
es el **agregado por diputado** (líneas 76-87, 103-107): `diputado_id`,
`n_sesiones`, `n_asiste`, `n_no_asiste`, `tasa_asistencia`. La granularidad
sesión × diputado se pierde en el `summarise(.by = diputado_id)` de la línea 82.

### Qué se descarta en el 33 (campos que la fuente sí entrega)

- **`Justificacion`** completa (código `Valor`, glosa `Nombre`,
  `RebajaAsistencia`, `RebajaQuorum`): nunca se lee. No aparece en ningún
  xpath del script. **Este es el hallazgo central de la medición** (ver PASO 1).
- **Glosa de `TipoAsistencia`** (el texto "Asiste"/"No Asiste"): se lee solo el
  atributo `Valor` (línea 56) y se retraduce con `DOMINIO_ASISTENCIA`
  (10_configuracion.R:68-71, aplicado en la línea 77).
- **Fecha de la sesión, número, tipo (Ordinaria/Especial/Congreso Pleno) y
  estado:** están en la respuesta de `retornarSesionesXAnno` que el script ya
  descarga (líneas 27-34), pero solo se usan `Id` y `Estado` para filtrar
  celebradas; nada de eso viaja a las filas (líneas 30-34).
- **Nombre y apellidos del diputado** dentro de `Asistencia/Diputado`: no se
  leen (redundantes con el roster del 32; descarte razonable).
- **Serie nominal completa:** aunque se conserva en el caché crudo, no llega a
  `asistencia.rds` ni al JSON.

### Qué publica el 39

`39_consolidar_json.R:174-185` arma el bloque `asistencia` del perfil con
`anio`, `n_sesiones`, `n_asiste`, `n_no_asiste`, `tasa_asistencia` — cinco
escalares. El índice publica solo `tasa_asistencia`
(`39_consolidar_json.R:109-110, 137`). No hay ningún array de sesiones.

### El modelo de simetría (34)

`34_extraer_votaciones.R:57-68` persiste **una fila por (diputado × votación)**
con `votacion_id`, `boletin`, `descripcion`, `fecha`, `resultado`, `tipo`,
`diputado_id`, `opcion_valor` → `sentido` (línea 86). El 39 lo publica nominal:
`bloque_votaciones$votos` es la lista completa de votos con
`votacion_id, boletin, tipo, fecha, resultado, sentido, descripcion, proyecto`
(`39_consolidar_json.R:190-222`). Ese es exactamente el contrato que asistencia
no tiene.

---

## PASO 1 — Qué entrega realmente la fuente

### Llamadas a la API declaradas

El caché del corte (`20260720_asistencia_long_2026_tope-inf.rds`) **no alcanza**:
guarda solo las tres columnas que el 33 decidió conservar, así que no permite
medir `Justificacion` ni la fecha de sesión. Fue necesario re-medir contra la
API. Llamadas hechas el 2026-07-25:

| Endpoint | Nº llamadas | Para qué |
|---|---|---|
| `GET WSSala.asmx` (página de operaciones) | 1 | enumerar operaciones publicadas |
| `GET WSSala.asmx?WSDL` | 1 | contrato declarado de los tipos |
| `WSSala.asmx/retornarSesionesXAnno` (`prmAnno=2026`) | 1 | universo de sesiones |
| `WSSala.asmx/retornarSesionAsistencia` | 66 | barrido completo al corte |
| `WSSala.asmx/retornarSesionAsistencia` (sesiones 4736, 4740, 4805) | 3+3 | muestras crudas (2 pasadas: exploratoria y re-guardado en bytes) |
| `GET WSComunes.asmx` | 1 | buscar catálogo oficial de justificaciones |
| **Total** | **76** | pausa de 0,15–0,3 s entre llamadas |

`WSSala.asmx` publica exactamente **tres** operaciones:
`retornarSesionesXAnno`, `retornarSesionesXLegislatura`, `retornarSesionAsistencia`.

### Campos por sesión (`retornarSesionesXAnno`, raíz `SesionSala`)

`Id`, `Numero`, `FechaInicio`, `FechaTermino`, `Tipo` (+ atributo `Valor`),
`Estado` (+ atributo `Valor`). No hay más nodos hoja. La respuesta de
`retornarSesionAsistencia` repite esos mismos seis campos a nivel de raíz, así
que **la fecha de la sesión viene gratis en el mismo response del detalle**: no
requiere una llamada extra ni un join contra la lista de sesiones.

### Campos por diputado (`//Asistencia`)

Unión observada sobre el barrido completo (66 sesiones, 10 225 items):

```
Asistencia/TipoAsistencia            (+ @Valor)   -> "Asiste" / "No Asiste"
Asistencia/Justificacion             (+ @Valor)   -> nodo OPCIONAL
Asistencia/Justificacion/Nombre                   -> glosa legible
Asistencia/Justificacion/RebajaAsistencia         -> boolean
Asistencia/Justificacion/RebajaQuorum             -> boolean
Asistencia/Diputado/Id
Asistencia/Diputado/Nombre
Asistencia/Diputado/ApellidoPaterno
Asistencia/Diputado/ApellidoMaterno
```

El WSDL declara además `Asistencia/TipoTitularAsistencia` (`minOccurs=0`).
**No aparece poblado en ninguno de los 10 225 items medidos.** Hueco declarado,
no resuelto: ver pregunta abierta P5.

Ejemplo crudo (sesión 4805, muestra versionada):

```xml
<Asistencia>
  <TipoAsistencia Valor="0">No Asiste</TipoAsistencia>
  <Justificacion Valor="25">
    <Nombre>Permiso especial Comités Parlamentarios</Nombre>
    <RebajaAsistencia>true</RebajaAsistencia>
    <RebajaQuorum>false</RebajaQuorum>
  </Justificacion>
  <Diputado><Id>986</Id>...</Diputado>
</Asistencia>
```

### Catálogo de justificaciones

La justificación viene como **código entero (`@Valor`) acompañado de su glosa
(`Nombre`) en el mismo nodo**: no hace falta un catálogo externo para mostrarla.

**No existe catálogo publicado.** Ni `WSSala.asmx` (3 operaciones, ninguna de
catálogos) ni el WSDL (0 `simpleType` con enumeración; `JustificacionInasistencia`
declara `Valor` como `s:int` sin restricción) ni `WSComunes.asmx` exponen la
lista de valores posibles. Lo que sigue es el **catálogo observado** en el
barrido de 66 sesiones, no un catálogo oficial:

| Valor | Glosa (texto de la fuente) | RebajaAsistencia | RebajaQuorum | n con No Asiste | n con Asiste |
|---|---|---|---|---|---|
| 12 | Misión oficial con aviso de salida del país (Art. 37) | true | false | 37 | 0 |
| 13 | Actividad propia de la labor parlamentaria (Art. 42) | false | false | 12 | 1 |
| 14 | Actividad oficial con el Presidente de la República (Art. 9) | false | false | 5 | 0 |
| 15 | Salida del país con aviso (Art. 34) | false | false | 9 | 0 |
| 16 | Desafuero (Art. 40) | false | true | 72 | 0 |
| 17 | Gestión encomendada por la Corporación (Art. 42) | true | false | 7 | 1 |
| 18 | Impedimento grave (Art. 42) | true | false | 111 | 1 |
| 19 | Licencia médica (Art. 42) | true | false | 203 | 10 |
| 21 | Permiso por motivos particulares sin goce de Dieta (Art. 42) | false | false | 68 | 1 |
| 23 | Acuerdo de Comités Parlamentarios | false | false | 15 | 0 |
| 25 | Permiso especial Comités Parlamentarios | true | false | 49 | 0 |
| 28 | Permiso postnatal parental (art. 197 bis Cód. del Trabajo) | true | false | 6 | 0 |
| 29 | Permiso Parental (Art. 195 Cód. del Trabajo) | true | false | 4 | 0 |
| *(sin nodo `Justificacion`)* | — | — | — | 70 | 9543 |

Observaciones que la medición sostiene y que el catálogo observado **no** cierra:

- Los códigos observados son 12–29 **con huecos** (faltan 20, 22, 24, 26, 27, y
  todo lo anterior a 12). El dominio real es más ancho que lo observado en 2026:
  no se puede declarar un `DOMINIO_JUSTIFICACION` cerrado (ver P1).
- `RebajaAsistencia`/`RebajaQuorum` son **constantes por código** en lo
  observado (una sola combinación por `Valor`), lo que sugiere que son atributo
  del código y no del caso. No verificable con una sola temporada (P2).
- **14 items con `TipoAsistencia = Asiste` traen `Justificacion`.** El campo no
  es exclusivo de la inasistencia. Qué significa una justificación sobre una
  asistencia registrada: ninguna fuente lo explica (P3).
- **70 inasistencias (10,5 % de 668) no traen nodo `Justificacion`.** El
  ausente-sin-justificar es un caso real y distinguible.

---

## PASO 2 — Volumen al corte 2026-07-20

- Sesiones publicadas para 2026: **73**; celebradas: **69**; celebradas con
  `FechaInicio <= 2026-07-20`: **66**.
- Filas long medidas: **10 225** (155 × 66 = 10 230 si la matriz fuera densa).
- Ids distintos en asistencia: **239** = 155 del roster vigente + **84 del
  período anterior**, que aparecen solo en las 18 sesiones del 2026-01-05 al
  2026-03-05.
- Filas de los ids del roster vigente: **8 713**. Por diputado: mín **47**,
  mediana **48**, máx **66**. Solo **70 de 155** aparecen en las 66 sesiones
  (los reelectos); los otros 85 entran en marzo con el período nuevo.
- Inasistencias: **668** (6,5 % de las filas); 598 con justificación, 70 sin
  justificación; 14 asistencias con justificación.

**Consecuencia de diseño:** la matriz **no es densa**. Una serie nominal por
diputado tiene ~48 entradas para un diputado nuevo y 66 para un reelecto, y el
denominador de la tasa no es comparable entre ambos salvo que se acote el
universo de sesiones al período vigente. Esto ya afecta al `n_sesiones` que hoy
se publica (ver PASO 3, nota).

### Peso (recontado programáticamente el 2026-07-25)

Estado actual medido sobre `docs/data/` real:

- `docs/data`: índice **50,8 KB** + 155 perfiles **39 973,8 KB** = **40 024,6 KB**
  (≈ 39,1 MB).
- Perfil de referencia `docs/data/perfiles/1017.json`: **337,3 KB**
  (742 votos nominales, 3 proyectos).

Simulación de embeber la serie nominal en el perfil, con el mismo escritor JSON
del 39 (`toJSON(auto_unbox, pretty, na="null", digits=NA)`):

| Variante | Perfil 1017 | Delta | Delta % |
|---|---|---|---|
| Hoy (sin serie) | 337,3 KB | — | — |
| **A** — serie mínima (`sesion_id`, `fecha`, `tipo_sesion`, `asistencia`) | 346,6 KB | +9,3 KB | +2,8 % |
| **B** — serie + justificación (código, glosa, dos rebajas) | 348,7 KB | +11,5 KB | +3,4 % |

Peso del bloque de serie por diputado, medido para los 155 (no extrapolado):

- Variante B: mín **7,4 KB**, mediana **8,2 KB**, máx **19,5 KB**, suma **1 440,9 KB**.
- Variante A: mediana **6,2 KB**, suma **1 128,4 KB**.

Totales de `docs/data/`:

| Escenario | Total | Delta |
|---|---|---|
| Hoy | 40 024,6 KB | — |
| + serie A embebida | 41 153,0 KB | **+2,8 %** |
| + serie B embebida | 41 465,5 KB | **+3,6 %** |

Alternativas de empaquetado, también recontadas:

- Catálogo compartido de sesiones (66 sesiones, un archivo): **7,2 KB**.
- Matriz long completa de los 155, solo códigos sin glosas, un archivo:
  **910,1 KB**.
- Serie B en archivo aparte por diputado (`perfiles/asistencia/<id>.json`):
  mediana **8,2 KB**, suma **1 440,9 KB** (mismo total que embeber, pero no
  carga en la petición del perfil).

**Lectura:** el costo en peso **no es el factor limitante**. El perfil ya pesa
337 KB por la serie nominal de votos; la serie de asistencia agrega 3,4 % en el
peor caso. Cualquier argumento contra la simetría tendrá que ser de otro tipo
(coste de extracción, semántica de la tasa), no de peso.

---

## PASO 3 — La asimetría actual, campo por campo

| Dimensión | Votaciones (34 → 39) | Asistencia (33 → 39) |
|---|---|---|
| Unidad persistida en el intermedio | fila por (diputado × votación) — `34:57-68` | fila por diputado (agregado) — `33:76-87` |
| Serie nominal en el JSON | sí: `votaciones.votos[]` — `39:190-222` | **no**: 5 escalares — `39:174-185` |
| Id del evento | `votacion_id` | descartado (existe en el caché crudo, no en el intermedio) |
| Fecha del evento | `fecha` — `34:61` | **descartada**, pese a venir en el mismo response |
| Tipo del evento | `tipo` de votación — `34:63` | descartado (`Ordinaria`/`Especial`/`Congreso Pleno`) |
| Resultado del evento | `resultado` — `34:62` | n/a (una sesión no tiene "resultado") |
| Posición del diputado | `sentido` (5 valores del `DOMINIO_VOTO`) | `tipo_valor` → 2 valores, solo agregado |
| Matiz sobre la posición | — | **`Justificacion` (13 códigos + glosa + 2 rebajas): existe en la fuente y se descarta entero** |
| Contexto legible | `descripcion` + `proyecto` anidado — `39:197-213` | ninguno |
| Resumen agregado | `resumen_por_sentido` — `39:189` | `n_sesiones`, `n_asiste`, `n_no_asiste`, `tasa_asistencia` |
| Métrica en el índice | `n_votaciones` | `tasa_asistencia` |
| Validación de dominio | `DOMINIO_VOTO`, aviso si hay valor fuera — `34:79-83` | `DOMINIO_ASISTENCIA`, aviso — `33:69-73`. **No hay dominio para justificación** |
| Trazabilidad al objeto votado | sí (boletín → proyecto) | n/a |

**Nota que la medición obliga a registrar:** el `n_sesiones` publicado hoy no es
un denominador común. Se construye como `n()` de las filas del propio diputado
(`33:79`), sobre **todas** las sesiones celebradas que la lista devolvía al
momento de descargar, sin filtro de período ni de `CORTE_FECHA`. Al corte medido
eso significa denominadores de 47–66 según el diputado, y para los 71 reelectos
incluye 18 sesiones del período 2022-2026. La tasa por diputado sigue siendo
interna a su propio denominador (no está "mal calculada"), pero **no es
comparable entre diputados** y el `n_sesiones` publicado no significa lo mismo
en dos perfiles distintos.

**Nota secundaria sobre el caché:** el caché del corte tiene 65 sesiones y la
medición encuentra 66 celebradas con `FechaInicio <= 2026-07-20`. La diferencia
es la sesión **4801 (nº 45, 2026-07-20 17:00)**, que al momento de la descarga
del corte no estaba marcada `Celebrada` y hoy sí. El filtro del `33:33-34`
evalúa `Estado` en el instante de la descarga, de modo que el contenido del
caché **no es función únicamente de `CORTE_FECHA`**: una sesión del día del
corte puede entrar o no según la hora de la corrida. No es un error de esta
medición ni contradice un supuesto del corte; es una arista del refresh que
queda anotada aquí porque cualquier diseño de Capa 3 que fije el universo de
sesiones tendrá que decidirlo explícitamente (P6).

---

## PASO 4 — Invariantes verificados (no modificados)

Verificado en sesión R limpia, contra el estado actual del repo:

| Invariante | Verificación | Resultado |
|---|---|---|
| Sello de procedencia | `leer_sellado()` sobre los 5 intermedios (`diputados`, `asistencia`, `votos`, `proyectos`, `proyectos_detalle`) | los 5 traen sello |
| `validar_corte()` del 39 | `validar_corte(sellos, CORTE_FECHA)` con `CORTE_FECHA = 2026-07-20` | **OK** |
| `CORTE_FECHA` sin default silencioso | `corte_para_clave()` con `CORTE_FECHA = ""` | `stop()`: *"CORTE_FECHA no esta fijada…"* |
| `CORTE_FECHA` vigente | `corte_para_clave()` | `20260720` |
| Territorio en el índice | `docs/data/indice_diputados.json` | 155 filas, **155 distrito**, **155 región**, 28 distritos |
| Territorio en perfiles | 155 archivos de `docs/data/perfiles/` | **155/155** con `distrito` y `region` no nulos |

Ninguno de estos se ve afectado por lo medido: la Capa 3 toca el 33 (y, si se
publica serie, el 39), no el sello, no el corte, no el join de territorio.

---

## PASO 5 — Veredicto

### Qué entrega la fuente vs. qué asume el pendiente D2

D2 (backlog acumulativo, entrada 23) fija un *"contrato de asistencia simétrico
(nominal por sesión en ambas cámaras)"*, con el costo reconocido de tener que
**extender el extractor de la Cámara**.

Contrastado con la medición:

| Supuesto de D2 | Lo que la medición muestra |
|---|---|
| Hay que extender el extractor de la Cámara | **Confirmado, y es más barato de lo supuesto.** El 33 ya descarga el response completo por sesión y ya recorre `//Asistencia` (`33:46-59`); la serie nominal ya está en el caché crudo. Falta persistirla y agregar 4 campos al parseo. Cero llamadas nuevas a la API. |
| Asistencia nominal por sesión | **Disponible.** `sesion_id` + `fecha` + `tipo` de sesión + `TipoAsistencia` por diputado, todo en el mismo response. |
| (D2 no se pronuncia sobre justificación) | **La fuente entrega mucho más de lo que D2 asume:** código + glosa + `RebajaAsistencia` + `RebajaQuorum`. 598 de 668 inasistencias vienen justificadas. Un contrato "simétrico" que solo copie el patrón de votaciones (evento + posición) dejaría fuera el campo con más contenido informativo del endpoint. |
| Simetría con el Senado | **Fuera del alcance de esta medición.** No se midió el backend del Senado; no se puede afirmar que el Senado exponga justificación equivalente ni que los códigos sean conmensurables (P4). |

**Veredicto:** la fuente entrega estrictamente más de lo que D2 asume, y la
extensión del extractor es de bajo costo (no hay llamadas adicionales). El
factor limitante **no es el peso** (+3,4 % en el peor caso), sino dos decisiones
metodológicas que ninguna fuente resuelve: qué universo de sesiones define el
denominador, y qué hacer con las justificaciones al calcular una tasa.

### Costo en peso (recontado el 2026-07-25)

- Perfil `1017.json`: 337,3 KB hoy → **348,7 KB** con serie nominal +
  justificación (**+11,5 KB, +3,4 %**).
- `docs/data/` completo: 40 024,6 KB hoy → **41 465,5 KB** (**+3,6 %**, es decir
  +1 440,9 KB para los 155 perfiles).
- Sin justificación (solo serie): +1 128,4 KB (**+2,8 %**).

### Opciones de diseño que la medición deja abiertas

| # | Opción | Qué implica | Costo medido |
|---|---|---|---|
| 1 | **Solo extractor**: persistir `asistencia_long.rds` nominal (sesión, fecha, tipo de sesión, tipo de asistencia, código y glosa de justificación, dos rebajas) y **no** cambiar el JSON | simetría de *datos*, no de *contrato publicado*. Habilita métricas nuevas sin tocar el cliente | 0 KB en `docs/data/`; un intermedio nuevo; el 39 no se toca |
| 2 | **Serie embebida en el perfil** (`asistencia.sesiones[]`), espejo exacto de `votaciones.votos[]` | simetría plena de contrato; una sola petición por perfil, patrón ya probado con los 742 votos | **+11,5 KB por perfil (+3,4 %); +1 440,9 KB total (+3,6 %)** |
| 3 | **Serie en archivo aparte** (`docs/data/perfiles/asistencia/<id>.json`) + resumen en el perfil | el perfil no crece; carga diferida al abrir la pestaña de asistencia | mediana 8,2 KB por archivo, 1 440,9 KB total; 155 archivos nuevos y una petición extra en el cliente |
| 4 | **Catálogo compartido + serie compacta**: un `sesiones.json` (id, fecha, tipo) y en el perfil solo `[sesion_id, codigo_asistencia, codigo_justificacion]` | evita repetir fecha/tipo/glosa 155 veces; el cliente resuelve por lookup | catálogo 7,2 KB + matriz completa 910,1 KB (**+2,3 %**), el más barato de los que publican serie; costo: el cliente debe resolver dos fuentes, y las glosas necesitan un mapa que hoy **no tiene catálogo oficial** (P1) |
| 5 | **Métricas derivadas sin serie**: publicar `n_justificadas`, `n_injustificadas`, desglose por código, y una segunda tasa que descuente justificaciones | responde la pregunta cívica ("¿faltó o estaba en misión oficial?") sin publicar 66 filas por diputado | ~+0,3 KB por perfil; costo real: exige fijar la decisión metodológica de P7, que es del titular |

Las opciones 1 y 5 son acumulables con cualquiera de 2/3/4.

### Preguntas abiertas que ninguna fuente resuelve

- **P1 — Dominio de `Justificacion`.** No hay catálogo publicado (ni en las 3
  operaciones de `WSSala.asmx`, ni en el WSDL, ni en `WSComunes.asmx`). Se
  observaron 13 códigos (12–29, con huecos). *No se puede declarar un
  `DOMINIO_JUSTIFICACION` cerrado como se hizo con `DOMINIO_VOTO`.* Queda
  abierto si el diseño debe (a) confiar en la glosa que viene en el nodo y no
  declarar dominio, o (b) declarar el dominio observado y alertar ante códigos
  nuevos, como hace el 33 hoy con `TipoAsistencia`.
- **P2 — Semántica de `RebajaAsistencia` / `RebajaQuorum`.** La fuente entrega
  los booleanos sin documentarlos. En lo observado son constantes por código,
  pero **no está establecido** si `RebajaAsistencia=true` significa "descuenta
  del numerador", "descuenta del denominador" u otra cosa reglamentaria. Sin
  eso, no se puede calcular una "tasa oficial" que replique la de la Cámara.
- **P3 — `Justificacion` sobre `Asiste`.** 14 items registran asistencia *y*
  justificación. Ninguna fuente explica qué significa.
- **P4 — Simetría con el Senado.** No medido en este encargo. Se desconoce si el
  Senado expone justificación, con qué códigos y si son conmensurables con los
  de la Cámara. D2 asume simetría en la unidad (nominal por sesión), no en este
  campo.
- **P5 — `TipoTitularAsistencia`.** Declarado en el WSDL, vacío en los 10 225
  items medidos. Se desconoce cuándo se puebla y qué codifica (¿titular vs.
  reemplazante?).
- **P6 — Universo de sesiones del denominador.** Ninguna fuente lo decide. Al
  corte hay 66 sesiones celebradas, de las cuales 18 pertenecen al período
  2022-2026. Hoy el denominador es implícito y desigual (47–66 según diputado).
  Filtrar por fecha de inicio del período vigente es una **decisión
  metodológica del titular**, no un dato de la fuente. Ligado a esto: el filtro
  por `Estado` del `33:33-34` se evalúa al descargar, así que el universo no es
  función pura de `CORTE_FECHA` (sesión 4801).
- **P7 — Qué es "asistencia" para el portal.** Con justificación disponible,
  hay al menos tres tasas defendibles: presencia bruta (la actual), presencia
  descontando justificadas del denominador, y presencia descontando solo las
  que traen `RebajaAsistencia=true`. Cuál se publica —y si se publica más de
  una— es decisión metodológica del titular, igual que la taxonomía de
  tendencia. Esta medición no la toma.

---

## Muestras crudas versionadas (`50_documentacion/andamios/muestras/`)

| Archivo | Qué respalda |
|---|---|
| `sesion_asistencia_4736.xml`, `_4740.xml`, `_4805.xml` | responses crudos (bytes de la API) de tres sesiones; 4805 contiene 14 items con `Justificacion` |
| `sesiones_x_anno_2026.xml` | universo de sesiones 2026 |
| `medicion_sesiones_2026.rds` | 73 sesiones parseadas (id, número, fechas, tipo, estado) |
| `medicion_asistencia_long_20260720.rds` | **barrido completo**: 10 225 filas × 11 columnas, las 66 sesiones al corte, con justificación y rebajas |
| `wssala.wsdl` | contrato declarado (`JustificacionInasistencia`, `TipoTitularAsistencia`, ausencia de enumeraciones) |
| `wssala_operaciones.html`, `wscomunes_operaciones.html` | evidencia de que no hay operación de catálogo |
| `tabla_catalogo_justificacion.md` | catálogo observado, generado en R (UTF-8) |
| `p1_log.txt`, `p1c_log.txt`, `p2_log.txt`, `p3_p4_log.txt`, `p5_log.txt` | logs de cada paso de la medición |
| `simulacion_perfil_1017_con_serie.json` | perfil 1017 simulado con serie nominal + justificación (variante B, 348,7 KB) |
