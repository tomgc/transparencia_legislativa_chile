# Auditoría de cobertura del web service de la Cámara

> Auditoría ADVERSARIAL insumos-first (rama `explore/cobertura-camara`). Responde,
> con evidencia empírica: ¿qué EXPONE `opendata.camara.cl` que los scripts 32-36
> NO consumen? No corrige el pipeline: inventaría los gaps para decidir después.
> Evidencia regenerable por `30_procesamiento/31f_auditar_cobertura_camara.R`;
> muestras crudas en `50_documentacion/andamios/muestras/`.

- **Fecha:** 2026-07-10
- **Base:** `https://opendata.camara.cl/camaradiputados/WServices/` (XML, namespace `.../v1`).
- **Catálogo real:** 5 servicios, **49 operaciones**. El pipeline usa **8**.

## FASE 1 — Lo CONSUMIDO (linaje campo-por-campo)

| Intermedio | Endpoint(s) de origen | Campos que EXTRAE/persiste | Campos que TOCA y DESCARTA |
|-----------|----------------------|----------------------------|----------------------------|
| `diputados.rds` (32) | `WSDiputado/retornarDiputadosPeriodoActual` | `Diputado/Id`→diputado_id, `Nombre`(+Nombre2+Apellidos)→nombre, `Sexo`, `FechaNacimiento`, militancia vigente `Partido/{Id,Nombre,Alias}`; deriva `tendencia`; fija `distrito=NA`, `region=NA` | **`RUT`, `RUTDV`**; **historial de militancias** (solo conserva la de mayor FechaInicio); `DiputadoPeriodo/FechaInicio`+`FechaTermino` |
| `asistencia.rds` (33) | `WSSala/retornarSesionesXAnno` + `retornarSesionAsistencia` | por sesión: `Asistencia/TipoAsistencia` (Valor) + `Diputado/Id`; **AGREGA** a n_sesiones, n_asiste, n_no_asiste, tasa_asistencia | **`sesion_id`** (lo tiene en el bucle, no lo persiste); **`Sesion/FechaInicio`** (la FECHA, nunca capturada); `Sesion/{Numero,FechaTermino,Tipo}`; **`Asistencia/Justificacion/{Nombre,RebajaAsistencia,RebajaQuorum}`** (motivo de ausencia por diputado) |
| `votos.rds` (34) | `WSLegislativo/retornarVotacionesXAnno` + `retornarVotacionDetalle` | root: `Descripcion`, `Fecha`, `Resultado`, `Tipo`; por voto: `Diputado/Id`, `OpcionVoto`→sentido; `boletin` **por regex de Descripcion** | root del detalle: **`TotalSi/TotalNo/TotalAbstencion/TotalDispensado`, `Quorum`**; y el **join estructurado votación↔proyecto** (ver GAP votaciones) |
| `proyectos.rds` (35) | `WSLegislativo/retornarMocionesXAnno` + `retornarProyectoLey` | lista: `NumeroBoletin`, `Nombre`, `FechaIngreso`, `CamaraOrigen`(Valor), `Admisible`; detalle: `Autores/.../Diputado/Id`, `Orden`→rol="firmante" | `ProyectoLey/Id` (id estable del proyecto); `Orden` real (siempre "0"); `TipoIniciativa` de la lista (36 lo re-baja) |
| `proyectos_detalle.rds` (36) | `WSLegislativo/retornarProyectoLey` (por boletín) | `Nombre`, `TipoIniciativa`, `Materias/Materia/{Id,Nombre}`→n_materias+materias | **`ProyectoLey/Votaciones/VotacionProyectoLey`** (join estructurado con Articulo, TramiteConstitucional/Reglamentario) |

JSON final (39): índice (11 campos) + perfil (perfil/asistencia/votaciones/proyectos/
metadatos). El bloque asistencia del perfil expone n_sesiones/n_asiste/n_no_asiste/
tasa — nunca el detalle por sesión (no existe en el intermedio).

## FASE 2 — Lo EXPUESTO (catálogo completo + campos reales)

**Operaciones por servicio** (muestra: `camara_catalogo_<servicio>.html`):

