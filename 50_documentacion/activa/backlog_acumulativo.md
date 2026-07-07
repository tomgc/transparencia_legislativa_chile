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
intencion primaria. Fuente del conteo: traspasos y log de la sesion.

## Clasificacion tematica

| Categoria | N | Descripcion / ejemplo |
|-----------|---|-----------------------|
| infraestructura | 1 | scaffold, estructura canonica, utils, config |
| extraccion de datos | 2 | pipeline de extraccion de la Camara (31-35); corrida del anno completo |
| consolidacion/salida | 1 | fusion a JSON (39) + orquestador |
| documentacion | 2 | README, CLAUDE.md, doc tecnica, exploracion API; precision del invariante R-only |
| decision metodologica | 2 | mapa partido->tendencia (diferido en v01, poblado en v02) |
| **Total** | **8** | |

## Resumen estadistico por sesion

| Sesion | Traspasos | N cambios | Modelo | Foco |
|--------|-----------|-----------|--------|------|
| 1 | v01 | 5 | Opus 4.8 | scaffold + pipeline Camara |
| 2 | v02 | 3 | Opus 4.8 | invariante R-only + tendencia + anno completo |
| Total | | 8 | | |

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

## Delta del backlog

- **v01:** primer backlog, 5 entradas nuevas (1-5), taxonomia inicial propuesta.
- **v02:** 3 entradas nuevas (6-8). Refinamiento de conteos de la taxonomia
  (extraccion de datos 1->2, documentacion 1->2, decision metodologica 1->2);
  sin reclasificaciones ni renumeracion de entradas previas.
