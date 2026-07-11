# Diagnóstico de propósito — la brecha entre lo prometido y lo entregado

> Diagnóstico (solo lectura). Mide, no corrige. Rama `explore/diagnostico-proposito`.
> Objetivo declarado (backlog §Objetivo): mostrar por parlamentario su asistencia,
> los proyectos que presentó, los que votó y el sentido del voto, y su perfil; con
> segmentación por cámara, partido, tendencia y región/distrito. Cifras producidas
> por `30_procesamiento/31g_diagnostico_proposito.R`; evidencia en
> `50_documentacion/andamios/muestras/`. Cada cifra fue recontada en el momento.

- **Fecha:** 2026-07-11 · **Corte de los datos:** el vigente en `docs/data`.

## FASE 1 — ¿Hay datos incompletos o erróneos publicados? (join autoritativo)

El pipeline (34) extrae el boletín del voto por **regex** sobre `Descripcion`. Se
construyó el mapa **autoritativo** `votacion_id → boletin` desde la fuente
(`retornarProyectoLey → Votaciones/VotacionProyectoLey/Id`), consultando **490
boletines** (universo: regex ∪ proyectos ∪ mociones 2026 ∪ mensajes 2026), **0
fallos de la API**. Clasificación de las 672 votaciones distintas:

| caso | qué significa | cifra |
|------|---------------|-------|
| **(d)** con boletín regex, el join lo **CONFIRMA** | dato correcto | **460** |
| **(c)** con boletín regex, el join **NO** lo confirma | **dato ERRÓNEO** | **0** |
| **(a)** sin boletín regex, el join **SÍ** lo resuelve | **dato INCOMPLETO** | **0** |
| **(b)** sin boletín y sin proyecto | estructural | **212** |
| | **suma** | **672** ✓ |

**VEREDICTO INEQUÍVOCO: NO hay datos erróneos (c=0) ni incompletos (a=0) publicados
hoy por el join.** El 31,5 % de votaciones sin boletín (212/672) es **100 %
estructural**: las 212 son Proyecto de Resolución (97), "Otros" (95) y Proyecto de
Acuerdo (20) — **cero Proyecto de Ley**; ninguna tiene un boletín que el regex haya
perdido (verificado: ninguna aparece en el mapa autoritativo de 490 proyectos). Las
460 con boletín son **todas** Proyecto de Ley y el join confirma el 100 %.

**Matiz honesto (contradice la hipótesis del encargo):** se esperaba que el join
estructurado recuperara parte del 31,5 %. Recupera **cero**: para este corte el
regex es accidentalmente exacto. El join sigue siendo **más robusto** (no depende
del formato del texto y distingue "sin proyecto" de "boletín no capturado"), pero
hoy no cambia ningún dato publicado. La conclusión del traspaso v03 (el 31,5 % es
estructural) queda **confirmada con evidencia autoritativa**, no por inferencia.

## FASE 2 — Estado real de lo publicado (docs/data)

| dimensión | medición | cifra |
|-----------|----------|-------|
| **Roster — campos muertos** | `distrito` nulo en el índice | **155/155 (100 %)** |
| | `region` nulo en el índice | **155/155 (100 %)** |
| | `tendencia` nula (IND, intencional) | 25/155 |
| | otros campos del índice nulos | 0 |
| **Trazabilidad del voto** | votos totales en los 155 perfiles | 84 927 |
| | votos con `proyecto = null` (ilegibles) | **27 974 (32,9 %)** |
| | fracción ilegible por diputado (mín/mediana/máx) | 0,315 / 0,351 / 0,351 |
| **Asistencia** | sesiones que declara la fuente (celebradas) | 64 (61 celebradas) |
| | `n_sesiones` por diputado (perfiles publicados) | **rango [43, 61], mediana 43** |
| | perfiles con `n_sesiones < 61` | **85/155** |
| | `n_asiste + n_no_asiste == n_sesiones` (intermedio) | 239/239 |
| **Materias (contenido legible)** | proyectos presentados con ≥1 materia | **0/1311 (0 %)** |
| | votos-con-proyecto con ≥1 materia | **1737/56 953 (3,0 %)** |
| **Proyectos** | diputados con 0 proyectos | 0/155 |
| | `estado_tramitacion_disponible == false` | 155/155 |
| **Consistencia índice↔perfiles** | discrepancias (n_votaciones, n_proyectos, tasa) | **0/155** |
| **Integridad 39** | en índice sin perfil / en perfil sin índice | 0 / 0 |
| **Sincronía intermedio↔publicado** | perfiles cuyo `n_sesiones` on-disk (`asistencia.rds`) ≠ publicado | **155/155** (ver hallazgo abajo) |