- **WSDiputado** (4): `retornarDiputado`, `retornarDiputados`, **`retornarDiputadosPeriodoActual`** (usado), `retornarDiputadosXPeriodo`.
- **WSSala** (3): **`retornarSesionAsistencia`** (usado), **`retornarSesionesXAnno`** (usado), `retornarSesionesXLegislatura`.
- **WSLegislativo** (14): `retornarLegislaturaActual`, `retornarLegislaturas`, `retornarMaterias`, `retornarMensajesXAnno`, **`retornarMocionesXAnno`** (usado), `retornarPeriodoLegislativoActual`, `retornarPeriodosLegislativos`, **`retornarProyectoLey`** (usado), `retornarProyectosLeyxNumeroLey`, `retornarTramitesConstitucionales`, `retornarTramitesReglamentarios`, **`retornarVotacionDetalle`** (usado), **`retornarVotacionesXAnno`** (usado), `retornarVotacionesXProyectoLey`.
- **WSComun** (24): catálogos (partidos, distritos, regiones, comunas, provincias, ministerios, y 18 `retornarTipos*`).
- **WSComision** (4): `retornarComision`, `retornarComisionesVigentes`, `retornarComisionesXPeriodo`, `retornarSesionesXComisionYAnno`.

**Campos completos por endpoint usado** (muestra en `andamios/muestras/`): ver la
columna "DESCARTA" de la Fase 1 — cada muestra `camara_<op>_muestra.xml` lista el
árbol de nodos hoja real. Hallazgos de campos ocultos, con evidencia:

- `retornarSesionesXAnno` → `Sesion/{Id, Numero, FechaInicio, FechaTermino, Tipo, Estado}`. **La FECHA por sesión está aquí** (`FechaInicio`). Muestra: `camara_retornarSesionesXAnno_muestra.xml`.
- `retornarSesionAsistencia` → `Asistencia/{TipoAsistencia, Diputado/*, Justificacion/{Nombre, RebajaAsistencia, RebajaQuorum}}`. El nodo **`Justificacion` aparece solo en los diputados ausentes-justificados** (por eso se detecta al unir los campos de TODOS los items, no del primero). Muestra: `camara_retornarSesionAsistencia_muestra.xml`.
- `retornarVotacionDetalle` (raíz) → `Id, Descripcion, Fecha, TotalSi, TotalNo, TotalAbstencion, TotalDispensado, Quorum, Resultado, Tipo, Votos`. **`Quorum` y los totales** están y no se usan. Muestra: `camara_retornarVotacionDetalle_muestra.xml`.
- `retornarProyectoLey` de un boletín **votado** → `Votaciones/VotacionProyectoLey/{Id, Descripcion, Fecha, TotalSi..TotalDispensado, Quorum, Resultado, Tipo, TipoVotacionProyectoLey, Articulo, TramiteConstitucional, TramiteReglamentario}` (15 votaciones en el boletín 18384-08). **Join estructurado votación↔proyecto, con artículo y trámite.** Muestra: `camara_retornarProyectoLey_muestra.xml`.

**Adversarial (parámetros/endpoints alternativos probados):**

