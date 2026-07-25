# CLAUDE.md — Contrato técnico del proyecto

Contrato operativo de Claude Code para `transparencia_legislativa_chile`. El
detalle de estructura, gobernanza y principios vive en
`50_documentacion/activa/POLITICA_PROYECTO.md` y
`SETTINGS_Y_PROMPTS_OPERACIONALES.md`: consúltalos, no los dupliques.

## Descripción

Portal de transparencia legislativa del Congreso de Chile, serverless, para
GitHub Pages. Un pipeline en R consolida datos públicos de la Cámara de
Diputadas y Diputados (`opendata.camara.cl`) en JSON estáticos que un dashboard
estático (Fase 2) visualiza en el navegador.

## Stack tecnológico

- **Procesamiento:** R (>= 4.5), Positron. Pipe nativo `|>`, `dplyr >= 1.1`
  con `.by=`, `here::here()`, `httr` + `xml2` para la API, `jsonlite` para la
  salida.
- **Cliente:** HTML/CSS/JS estático que consume JSON precomputado (Fase 2).
- **CI:** GitHub Actions (Fase 2). YAML solo para ese workflow.

## Invariantes (🔒 — intocables)

1. 🔒 **R es el único lenguaje del proyecto.** El alcance es total, no solo el
   pipeline de datos del producto: aplica también a toda verificación,
   auditoría o script auxiliar del proyecto, sin excepción. **Nada de Python en
   ningún contexto.** La independencia adversarial de una auditoría se logra
   **en R** — sesión limpia, pull fresco de la fuente, y código que no comparta
   funciones con el pipeline (para no heredar sus puntos ciegos) —, nunca
   cambiando de lenguaje. (Precisión que cierra la ambigüedad registrada en el
   traspaso v01 §15, error 2.)
2. 🔒 **El navegador NO ejecuta R ni llama APIs en caliente:** solo lee JSON
   estático precomputado. Toda extracción y cálculo ocurre en el pipeline R.
3. 🔒 **Web estática autocontenida:** HTML5 semántico, CSS/JS inline o local,
   SVG inline, JSON como formato de datos, sin dependencias de CDN salvo
   necesidad estricta declarada.
4. 🔒 **Llaves de identificación siempre `character`**, nunca `numeric`
   (id de diputado, boletín, códigos). Un join con tipos mezclados falla en
   silencio.
5. 🔒 **Estructura canónica por decenas**; naming `snake_case` sin tildes, ñ ni
   espacios.
6. 🔒 **Datos 100 % públicos, Rama A** (POLITICA §8.2): raíz unificada, sin
   data root externo, sin `.gitignore` blindado de datos.

## Convención del JSON de salida

- `40_salidas/json/indice_diputados.json`: array de `{id, nombre, partido,
  distrito, region, tendencia}` (id como string), ordenado por nombre.
- `40_salidas/json/perfiles/<id>.json`: objeto con bloques en este orden —
  `perfil`, `asistencia`, `votaciones`, `proyectos`, `metadatos`.
- Claves ordenadas, indentación fija (2 espacios, `jsonlite::toJSON(pretty=TRUE)`),
  UTF-8 explícito, `NA -> null`. Tasas como decimal sin redondear.

## Estructura de archivos relevantes

- `10_utils/10_utils.R` — bootstrapping, `descargar_xml_camara()`, `con_cache()`,
  helpers de nodo XML y de llave.
- `10_utils/10_configuracion.R` — rutas (`here::here()`), `ANIO_PROCESO`, topes
  de extracción, dominios canónicos, `MAPA_PARTIDO_TENDENCIA`.
- `50_documentacion/andamios/31_explorar_api_camara.R` — exploración
  (diagnóstico, fuera del pipeline; vive en andamios, no es una etapa).
- `30_procesamiento/{32,33,34,35}_*.R` — extracción (diputados, asistencia,
  votaciones, proyectos).
- `30_procesamiento/39_consolidar_json.R` — fusión a JSON.
- `00_run_all.R` — orquestador (`run_all(from/to/only/skip)`).