Lecturas: (1) **`distrito` y `region` son promesas muertas** — 100 % nulas. (2) casi
**un tercio de los votos son ilegibles** (se ve "votó a favor" sin saber de qué);
esto es exactamente el 31,5 % estructural de la Fase 1, distribuido por diputado
(mediana 35,1 %). (3) Las **materias (el "contenido legible") están casi ausentes**:
0 % de los proyectos presentados y 3 % de los votos-con-proyecto traen alguna materia
— la fuente las entrega vacías casi siempre (hueco de origen ya conocido, aquí
cuantificado). (4) La **tasa de asistencia tiene denominador heterogéneo** [43, 61]
sesiones por diputado (mediana 43); **85/155 no llegan a las 61 celebradas** —
comparar tasas entre diputados es entre denominadores distintos (reemplazos/ingresos
a mitad de período). (5) 39 es **internamente consistente** (0 discrepancias, 0
huérfanos): los bugs, si los hay, están aguas arriba, no en la consolidación.

**Hallazgo de reproducibilidad (perseguido a partir de una discrepancia):** el
intermedio on-disk `40_salidas/intermedios/asistencia.rds` (máx 58 sesiones, mtime
2026-07-10 11:58) **NO corresponde** al `docs/data` publicado (máx 61, `generado`
16:13): los **155/155** perfiles difieren en `n_sesiones`. `votos.rds` sí coincide
con lo publicado (los 27 974 votos-null cuadran). Como los intermedios están
gitignored, reflejan la última corrida LOCAL, desincronizada del publish commiteado
(residuo de corridas de prueba en este working tree). Implicancia: correr hoy
`run_all(only=39)` —la verificación de reproducibilidad documentada— **republicaría
con la asistencia stale**, cambiando las tasas publicadas. No es un bug de la lógica
de 39 (que es consistente), sino un estado local inconsistente. # REVISAR (del titular).

## FASE 3 — El frontend: qué consume y cómo degrada

`docs/index.html` (1078 líneas). **Consume** del JSON: id, nombre, sexo, partido,
partido_nombre, **distrito, region**, tendencia, tasa_asistencia, n_proyectos,
n_votaciones, n_sesiones, n_asiste, n_no_asiste, resumen_por_sentido, votos, boletin,
resultado, sentido, descripcion, proyecto, materias, tipo_iniciativa, fecha_ingreso,
admisible, rol. **No consume** (producido y no mostrado): `fecha_nacimiento`,
`partido.alias`, `votacion_id` (interno). = trabajo del pipeline sin destino en la UI.

**Lo que promete y no cumple (la peor brecha):** el frontend tiene una columna
**"Región / Distrito"** y un **filtro de Región**, pero los datos son 100 % nulos:
- L679: encabezado `<span class="th col-region">Región / Distrito</span>`.
- L718: la celda siempre renderiza `<span class="sin-dato">Sin dato</span>`.
- L478: `if(state.region && state.region!=='__sindato__') return false;` → elegir una
  región concreta **filtra a TODOS** (lista vacía).
- L737-738: mensaje de vacío "Ningún diputado o diputada tiene la región X registrada".

**Pero degrada HONESTAMENTE y está documentado como hueco conocido:**
- L312-314 (comentario): "El filtro Región queda preparado: la fuente actual no
  expone region/distrito (ver CLAUDE.md, huecos conocidos)".
- Ante null NUNCA muestra "null"/"undefined" al usuario: usa `|| '—'` (L836, L842,
  L880, L887) y "Sin dato". Los tokens `null` (10) y `undefined` (1) están solo en el
  JS, no en la vista.

Veredicto Fase 3: la UI no miente con "null", pero la **segmentación por territorio
del propósito es no funcional** (columna 100 % "Sin dato" + filtro que devuelve
vacío para cualquier región real). Es una promesa del objetivo declarado que el
frontend expone como control pero no puede cumplir con los datos actuales.

## FASE 4 — Lo no cubierto: ¿vale la pena?

