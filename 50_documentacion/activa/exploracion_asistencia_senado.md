# Exploracion — asistencia nominal por sesion del Senado (H1-bis)

> Tercer diagnostico insumos-first (rama `explore/api-senado-v02-asistencia`).
> Cierra un sub-hueco de v02: si el Senado expone asistencia NOMINAL POR SESION o
> solo el agregado por legislatura. Muestras regeneradas por
> `30_procesamiento/31d_explorar_asistencia_senado.R` en
> `50_documentacion/andamios/exploracion_asistencia_senado/`. NO se construyo pipeline.

- **Fecha:** 2026-07-10

## Veredicto

**SI — existe asistencia NOMINAL POR SESION, estructurada y cruzable por
`ID_PARLAMENTARIO`.** No hubo que recurrir a la via secundaria: la via primaria
(backend `web-back.senado.cl`) la resolvio.

El hallazgo clave es que **el mismo endpoint es polimorfico segun el parametro**:

| Llamada | Devuelve |
|---------|----------|
| `api/sessions/attendance?id_legislatura=<id>` | AGREGADO por senador (asistio 92/105, justificado, sin_justificar) — lo que mapeo v02 |
| `api/sessions/attendance?id_sesion=<id>` | **NOMINAL de ESA sesion** (asistio/ausente + justificacion, por senador, con id) |

v02 solo probo `id_legislatura` y por eso concluyo (erroneamente) que solo existia
el agregado. Con `id_sesion` aparece el detalle nominal.

## Endpoint, parametro y formato

- **Endpoint:** `GET https://web-back.senado.cl/api/sessions/attendance?id_sesion=<ID_SESION>`
- **Parametro de sesion:** `id_sesion` (el `ID_SESION` del backend; NO el numero
  humano de sesion). Otros nombres probados (`id_reunion`, `id`, `session_id`)
  devuelven vacio: el correcto es `id_sesion`.
- **Respuesta:** JSON `{TOTAL_SENADORES, ID_SESION, NUMERO_SESION,
  FECHA_HORA_INICIO, FECHA_HORA_TERMINO, DATA[]}`. Cada elemento de `DATA` (un
  senador):

```
ASISTENCIA        (dominio: "Asiste" / "Ausente")
ID_PARLAMENTARIO  (id estable = PARLID = ID_PARLAMENTARIO del roster/votos)
NOMBRE
APELLIDO_PATERNO
APELLIDO_MATERNO
SLUG
ID_SESION
NUMERO_SESION
JUSTIFICACION     (dominio observado: "Enfermedad" / "Otras actividades" / null)
```

- **Universo de sesiones:** `GET api/sessions?id_legislatura=<id>` lista las
  sesiones de una legislatura (`ID_SESION`, `NRO_SESION`, `FECHA`, `TIPO_SESION`,
  ...; p. ej. la legislatura backend 504 declara `total: 105` sesiones). El
  `ID_SESION` tambien viene en cada votacion de `api/votes` (`ID_SESION`), lo que
  permite alinear votaciones y asistencia por sesion.

## Evidencia (2 sesiones distintas, muestras guardadas)

| Muestra | ID_SESION | N sesion | Fecha | Senadores | ASISTENCIA | id 1110 |
|---------|-----------|----------|-------|-----------|-----------|---------|
| `senado_backend_sesion_10221_muestra.json` | 10221 | 41 | 08-07-2026 | 50 | 48 Asiste / 2 Ausente | presente |
| `senado_backend_sesion_9884_muestra.json` | 9884 | 102 | 05-03-2025 | 50 | 46 Asiste / 4 Ausente | presente |

Las dos sesiones dan distribuciones distintas y estado por-senador distinto (un
mismo senador Asiste en una y Ausente en otra) → son registros por-sesion reales,
no el agregado repetido. El id estable `1110` (Pedro Araya) aparece en ambas y
cruza con el roster.

## Cruce por id y membresia dependiente del tiempo (nota para el pipeline)

El cruce es **por `ID_PARLAMENTARIO`, determinista, sin fuzzy**. Pero la
composicion del Senado cambia en el tiempo, asi que la asistencia de una sesion
debe unirse al roster **vigente EN LA FECHA de esa sesion**, no al roster actual:

- Sesion **reciente** (10221, jul-2026): **50/50** de los asistentes son senadores
  del roster vigente actual.
- Sesion **historica** (9884, mar-2025): solo **31/50** cruzan con el roster
  vigente actual — los otros 19 dejaron el Senado en la renovacion de marzo-2026.
  El id es el mismo espacio; lo que cambio es quien es senador. Para poblar
  historia habria que resolver esos ids contra el padron historico
  (`api/parlamentarios` sin `vigentes=1`, o por fecha), no contra `vigentes=1`.

## Implicancia para el contrato del pipeline: SIMETRICO

El contrato puede ser **simetrico con la Camara**: asistencia **nominal por sesion
en ambas camaras**. La Camara la obtiene en `33_extraer_asistencia.R`
(`retornarSesionAsistencia` por `prmSesionId`, con `TipoAsistencia` 0/1 por
diputado); el Senado la obtiene en `api/sessions/attendance?id_sesion=<id>`
(`ASISTENCIA` Asiste/Ausente + `JUSTIFICACION`, por senador). Estructura analoga:
listar sesiones de la legislatura → pedir el detalle nominal por cada `ID_SESION`.
No hace falta conformarse con el agregado.

Diferencia menor de esquema: el Senado ademas expone `JUSTIFICACION` (motivo de la
ausencia, texto) que la Camara no da; y el estado es texto ("Asiste"/"Ausente") en
vez del `Valor` 0/1 de la Camara.

## Tabla de vias

| Via | ¿responde? | ¿nominal por sesion? | ¿id estable? | ¿sala o comision? |
|-----|-----------|---------------------|--------------|-------------------|
| Backend `api/sessions/attendance?id_sesion=` | **Si** | **Si** (Asiste/Ausente + justificacion) | **Si** (`ID_PARLAMENTARIO`) | **Sala** |
| Backend `api/sessions/attendance?id_legislatura=` (v02) | Si | No (agregado por legislatura) | Si | Sala |
| `tramitacion.senado.cl/.../asist_x_senador` (via secundaria) | no probada — no fue necesaria (Fase 1 resolvio) | — | — | (seria comision, no sala) |

> La via secundaria (`mo=comisiones&ac=asist_x_senador`) no se exploro porque la
> Fase 1 resolvio el veredicto con evidencia; ademas su nombre sugiere asistencia a
> COMISIONES, no a SALA (el contrato del dashboard es sala). Queda como via de
> respaldo documentada, no verificada.
