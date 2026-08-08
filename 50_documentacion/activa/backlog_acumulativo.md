# Backlog acumulativo — transparencia_legislativa_chile

> Memoria de largo plazo del proyecto (POLITICA §10, SETTINGS §2.2.5). En cada
> cierre se copia integro y se agregan las entradas nuevas al final; jamas se
> reescriben, resumen ni renumeran entradas anteriores. Numeracion global
> permanente. Extraido a este archivo en el segundo cierre (sesion 2); en el
> primer cierre (v01) vivia embebido en el traspaso.
>
> **Nota de consolidacion diferida (sesion 12, 2026-07-25).** Este archivo estuvo
> cerrado en v06 (entradas 1-23) durante cinco sesiones. Las sesiones 7 a 11 se
> incorporan aqui de una vez, en la sesion 12, a partir de sus fuentes:
> `backlog_entradas_sesion_7.md` (entradas 24-26, ya numeradas ahi y copiadas
> verbatim) y los traspasos `v08`, `v09`, `v10` y `v11` (§4 y §5 de cada uno). La
> deuda de memoria queda saldada: no hay sesiones pendientes de incorporar. El
> archivo de trabajo `backlog_entradas_sesion_7.md` queda superado por esta
> consolidacion y se retira del canonico en el mismo commit que la incorpora
> (su contenido vive aqui y su historia, en Git).

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