### 4a. Comisiones (`WSComision/*`)
- `retornarComision(prmComisionId)` expone **`Integrantes/DiputadoIntegrante/Diputado/Id`**
  (miembros actuales) + `IntegrantesHistorico` + `PresidentesHistorico` + `Presidente`,
  todos con **id de diputado estable** (cruzable al roster). Muestra:
  `camara_retornarComision_muestra.xml`.
- Con esto se podría construir: "¿en qué comisiones está el diputado X?", rol
  (integrante/presidente), y trayectoria en comisiones. **Esfuerzo: ~1 script nuevo**
  (iterar comisiones vigentes, invertir Integrantes→diputado).
- `retornarSesionesXComisionYAnno(prmComisionId, prmAnno)`: endpoint existe pero las
  comisiones muestreadas devolvieron **0 sesiones** en 2025/2026 → la **asistencia a
  comisión NO está confirmada** (no verificable con las muestras obtenidas). Requeriría
  más exploración antes de prometerla.

### 4b. Territorio (distrito/región): mapa de fuentes alternativas
El web service de la Cámara NO expone distrito/región por diputado (confirmado en la
auditoría previa). Opciones externas, con evidencia:

| fuente | ¿tiene distrito por diputado? | ¿id cruzable? | acceso automatizado | evidencia |
|--------|-------------------------------|---------------|---------------------|-----------|
| **camara.cl** (fichas, `prmId`) | sí | **PERFECTO** (mismo `Diputado/Id`) | **NO — WAF/403** | 403 en R y WebFetch |
| **SERVEL** (`elecciones.servel.cl`) | sí, autoritativo (28 distritos) | por **nombre** (fuzzy) | descarga no verificada a fondo | búsqueda web |
| **datos.bcn.cl** (SPARQL, "Modelo de congreso") | probable (parlamentarios) | por nombre / URI BCN | **SÍ (SPARQL 200)** | `territorio_bcn_persona_muestra.txt`; predicado de distrito no resuelto en el intento exploratorio (ontología por aprender) |
| **WSComun/retornarDistritos** (propio WS) | NO (catálogo distrito→comuna, sin vínculo diputado) | — | sí | auditoría previa |

**El trade-off del titular:** la única fuente con cruce PERFECTO por id (camara.cl)
está bloqueada a bots; las accesibles (BCN, SERVEL) cruzan por **nombre** (matching
difuso, con el riesgo de homónimos/tildes). No hay una opción que sea a la vez
accesible por máquina Y cruzable por id. (No se decide cuál usar: es del titular.)

## Panel adversarial (auto-auditoría)

**Agente 1 — re-derivación técnica (código independiente, sin ver 31g).** Reconstruyó
el mapa autoritativo desde la fuente (490 boletines, 0 fallas HTTP) y clasificó las
672 por su cuenta. Resultado **idéntico**, sin contradecirme:
- Fase 1: d=460, c=0, a=0, b=212 (suma 672); 0 boletines del regex sin resolver.
- Trazabilidad: 84 927 votos, 27 974 null = **32,94 %**, mediana por perfil 35,06 %.
- Consistencia índice↔perfiles: **0/155**.

Confirma la partición limpia (las 460 con boletín todas verificadas; las 212 sin
boletín ninguna recuperada). El panel técnico **no encontró error**; su valor fue
descartar, con código independiente, que hubiera datos erróneos/incompletos ocultos.

**Agente 2 — el ciudadano adversarial.** Recorrió el portal como fiscalizador y listó
16 preguntas razonables, clasificando la causa de cada hueco. Lo que SÍ responde hoy:
asistencia (tasa/conteos), partido/tendencia/sexo, nº de proyectos y votos,
distribución del voto, y filtros por partido y tendencia. Lo que NO, por causa:

- **(a) hueco de fuente:** ¿quién representa a mi comuna/distrito? ¿en qué región
  vota? (distrito/region null); estado de tramitación de sus proyectos; ¿es autor o
  solo adhirió? (`rol="firmante"` para todos); ¿cambió de partido? (sin historial);
  ¿cuántos años lleva? (sin períodos previos).
- **(b) gap de cobertura (dato en la fuente, no en el JSON):** ¿en qué **comisiones**
  trabaja? (la Cámara lo expone); ¿faltó con o sin **justificación**? (la fuente la da
  —auditoría previa—, el pipeline la descarta); evolución de asistencia por sesión.