- `retornarDiputado` (individual, `prmDiputadoId`) → MISMOS campos que el roster, **sin distrito/región**. Confirma que distrito/región NO se exponen ni en el endpoint individual. Muestra: `camara_retornarDiputado_muestra.xml`.
- `retornarVotacionesXProyectoLey` → el param correcto es **`prmNumeroBoletin`** (con `prmBoletin`/`prmProyectoLeyId` da HTTP 500). Devuelve las mismas `VotacionProyectoLey` (join reverso proyecto→votaciones). Muestra: `camara_retornarVotacionesXProyectoLey_muestra.xml`.
- `retornarTramitesConstitucionales`/`retornarTramitesReglamentarios` → son **catálogos** de tipos de trámite, NO el estado de un proyecto. Muestras homónimas.
- `retornarTiposEstado` → dominio `Activo`/`Inactivo` (no es estado de tramitación).
- `retornarTiposAsistencia` → **3 valores: `0=No Asiste`, `1=Asiste`, `2=Justificado`**. El pipeline (`DOMINIO_ASISTENCIA`) mapea solo 0/1. Ocurrencia real 2026 (5 sesiones): solo 0/1 (el valor 2 no aparece). Muestra: `camara_retornarTiposAsistencia_muestra.xml`.
- `retornarMensajesXAnno` → 44 mensajes (iniciativa ejecutiva), mismos campos que mociones. El pipeline solo procesa mociones (correcto: los diputados no autoran mensajes).
- `retornarDistritos` (1219) y `retornarRegiones` (1328) → catálogos territorio→comuna, **sin vínculo diputado→distrito**.
- `retornarTiposJustificacionesInasistencia` → 89 tipos (Nombre, RebajaAsistencia, RebajaQuorum); es catálogo, no viene por-diputado en la asistencia.
- `retornarComisionesVigentes` (37) → entidad **comisiones** (no cubierta por el pipeline; ver endpoints no usados).

## FASE 3 — Tabla de gaps

Convención: GAP = la fuente lo entrega y el pipeline no lo consume. "confirmado
NO" = adversarialmente verificado que la fuente NO lo expone (no es gap: es hueco
real de la fuente).

### Roster (diputados)

| campo/endpoint fuente | ¿lo entrega? (evidencia) | ¿lo consume? | script | GAP |
|---|---|---|---|---|
| `RUT` + `RUTDV` | SÍ (`camara_retornarDiputadosPeriodoActual_muestra.xml`) | NO | 32 | **GAP** — id nacional estable, descartado |
| historial de militancias | SÍ (misma muestra, N Militancia>1) | solo la vigente | 32 | **GAP** — trayectoria partidaria descartada |
| `DiputadoPeriodo/FechaInicio`+`FechaTermino` | SÍ (misma muestra) | NO | 32 | gap menor |
| distrito / región por diputado | **NO** (`camara_retornarDiputado_muestra.xml`, adversarial) | — | 32 | confirmado NO (hueco de la fuente) |

### Asistencia

| campo/endpoint fuente | ¿lo entrega? (evidencia) | ¿lo consume? | script | GAP |
|---|---|---|---|---|
| detalle NOMINAL por sesión (sesión×diputado×tipo) | SÍ (`camara_retornarSesionAsistencia_muestra.xml`) | lo agrega y descarta el detalle | 33 | **GAP MAYOR** (A23) |
| `Sesion/FechaInicio` (fecha de sesión) | SÍ (`camara_retornarSesionesXAnno_muestra.xml`) | NO | 33 | **GAP MAYOR** — sin fecha no hay as-of |
| `Sesion/{Numero,Tipo,FechaTermino}` | SÍ (misma muestra) | NO | 33 | gap menor |
| `TipoAsistencia=2 (Justificado)` | SÍ en catálogo; NO en datos 2026 (`camara_retornarTiposAsistencia_muestra.xml`) | mapea solo 0/1 (con guardia de dominio) | 33 | gap latente (sin pérdida actual) |
| **`Asistencia/Justificacion/{Nombre, RebajaAsistencia, RebajaQuorum}` por diputado** | **SÍ** (`camara_retornarSesionAsistencia_muestra.xml`: 9 justificaciones en la sesión 4736) | NO | 33 | **GAP** — motivo de la ausencia por diputado (equivalente al `JUSTIFICACION` del Senado), descartado. **Descubierto por el panel adversarial** (mi enumeración inicial miró solo el primer item, que era "Asiste" sin justificación) |

### Votaciones

