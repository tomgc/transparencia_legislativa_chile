# Backlog acumulativo — transparencia_legislativa_chile

> Memoria de largo plazo del proyecto (POLITICA §10, SETTINGS §2.2.5). En cada
> cierre se copia integro y se agregan las entradas nuevas al final; jamas se
> reescriben, resumen ni renumeran entradas anteriores. Numeracion global
> permanente. Extraido a este archivo en el segundo cierre (sesion 2); en el
> primer cierre (v01) vivia embebido en el traspaso.

## Objetivo del proyecto

Portal de transparencia legislativa del Congreso de Chile, serverless, alojado
en GitHub Pages. R consolida datos publicos del Congreso en JSON estaticos que
un dashboard estatico visualiza en el navegador, sin backend. El dashboard
prioritario muestra, por parlamentario: asistencia a sesiones, proyectos
presentados, proyectos votados y sentido del voto, y perfil. Segmentaciones:
camara, partido, tendencia, region/distrito. Producido con R (Positron) desde
2026. Fase 1 cubre solo la Camara de Diputadas y Diputados; el alcance objetivo
del proyecto es el Congreso completo (Camara + Senado), reconocido en sesion 4
(entrada 19), pendiente de disenar.

## Nota metodologica

Un "cambio" es una solicitud distinguible del titular (no las acciones tecnicas
que la implementan). No cuentan los errores del asistente corregidos de
inmediato; si cuentan los bugfixes reportados por el titular. Clasificacion por
intencion primaria. Fuente del conteo: traspasos y logs de la sesion.

## Clasificacion tematica

| Categoria | N | Descripcion / ejemplo |
|-----------|---|-----------------------|
| infraestructura | 3 | scaffold, estructura canonica, utils, config; fix de la clave de cache (tope); corte temporal explicito (CORTE_FECHA) |
| extraccion de datos | 3 | pipeline de extraccion de la Camara (31-35); corrida del anno completo; detalle de proyectos (36) |
| consolidacion/salida | 2 | fusion a JSON (39) + orquestador; enriquecimiento de perfiles (contenido + trazabilidad) |
| interfaz/dashboard | 2 | dashboard estatico Fase 2; enriquecimiento visual (metricas, materias, voto->proyecto) |
| diagnostico/exploracion | 4 | diagnostico insumos-first del contenido legible y del join voto->proyecto; exploracion API Senado v02 (backend con ids estables); asistencia nominal por sesion (H1-bis); esquema de la Camara y contrato de datos comun |
| documentacion | 2 | README, CLAUDE.md, doc tecnica, exploracion API; precision del invariante R-only |
| decision metodologica | 3 | mapa partido->tendencia (diferido en v01, poblado en v02); tres decisiones de arquitectura del pipeline del Senado (extendido + normalizacion, asistencia simetrica, clave compuesta con fecha capturada) |
| integracion/repo | 3 | integracion de las tres ramas a main + reconciliacion de 36; migracion a GitHub (repo publico + Pages); primer refresh real en produccion |
| automatizacion | 1 | workflow de GitHub Actions para refresh semanal con gate de conteos |
| decision de alcance | 1 | Congreso completo (Camara + Senado) como objetivo real del proyecto |
| **Total** | **23** | |

## Resumen estadistico por sesion

| Sesion | Traspasos | N cambios | Modelo | Foco |
|--------|-----------|-----------|--------|------|
| 1 | v01 | 5 | Opus 4.8 | scaffold + pipeline Camara |
| 2 | v02 | 3 | Opus 4.8 | invariante R-only + tendencia + anno completo |
| 3 | v03 | 6 | Opus 4.8 | dashboard Fase 2 + contenido legible + fix cache + integracion |
| 4 | v04 | 5 | Opus 4.8 | corte temporal + migracion GitHub + Actions + primer refresh |
| 5 | v05 | 0 | Opus 4.8 | diseno: evaluacion diagnostico Senado v01 + encargo v02 |
| 6 | v06 | 4 | Opus 4.8 | diseno: fuente del Senado confirmada + arquitectura + contrato |
| Total | | 23 | | |

## Detalle cronologico (numeracion global permanente)

### Sesion 1 (v01) — scaffold + pipeline Camara
1. Scaffold Rama A: estructura canonica, utils (cliente HTTP, cache, helpers),
   config con constantes y dominios.
2. Instrumentacion de la API de la Camara: firma real descubierta y documentada.
3. Extraccion de roster, asistencia, votaciones y proyectos (32-35).
4. Consolidacion JSON (indice + 155 perfiles) y orquestador run_all (39, 00).
5. Cierre: log, traspaso v01, ESTADO.