- **(c) gap de presentación (dato en el JSON, no en la UI):** el más claro es el
  **recorte a 16 votos** (el perfil trae cientos); la UI expone el resto con honestidad.
- **(d) gap de diseño (dato presente, no responde la pregunta):** ¿asiste más o menos
  que el **promedio de su partido/Cámara**? (calculable, no computado); buscar votos
  **por tema**; ¿presentó un proyecto y luego lo **votó**? (autor→voto, ambos en el
  perfil, sin cruzar); disciplina partidaria.

Lectura del agente: los huecos (a) no son culpa del portal; **la fruta más al alcance
es (d)** —vistas nuevas sobre datos que ya están— y luego (b) comisiones/justificación
—que dependen solo del pipeline—. La presentación (c) está sana salvo el recorte a 16.

**Lo que el panel me aportó/corrigió:** el agente ciudadano cuantificó la casi total
ausencia de **materias** (verificada: 0 %/3 %) y el recorte a 16 votos, que yo no
había medido. Y perseguir una discrepancia de asistencia (máx 58 vs 61) destapó el
**desync intermedio↔publicado** (§Fase 2) — un hallazgo que no estaba en el plan del
encargo y que toca producción (reproducibilidad).

## TABLA FINAL DE BRECHAS

Ordenada por impacto sobre el propósito declarado. Sin recomendaciones (decide el titular).

| # | brecha | evidencia (cifra + ruta) | causa | ¿bloquea el propósito? | ¿toca producción? |
|---|--------|--------------------------|-------|------------------------|-------------------|
| 1 | **Segmentación por región/distrito** no funcional | 155/155 nulos (`docs/data`); columna+filtro en `index.html` L679/L478/L718 | **fuente** (hueco de origen) | **SÍ** (segmentación explícita en el objetivo) | no |
| 2 | **~1/3 de los votos ilegibles** (sin proyecto) | 27 974/84 927 = 32,9 % (`docs/data`); Fase 1 (b)=212 | **fuente** (212 son Resolución/Acuerdo/Otros, sin proyecto de ley) | parcial (para Proyectos de Ley se cumple 100 %; el resto no tiene proyecto que mostrar) | no |
| 3 | **Materias (contenido temático) casi ausentes** | 0/1311 proyectos, 1737/56 953 votos (3 %) | **fuente** (materias vacías) | parcial (limita "qué votó sobre X tema") | no |
| 4 | **Asistencia sin nominal/sesión, sin fecha, sin justificación** | fuente SÍ los da (auditoría cobertura); 33 agrega; denominador [43,61] | **pipeline** | no (la tasa se muestra) — limita "¿faltó justificado?" y comparabilidad | no |
| 5 | **Votos recortados a 16 en la UI** | `index.html` L816-817 ("muestra de 16 de N"); JSON trae todos | **frontend/diseño** | parcial ("verificar un voto puntual") | no |
| 6 | **Intermedio `asistencia.rds` desincronizado del publish** | 155/155 perfiles difieren; mtimes 11:58 vs 16:13 | **estado local / ops** | no | **SÍ** (`run_all(only=39)` republicaría stale) |
| 7 | **Comisiones: entidad no cubierta** | `retornarComision` trae Integrantes con `Diputado/Id` (`camara_retornarComision_muestra.xml`) | **pipeline** | no (no está en el objetivo mínimo) | no |
| 8 | **Comparativas no diseñadas** (asistencia vs promedio; autor→voto) | datos presentes en JSON; 0 hits "promedio" en HTML (agente ciudadano #3, #9) | **diseño** | no (excede el mínimo) | no |
| 9 | **Estado de tramitación / rol autor / historial de partido** | huecos de fuente confirmados (`estado_...=false` 155/155; `rol="firmante"`) | **fuente** | parcial | no |
| 10 | **Campos producidos y no mostrados** (`fecha_nacimiento`, `partido.alias`) | Fase 3 (no referenciados en el HTML) | **frontend** | no (trabajo desperdiciado, no brecha de propósito) | no |

Nota sobre el propósito: de lo prometido (asistencia, proyectos presentados,
proyectos votados + sentido, perfil; segmentación por cámara/partido/tendencia/
región-distrito), **todo se entrega salvo la segmentación por región/distrito**
(brecha #1, hueco de fuente) y con la salvedad de que "qué votó" cubre 100 % de los
Proyectos de Ley pero no las Resoluciones/Acuerdos (que no tienen proyecto).