| campo/endpoint fuente | ¿lo entrega? (evidencia) | ¿lo consume? | script | GAP |
|---|---|---|---|---|
| join estructurado votación↔proyecto (`VotacionProyectoLey/Id`) | SÍ (`camara_retornarProyectoLey_muestra.xml`, `camara_retornarVotacionesXProyectoLey_muestra.xml`) | NO — usa regex de Descripcion | 34/36 | **GAP MAYOR** — el join robusto existe. Hoy **31.5% de las votaciones (212/672) quedan sin boletín** por el regex (recuento sobre `votos.rds`); es una mezcla de votaciones genuinamente sin proyecto (acuerdos/resoluciones) y de boletines que el regex no captó — el join estructurado los distingue autoritativamente |
| `Quorum` | SÍ (`camara_retornarVotacionDetalle_muestra.xml`) | NO | 34 | **GAP** — el Senado sí lo guarda |
| `TotalSi/No/Abstencion/Dispensado` (raíz) | SÍ (misma muestra) | recomputa desde votos | 34 | gap menor (redundante) |
| `TipoVotacionProyectoLey`, `Articulo`, `TramiteConstitucional`, `TramiteReglamentario` | SÍ (muestra proyecto votado) | NO | 34/36 | **GAP** — contexto de artículo/etapa del voto |

### Proyectos

| campo/endpoint fuente | ¿lo entrega? (evidencia) | ¿lo consume? | script | GAP |
|---|---|---|---|---|
| estado de tramitación por proyecto | **NO** (`camara_retornarProyectoLey_muestra.xml` sin nodo Estado; `retornarTiposEstado`=Activo/Inactivo) | usa `Admisible` como proxy | 35/36 | confirmado NO (hueco de la fuente) — pero ver trámite-por-voto |
| `TramiteConstitucional`/`Reglamentario` por votación | SÍ (muestra proyecto votado) | NO | 36 | **GAP** — señal PARCIAL de etapa, sin usar |
| `ProyectoLey/Id` (id estable del proyecto) | SÍ (`camara_retornarProyectoLey_muestra.xml`) | NO (llavea por boletín) | 35 | gap menor |

### Endpoints NO usados por el pipeline

- **`WSComision/*`** (`retornarComisionesVigentes`, `retornarSesionesXComisionYAnno`, ...): **entidad completa de comisiones** (sesiones y trabajo en comisión) — no cubierta. Fuera del contrato actual (que es sala), pero existe. Evidencia: `camara_retornarComisionesVigentes_muestra.xml`.
- `retornarVotacionesXProyectoLey`, `ProyectoLey/Votaciones`: el join estructurado (GAP votaciones).
- `retornarMensajesXAnno`: iniciativa ejecutiva (44 en 2026); no es autoría de diputados.
- `retornarProyectosLeyxNumeroLey`: proyectos por número de ley (leyes promulgadas).
- `retornarMaterias`, `retornarLegislaturas`, `retornarPeriodosLegislativos`, catálogos `WSComun` (`retornarPartidosPoliticos`, `retornarTiposOpcionVoto`, `retornarTiposSexo`, ...): tablas de referencia útiles para normalizar dominios, no entidades faltantes.

## FASE 4 — Implicancia sobre las 8 preguntas del contrato de datos

(No decido; marco.)

1. **Asistencia agregado vs nominal por sesión** → **CAMBIA (gap asistencia MAYOR).** El detalle nominal por sesión, la fecha Y el motivo de ausencia (`Justificacion`) SÍ están en la fuente de la Cámara (evidencia: `camara_retornarSesionesXAnno_muestra.xml` + `camara_retornarSesionAsistencia_muestra.xml`); `33` los descarta al agregar. La Cámara PUEDE ser simétrica con el Senado —incluso en la justificación, que el Senado también expone—; el trabajo es en el normalizador, no en la fuente.
2. **Llave de identidad compuesta** → **sin cambio en la conclusión; matiz (gap RUT).** `RUT`/`RUTDV` disponibles (id nacional estable) y descartados. Podría ser una llave de persona, pero el backend del Senado no expone RUT, así que no cruza cámaras; la clave compuesta `(camara, id)` sigue.
3. **Vocabulario canónico del sentido** → **sin cambio.** `DOMINIO_VOTO` cubre 0-4; no aparecieron valores nuevos. `WSComun/retornarTiposOpcionVoto` disponible como catálogo canónico.
4. **Normalización de `sexo`** → **sin cambio.** Femenino/Masculino confirmado; `WSComun/retornarTiposSexo` disponible para el dominio canónico.
5. **`territorio` (distrito vs circunscripción)** → **sin cambio (confirma el hueco).** Distrito/región NO se exponen por diputado (adversarial: ni el endpoint individual los trae; los catálogos no vinculan). La asimetría con el Senado (que sí puebla) se mantiene.
6. **Proyectos / estado de tramitación** → **CAMBIA parcialmente (gaps proyectos/votaciones).** El estado como tal NO existe (confirmado adversarialmente), pero `TramiteConstitucional`/`TramiteReglamentario` por votación SÍ están y sin usar (señal parcial de etapa), y el join estructurado fortalece la entidad. La asimetría se atenúa, no desaparece.
7. **Crosswalk partido→tendencia del Senado** → **sin cambio.** Es del Senado; la Cámara tiene `retornarPartidosPoliticos` (145) para su lado.
8. **Membresía dependiente del tiempo (fecha de sesión)** → **CAMBIA (habilitado).** La fecha de sesión (`Sesion/FechaInicio`) SÍ está en la fuente de la Cámara; capturarla habilita el mismo mecanismo as-of que el Senado. Confirmado con muestra.

