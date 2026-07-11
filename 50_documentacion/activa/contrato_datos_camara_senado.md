# Contrato de datos comun Camara / Senado

> Diagnostico + propuesta (insumos-first), paso previo al diseno del pipeline del
> Senado. Rama `design/contrato-datos` (desde `main`). Documenta el esquema REAL
> que hoy produce el pipeline de la Camara (leido del codigo 32-39 y de los `.rds`
> reales) y PROPONE un contrato comun para que ambas camaras normalicen a las
> mismas columnas. NO decide el crosswalk de partidos ni escribe normalizadores.
> Campos-Senado citados: de `exploracion_api_senado_v02.md` (backend) y
> `exploracion_asistencia_senado.md` (asistencia nominal), ramas explore/*. Los
> campos del detalle de proyectos del Senado (`titulo`, `iniciativa`, `estado`,
> `materias` de `wspublico/tramitacion.php`) provienen de v01
> `exploracion_api_senado.md`, que v02 cita como fuente complementaria de proyectos.

- **Fecha:** 2026-07-10

---

## FASE 1 — Esquema real del pipeline de la Camara

Fuente de cada esquema: **codigo** (scripts 32-39) confirmado contra el **`.rds`
real** en `40_salidas/intermedios/` (`readRDS` + `class`). Todas las llaves son
`character` (invariante 🔒).

### Intermedios (`40_salidas/intermedios/*.rds`)

**`diputados.rds`** — roster, 1 fila/diputado (155). Escrito por `32`.

| columna | tipo | clave | nota |
|---------|------|-------|------|
| `diputado_id` | character | **PK** | id de `WSDiputado` (espacio propio de la Camara) |
| `nombre` | character | | nombre completo concatenado |
| `sexo` | character | | dominio `Femenino`/`Masculino` |
| `fecha_nacimiento` | character | | `AAAA-MM-DD` |
| `partido_id` | character | | codigo Camara (`PREP`,`UDI`,`RN`,`IND`,...) |
| `partido_nombre` | character | | |
| `partido_alias` | character | | |
| `distrito` | character | | **siempre NA** — la API no lo expone (# REVISAR) |
| `region` | character | | **siempre NA** — idem |
| `tendencia` | character | derivada | `tendencia_de_partido(partido_id)` via `MAPA_PARTIDO_TENDENCIA` |

**`asistencia.rds`** — **AGREGADO por diputado** (239 filas; incluye ids fuera del
roster vigente). Escrito por `33`.

| columna | tipo | clave | nota |
|---------|------|-------|------|
| `diputado_id` | character | **PK** | |
| `n_sesiones` | integer | | sesiones celebradas consideradas |
| `n_asiste` | integer | | |
| `n_no_asiste` | integer | | |
| `tasa_asistencia` | numeric | | `n_asiste/n_sesiones`, decimal sin redondear |

> **Gap central (ver PREGUNTAS ABIERTAS #1):** `33` **agrega** y NO persiste el
> detalle nominal por sesion ni la FECHA. El formato largo (`sesion_id`,
> `diputado_id`, `tipo_valor`) existe SOLO en el cache
> `20_insumos/camara/..._asistencia_long_2026.rds`, no en el intermedio. La fecha
> por sesion la da la fuente (`retornarSesionesXAnno` → `Sesion/FechaInicio`) pero
> `33` no la captura.

**`votos.rds`** — formato largo diputado×votacion (104.160 filas). Escrito por `34`.

| columna | tipo | clave | nota |
|---------|------|-------|------|
| `votacion_id` | character | **PK** (con `diputado_id`) | |
| `diputado_id` | character | **PK** | |
| `boletin` | character | join→proyecto | extraido por regex de `Descripcion` (NA si no aparece) |
| `descripcion` | character | | |
| `fecha` | character | | `AAAA-MM-DD` de la votacion |
| `resultado` | character | | `Aprobado`/`Rechazado`/... |
| `tipo` | character | | `Proyecto de Ley`/`Proyecto de Acuerdo`/... |
| `opcion_valor` | character | | crudo `0..4` |
| `sentido` | character | | `DOMINIO_VOTO`: `a_favor`/`en_contra`/`abstencion`/`dispensado`/`no_vota` |

**`proyectos.rds`** — 1 fila/autor×boletin (1.313 filas). Escrito por `35`. Solo
mociones de **origen Camara** (autores diputados).

| columna | tipo | clave | nota |
|---------|------|-------|------|
| `boletin` | character | **PK** (con `diputado_id`) | |
| `diputado_id` | character | **PK** | |
| `orden` | character | | siempre `"0"` — la API no distingue jerarquia |
| `rol` | character | | siempre `"firmante"` (derivado; # REVISAR) |
| `nombre` | character | | titulo del proyecto |
| `fecha_ingreso` | character | | `AAAA-MM-DD` |
| `admisible` | character | | `"true"`/`"false"` — proxy del estado (no hay estado real) |

**`proyectos_detalle.rds`** — 1 fila/boletin (317 filas). Escrito por `36`.

| columna | tipo | clave | nota |
|---------|------|-------|------|
| `boletin` | character | **PK** | |
| `nombre` | character | | |
| `tipo_iniciativa` | character | | `Mocion`/`Mensaje` |
| `n_materias` | integer | | |
| `materias` | list-col&lt;data.frame(id,nombre)&gt; | | `[]` si sin materias (nunca fabricado) |

### Claves de join entre intermedios (todas `character`)

- `asistencia`,`votos`,`proyectos` → `diputados` por **`diputado_id`**.
- `votos.boletin` y `proyectos.boletin` → `proyectos_detalle.boletin` por **`boletin`**
  (es el join voto→proyecto que hace legible/trazable el perfil).

### Estructura del JSON final que `39` produce (el contrato que consume hoy)

**`indice_diputados.json`** — array, 1 objeto/diputado, ordenado por nombre:
`id, nombre, sexo, partido (=partido_id), partido_nombre, distrito, region,
tendencia, tasa_asistencia, n_proyectos, n_votaciones`.

**`perfiles/<id>.json`** — objeto con 5 bloques (orden fijo):
- `perfil`: `id, nombre, sexo, fecha_nacimiento, partido{id,nombre,alias}, distrito, region, tendencia`.
- `asistencia`: `anio, n_sesiones, n_asiste, n_no_asiste, tasa_asistencia`.
- `votaciones`: `anio, n_votaciones, resumen_por_sentido{}, votos[ {votacion_id, boletin, tipo, fecha, resultado, sentido, descripcion, proyecto{boletin,nombre,tipo_iniciativa,materias[]}|null} ]`.
- `proyectos`: `anio, n_proyectos, estado_tramitacion_disponible(=false), proyectos[ {boletin, nombre, fecha_ingreso, admisible, rol, tipo_iniciativa, materias[]} ]`.
- `metadatos`: `fuente, periodo, anio_proceso, generado`.

`39` hace `left_join` sobre el roster (nunca inner): un diputado sin votos/proyectos
queda con `0`/`null`, no desaparece.

---

## FASE 2 — Propuesta de contrato comun

Nombre canonico = columna que **ambos** normalizadores emitirian. `camara` ("D"/"S")
es discriminador en TODAS las entidades. La llave de identidad es **compuesta
`(camara, parlamentario_id)`**: los espacios de id NO se comparten (solo 11/155
`diputado_id` coinciden con `ID_PARLAMENTARIO`, colisiones casuales) → `parlamentario_id`
solo NO es unico entre camaras.

### Entidad: roster (parlamentario)

| columna canonica | tipo | clave | campo-Camara | campo-Senado | nota |
|------------------|------|-------|--------------|--------------|------|
| `camara` | character | discrim | `"D"` (constante) | `CAMARA` (`"S"`) | |
| `parlamentario_id` | character | **PK** (con `camara`) | `diputado_id` | `ID_PARLAMENTARIO` | espacios distintos → clave compuesta |
| `nombre` | character | | `nombre` | `NOMBRE_COMPLETO` | |
| `sexo` | character | | `sexo` (Femenino/Masculino) | `SEXO_ETIQUETA` (Mujer/Hombre) | **dominios distintos → normalizar** |
| `partido_id` | character | | `partido_id` (`UDI`,`RN`) | `PARTIDO_ID` (num) | codigos distintos → crosswalk |
| `partido_nombre` | character | | `partido_nombre` | `PARTIDO` (texto) | |
| `tendencia` | character | derivada | `tendencia_de_partido(partido_id)` | crosswalk `PARTIDO_ID`→tendencia | metodologico (titular) |
| `region` | character | | `NA` (hueco) | `REGION` | Senado SI puebla |
| `territorio` | character | | `distrito` (`NA`) | `CIRCUNSCRIPCION_ID` | nombre neutro; Camara=distrito, Senado=circunscripcion |
| `fecha_nacimiento` | character | opcional | `fecha_nacimiento` | (no en backend) | opcional-por-fuente |

### Entidad: asistencia (contrato SIMETRICO — nominal por sesion)

| columna canonica | tipo | clave | campo-Camara | campo-Senado | nota |
|------------------|------|-------|--------------|--------------|------|
| `camara` | character | | `"D"` | `"S"` | |
| `parlamentario_id` | character | **PK** (con `sesion_id`) | `diputado_id` | `ID_PARLAMENTARIO` | |
| `sesion_id` | character | **PK** | `sesion_id` (en cache, **no persistido**) | `ID_SESION` | **gap Camara (#1)** |
| `fecha_sesion` | character | | `Sesion/FechaInicio` (fuente lo da, **no capturado**) | `FECHA_HORA_INICIO` | **gap Camara (#1)**; capturar por decision de diseno |
| `numero_sesion` | character | opcional | `Sesion/Numero` (disponible, no capturado) | `NUMERO_SESION` | |
| `asistio` | boolean | | `TipoAsistencia` Valor `1`/`0` → asiste/no | `ASISTENCIA` (`Asiste`/`Ausente`) | normalizar a booleano canonico |
| `justificacion` | character | opcional | (no expone) | `JUSTIFICACION` (Enfermedad/Otras act.) | opcional-por-fuente (Senado SI) |

### Entidad: votos (nominal por votacion)

| columna canonica | tipo | clave | campo-Camara | campo-Senado | nota |
|------------------|------|-------|--------------|--------------|------|
| `camara` | character | | `"D"` | `"S"` | |
| `parlamentario_id` | character | **PK** (con `votacion_id`) | `diputado_id` | `PARLID` (en `VOTACIONES.{SI,NO,...}[]`) | |
| `votacion_id` | character | **PK** | `votacion_id` | `ID_VOTACION` | espacios distintos |
| `sesion_id` | character | opcional | (no en `votos.rds`) | `ID_SESION` | Senado lo trae; permite alinear con asistencia |
| `fecha` | character | | `fecha` | `FECHA_VOTACION` | |
| `boletin` | character | **join→proyecto** | `boletin` (regex de `Descripcion`) | `BOLETIN` (campo directo) | |
| `sentido` | character | | `sentido` (a_favor/en_contra/abstencion/dispensado/no_vota) | grupo `SI`/`NO`/`ABSTENCION`/`PAREO` | **dominios distintos → vocabulario canonico** |
| `resultado` | character | opcional | `resultado` | (agregados `SI/NO/ABS/PAREO`) | |
| `tipo` | character | opcional | `tipo` | `TIPOVOTACION`/`QUORUM` | |

> Sentido: la Camara tiene `dispensado` y `no_vota`; el Senado tiene `Pareo`.
> El vocabulario canonico debe cubrir la union: p. ej.
> `a_favor / en_contra / abstencion / pareo / dispensado / no_vota` (a confirmar).

### Entidad: proyectos (autoria + detalle)

| columna canonica | tipo | clave | campo-Camara | campo-Senado | nota |
|------------------|------|-------|--------------|--------------|------|
| `camara` | character | | `"D"` | `"S"` | |
| `parlamentario_id` | character | **PK** (con `boletin`) | `diputado_id` | autor por **nombre** → `ID_PARLAMENTARIO` via crosswalk `NOMBRE_COMPLETO_POR_APELLIDOS` del roster | Senado sin id en autoria |
| `boletin` | character | **PK** | `boletin` | `boletin` (wspublico) | |
| `nombre_proyecto` | character | | `nombre` | `titulo` (wspublico) | |
| `fecha_ingreso` | character | | `fecha_ingreso` | `fecha_ingreso` (wspublico) | |
| `rol` | character | | `rol` (`firmante`) | autor (sin jerarquia) | ninguna fuente distingue jerarquia |
| `tipo_iniciativa` | character | opcional | `tipo_iniciativa` (Mocion/Mensaje) | `iniciativa` (wspublico) | |
| `estado_tramitacion` | character | opcional | `NA` (no expone; `admisible` proxy) | `estado` (wspublico SI) | **Senado SI, Camara no** |
| `materias` | list | opcional | `materias` (list-col) | `materias` (wspublico) | |
| `admisible` | character | opcional | `admisible` | (no) | Camara only |

> Proyectos del Senado: NO estan en el backend `web-back.senado.cl`; se
> complementan con `wspublico/tramitacion.php?boletin=<n>` (autores por nombre,
> resolubles a id via el roster). Marcar los campos exclusivos como
> **opcional-por-fuente**, no forzar simetria donde la fuente no la da.

---

## FASE 3 — Pares de partido reales del Senado (insumo del crosswalk)

Traidos en vivo de `web-back.senado.cl/api/parlamentarios?vigentes=1` (`CAMARA=="S"`,
50 senadores) por `30_procesamiento/31e_extraer_partidos_senado.R`. Muestra:
`50_documentacion/andamios/contrato_datos/senado_partidos_muestra.json`.

**Este encargo NO decide la tendencia de cada partido (es del titular).** Solo la
lista de pares reales:

| PARTIDO_ID | PARTIDO (texto) | n_senadores |
|------------|-----------------|-------------|
| 6 | Independiente | 10 |
| 3 | R.N. | 8 |
| 4 | P.S. | 7 |
| 5 | U.D.I. | 5 |
| 12 | P.C | 3 |
| 1 | P.D.C. | 3 |
| 2 | P.P.D. | 3 |
| 20 | Republicano | 3 |
| 18 | Evopoli | 2 |
| 24 | Frente Amplio | 2 |
| 22 | Democratas | 1 |
| 21 | F.R.E.V.S. | 1 |
| 15 | Liberal | 1 |
| 25 | Nacional Libertario | 1 |

Total: 50 senadores, 14 partidos distintos.

### Taxonomia destino (formato del crosswalk, NO extrapolada al Senado)

De `10_configuracion.R` (`MAPA_PARTIDO_TENDENCIA`), taxonomia de **5 niveles**:
`izquierda / centroizquierda / centro / centroderecha / derecha`. Mapa vigente de
la **Camara** (para que el titular vea el formato destino):

`PREP→derecha, FA→izquierda, PDG→centro, UDI→derecha, RN→centroderecha,
PS→centroizquierda, PC→izquierda, PNL→derecha, DC→centro, PPD→centroizquierda,
PSC→derecha, EVOP→centroderecha, PL→centroizquierda, DEM→centro, FRVS→izquierda,
PAH→izquierda, PR→centroizquierda`; `IND→NA` (Independientes, no clasificable).

El titular debe producir el equivalente `PARTIDO_ID(Senado)→tendencia` para los 14
partidos de arriba. Nota: los codigos del Senado (numericos) NO son los de la
Camara (siglas); varios partidos coinciden en nombre (R.N., U.D.I., P.S., P.P.D.,
P.C, Evopoli, Frente Amplio, Republicano, Liberal, F.R.E.V.S., Nacional Libertario)
y otros aparecen distinto (P.D.C. vs DC, Democratas vs DEM).

---

## PREGUNTAS ABIERTAS (para la sesion de diseno)

1. **Asistencia de la Camara: agregado vs nominal por sesion.** El contrato
   simetrico exige nominal por sesion + fecha en AMBAS camaras. El `33` actual
   **agrega** y descarta `sesion_id` y la fecha (que la fuente SI da). ¿Se extiende
   el normalizador de la Camara para persistir el largo (`sesion_id`, `fecha_sesion`,
   `asistio` por diputado) — dato que ya esta en el cache/fuente — o el contrato se
   deja asimetrico? (Caso de detencion #3: decision de contrato del codigo actual
   que contradice la premisa simetrica.)

2. **Llave de identidad compuesta.** `diputado_id` (Camara) e `ID_PARLAMENTARIO`
   (Senado) son espacios de id DISTINTOS (11/155 colisiones casuales). Se propone
   `(camara, parlamentario_id)` como PK. ¿Se confirma, o se quiere un id global
   sintetico (p. ej. `"D-1074"`/`"S-1110"`) en el JSON final?

3. **Vocabulario canonico del sentido del voto.** Union de dominios: Camara
   (`dispensado`,`no_vota`) + Senado (`pareo`). ¿Cual es el set canonico y como se
   mapea cada valor de origen?

4. **Normalizacion de `sexo`.** Camara `Femenino`/`Masculino` vs Senado
   `Mujer`/`Hombre`. Definir el dominio canonico.

5. **`territorio` (distrito vs circunscripcion).** El Senado puebla
   `region`+`circunscripcion`; la Camara los tiene en `NA`. ¿El JSON final usa un
   campo neutro `territorio` con subtipo, o mantiene `distrito`/`circunscripcion`
   separados con el otro en `null`?

6. **Proyectos del Senado por wspublico.** La autoria del Senado (nombre → id via
   `NOMBRE_COMPLETO_POR_APELLIDOS`) y el `estado` de tramitacion (que la Camara NO
   tiene) hacen la entidad `proyectos` la mas asimetrica. ¿Se acepta el crosswalk
   nombre→id como cierre determinista, y `estado` como campo opcional-por-fuente?

7. **Crosswalk de partido→tendencia del Senado.** Insumo entregado (14 pares); la
   decision es del titular (fuera de este encargo).

8. **Membresia dependiente del tiempo.** Ya decidido: capturar `fecha_sesion` para
   resolver el roster as-of en el futuro (el Senado renovo en mar-2026; una sesion
   vieja cruza <50 con el roster vigente). Confirma que el contrato de asistencia y
   votos lleva la fecha para habilitarlo.