| Categoria | N | % | Descripcion / ejemplo |
|-----------|---|---|-----------------------|
| infraestructura | 6 | 11,8 | scaffold, estructura canonica, utils, config; fix de la clave de cache (tope); corte temporal explicito (CORTE_FECHA); sello de procedencia de los intermedios; arreglo del sello desalineado de los intermedios (P-62); guarda de autorregeneracion en el orquestador (P-65) |
| extraccion de datos | 6 | 11,8 | pipeline de extraccion de la Camara (31-35); corrida del anno completo; detalle de proyectos (36); Capa 2 territorial (crosswalk + join en el 32); Capa 3 de asistencia simetrica (serie nominal, justificacion, dos ambitos); retiro del bloque legacy del 33 y de su descarga duplicada |
| consolidacion/salida | 3 | 5,9 | fusion a JSON (39) + orquestador; enriquecimiento de perfiles (contenido + trazabilidad); retiro del contrato legacy de asistencia del JSON publicado |
| interfaz/dashboard | 5 | 9,8 | dashboard estatico Fase 2; enriquecimiento visual (metricas, materias, voto->proyecto); toggle del historial de votos; celda de region que lee el dato; frontend de la Capa 3 de asistencia en la ficha (dos ambitos, sin_registro, tabla de sesiones) |
| diagnostico/exploracion | 10 | 19,6 | diagnostico insumos-first del contenido legible y del join voto->proyecto; exploracion API Senado v02 (backend con ids estables); asistencia nominal por sesion (H1-bis); esquema de la Camara y contrato de datos comun; auditoria adversarial de cobertura del web service de la Camara; diagnostico de brecha entre proposito declarado y entregado; cierre de P-56 (el `+0` entre cortes es real); comprobacion de la republicacion de Pages por identidad de md5; medicion del conflicto entre los dos PRs abiertos; auditoria de fuentes Camara/Senado con panel adversarial (P-61) |
| documentacion | 7 | 13,7 | README, CLAUDE.md, doc tecnica, exploracion API; precision del invariante R-only; consolidacion del backlog de las sesiones 7 a 11; correccion de la glosa del frontend que citaba el campo retirado; cierre de P-52 (auditoria de apertura #3); encargo de auditoria de fuentes Camara/Senado; ampliacion de ese encargo al eje tematico (P-61 v2) |
| decision metodologica | 3 | 5,9 | mapa partido->tendencia (diferido en v01, poblado en v02); tres decisiones de arquitectura del pipeline del Senado (extendido + normalizacion, asistencia simetrica, clave compuesta con fecha capturada) |
| integracion/repo | 7 | 13,7 | integracion de las tres ramas a main + reconciliacion de 36; migracion a GitHub (repo publico + Pages); primer refresh real en produccion; versionado de la memoria estructural del proyecto; merge y publicacion de la Capa 2 territorial; exclusion de la configuracion local del asistente del versionado (P-55); resolucion por hunk de los dos PRs abiertos y publicacion del contrato depurado (P-58) |
| automatizacion | 3 | 5,9 | workflow de GitHub Actions para refresh semanal con gate de conteos; timeout declarado a nivel de job; el bot commitea en rama y abre PR (main deja de recibir escrituras automaticas) |
| decision de alcance | 1 | 2,0 | Congreso completo (Camara + Senado) como objetivo real del proyecto |
| **Suma de la columna** | **51** | **100,1** | |

> **Discrepancia heredada, no resuelta aqui.** La tabla vigente hasta v06
> declaraba un total de 23 y su columna de N sumaba 24. Esa diferencia de una
> unidad se arrastra: hoy la columna suma 51 mientras las entradas numeradas del
> detalle cronologico son 50 (1-50). No se resuelve aqui porque resolverla exige
> reclasificar alguna de las entradas 1-23, y el protocolo prohibe reescribir o
> reclasificar entradas anteriores en silencio (§2.2.5). Los porcentajes se
> calculan sobre la suma de la columna (51); suman 100,1 por redondeo a un decimal,
> no por una entrada sobrante (recuento de la sesion 16, pendiente de verificacion
> programatica al integrar).
> Pendiente declarado: auditar la clasificacion de las entradas 1-23 contra los
> traspasos v01-v06 y corregir con una nota explicita.

## Resumen estadistico por sesion

| Sesion | Traspasos | N cambios | Modelo | Foco |
|--------|-----------|-----------|--------|------|
| 1 | v01 | 5 | Opus 4.8 | scaffold + pipeline Camara |
| 2 | v02 | 3 | Opus 4.8 | invariante R-only + tendencia + anno completo |
| 3 | v03 | 6 | Opus 4.8 | dashboard Fase 2 + contenido legible + fix cache + integracion |
| 4 | v04 | 5 | Opus 4.8 | corte temporal + migracion GitHub + Actions + primer refresh |
| 5 | v05 | 0 | Opus 4.8 | diseno: evaluacion diagnostico Senado v01 + encargo v02 |
| 6 | v06 | 4 | Opus 4.8 | diseno: fuente del Senado confirmada + arquitectura + contrato |
| 7 | v07 | 3 | Opus 4.8 | auditoria de cobertura + diagnostico de proposito |
| 8 | v08 | 3 | no consta en los insumos | sello de procedencia (P-15) + Capa 1 de presentacion |
| 9 | v09 | 0 | Opus 4.8 | higiene: integracion a main, P-17, P-20, rebase sobre el bot |
| 10 | v10 | 1 | Opus 4.8 | Capa 2 territorio: medicion BCN + crosswalk determinista |
| 11 | v11 | 2 | Opus 4.8 | merge de la Capa 2 a produccion + Capa 3 de asistencia simetrica |
| 12 | v12 | 2 | Opus 5 | consolidacion del backlog + timeout del workflow |
| 13 | v13 | 1 | Opus 5 | P-22: el bot trabaja en rama y abre PR |
| 14 | v14 | 1 | Opus 5 | frontend de la Capa 3 de asistencia |
| 15 | v15 | 9 | Opus 5 | retiro del contrato legacy de asistencia (P-48) + cierres de P-52, P-55 y P-56 |
| 16 | v16 | 5 | Opus 5 | publicacion, auditoria de fuentes y eje tematico |
| Total | | 50 | | |

> Sesion 8: el modelo no consta en `traspaso_cierre_v08.md` ni en los demas
> insumos de esta consolidacion; se deja declarado como ausente en vez de
> inferirlo. Sesiones 9, 10 y 11: se toman del nombre de chat fijado en la
> reapertura del traspaso anterior (`v08` §14, `v09` §14 y `v10` §14).

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

### Sesion 7 (v07) — auditoria de cobertura y diagnostico de proposito

> Entradas 24-26 copiadas verbatim desde `backlog_entradas_sesion_7.md`
> (archivo de trabajo de la sesion 7, incorporado al canonico en la sesion 12).

**24. Versionado de la memoria estructural del proyecto.**
Se detectó que los traspasos v04, v05 y v06, la carpeta `activa/decisiones/`
completa, los tres encargos de la sesión 6, el backlog con sus entradas 20-23 y el
`ESTADO.md` estaban sin versionar: existían únicamente en el working tree local. Se
commitearon a `main` como `fe0e226` (11 archivos, 2.430 inserciones). El hallazgo
surgió al notar que el escáner mostraba el mismo contenido desde dos ramas distintas,
lo que llevó a verificar con `git ls-tree` en lugar de con el escáner. Sin este
commit, un working tree perdido se llevaba tres sesiones de memoria del proyecto.
Categoría: integración / repo.

**25. Auditoría adversarial de cobertura del web service de la Cámara (cierra el pendiente 12).**
Encargo autónomo a Claude Code, solo lectura, en `explore/cobertura-camara`. Se
enumeró el catálogo ASMX completo (5 servicios, 49 operaciones; el pipeline consume
8), se descargó una respuesta real de cada endpoint (usado y no usado) con su muestra
en disco, y se sondearon parámetros y endpoints alternativos. Resultado: ~14 gaps
inventariados con evidencia, más una entidad completa sin cubrir (comisiones).
Confirma y extiende A23: la asistencia no solo entrega el detalle nominal por sesión y
la fecha, sino también la justificación por diputado. El panel adversarial detectó un
falso negativo del propio auditor (había enumerado los campos mirando solo el primer
item de la colección, que era un "Asiste" sin justificación). Confirma A24: la Cámara
estaba efectivamente sub-explorada. Categoría: diagnóstico / exploración.

**26. Diagnóstico de brecha entre el propósito declarado y lo entregado.**
Encargo autónomo a Claude Code, solo lectura, en `explore/diagnostico-proposito`.
Cuatro fases: join autoritativo votación-proyecto contra la fuente (490 boletines
consultados), estado real de lo publicado en `docs/data/`, análisis del frontend, y
mapa de fuentes alternativas de territorio (con búsqueda web). Panel adversarial de
dos agentes (uno técnico, uno "ciudadano adversarial" que recorrió el portal listando
las preguntas que no puede responder). Tres resultados principales: (a) se derogó la
hipótesis de que el regex del script 34 perdiera boletines — las cuatro cifras del
join autoritativo son d=460, c=0, a=0, b=212, de modo que el 31,5% de votaciones sin
boletín es estructural y el traspaso v03 tenía razón; (b) se midieron las brechas de
propósito con cifras (territorio 100% nulo en 155/155 perfiles; 32,9% de votos sin
proyecto legible; 0 de 1.311 proyectos con materia); (c) persiguiendo una discrepancia
menor no solicitada, se destapó un bug activo de reproducibilidad: el intermedio
`asistencia.rds` en disco no corresponde a lo publicado, por lo que `run_all(only=39)`
republicaría el dashboard con datos stale. Categoría: diagnóstico / exploración.

### Sesion 8 (v08) — sello de procedencia (P-15) + Capa 1 de presentacion

**27. Sello de procedencia en los intermedios (cierra el bug P-15).**
Categoría: infraestructura. `escribir_atomico()` se extendió con `hash_origen` para
sellar cada intermedio con `{corte_fecha, anio_proceso, hash_origen, escrito_en}`, y
se agregaron `sellar()`, `hash_origen_de()`, `ruta_cache()`, `leer_sellado()` (exige
sello, `stop()` si falta) y `validar_corte()` (falla si falta el sello, si el corte no
coincide con `CORTE_FECHA` o si los hermanos son incoherentes). Los cinco scripts `3x`
pasan el hash de su caché de origen; el `39` valida antes de cualquier join o
escritura. Cierra el bug que la entrada 26 había destapado: `run_all(only = 39)` podía
republicar el dashboard con un intermedio de otro corte, en silencio, porque los
intermedios están gitignored y el `.rds` en disco reflejaba la última corrida local
(caché del 06) y no el insumo del publish vigente (caché del 10). Verificado con
prueba de falla real (intermedio adulterado, `stop()` diagnóstico que nombra archivo,
corte declarado, corte esperado y acción correctiva) y con doble panel adversarial con
manifiestos md5; `docs/` byte-idéntico tras el encargo. La arqueología de la fase de
diagnóstico corrigió además el valor registrado de `CORTE_FECHA` (2026-07-10, no
2026-07-06 como declaraba v07 §9). Rama `fix/sello-corte-intermedios`, mergeada a
`main` en la sesión 9.

**28. Capa 1 de presentación: toggle del historial de votos.**
Categoría: interfaz/dashboard. `docs/index.html` gana `state.votosExpandidos`
(reseteado por perfil en `syncFromHash`), `LIMITE_COLAPSADO = 16` y un botón
`toggle-votos`; la conjunción `hayMas && expandido` hace imposible que el botón
desaparezca dejando la lista expandida sin poder colapsarla. La lógica del voto sin
proyecto no se tocó (bloque byte-idéntico a `main`). El recorte previo a 16 votos
ocultaba entre el 96 % y el 98 % del historial de **todos** los diputados (máx. 717
votos, mín. 405), no un excedente de unos pocos, e impedía el propósito declarado de
verificar un voto puntual. Verificación: 717 filas en el DOM iguales a
`n_votaciones`, clic real, 9 ms de render, 0 errores de consola. Rama
`feat/presentacion-votos`, mergeada a `main` en la sesión 9.

**29. Capa 1 de presentación: la celda de región lee el dato.**
Categoría: interfaz/dashboard. `docs/index.html` gana `regionPartes()`,
`renderRegionCell()` (tabla) y `renderRegionChip()` (encabezado de ficha, ampliación
respecto del encargo); ambas degradan a "Sin dato" solo si el dato es `null` o vacío.
Antes la celda hardcodeaba el literal, de modo que habría seguido negando el dato
incluso después de que la Capa 2 lo poblara. Cambio invisible en su momento
(155/155 perfiles con territorio nulo) y habilitante de la Capa 2. Verificación: con
dato inyectado en memoria muestra región y distrito; con `null` es byte-idéntico al
literal anterior; escapado sólido. Rama `feat/presentacion-votos`, mergeada a `main`
en la sesión 9.

### Sesion 9 (v09) — higiene: integracion a main, P-17, P-20, rebase sobre el bot

**Sesion sin entradas numeradas (0 cambios de producto).** Segun la nota
metodologica, un cambio es una solicitud distinguible del titular que altera el
artefacto entregado; las operaciones de git de integracion no lo son. La sesion
consolido en `main` todo el trabajo acumulado de las sesiones 7 y 8, que vivia en
ramas y en un working tree sucio: se versiono la memoria estructural pendiente
(`71e4e68`), se mergearon con `--no-ff` las dos ramas de la sesion 8 (`ea4cb40` sello
de corte, `a12007b` Capa 1, infraestructura antes que feature), se saco el Python de
`.claude/launch.json` reemplazandolo por `Rscript` + `servr::httd` (`c17129c`, P-20,
invariante R-only), y se movio `31_explorar_api_camara.R` de `30_procesamiento/` a
`50_documentacion/andamios/` (`4217aa8`, P-17). El push choco con un commit del bot
de refresh semanal (corte 2026-07-13) y se resolvio con rebase limpio sobre el
refresh, dejando `main` local == `origin/main` == `b707c51`; `CORTE_FECHA` avanzo a
2026-07-13. Se borraron tres ramas integradas o muertas, verificadas por `git cherry`
(patch-id) y no por `git diff`. Nacio el pendiente estructural P-22: el cron semanal y
el trabajo manual compiten por `main`.

### Sesion 10 (v10) — Capa 2 territorio: medicion BCN + crosswalk determinista

**30. Capa 2: territorio poblado en los 155 perfiles (cierra el `# REVISAR` del `32`
arrastrado desde la sesion 1).**
Categoría: extracción de datos. Abrió midiendo la fuente antes de diseñar (D5/A28), y
la medición refutó el supuesto vigente: BCN publica `idCamaraDeDiputados`, que es
literalmente el `diputado_id` de la Cámara, de modo que el cruce es determinista por
id (155/155) y no por nombre normalizado, como el diseño previo asumía. El territorio
no está en el grafo RDF (tripletas vestigiales en nodos huérfanos; el join SPARQL da 0
filas) sino en la ficha HTML de reseñas parlamentarias; SERVEL quedó descartado por
venir en un Power BI embebido, no reproducible. Se versionaron dos insumos estáticos
auditados en `20_insumos/territorio/`: el crosswalk `diputado_id→distrito` de 155
filas (con la regla de desambiguación de los 4 ids que BCN reutiliza entre persona
histórica y vigente materializada en las propias filas) y el catálogo
`distrito→region` de 28 filas contra la ley electoral. El `32` reemplazó sus dos
`NA_character_` por dos `left_join` con validación ruidosa: `stop()` nombrando el
`diputado_id` culpable si un reemplazo futuro no está cubierto, más validación de
rango, duplicados y cobertura de región; el territorio nunca degrada a `NA` en
silencio ni se fabrica. El andamio de medición se promovió a generador reproducible
del insumo (fase `gen`, a mano cuando cambie el roster, explícitamente **no** una
etapa de `00_run_all`), y se congela en vez de scrapear cada refresh porque la ficha
BCN es HTML sin contrato de datos. Durante la construcción se corrigió un bug de
encoding transversal: bajo `LC_CTYPE=C` R escapa los literales no-ASCII del propio
script al parsear, de modo que el catálogo salió con `Región de Ñuble` como texto de
los escapes, siendo el archivo UTF-8 válido; el fix corre el generador bajo locale
UTF-8 y marca `Encoding()<-"UTF-8"` en la lectura del `32`. Verificado por panel
adversarial 4/4: 155/155 con distrito y región no nulos, suma de escaños 155, 28
distritos, 16 regiones. Commits `efb479e`, `0f93cb5`, `a03be0a`, `8c0ba3a` en la rama
`feat/territorio-crosswalk`, sin mergear al cierre de la sesión.

### Sesion 11 (v11) — merge de la Capa 2 a produccion + Capa 3 de asistencia simetrica

**31. Merge y publicacion de la Capa 2 territorial.**
Categoría: integración / repo. Cerró el gate que la sesión 10 dejó abierto. Se
verificó empíricamente que el fix de copy del frontend estaba hecho (`830919f`, cero
ocurrencias de `__sindato__` en `docs/index.html`), se versionó el residuo documental
del cierre anterior (`42910a3`) y, con la compuerta de divergencia dando `0 0` tras un
`fetch` inmediatamente previo, se mergeó con `--no-ff` (`ac177be`, 346 archivos) y se
pusheó. Verificación sobre el estado real de `main` antes del push: 155 ocurrencias de
`"distrito"` en el índice y working tree limpio. El territorio quedó en producción,
155/155 con distrito y región. Rama `feat/territorio-crosswalk` conservada.

**32. Capa 3: asistencia simetrica con serie nominal, justificacion y dos ambitos
(implementa D2 de la entrada 23).**
Categoría: extracción de datos. Abrió con la misma disciplina que salvó a la Capa 2:
medición de solo lectura antes de diseñar. La medición refutó el supuesto de D2 **por
exceso**: la fuente entrega un nodo de justificación completo (código, glosa y dos
rebajas) que el `33` descartaba entero, y la serie nominal ya viajaba en el response
que el script descargaba, de modo que extender el extractor no costaba ni una llamada
nueva. El factor limitante no resultó ser el peso sino dos decisiones metodológicas
del titular, tomadas en sesión: dos ámbitos de denominador (`periodo_vigente`, 48
sesiones comunes a los 155 y único comparable entre diputados, y `en_ejercicio`,
propio de cada uno) y dos tasas que comparten denominador (`tasa_presencia` y
`tasa_presencia_o_justificada`), de modo que la diferencia entre ambas es exactamente
el peso de las ausencias justificadas. Las rebajas se persisten y publican pero no
entran en ninguna fórmula mientras la fuente no documente su semántica, verificado por
prueba discriminante. El `33` ganó un bloque nominal con clave de caché propia (8 718
entradas, 310 filas de agregados por ámbito) y la fecha de instalación del período se
lee de la API en cada corte, jamás hardcodeada. El `39` añade al perfil, después de
los cinco campos legacy, el alcance temporal con nota legible, los dos ámbitos y la
serie de sesiones como espejo de los votos, y suma `tasa_presencia` al índice como
último campo para no alterar el orden que el cliente recorre. Se modeló un tercer
estado explícito `sin_registro` porque la matriz no es densa (5 pares diputado-sesión
sin fila en la fuente): nada se imputa. El agregado legacy conserva su propia descarga
como deuda declarada con fecha de vencimiento conocida (muere cuando el frontend
migre), porque derivarlo del barrido nominal habría cambiado cifras publicadas. Cero
campos legacy alterados, verificado 155/155 y por panel adversarial 4/4 con
re-derivación independiente desde la API. Peso de `docs/data/`: +5,85 %. Mergeado a
`main` y publicado en la sesión 12 (`70263cf`).

### Sesion 12 (v12) — consolidacion del backlog + timeout del workflow

**33. `timeout-minutes` declarado en el workflow de refresh semanal.**
Categoría: automatización. La revisión del workflow contra la doble descarga de
asistencia que introdujo la Capa 3 cerró la pregunta de riesgo por medición (un solo
job, barrido duplicado de unos 15 s sobre una corrida de ~9 m 50 s, ninguna parte que
asuma un único barrido), y dejó a la vista que el techo real era el default de
GitHub Actions: 360 min por job, sin `timeout-minutes` declarado en ningún nivel. Ante
un cuelgue de la API el job se arrastraría seis horas antes de fallar. Se declaró
`timeout-minutes: 30` a nivel de job, margen de unas tres veces sobre la duración
medida, para que el fallo sea rápido y legible.

**34. Consolidacion del backlog acumulativo (sesiones 7 a 11) y retiro del archivo de
trabajo.**
Categoría: documentación. El canónico llevaba cerrado en v06 (23 entradas) durante
cinco sesiones, con las entradas 24-26 viviendo en un archivo aparte y las sesiones 8
a 11 sin consolidar. Se incorporaron de una vez y en orden estricto: 24-26 copiadas
verbatim desde `backlog_entradas_sesion_7.md`, 27-29 derivadas de v08, la sesión 9
como nota de sesión con cero entradas numeradas (según su propia declaración: las
operaciones de git no son cambios de producto), 30 de v10 y 31-32 de v11. Se agregó la
columna de porcentaje que exige el protocolo y faltaba, se declararon los mapeos de
las etiquetas ad hoc de los traspasos a la taxonomía canónica, y se dejó registrada
sin corregir en silencio una discrepancia aritmética heredada de antes de v06 (la
columna de la clasificación suma una unidad más que las entradas numeradas). La
numeración se verificó programáticamente: sin huecos ni duplicados. Cuando se detectó
que la sesión 10 no era reconstruible con los insumos disponibles, se pidió su
traspaso y se esperó, en vez de fabricar las entradas faltantes. El archivo de trabajo
`backlog_entradas_sesion_7.md` quedó superado y se retiró con `git rm` en el mismo
commit (`a527a95`), no antes, para que ninguna sesión futura vuelva a encontrar dos
fuentes reclamando las mismas entradas.

### Sesion 13 (v13) — P-22: el bot trabaja en rama y abre PR

**35. El refresh semanal commitea en rama y abre PR; `main` deja de recibir
escrituras automaticas del bot.**
Categoria: automatizacion. Durante tres sesiones el bot semanal y el trabajo
manual compitieron por `main` (rebase en la s9, fast-forward en la s10, riesgo
vivo en la s12): el peaje era que `main` podia moverse sin conocimiento del
titular entre dos turnos de una misma sesion. Se reescribio
`.github/workflows/refresh-semanal.yml` para que el job cree una rama
`refresh/<corte>` desde el HEAD de `main`, commitee ahi y abra un PR contra
`main` con el resumen de conteos como cuerpo; `permissions` suma
`pull-requests: write` y el push va forzado pero acotado por refspec a
`refresh/*`, semantica correcta porque la rama es propiedad del bot y se
reconstruye en cada corrida. Se conservaron sin cambio de semantica el gate de
conteos (FAIL aborta sin rama ni PR), el commit condicional (sin cambios, sin
rama ni PR), el `git add` acotado a las cuatro rutas y el `timeout-minutes: 30`
de la entrada 33. La decision de fondo, tomada por el titular, fue revision
manual del PR en vez de automerge: el problema que P-22 resuelve es que `main`
se mueva sin su conocimiento, y el automerge lo reintroduce con mas pasos. El
costo asumido y declarado en la cabecera del YAML es que GitHub Pages republica
`docs/` al mergear, no al terminar el job, de modo que la frescura del dato en
produccion pasa a depender de la cadencia de revision. Validado en dos etapas:
una corrida manual desde `main` con los cinco criterios en verde (`main`
identico antes y despues, rama nacida del HEAD de `main`, PR abierto, gate OK,
PR data-only con 0 archivos bajo `.github/` sobre 320) y, dos dias despues, la
primera corrida desatendida por `schedule` del lunes 27, que dejo
`refresh/2026-07-27` (`188e8e0`) y el PR #2 sin intervencion alguna. Resuelve el
pendiente P-22, abierto desde la sesion 9.

### Sesion 14 (v14) — frontend de la Capa 3 de asistencia

**36. La ficha publica los dos ambitos de asistencia de la Capa 3, con presencia
del periodo vigente como titular y la serie nominal de sesiones.**
Categoria: interfaz/dashboard. Desde la sesion 11 el JSON traia la serie nominal,
los dos ambitos y la justificacion de cada inasistencia, y el portal seguia
mostrando solo los cinco campos legacy: el dato estaba publicado y no se veia.
La decision de fondo era P7, heredada sin resolver de la medicion de la Capa 3
(cual de las tasas es "la" tasa del portal), y la tomo el titular: el titular
pasa a `periodo_vigente.tasa_presencia`, cuyo denominador (51 sesiones desde la
instalacion del periodo 2026-2030) es el mismo para las 155 y los 155 y por lo
tanto el unico comparable entre personas; `tasa_presencia_o_justificada` se
publica como segunda lectura adyacente y nunca en lugar del titular, porque su
mediana es 1 y no discrimina; `en_ejercicio` queda como universo declarado de la
tabla de sesiones y no compite por la cabecera. Se reescribio `docs/index.html`
(unico archivo tocado): la columna ordenable del indice pasa de `tasa_asistencia`
a `tasa_presencia` (verificado antes de tocar codigo que el campo del indice es
el de `periodo_vigente`, identico en 155/155 perfiles), la cabecera de la ficha
suma una cuarta tarjeta `sin_registro` con glosa explicita de que esas sesiones
no se imputan como inasistencia, y se agrego una seccion nueva de sesiones de
sala, espejo de la de votaciones, con barra apilada de los tres estados, tabla
colapsada a 16 con expansion, glosa de justificacion tal como la entrega la
fuente (sin catalogo cerrado, P1) y marcadores de rebaja por fila que no entran
en ningun conteo mientras P2 siga abierta. Dos correcciones salieron de la
revision visual del titular sobre fichas reales: la segunda lectura se rinde
solo si hay inasistencias (con `n_no_asiste = 0` la frase atribuia a una falta
lo que producia el `sin_registro`) y la nota de ambitos bifurca segun si los dos
denominadores difieren de verdad. Los cinco campos legacy y `tasa_asistencia`
siguen publicados en el JSON y dejan de consumirse en el frontend, que es
exactamente la precondicion de P-48. Commit `f55430d`, pusheado a `origin/main`.

### Sesion 15 (v15) — retiro del contrato legacy de asistencia (P-48)

**37. Retiro del contrato legacy de asistencia del JSON publicado: cinco campos
del bloque `asistencia` del perfil y `tasa_asistencia` del indice.**
Categoria: consolidacion/salida (la sesion lo etiqueto "deuda tecnica"; se mapea
a la categoria canonica por intencion primaria, que es cambiar el contrato de
salida del `39`). El `39` dejo de leer `asistencia.rds`: salieron `anio`,
`n_sesiones`, `n_asiste`, `n_no_asiste` y `tasa_asistencia` del perfil, y
`tasa_asistencia` del indice, con su `leer()`, su `stopifnot` de llave, su
`cobertura()`, su `resumen_asistencia` y su `left_join`. La precondicion la habia
dejado la entrada 36: desde `f55430d` ningun consumidor los leia. `anio` no se
pierde, su valor viaja en `asistencia.alcance_temporal.anio_proceso` con ambito
declarado, asi que el retiro elimina una duplicacion sin ambito, no informacion.
`validar_corte()` no requirio adaptacion pese a pasar de 7 a 6 sellos: recorre
`names(sellos)` sin numero fijo. Verificado antes de commitear: 1 058 008 claves
comparadas en 155 perfiles y 1 705 en el indice, cero diferencias en los campos
sobrevivientes, excluido `metadatos.generado`. Commit `4f0bfba`.

**38. Eliminacion del bloque de extraccion legacy del `33` y de su segunda
descarga completa de la asistencia por corrida.**
Categoria: extraccion de datos. El `33` sostenia dos barridos completos de la
asistencia bajo claves de cache distintas: el nominal de la Capa 3 y el legacy,
que existia solo para alimentar los campos que la entrada 37 retiro. Salio el
bloque 1 entero (extraccion, validacion de dominio, agregado por diputado,
validacion de integridad y escritura de `asistencia.rds`) y el `# REVISAR` que
anunciaba este retiro desde la sesion 11. Los `.rds` de la clave
`asistencia_long_<anio>` en `20_insumos/camara/` no se borraron: son captura
cruda e inmutable por gobernanza, solo dejaron de leerse. Evidencia del barrido
unico en el log del `33`: antes registraba dos cache hits de asistencia, despues
uno. Regeneracion completa 32-36 y 39 con cero diferencias contra la salida
previa. Commit `970d564`.

**39. Correccion de la glosa de `docs/index.html` que citaba el campo retirado
como vigente.**
Categoria: documentacion. La glosa del bloque de derivacion afirmaba que
`tasa_asistencia` seguia publicado en el JSON y que solo no se consumia en el
cliente; tras la entrada 37 eso pasaba a ser falso sobre el contrato. Se
reescribio para declarar que `tasa_presencia` es el unico indicador de asistencia
del indice. Cambio de prosa unicamente: ninguna expresion que lea datos se toco.
Commit `545d053`.

**40. `.claude/settings.local.json` excluido del versionado por contener rutas
absolutas del titular en un repositorio publico (cierra P-55).**
Categoria: integracion/repo. Se ignoro el archivo, no la carpeta: `.claude/`
tambien aloja configuracion compartible que si debe versionarse. Commit
`a2b0933`.

**41. Cierre de P-56: el `+0` de conteos entre los cortes del 25 y del 27 es
real, no anomalia de captura.**
Categoria: diagnostico/exploracion. Verificado pareando los 7 caches por sufijo
entre `20260725_*` y `20260727_*`: md5 identico en los 7, y el cache nominal da
10 690 filas, 69 sesiones y `fecha_ultima = 2026-07-22` en ambos cortes. La
fuente no publico sesiones nuevas en esa ventana; el pipeline no perdio nada.

**42. Cierre de P-52 con hallazgo abierto: la auditoria de apertura #3 da
conforme sobre 11 scripts y cero rutas absolutas escritas a mano.**
Categoria: documentacion.

**43. Comprobacion de la republicacion de Pages por identidad de md5, que cerro
la prioridad 1 heredada de la sesion 14.**
Categoria: diagnostico/exploracion. Se verifico por identidad de hash entre lo
servido y lo versionado, no por inspeccion visual del sitio.

**44. Medicion del conflicto entre el PR #4 y el PR #3 del bot, con el hallazgo
del hunk unico y del modo de fallo por resolucion a nivel de archivo.**
Categoria: diagnostico/exploracion. Medido con `merge-tree`, sin tocar ninguno de
los dos PRs. Los dos tocan los mismos 310 archivos de datos y conflictan en
ambos ordenes, pero el conflicto es de **un solo hunk por archivo y es la linea
`metadatos.generado`** (310 de 310 medidos): los dos cambian lineas casi
disjuntas, el bot 3 (`corte_fecha`, `nota`, `generado`) y el retiro 6 quitadas y
1 agregada. Resolviendo ese hunk por cualquiera de los dos lados quedan 0 de 310
perfiles con campos legacy y `corte_fecha` 2026-08-03 en 310 de 310: git combina
bien el retiro con el dato fresco y no hay que regenerar nada. El modo de fallo
es resolver **a nivel de archivo** (`git checkout --theirs`), que reinstala la
version integra del bot con los 5 campos en 310 de 310 y deja ademas el contrato
incoherente, porque el indice no conflicta y conserva la version sin
`tasa_asistencia`. De aqui sale el aprendizaje A55.

**45. Redaccion del encargo de auditoria de fuentes Camara/Senado, sin
ejecutar.**
Categoria: documentacion. Queda como insumo listo para la sesion 16 (P-61).

### Sesion 16 (v16) — publicacion, auditoria de fuentes y eje tematico

#### Publicacion y deuda de datos

**46. Resolucion por hunk de los dos PRs abiertos y publicacion del contrato de
asistencia depurado.**
Categoria: integracion/repo. Los PRs #3 (refresco semanal del bot, corte
2026-08-03) y #4 (retiro del contrato legacy de asistencia) tocaban los mismos 310
archivos de datos y conflictaban en ambos ordenes. Se midio la forma del conflicto
antes de resolverlo: 310 archivos, un solo hunk cada uno, y el contenido de ese
hunk unicamente `metadatos.generado` en 310 de 310. Se resolvio por hunk
conservando el lado del bot, nunca a nivel de archivo, porque `git checkout
--theirs` habria resucitado los cinco campos legacy en todos los perfiles.
Resuelve el pendiente P-58 y cierra la tension entre B.1 y C.11 abierta en la
decision D21 de la sesion 15. Verificado con 8 de 8 criterios: 0 de 310 perfiles
con campos legacy, indice con 0 `tasa_asistencia` y 155 `tasa_presencia`,
`corte_fecha` uniforme en 310 de 310, y espejo `docs/data` identico a
`40_salidas/json` en 156 de 156 md5.