## Panel adversarial (auto-auditoría)

Dos agentes de solo lectura re-derivaron, con código propio e independiente, las
afirmaciones de mayor riesgo. Resultado — incluido lo que me contradijo:

**Panel A (re-derivación desde el CÓDIGO, sin ver la fuente).** Confirmó las tres
afirmaciones de descarte, con la nota honesta de que el código por sí solo no
prueba que la *fuente* traiga RUT o FechaInicio (solo prueba que el pipeline no los
captura) — por eso las muestras de la Fase 2 son necesarias:
- 33 agrega y descarta `sesion_id` en el `summarise(.by = diputado_id)` (línea 82) y nunca lee un nodo de fecha (solo `./Id` y `./Estado` de la sesión). CONFIRMADA.
- 34 obtiene el boletín por `regexpr("[0-9]{3,6}-[0-9]{1,2}", descripcion)` (líneas 26-29), sin endpoint de join; `NA` cuando no hay patrón. CONFIRMADA.
- 32 nunca lee `RUT`/`RUTDV` y conserva solo la militancia de `which.max(FechaInicio)` (línea 47), descartando el historial. CONFIRMADA.

**Panel B (re-sondeo ADVERSARIAL de la fuente, intentando refutar).**
- CLAIM distrito/región **NO refutable**: probó `retornarDiputado`, `retornarDiputadosPeriodoActual`, `retornarDiputadosXPeriodo`, `retornarDiputados`, y los embeds por-diputado en votación/asistencia — cero campos geográficos en todos. Confirmado hueco de la fuente.
- CLAIM estado de tramitación **NO refutable**: `retornarProyectoLey` solo trae `Admisible`; probó incluso `retornarProyectosLeyxNumeroLey` sobre una **ley ya promulgada** (mismo esquema, sin `Estado`/`Etapa`). Los `Tramite*` son per-votación, no estado del proyecto. Confirmado.
- **CONTRADICCIÓN útil (el panel me corrigió):** el Panel B observó que la respuesta de `retornarSesionAsistencia` incluye un nodo `Justificacion` por diputado. Mi enumeración original de la Fase 2 **lo había perdido** porque miraba solo el primer item (que era "Asiste", sin justificación). Re-verificado: `Asistencia/Justificacion/{Nombre, RebajaAsistencia, RebajaQuorum}` existe para los ausentes-justificados (9 en la sesión 4736). Esto **agregó un GAP** (motivo de ausencia por diputado) y corrigió un falso "confirmado NO". **Causa raíz de mi error:** enumerar campos del primer item en vez de la UNIÓN sobre todos; corregido en `31f` (ahora une los campos hoja de todos los items). Re-corrida completa: ningún otro endpoint tenía campos ocultos por este motivo (p. ej. `retornarVotacionDetalle` unido sobre los 155 votos = solo `Diputado/*` + `OpcionVoto`).

Lección: el panel adversarial pagó — encontró un campo que mi propio flujo había
enmascarado por un sesgo de método (primer-item vs unión). Sin él, el gap de
justificación se habría reportado como inexistente.