## Huecos conocidos de la fuente (# REVISAR)

- ~~**Distrito y región** no los expone la API de la Cámara → `NA`.~~ **Cerrado
  (sesión 10).** La API sigue sin exponerlos, pero el `32` los puebla por join
  contra `20_insumos/territorio/` (insumo estático auditado, D5): 155/155.
  Llave: `idCamaraDeDiputados` de BCN, que **es** el `diputado_id` de la Cámara.
  El insumo NO se regenera en el refresh semanal; el generador es la fase `gen`
  de `50_documentacion/andamios/medir_fuente_territorio.R`, a mano y con revisión
  del diff cuando cambie el roster.
- **Tendencia** no viene en la API: es columna derivada de
  `MAPA_PARTIDO_TENDENCIA`, decisión metodológica del titular (taxonomía de 5
  niveles: izquierda/centroizquierda/centro/centroderecha/derecha). Los 18
  partidos del roster están clasificados (sesión 2); `IND` queda `NA` por no
  ser partido.
- **Estado de tramitación** de un proyecto no se expone → `NA`; se conserva
  `admisible` como proxy.
- **Rol autor/coautor:** la API entrega `Orden=0` para todos los firmantes; no
  distingue jerarquía → todos se marcan `firmante`.

## Convenciones del proyecto

- Mensajes de commit, comentarios y documentación en español.
- No pedir confirmación para operaciones git locales (commit, checkout, branch).
- `git push` requiere visto bueno del titular.

## Últimos cambios (máx. 5, más recientes primero)

1. **Capa 2 — territorio (2026-07-24):** `distrito` y `region` dejan de ser `NA`:
   155/155 en índice y perfiles, 28 distritos, suma 155 escaños. El `32` hace
   `left_join` contra dos insumos estáticos versionados en `20_insumos/territorio/`
   (crosswalk `diputado_id`→distrito y catálogo distrito→región contra la Ley
   20.840), con `stop()` diagnóstico si un reemplazo del roster no está cubierto.
   El `39` no se tocó. Fuente y llave establecidas por medición previa (BCN
   `idCamaraDeDiputados` == `diputado_id`); 4 ids que BCN reusa entre persona
   histórica y vigente se desambiguan por período. Panel adversarial: 4/4 cuadra.
   Rama `feat/territorio-crosswalk` (sin merge, gate del titular).
2. **Presentación de votos + región/distrito (2026-07-15):** Capa 1 de la ruta de
   la sesión 8, solo `docs/index.html`. Botón `Ver los N votos` / `Ver menos` que
   expande la lista completa en el perfil (antes recortaba a 16 de hasta 717; el
   JSON ya venía entero al cliente, 9 ms de re-render). Región/distrito dejan de
   estar hardcodeados: la celda de la tabla y el chip de la ficha leen
   `region`/`distrito` y degradan a "Sin dato" solo si faltan — invisible hoy
   (155/155 `null`), habilitante para la Capa 2. Rama `feat/presentacion-votos`
   (sin merge, gate del titular).
3. **Workflow GitHub Actions (2026-07-10):** `.github/workflows/refresh-semanal.yml`
   (cron lunes 11:00 UTC + `workflow_dispatch`) automatiza el refresh semanal:
   calcula el corte con `date`, lo inyecta en `CORTE_FECHA` vía `sed`, corre
   `run_all()`, y un gate (`10_diff_conteos.R`) aborta antes de commitear/pushear
   si `perfiles < 155` o cae cualquier métrica. Probado local de punta a punta;
   rama `feature/github-actions-refresh` (sin merge, gate del titular).
4. **Corte temporal explícito (2026-07-10):** `CORTE_FECHA` reemplaza `Sys.Date()`
   en la clave de caché (refresh reproducible sin drift); procedimiento de
   actualización semanal + script de diff de conteos como compuerta.
5. **Integración de ramas + contenido legible (2026-07-09):** merge a `main` de
   trazabilidad voto→proyecto y detalle de proyectos (paso 36); fix de clave de
   caché que codifica el tope.