**49. Diagnostico y arreglo del sello desalineado de los intermedios, mas cierre
de P-61 por merge del PR #5.**
Categoria: infraestructura. Los seis intermedios de `40_salidas/intermedios/`
declaraban sello 2026-07-27 mientras `CORTE_FECHA` valia 2026-08-03, con lo que
`validar_corte()` abortaba y ninguna corrida de `39` era posible. La causa raiz
resulto estructural y no accidental: los intermedios estan en `.gitignore` y el
workflow no los commitea, pero si commitea el avance de `CORTE_FECHA`, de modo que
toda copia local queda desalineada tras cada merge del bot. La procedencia del
contenido se probo contra el artefacto publicado (155 de 155 perfiles coincidiendo
en tres metricas) y no por reconciliacion interna, y el arreglo se aplico corriendo
`32`-`36` desde la captura cruda ya versionada: 0,9 segundos, cero llamadas a la
API, con `20_insumos/camara/` identico antes y despues en 43 de 43 md5. La
compuerta no se debilito. Resuelve el pendiente P-62. Verificado con 10 de 10
criterios.

#### Medicion y exploracion de fuentes

**47. Ampliacion del encargo de auditoria de fuentes al eje tematico, antes de
lanzarlo.**
Categoria: documentacion. El titular declaro que el eje de mayor interes del
proyecto es temas, proyectos y votaciones, con asistencia en segundo plano. El
encargo, escrito en la sesion 15 y aun sin ejecutar (entrada 45), se amplio antes
de lanzarse: quinta pregunta de meta con seis eslabones desglosados, artefacto de
salida nuevo (veredicto del eje tematico), criterios de exito 10 a 14, cuarto
hallazgo en el panel adversarial, e invariante nuevo que prohibe medir cobertura
sobre muestras convenientes. Se corrigio ademas un invariante que habia quedado
obsoleto: mandaba no tocar dos PRs que la entrada 46 ya habia cerrado.

