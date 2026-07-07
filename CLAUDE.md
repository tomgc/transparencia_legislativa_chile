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
- `30_procesamiento/31_explorar_api_camara.R` — exploración (diagnóstico, fuera
  del pipeline).
- `30_procesamiento/{32,33,34,35}_*.R` — extracción (diputados, asistencia,
  votaciones, proyectos).
- `30_procesamiento/39_consolidar_json.R` — fusión a JSON.
- `00_run_all.R` — orquestador (`run_all(from/to/only/skip)`).

## Huecos conocidos de la fuente (# REVISAR)

- **Distrito y región** no los expone la API de la Cámara → `NA`. Requeriría
  una segunda fuente (BCN/SERVEL), fuera del alcance de Fase 1.
- **Tendencia (izq/der)** no viene en la API: se deriva de
  `MAPA_PARTIDO_TENDENCIA`, decisión metodológica del titular. Hoy los 18
  partidos del roster están sin clasificar (`NA`).
- **Estado de tramitación** de un proyecto no se expone → `NA`; se conserva
  `admisible` como proxy.
- **Rol autor/coautor:** la API entrega `Orden=0` para todos los firmantes; no
  distingue jerarquía → todos se marcan `firmante`.

## Convenciones del proyecto

- Mensajes de commit, comentarios y documentación en español.
- No pedir confirmación para operaciones git locales (commit, checkout, branch).
- `git push` requiere visto bueno del titular.

## Últimos cambios (máx. 5, más recientes primero)

1. **Sesión 1 (2026-07-06):** scaffold Fase 1 completo + pipeline de extracción
   de la Cámara (roster, asistencia, votaciones, proyectos) validado extremo a
   extremo hasta producir `indice_diputados.json` y 155 perfiles.