### Sesion 2 (v02) — invariante R-only + tendencia + anno completo
6. Precision del alcance del invariante R-only en CLAUDE.md: aplica al pipeline
   Y a toda verificacion/auditoria/script auxiliar (cierra la ambiguedad del
   traspaso v01 §15 error 2). Commit `2ddd754`.
7. Clasificacion de tendencia de los 18 partidos del roster, fijada por el
   titular con taxonomia de 5 niveles (izquierda / centroizquierda / centro /
   centroderecha / derecha); IND queda NA por no ser partido. Puebla
   `MAPA_PARTIDO_TENDENCIA`. Commit `a11b3fb`. (Resuelve el diferido de la
   entrada 5 / pendiente de v01.)
8. Corrida del anno completo (topes de extraccion a Inf) y regeneracion del
   JSON con la tendencia propagada: 672 votaciones y 218 mociones (vs 120/150
   en sesion 1); 155 perfiles regenerados. Commit `48e158c`. Detecto un
   # REVISAR nuevo: la clave de cache no codifica el tope.

### Sesion 3 (v03) — dashboard Fase 2 + contenido legible + fix cache + integracion

#### Dashboard (Fase 2)
9. Construccion del dashboard estatico `docs/index.html` (HTML/CSS/JS vanilla,
   sin CDN, carga perezosa, hash routing, hemiciclo por tendencia con grupo IND
   explicito, filtros e vista de perfil), a partir de un mockup de Claude Design.
   Incluye: metricas resumen en el indice (`39`), publicacion del JSON a
   `docs/data/`, fuentes autohospedadas. Rama `feature/dashboard-fase2` (5 commits).
10. Enriquecimiento del indice con `partido_nombre` y `sexo`, eliminacion de la
    constante `PARTIDO_NOMBRES` embebida en JS, y subtitulo de genero real por
    fila con fallback neutro. Salda dos deudas del dashboard.

#### Contenido legible y trazabilidad
11. Diagnostico insumos-first (rama `explore/...`): descubrio que
    `retornarProyectoLey` expone `tipo_iniciativa` y `materias` (que 35
    descartaba) y un join estructurado voto->proyecto via `VotacionProyectoLey/Id`;
    cobertura del join 460/460 en Proyecto de Ley; el 31,5% sin boletin es
    estructural. Documento + muestras reales.
12. Contenido legible + trazabilidad (rama `feature/contenido-legible-trazabilidad`):
    nuevo paso 36 (detalle de proyectos autorados + votados), `39` enriquece
    `proyectos[]` (tipo_iniciativa, materias) y `votos[]` (sub-objeto `proyecto`
    anidado o null + tipo del voto), y el frontend muestra materias como chips y
    el titulo real del proyecto votado. Materias vacias = "Sin materias registradas"
    explicito, nunca fabricado.

#### Deuda tecnica e integracion
13. Fix de la clave de cache (rama `fix/cache-key-tope`): `con_cache` codifica el
    tope de extraccion (`sufijo_tope`: `_tope-inf` / `_tope-<n>`); los tres
    call-sites (33/34/35) pasan su tope; snapshots de produccion migrados a
    `_tope-inf`. Resuelve el # REVISAR de la entrada 8 (reutilizacion silenciosa
    con tope distinto el mismo dia). Emergio que el date-stamping (`Sys.Date()` en
    la clave) sigue siendo el limite entre dias — nuevo # REVISAR central.
14. Integracion de las tres ramas a main (`71ff7c3`): merges `--no-ff` en orden
    cache-fix -> contenido-legible -> explore, con reconciliacion semantica del
    paso 36 (que llamaba `con_cache` sin tope; se le puso `tope = Inf`, el valor
    honesto porque 36 no aplica cap propio). Verificacion end-to-end: only=39
    reproduce los perfiles identicos salvo timestamp; produccion intacta. main
    queda como fuente unica. Versionado de los logs de la jornada.

### Sesion 4 (v04) — corte temporal + migracion GitHub + Actions + primer refresh