**48. Ejecucion de la auditoria de fuentes Camara/Senado con panel adversarial:
cuatro veredictos y cinco artefactos.**
Categoria: diagnostico/exploracion. Diez agentes en dos sondeos mas un panel
adversarial de cinco verificadores independientes con codigo propio. El universo
real de la API de la Camara resulto ser de 38 operaciones en 5 servicios, no 49, y
`WSComunes` no existe. P2 queda cerrado como NO por la via de la API (los cinco
WSDL suman 0 `documentation`, 0 `simpleType` y 0 `enumeration`). El eje tematico
recibe veredicto NO: la cadena voto -> proyecto -> materia cierra en 2325 de
122 605 filas de voto (1,90 %), con el cuello de botella en proyecto -> materia
(5 de 381 boletines). El padron del Senado si tiene fuente confiable, distinta de
la ya descartada, verificada 50 de 50 contra BCN. El contrato simetrico D2 recibe
veredicto SI CON LAGUNAS, con cinco lagunas de las cuales una (tres sesiones
centinela que devuelven las 50 filas en ausencia) produciria cifras falsas si no se
maneja. La auditoria ademas refuto la justificacion de la decision D3: existen
cinco colisiones numericas activas entre identificadores de senador y
`diputado_id`, y en cinco de cinco designan personas distintas. Resuelve el
pendiente P-61 y genera los pendientes P-63 y P-66 a P-73.

