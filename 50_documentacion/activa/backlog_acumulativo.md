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
2026. Fase 1 cubre solo la Camara de Diputadas y Diputados.

## Nota metodologica

Un "cambio" es una solicitud distinguible del titular (no las acciones tecnicas
que la implementan). No cuentan los errores del asistente corregidos de
inmediato; si cuentan los bugfixes reportados por el titular. Clasificacion por
intencion primaria. Fuente del conteo: traspasos y logs de la sesion.

## Clasificacion tematica

| Categoria | N | Descripcion / ejemplo |
|-----------|---|-----------------------|
| infraestructura | 2 | scaffold, estructura canonica, utils, config; fix de la clave de cache (tope) |
| extraccion de datos | 3 | pipeline de extraccion de la Camara (31-35); corrida del anno completo; detalle de proyectos (36) |
| consolidacion/salida | 2 | fusion a JSON (39) + orquestador; enriquecimiento de perfiles (contenido + trazabilidad) |
| interfaz/dashboard | 2 | dashboard estatico Fase 2; enriquecimiento visual (metricas, materias, voto->proyecto) |
| diagnostico/exploracion | 1 | diagnostico insumos-first del contenido legible y del join voto->proyecto |
| documentacion | 2 | README, CLAUDE.md, doc tecnica, exploracion API; precision del invariante R-only |
| decision metodologica | 2 | mapa partido->tendencia (diferido en v01, poblado en v02) |
| integracion/repo | 1 | integracion de las tres ramas a main + reconciliacion de 36 |
| **Total** | **14** | |

## Resumen estadistico por sesion

| Sesion | Traspasos | N cambios | Modelo | Foco |
|--------|-----------|-----------|--------|------|
| 1 | v01 | 5 | Opus 4.8 | scaffold + pipeline Camara |
| 2 | v02 | 3 | Opus 4.8 | invariante R-only + tendencia + anno completo |
| 3 | v03 | 6 | Opus 4.8 | dashboard Fase 2 + contenido legible + fix cache + integracion |
| Total | | 14 | | |

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