#### Corte temporal explicito
15. Corte temporal explicito (`CORTE_FECHA`): nueva constante string `AAAA-MM-DD`
    sin default silencioso y funcion `corte_para_clave()` que valida formato y
    hace `stop()` claro si falta/vacia/invalida; `con_cache` la usa en vez de
    `Sys.Date()`; `run_all()` valida el corte al inicio, no a mitad de pipeline.
    Resuelve el # REVISAR central de la entrada 13 (el date-stamping como limite
    silencioso entre dias). Se fijo un corte canonico unico `2026-07-06` para
    todo el dataset, renombrando solo el snapshot de detalle (enriquecimiento
    estable, no datos nuevos) a ese corte para dar cache-hit total (D1).
    Commits `3765dbf`, `e1af2b9`. Ejecutado por Claude Code
    (encargo `encargo_corte_temporal_v01.md`).

#### Migracion a GitHub
16. Migracion a GitHub: repo creado y sincronizado; visibilidad pasada a publica
    (`gh repo edit --visibility public`) porque Pages sobre repos privados
    requiere plan pago y el proyecto es 100% publico por naturaleza (Rama A);
    Pages activado sirviendo `/docs` en `main`. Dashboard operativo en
    `https://tomgc.github.io/transparencia_legislativa_chile/`. La auditoria de
    seguridad pre-migracion la hizo el titular manualmente; se salto la ejecucion
    del script `diagnostico_migracion_github.R`, excepcion explicita y documentada
    (D4), decision del titular. Comandos ejecutados en terminal por el titular.

#### Automatizacion
17. Workflow de GitHub Actions para refresh semanal
    (`.github/workflows/refresh-semanal.yml`): dos disparadores (`cron` lunes
    11:00 UTC + `workflow_dispatch`); pasos de checkout, instalar R + 7 paquetes
    via RSPM, calcular corte del dia, copiar el JSON del checkout como "anterior"
    (no respaldo persistente — adaptacion del invariante al runner), inyectar el
    corte via `sed` sobre `10_configuracion.R` (D2, para que el cambio quede
    trazable en el commit), `run_all()`, gate de conteos y commit+push
    condicional con `GITHUB_TOKEN` automatico. `10_diff_conteos.R` extendido
    (aditivo) para retornar `$gate`/`$motivos`: falla si `perfiles < 155` o si
    cae `perfiles/votaciones/mociones/votos_con_proyecto`; `votos_sin_proyecto`
    se reporta pero no gatea (D3). Gate probado en ambos sentidos con exit codes
    reales sin pipe. Commits `07a2852`, `c950e5b`, `0fe8803`. Ejecutado por
    Claude Code (encargo `encargo_github_actions_v01.md`).

#### Primer refresh en produccion
18. Merges `--no-ff` de las dos ramas de feature a main (`736e7e9`, `deab646`)
    con revision del diff completo por el titular antes de cada merge, y primer
    disparo del workflow en produccion via `workflow_dispatch`: corrida real de
    9m50s, `GATE OK`, commit automatizado `95dedbc` confirmado en `origin/main`.
    Cierra los cinco pendientes de v03 relacionados con actualizacion e
    infraestructura. El disparo por cron aun no se observa en vivo (pendiente 8).

#### Decision de alcance
19. Decision de alcance: el titular corrigio que el objetivo real del proyecto es
    el Congreso completo (Camara + Senado), no solo la Camara. No se diseno ni
    construyo en esta sesion; queda como pendiente de diseno dedicado
    (pendiente 7), a abordar con sesion de diseno conversacional propia antes de
    cualquier construccion.

### Sesion 6 (v06) — diseno: fuente del Senado confirmada + arquitectura + contrato

#### Exploracion de la fuente del Senado
20. Exploracion API Senado v02 (rama `explore/api-senado-v02`, encargo autonomo):
    descubrio el backend `web-back.senado.cl/api/` detras del sitio senado.cl, con
    **identificador estable de parlamentario** (`ID_PARLAMENTARIO`/`PARLID`)
    consistente en roster, asistencia y votos. Resuelve los tres huecos de v01:
    roster real de 50 (`api/parlamentarios?vigentes=1`, filtrando `CAMARA=="S"`; el
    31 de v01 era artefacto de un endpoint viejo), votaciones con detalle nominal
    agrupado por sentido y con `BOLETIN` para el join a proyecto, y elimina el fuzzy
    name matching que v01 daba por inevitable. Establecio que `opendata.congreso.cl`
    NO es una API nueva sino un portal de documentacion que reenvia a `wspublico`
    (desinfla el pendiente 11). Proyectos siguen viniendo de wspublico
    (`tramitacion.php`), que el backend no cubre. Commits `94200b6`, `0f7c081`,
    `ecac959`.