#### Infraestructura y orquestacion

**50. Guarda de autorregeneracion de intermedios en el orquestador, y correccion
de `procedimiento_actualizacion.md`.**
Categoria: infraestructura. Tras decidir que los intermedios no se versionan
(decision D24), la causa raiz identificada en la entrada 49 se cerro por la via del
codigo: `regenerar_intermedios_si_desalineados()` en `10_utils/10_utils.R:294`,
invocada desde un punto unico en `00_run_all.R:84`, detecta el desfase de sello,
avisa por consola y regenera `32`-`36` desde la captura cruda versionada, o falla
con `stop()` diagnostico si esa captura no esta. La guarda nunca descarga: fuerza
`camara.refrescar = FALSE` y lo restaura con `on.exit`, de modo que el invariante
de cero red no depende del estado que dejo el operador. Ninguna de las tres
funciones de la compuerta (`sellar`, `leer_sellado`, `validar_corte`) fue tocada.
Probado en cuatro escenarios, incluido el de cache ausente, inducido sin borrar ni
mover nada del insumo crudo. Resuelve los pendientes P-64 y P-65. Verificado con 13
de 13 criterios. Absorbe P-64: el mismo documento describia como pseudocodigo, bajo
el rotulo "NO EJECUTAR AUN", un workflow que corre desde el 2026-07-10, y quedo
reescrito como descripcion del workflow real.


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
- **v07 (incorporado en la sesion 12):** 3 entradas nuevas (24-26), copiadas
  verbatim desde `backlog_entradas_sesion_7.md`. Conteos actualizados
  (integracion/repo 3->4, diagnostico/exploracion 4->6). Sin categorias nuevas.
  Sin renumeracion ni reescritura de entradas 1-23.
