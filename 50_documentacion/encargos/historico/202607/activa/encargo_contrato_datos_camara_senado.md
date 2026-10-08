# Encargo — Extraccion de esquema de la Camara y propuesta de contrato comun Camara/Senado

> **Instrumento de sesion.** Encargo de DIAGNOSTICO + PROPUESTA insumos-first para
> transparencia_legislativa_chile, paso previo al diseno del pipeline del Senado.
> Patron: `encargo_autonomo_claude_code_v1.md` (dirigido por meta).
>
> **Contexto (decisiones de arquitectura ya tomadas en sesion de diseno):**
> El pipeline del Senado sera EXTENDIDO (no duplicado): extraccion bifurcada por
> fuente (Camara desde su web service; Senado desde el backend
> `web-back.senado.cl/api/`), normalizacion a un CONTRATO COMUN, y consolidacion
> unificada en `39`. Ya se confirmo (encargos de exploracion v02 y H1-bis) que el
> Senado tiene, con `ID_PARLAMENTARIO`/`PARLID` estable:
>   - roster de 50 (`api/parlamentarios?vigentes=1`, `CAMARA=="S"`),
>   - asistencia NOMINAL POR SESION (`api/sessions/attendance?id_sesion=<id>`),
>   - votaciones con detalle nominal por id (`api/votes?id_votacion=<id>`, con BOLETIN),
>   - proyectos: NO en el backend (se complementa con wspublico `tramitacion.php`).
> El contrato de asistencia sera SIMETRICO (nominal por sesion en ambas camaras).
> La identidad sera por id, con la FECHA de sesion capturada para resolver el roster
> as-of en el futuro (membresia dependiente del tiempo; el Senado renovo en mar-2026).
>
> **Que NO decide este encargo:** el crosswalk de partidos a tendencia (metodologico,
> del titular) y la construccion de los normalizadores (siguiente encargo). Este solo
> DOCUMENTA el esquema real de la Camara y PROPONE el contrato comun, para que la
> sesion de diseno lo apruebe o ajuste.
>
> **Rama base:** `main` (necesita el pipeline de la Camara vigente y estable; las
> ramas explore/* del Senado NO son la base).

---

## Bloque para Claude Code

```
MODO: EJECUCION AUTONOMA. Encargo de DIAGNOSTICO + PROPUESTA (insumos-first) para
ejecutar AHORA en este repositorio (transparencia_legislativa_chile). NO construyes
pipeline, NO escribes normalizadores, NO tocas ningun archivo existente, NO
consolidas JSON. Solo LEES el pipeline de la Camara y AGREGAS dos archivos nuevos
(un documento de esquema+contrato y su log). Ejecuta las fases en orden y de forma
autonoma; te detienes solo en los casos de detencion declarados.

═══════════════════════════════════════════════════════════════════════
CONTRATO DE ENTORNO
═══════════════════════════════════════════════════════════════════════
- ENTORNO: filesystem local via Claude Code, repo en
  /Users/tomgc/Projects/transparencia_legislativa_chile (Rama A, repo publico).
- POSICION: toda ruta completa desde la raiz del proyecto. Ningun comando asume
  cd previo. Usa git -C /Users/tomgc/Projects/transparencia_legislativa_chile ...
  en cada comando git.
- RAMA BASE: main (el pipeline de la Camara vigente).
- INSUMOS de referencia (leelos del filesystem; estan en main):
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/32_extraer_diputados.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/33_extraer_asistencia.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/34_extraer_votaciones.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/35_extraer_proyectos.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/36_extraer_detalle_proyectos.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/39_consolidar_json.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/10_utils/10_configuracion.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/activa/exploracion_api_senado_v02.md
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/activa/exploracion_asistencia_senado.md
  Los dos ultimos (docs de exploracion del Senado) viven en las ramas explore/*, NO
  en main. Si no estan en main, obtenlos SIN cambiar de rama con:
    git -C <raiz> show explore/api-senado-v02:50_documentacion/activa/exploracion_api_senado_v02.md
    git -C <raiz> show explore/api-senado-v02-asistencia:50_documentacion/activa/exploracion_asistencia_senado.md
  (son solo lectura de referencia; no los copies al working tree de main).

═══════════════════════════════════════════════════════════════════════
REGLAS CANONICAS HEREDADAS (🔒)
═══════════════════════════════════════════════════════════════════════
- R como UNICO lenguaje, sin excepcion (toda inspeccion en R; nada de Python ni
  curl+jq). Bash solo para git.
- httr2/jsonlite para las llamadas de la FASE 3; el resto es lectura de codigo.
- here::here() dentro de scripts; sin rutas absolutas en codigo R.
- Naming sin tildes/ñ/espacios; snake_case. Identificadores como character.
- Trabajas en la rama design/contrato-datos (nueva, desde main). NO push, NO PR,
  NO merge. Si hay cambios sin commitear heredados en el working tree, NO los
  toques ni los incluyas.

═══════════════════════════════════════════════════════════════════════
META DEL ENCARGO
═══════════════════════════════════════════════════════════════════════
Producir un documento que habilite el diseño del contrato de datos comun, con tres
componentes:
  (1) El ESQUEMA REAL que hoy produce el pipeline de la Camara: para cada intermedio
      (roster, asistencia, votos, proyectos, detalle) y para el JSON final de 39,
      las columnas exactas, su tipo, y cuales son claves. Extraido del codigo, no
      supuesto.
  (2) Una PROPUESTA de contrato comun Camara/Senado: para cada entidad, el conjunto
      de columnas que ambos normalizadores deberian emitir, mapeando campo-Camara y
      campo-Senado (segun los docs de exploracion) a un nombre canonico comun.
  (3) Los pares (PARTIDO_ID, PARTIDO texto) REALES del roster del Senado, extraidos
      en vivo del backend, para que el titular decida el crosswalk a tendencia (este
      encargo NO decide el crosswalk; solo entrega el insumo).

═══════════════════════════════════════════════════════════════════════
INVARIANTES (🔒)
═══════════════════════════════════════════════════════════════════════
- NO modificar NINGUN archivo existente (ni 32-39, ni config, ni pipeline). Solo
  AGREGAS el documento nuevo y su log.
- NO escribir normalizadores ni scripts de pipeline. Este encargo es diagnostico +
  propuesta en prosa/tablas, no codigo de produccion. (Un unico script auxiliar de
  exploracion para la FASE 3 es admisible, mismo criterio que 31c/31d: NO entra a
  run_all.)
- NO tocar 20_insumos/, 40_salidas/, docs/.
- NO decidir el crosswalk de partidos: solo listar los pares reales.
- NO inventar esquema: si un tipo o clave no es evidente del codigo, leer el dato
  real del .rds intermedio (readRDS en R, solo lectura) o declararlo como "a
  confirmar", nunca fabricar.

═══════════════════════════════════════════════════════════════════════
FASES (orden estricto)
═══════════════════════════════════════════════════════════════════════
FASE 0 — Preparacion
- git -C <raiz> checkout main
- git -C <raiz> status (constata heredados; no los toques).
- git -C <raiz> checkout -b design/contrato-datos
- Lee los 7 archivos de codigo de la Camara. Obten los 2 docs de exploracion del
  Senado via git show (arriba). Si falta un archivo de codigo de la Camara en main,
  PARA y reporta (caso #4).

FASE 1 — Esquema real de la Camara (leer codigo + datos)
- Para cada script 32-36: identifica que .rds escribe, con que columnas y tipos.
  Donde el codigo no deje claro el tipo/clave, LEE el .rds real correspondiente en
  20_insumos/camara/ o 40_salidas/intermedios/ con readRDS (solo lectura) y usa
  str()/sapply(class) para el esquema efectivo. Reporta la fuente de cada dato
  (codigo vs .rds leido).
- Para 39: documenta la ESTRUCTURA del JSON final (indice + perfil): que campos de
  nivel superior, que arrays anidados (votos[], proyectos[], asistencia), y de que
  intermedio sale cada uno. El objetivo es el CONTRATO que 39 consume hoy.
- Identifica las CLAVES de join entre intermedios (que campo une votos con
  proyectos, asistencia con roster, etc.) y su tipo (confirmar character).

FASE 2 — Propuesta de contrato comun
- Para cada entidad (roster, asistencia, votos, proyectos), una tabla:
  [columna canonica | tipo | clave? | campo-Camara (de FASE 1) | campo-Senado (de
  los docs de exploracion) | nota]. La columna canonica es el nombre comun que
  ambos normalizadores emitirian.
- Marca explicitamente:
  * el campo comun de identidad (id de parlamentario): como se llama en Camara vs
    ID_PARLAMENTARIO/PARLID en Senado.
  * en asistencia: incluir id_sesion + FECHA de sesion en el contrato (decision de
    diseño ya tomada: capturar fecha para resolucion temporal futura). Verifica si
    el 33 de la Camara ya trae fecha por sesion; si no, marcalo como gap a cubrir
    en el normalizador de la Camara.
  * en votos: el campo BOLETIN (join a proyecto) y el sentido del voto, en ambas
    camaras.
  * donde una camara tiene un campo que la otra no (p. ej. proyectos: detalle rico
    en Camara/wspublico; en Senado via wspublico complementario): marcar como
    opcional-por-fuente, no forzar.
- Añade una CAMARA (columna `camara` = "D"/"S") como discriminador en cada entidad.

FASE 3 — Pares de partido reales del Senado (insumo del crosswalk)
- En R (httr2/jsonlite), trae el roster del Senado en vivo:
    GET https://web-back.senado.cl/api/parlamentarios?vigentes=1
  filtra CAMARA=="S" (50 senadores) y extrae los pares UNICOS (PARTIDO_ID, PARTIDO
  texto). Guarda la muestra en
  50_documentacion/andamios/contrato_datos/senado_partidos_muestra.json y la tabla
  de pares unicos en el documento.
- NO propongas la tendencia de cada partido: eso lo decide el titular. Solo entrega
  la lista [PARTIDO_ID | PARTIDO | n_senadores]. Como referencia, incluye (leyendo
  MAPA_PARTIDO_TENDENCIA de 10_configuracion.R) la taxonomia de 5 niveles vigente y
  el mapa actual de la Camara, para que el titular vea el formato destino — sin
  extrapolarlo al Senado.

FASE 4 — Documento + log
- Escribe 50_documentacion/activa/contrato_datos_camara_senado.md con: FASE 1
  (esquema Camara), FASE 2 (propuesta de contrato comun, una tabla por entidad),
  FASE 3 (pares de partido del Senado + taxonomia destino), y una seccion de
  PREGUNTAS ABIERTAS para la sesion de diseño (todo lo que quede "a confirmar").
- Log honesto en
  50_documentacion/andamios/logs/AAAAMMDD_contrato_datos_log.md
  (plantilla encargo_autonomo_claude_code_v1.md §4).

═══════════════════════════════════════════════════════════════════════
CRITERIOS DE EXITO VERIFICABLES (B.4)
═══════════════════════════════════════════════════════════════════════
- El esquema de la Camara sale del codigo Y (donde haga falta) del .rds real, con
  la fuente de cada campo declarada. Ningun tipo/clave "supuesto" sin marcar.
- La propuesta de contrato comun cubre las 4 entidades, mapea campo-Camara y
  campo-Senado a un nombre canonico, e incluye `camara`, `id_sesion`+fecha en
  asistencia, y BOLETIN+sentido en votos.
- Los pares de partido del Senado salen de una llamada real al backend (muestra
  guardada, parseable, con conteo = 50 senadores).
- git status: limpio salvo el documento nuevo, su log, la muestra de partidos, y el
  script auxiliar de FASE 3 si se creo. NO archivos del pipeline modificados.

═══════════════════════════════════════════════════════════════════════
CASOS DE DETENCION (PARA y reporta; no improvises)
═══════════════════════════════════════════════════════════════════════
1. El backend del Senado exige auth / no responde (para la FASE 3): reporta y
   completa igual FASES 1-2 (no bloquea el esquema de la Camara).
2. Un intermedio .rds referido por el codigo no existe en disco y su esquema no es
   deducible del codigo: reporta ese campo como "a confirmar", no lo fabriques.
3. El codigo de la Camara revela una decision de contrato que contradice una
   premisa de diseño (p. ej. la Camara NO guarda fecha por sesion y el contrato
   simetrico la necesita): reportalo como PREGUNTA ABIERTA, es exactamente lo que
   la sesion de diseño debe resolver.
4. Falta un insumo de referencia de la Camara en main (FASE 0): PARA y reporta.

═══════════════════════════════════════════════════════════════════════
AUTO-AUDITORIA Y CIERRE
═══════════════════════════════════════════════════════════════════════
- Antes de reportar, re-lee tu tabla de contrato contra los docs de exploracion del
  Senado: cada campo-Senado citado debe existir en esos docs (no inventado).
- Para la FASE 3, abre la muestra de partidos en R y confirma 50 senadores y la
  lista de pares unicos.
- Commits atomicos en design/contrato-datos, mensajes en espanol. NO push.

REPORTE FINAL AL CHAT:
- Resumen del esquema de la Camara (entidades y sus claves).
- La propuesta de contrato comun (tablas por entidad) o su resumen.
- La lista de pares (PARTIDO_ID, PARTIDO, n) del Senado.
- Las PREGUNTAS ABIERTAS detectadas para la sesion de diseño.
- Hashes de commits (locales, sin push) y ruta del log.
```