21. Asistencia nominal por sesion del Senado (H1-bis, rama
    `explore/api-senado-v02-asistencia`, encargo autonomo): nacio de cuestionar una
    conclusion de la entrada 20 antes de darla por buena. Veredicto: la asistencia
    nominal por sesion SI existe. El endpoint es **polimorfico**:
    `api/sessions/attendance?id_legislatura=<id>` da el agregado (lo que v02 mapeo),
    `api/sessions/attendance?id_sesion=<id>` da el detalle nominal (Asiste/Ausente +
    justificacion, por senador, con id estable). Universo de sesiones via
    `api/sessions?id_legislatura=<id>`. Hallazgo colateral: **membresia dependiente
    del tiempo** (una sesion de mar-2025 cruza 31/50 con el roster vigente porque 19
    senadores salieron en la renovacion de mar-2026); la asistencia debe unirse al
    roster as-of la fecha de la sesion. Commits `ccbf0a7`, `c4c61c7`, `16b40f5`.

#### Contrato de datos
22. Esquema real de la Camara + propuesta de contrato comun + pares de partido del
    Senado (rama `design/contrato-datos`, encargo autonomo): documento el esquema
    efectivo de los cinco intermedios de la Camara (del codigo Y de los `.rds`
    reales) y del JSON de `39`; propuso una tabla canonica por entidad con `camara`
    como discriminador; y extrajo los 14 partidos reales del Senado (50 senadores)
    como insumo del crosswalk. **Dos hallazgos que derogaron supuestos vigentes:**
    (a) `diputado_id` de la Camara y `ID_PARLAMENTARIO` del backend son **espacios de
    ids distintos** (solo 11/155 coincidencias, casuales) → la clave comun debe ser
    compuesta `(camara, parlamentario_id)`; (b) el `33` de la Camara **NO persiste el
    detalle de asistencia por sesion** (lo agrega a tasa y descarta `sesion_id`/fecha)
    pese a que la fuente si lo entrega → el contrato simetrico exige extender el
    extractor de la Camara. Dejo 8 preguntas abiertas. Commits `276210e`, `0473ba8`.

#### Arquitectura
23. Tres decisiones de arquitectura del pipeline del Senado, fijadas por el titular:
    **D1** pipeline extendido con capa de normalizacion (no duplicado), porque el
    backend entrega un roster unificado de ambas camaras; **D2** contrato de
    asistencia simetrico (nominal por sesion en ambas camaras), habilitado por la
    entrada 21, con el costo reconocido de tener que extender el extractor de la
    Camara (hallazgo (b) de la entrada 22); **D3** identidad por clave compuesta
    `(camara, parlamentario_id)` capturando `id_sesion` + fecha en la extraccion, con
    la resolucion de roster as-of diferida al modulo biblioteca historica
    (pendiente 10). NO se construyo pipeline.

## Delta del backlog

- **v01:** primer backlog, 5 entradas nuevas (1-5), taxonomia inicial propuesta.
- **v02:** 3 entradas nuevas (6-8). Refinamiento de conteos de la taxonomia
  (extraccion de datos 1->2, documentacion 1->2, decision metodologica 1->2);
  sin reclasificaciones ni renumeracion de entradas previas.
- **v03:** 6 entradas nuevas (9-14). Taxonomia ampliada con tres categorias
  nuevas (interfaz/dashboard, diagnostico/exploracion, integracion/repo) para
  reflejar el trabajo de la sesion 3; conteos actualizados (infraestructura
  1->2, extraccion 2->3, consolidacion 1->2). Sin renumeracion ni reescritura de
  entradas 1-8.
- **v04:** 5 entradas nuevas (15-19). Taxonomia ampliada con dos categorias
  nuevas (automatizacion, decision de alcance); conteos actualizados
  (infraestructura 2->3, integracion/repo 1->3). Objetivo del proyecto
  actualizado para reconocer el alcance Congreso completo (entrada 19). Sin
  renumeracion ni reescritura de entradas 1-14.
- **v05:** 0 entradas nuevas. Sesion de diseno sin cambios contables segun la nota
  metodologica (evaluacion del diagnostico v01 del Senado y preparacion del encargo
  v02); nacieron dos pendientes de diseno (modulo biblioteca historica, barrido de
  opendata) que viven en el traspaso, no en el backlog.
- **v06:** 4 entradas nuevas (20-23). Conteos actualizados (diagnostico/exploracion
  1->4, decision metodologica 2->3). Sin categorias nuevas. Sin renumeracion ni
  reescritura de entradas 1-19. Nota: la entrada 20 desinfla el pendiente 11
  (opendata.congreso.cl resulto ser un portal de documentacion, no una fuente).