- **v08 (incorporado en la sesion 12):** 3 entradas nuevas (27-29), derivadas de
  `traspaso_cierre_v08.md` §4-§5, que declara 3 entradas (una por cambio) con las
  categorias ad hoc "infraestructura/reproducibilidad" (+1) y "frontend/presentacion"
  (+2). Esas etiquetas se mapean por significado a las categorias canonicas ya
  existentes: infraestructura 4 y interfaz/dashboard 4. Se mapea en vez de crear
  categorias nuevas porque la taxonomia canonica del backlog manda sobre las
  etiquetas de un traspaso, y porque duplicar categorias por sinonimia rompe la
  exclusividad mutua por intencion primaria (§2.2.5). Sin renumeracion ni
  reescritura de entradas 1-26.
- **v09 (incorporado en la sesion 12):** 0 entradas nuevas. Sesion de higiene e
  integracion de git; el propio `traspaso_cierre_v09.md` §5 declara que las
  operaciones de git no son cambios de producto. Se registra como fila de 0 cambios
  en el resumen estadistico y como nota de sesion en el detalle cronologico, sin
  entradas numeradas. Sin refinamientos de taxonomia ni reclasificaciones.
- **v10 (incorporado en la sesion 12):** 1 entrada nueva (30), segun el delta
  declarado en `traspaso_cierre_v10.md` §5 (la Capa 2 es un cambio de producto; los
  nueve cambios de su §4 son las acciones tecnicas que la implementan, no cambios
  distinguibles del titular). Conteo actualizado (extraccion de datos 3->4). Sin
  categorias nuevas. Sin renumeracion ni reescritura de entradas 1-29.
