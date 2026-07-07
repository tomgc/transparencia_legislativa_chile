# Documentación técnica — transparencia_legislativa_chile

**Versión:** v1
**Fecha de creación:** 2026-07-06

## Propósito del proyecto

Portal de transparencia legislativa serverless: R consolida datos públicos de
la Cámara de Diputadas y Diputados en JSON estáticos para un dashboard que
corre 100 % en el navegador (GitHub Pages).

## Arquitectura

```
opendata.camara.cl (XML)
      |  30_procesamiento/32-35 (extracción, R + httr + xml2)
      v
20_insumos/camara/*.rds        (captura cruda date-stamped, cacheada)
      |  30_procesamiento/32-35 (limpieza + agregación, dplyr)
      v
40_salidas/intermedios/*.rds   (tablas tidy: diputados, asistencia, votos, proyectos)
      |  30_procesamiento/39 (fusión + JSON, jsonlite)
      v
40_salidas/json/               (indice_diputados.json + perfiles/<id>.json)
      |  (Fase 2, no implementada)
      v
dashboard estático en GitHub Pages
```

El navegador **solo lee JSON precomputado**; nunca ejecuta R ni llama la API.

## Sub-etapas del pipeline (30_procesamiento/)

| ID | Archivo | Propósito | En `run_all()` |
|----|---------|-----------|:---:|
| 31 | `31_explorar_api_camara.R` | Instrumentación: descubre la firma real de la API y genera `exploracion_api_camara.md`. | No (diagnóstico) |
| 32 | `32_extraer_diputados.R` | Roster del período vigente: id, nombre, sexo, partido vigente, tendencia derivada. | Sí |
| 33 | `33_extraer_asistencia.R` | Asistencia por sesión → agregado por diputado (tasa efectiva decimal). | Sí |
| 34 | `34_extraer_votaciones.R` | Votaciones nominales: sentido del voto por diputado; boletín desde `Descripcion`. | Sí |
| 35 | `35_extraer_proyectos.R` | Mociones de origen Cámara con firmantes diputados. | Sí |
| 39 | `39_consolidar_json.R` | Fusión a `indice_diputados.json` + `perfiles/<id>.json`. | Sí |

## Firma de la API (resumen; detalle en `exploracion_api_camara.md`)

Base `https://opendata.camara.cl/camaradiputados/WServices/` (solo HTTPS).
XML, namespace `http://opendata.camara.cl/camaradiputados/v1` (se remueve).

| Fuente | Operación | Notas |
|--------|-----------|-------|
| Roster | `WSDiputado.asmx/retornarDiputadosPeriodoActual` | 155 diputados; partido = militancia de mayor `FechaInicio`. |
| Sesiones | `WSSala.asmx/retornarSesionesXAnno?prmAnno=` | filtrar `Estado` = Celebrada. |
| Asistencia | `WSSala.asmx/retornarSesionAsistencia?prmSesionId=` | `TipoAsistencia` Valor 0/1. |
| Votaciones | `WSLegislativo.asmx/retornarVotacionesXAnno?prmAnno=` | 672 en 2026. |
| Voto detalle | `WSLegislativo.asmx/retornarVotacionDetalle?prmVotacionId=` | `OpcionVoto` Valor 0/1/2/3/4. |
| Mociones | `WSLegislativo.asmx/retornarMocionesXAnno?prmAnno=` | `CamaraOrigen` 1=Cámara, 2=Senado. |
| Proyecto detalle | `WSLegislativo.asmx/retornarProyectoLey?prmNumeroBoletin=` | `Autores/ParlamentarioAutor/Diputado`. |

## Dominios canónicos (validados contra la API)

- **TipoAsistencia:** `0` no_asiste, `1` asiste.
- **OpcionVoto:** `0` en_contra, `1` a_favor, `2` abstencion, `3` dispensado,
  `4` no_vota.
- **CamaraOrigen:** `1` cámara_diputados, `2` senado.

## Huecos de la fuente (documentados, no fabricados)

| Campo | Estado | Decisión |
|-------|--------|----------|
| distrito / región | No expuesto por la API | `NA`; requeriría BCN/SERVEL (fuera de alcance). |
| tendencia izq/der | No viene en la API | Derivada de `MAPA_PARTIDO_TENDENCIA`; hoy 18 partidos sin clasificar. Decisión del titular. |
| estado de tramitación | No expuesto | `NA`; `admisible` como proxy. |
| rol autor/coautor | `Orden`=0 para todos | Todos `firmante`; la API no jerarquiza. |

## Constantes y configuraciones

Fuente canónica: `10_utils/10_configuracion.R`.

| Constante | Valor | Nota |
|-----------|-------|------|
| `ANIO_PROCESO` | `2026` | Acota sesiones/votaciones/mociones. |
| `MAX_SESIONES_DETALLE` | `Inf` | Asistencia por sesión (calls baratas). |
| `MAX_VOTACIONES_DETALLE` | `120` | Tope de validación; `Inf` = año completo. |
| `MAX_PROYECTOS_DETALLE` | `150` | Tope de validación; `Inf` = año completo. |
| `PAUSA_API_SEG` | `0.12` | Cortesía entre llamadas de detalle. |
| `REFRESCAR_API` | `FALSE` | `options(camara.refrescar=TRUE)` para forzar. |

## Convenciones específicas

- Todo acceso a la API pasa por `descargar_xml_camara()` (reintentos con
  backoff, timeout, User-Agent).
- Toda captura cruda pasa por `con_cache()` (idempotencia y cortesía).
- Escritura atómica (`escribir_atomico()`, patrón write→rename) en todo
  artefacto que alimente pasos siguientes.
