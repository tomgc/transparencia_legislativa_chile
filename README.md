# transparencia_legislativa_chile

Portal de transparencia legislativa del Congreso de Chile, **serverless**,
pensado para alojarse en GitHub Pages. Un pipeline en R consolida datos
públicos de la Cámara de Diputadas y Diputados en JSON estáticos; un dashboard
estático (Fase 2, no incluido aún) los visualiza en el navegador sin backend.

Por parlamentario, el portal muestra: **asistencia** a sesiones, **proyectos**
presentados, **votaciones** y sentido del voto, y **perfil**. Segmentaciones:
cámara, partido, tendencia (izq/der), región/distrito.

> **Estado:** Fase 1 completa (scaffold + pipeline de extracción de la Cámara
> validado extremo a extremo hasta producir JSON). Fase 2 (dashboard + GitHub
> Actions), Senado y BCN quedan fuera de este alcance.

## Origen de los datos

- **Fuente única (Fase 1):** `opendata.camara.cl`
  (`https://opendata.camara.cl/camaradiputados/WServices/`), servicios que
  devuelven XML. La firma real de cada endpoint está documentada en
  [`50_documentacion/activa/exploracion_api_camara.md`](50_documentacion/activa/exploracion_api_camara.md).
- **Datos 100 % públicos** del Estado sobre figuras públicas. Este es un
  proyecto de **Rama A** (raíz unificada, POLITICA §8.2): `20_insumos/` y
  `40_salidas/` viven en el repo y se versionan.

## Cómo correr el pipeline

```r
source("00_run_all.R")
run_all()                    # pipeline completo (32 -> 39)
# run_all(from = 33)         # desde asistencia
# run_all(only = c(34, 39))  # solo votaciones y consolidación
```

Requiere R (>= 4.5) con acceso a internet la primera vez. El pipeline cachea
la captura cruda de la API en `20_insumos/camara/` (con fecha); las corridas
siguientes reutilizan esa captura salvo que se fuerce el refresco:

```r
options(camara.refrescar = TRUE); source("00_run_all.R"); run_all()
```

Salidas en `40_salidas/json/`:
- `indice_diputados.json` — lista mínima para el selector.
- `perfiles/<id>.json` — un perfil por diputado, con cuatro bloques
  (perfil, asistencia, votaciones, proyectos) + metadatos.

**Exploración de la API** (diagnóstico, fuera del pipeline):

```r
source("30_procesamiento/31_explorar_api_camara.R")
```

## Estructura

Sigue `POLITICA_PROYECTO.md` (ver `50_documentacion/activa/`).

- `00_run_all.R` — orquestador (punto de entrada único).
- `00_escanear_proyecto.R` — escáner de estructura.
- `10_utils/` — bootstrapping, cliente HTTP de la Cámara, config y constantes.
- `20_insumos/camara/` — capturas crudas de la API (date-stamped, cacheadas).
- `30_procesamiento/` — 31 exploración, 32-35 extracción, 39 consolidación.
- `40_salidas/json/` — JSON estáticos que consume el dashboard.
- `40_salidas/intermedios/` — tablas intermedias (`.rds`).
- `50_documentacion/` — activa, traspasos, andamios, estructura.

## Convenciones clave

- **R es el único lenguaje de procesamiento.** El navegador solo lee JSON
  precomputado; no ejecuta R ni llama APIs en caliente.
- **Llaves de identificación siempre `character`** (id de diputado, boletín).
- **Web estática autocontenida**, sin dependencias externas de CDN.
- Naming `snake_case` sin tildes/ñ/espacios; comentarios en español.

## Documentación clave

- `50_documentacion/activa/POLITICA_PROYECTO.md` — política maestra.
- `50_documentacion/activa/SETTINGS_Y_PROMPTS_OPERACIONALES.md` — protocolos.
- `50_documentacion/activa/exploracion_api_camara.md` — firma real de la API.
- `50_documentacion/activa/documentacion_tecnica_v1.md` — arquitectura.
- `CLAUDE.md` — contrato operativo de Claude Code.
- `50_documentacion/traspasos/` — handoffs entre sesiones.

## Escanear la estructura actual

```r
source("00_escanear_proyecto.R")
```