- **v11 (incorporado en la sesion 12):** 2 entradas nuevas (31-32), segun el delta
  declarado en `traspaso_cierre_v11.md` §5. Conteos actualizados (integracion/repo
  4->5, extraccion de datos 4->5). Sin categorias nuevas. Sin renumeracion ni
  reescritura de entradas 1-30. Nota: la entrada 32 implementa la decision D2 de la
  entrada 23 (contrato de asistencia simetrico), fijada cinco sesiones antes.
- **Mapeo declarado de las entradas 30 y 32.** Ambas se clasifican en `extraccion de
  datos` por intencion primaria: el trabajo nuclear en las dos fue extender lo que el
  pipeline extrae y persiste (join territorial en el `32`; bloque nominal en el `33`),
  aunque ambas terminen visibles en el JSON publicado. Se prefirio mapear a la
  categoria canonica existente antes que abrir categorias nuevas por matiz, que
  romperia la exclusividad mutua por intencion primaria (§2.2.5).
- **v12:** 2 entradas nuevas (33-34). Conteos actualizados (automatizacion 1->2,
  documentacion 2->3). Sin categorias nuevas. Sin renumeracion ni reescritura de
  entradas 1-32. **Lo que NO se conto, declarado para que una sesion futura no lo
  duplique:** el merge y la publicacion de la Capa 3 ocurrieron materialmente en la
  sesion 12, pero ya estan registrados dentro de la entrada 32 con su hash
  (`70263cf`), porque v11 §5 declaro la Capa 3 completa como una de sus dos entradas;
  el push del cierre de la s11 y el commit de consolidacion son operaciones de git
  (precedente de la sesion 9); y la medicion del workflow es el diagnostico que
  fundamenta la entrada 33, no un cambio distinguible por si mismo.
- **Deuda de memoria saldada.** Con la consolidacion de la sesion 12 el canonico
  cubre las sesiones 1 a 12 sin huecos. El archivo de trabajo
  `backlog_entradas_sesion_7.md` quedo superado y se retiro en el commit `a527a95`.
- **Discrepancia heredada abierta:** ver el bullet siguiente y la nota bajo la tabla
  de clasificacion tematica.
- **Discrepancia heredada abierta:** la columna de N de la clasificacion tematica
  sumaba 24 con un total declarado de 23 desde antes de esta consolidacion. Se deja
  registrada y no se corrige en silencio; ver la nota bajo la tabla.
- **v13:** 1 entrada nueva (35). Conteo actualizado (automatizacion 2->3); suma de
  la columna 35->36 y porcentajes recalculados sobre 36. Sin categorias nuevas. Sin
  renumeracion ni reescritura de entradas 1-34. La discrepancia heredada sigue
  abierta con el mismo signo (columna 36, entradas 35). **Lo que NO se conto,
  declarado para que una sesion futura no lo duplique:** la poda de nueve ramas y el
  push del cierre de la s12 son operaciones de git, no cambios de producto
  (precedente de la sesion 9); el merge del PR #1 (corte del 25) es una corrida
  rutinaria del refresh ya automatizado, no un cambio distinguible (el "primer
  refresh real en produccion" ya esta contado en `integracion/repo`, sesion 4); y el
  push de `15be859` publica la ola canonica S-01, que es trabajo de una sesion
  BIBLIOTECA de cartera, no de este proyecto.
- **v14:** 1 entrada nueva (36). Conteo actualizado (interfaz/dashboard 4->5); suma
  de la columna 36->37 y porcentajes recalculados sobre 37 (suman 99,9 por redondeo).
  Sin categorias nuevas. Sin renumeracion ni reescritura de entradas 1-35. La
  discrepancia heredada sigue abierta con el mismo signo y la misma unidad (columna
  37, entradas 36). **Lo que NO se conto, declarado para que una sesion futura no lo
  duplique:** el merge del PR #2 (corte del 27) es una corrida rutinaria del refresh
  ya automatizado, mismo criterio con que v13 excluyo el PR #1; las dos correcciones
  de la revision visual son iteraciones dentro de la entrada 36, no cambios
  distinguibles del titular; y el `git pull` y el push del cierre son operaciones de
  git (precedente de la sesion 9).
- **v15:** 9 entradas nuevas (37-45). Conteos actualizados (consolidacion/salida
  2->3, extraccion de datos 5->6, documentacion 3->6, integracion/repo 5->6,
  diagnostico/exploracion 6->9); suma de la columna 37->46 y porcentajes
  recalculados sobre 46 (suman 99,9 por redondeo a un decimal; recuento
  programatico de esta sesion). Sin categorias nuevas. Sin renumeracion ni
  reescritura de entradas 1-36. La discrepancia heredada sigue abierta con el
  mismo signo y la misma unidad (columna 46, entradas 45). **Mapeo de las
  etiquetas del traspaso a la taxonomia canonica**, declarado porque la §5 de
  v15 usa etiquetas ad hoc: "deuda tecnica" -> consolidacion/salida (37) y
  extraccion de datos (38), segun que artefacto cambia; "administrativo" ->
  integracion/repo (40); "deuda de datos" y "verificacion" ->
  diagnostico/exploracion (41, 43, 44); "documentacion" se mantiene (39, 42,
  45). Se prefirio mapear a las categorias existentes antes que abrir
  categorias nuevas por matiz, que romperia la exclusividad mutua por intencion
  primaria (§2.2.5), mismo criterio que la consolidacion de v12. **Lo que NO se
  conto, declarado para que una sesion futura no lo duplique:** la correccion
  del log de ejecucion y la medicion de sus cifras (§4.5 de v15) son higiene
  documental sobre un artefacto de la propia sesion, no un cambio de producto;
  el archivado de los traspasos previos bajo `traspasos/archivo/` es aplicacion
  de una regla de politica vigente (1.3.1), no una solicitud distinguible; y el
  push del cierre y los commits de documentacion son operaciones de git
  (precedente de la sesion 9).
- **v16:** 5 entradas nuevas (46-50). Conteos actualizados (infraestructura 4->6,
  documentacion 6->7, diagnostico/exploracion 9->10, integracion/repo 6->7); suma de
  la columna 46->51 y porcentajes recalculados sobre 51 (suman 100,1 por redondeo a
  un decimal). Sin categorias nuevas. Sin renumeracion ni reescritura de entradas
  1-45. La discrepancia heredada sigue abierta con el mismo signo y la misma unidad
  (columna 51, entradas 50). **Mapeo declarado:** la entrada 46 va a
  `integracion/repo` y no a `consolidacion/salida` porque su intencion primaria fue
  resolver y mergear dos PRs en conflicto, no cambiar la forma del JSON (el cambio de
  forma ya estaba contado en la entrada 37 de v15); las entradas 49 y 50 van ambas a
  `infraestructura` porque su objeto es la reproducibilidad del pipeline, no el dato
  publicado, que quedo identico en 156 de 156 artefactos. **Lo que NO se conto,
  declarado para que una sesion futura no lo duplique:** el merge del PR #3 (corte
  del 2026-08-03) es una corrida rutinaria del refresh ya automatizado, mismo
  criterio con que v13 y v14 excluyeron los PRs #1 y #2; los merges de los PRs #5 y
  #6 son la publicacion de artefactos ya contados en las entradas 48 y 50; la
  correccion del reproductor de la auditoria (cacheaba un HTTP 500 como si fuera el
  descriptor) es higiene sobre un artefacto de la propia sesion, no un cambio de
  producto; el `.gitignore` del cache de exploracion es gobernanza aplicada dentro de
  la entrada 48; y el push del cierre y los commits de documentacion son operaciones
  de git (precedente de la sesion 9).
