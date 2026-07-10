# Log de ejecución — Exploración de la API del Senado

**Fecha:** 2026-07-10
**Rama:** `explore/api-senado` (desde `main`; sin push, sin PR, sin merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `xml2`.
**Naturaleza:** andamio congelado (diagnóstico insumos-first, no se actualiza).

## 1. Resumen

Diagnóstico reproducible de los web services públicos del Senado
(`tramitacion.senado.cl/wspublico`) para las cuatro entidades del contrato:
senadores, asistencia, votaciones y proyectos. Se descubrió la firma real en
vivo (no se asumió), se trajeron muestras crudas de cada entidad con fuente, y
se comparó su esquema contra el de la Cámara. **Tres de cuatro entidades tienen
fuente; la asistencia nominal es un hueco total.** No se construyó pipeline, no
se tocó `20_insumos/`, `40_salidas/`, `docs/`, ni ningún script del flujo
existente. Solo se agregaron archivos nuevos.

## 2. Qué se descubrió por entidad (fuente + hallazgo)

| Entidad | Fuente localizada | Forma | Nota clave |
|---------|-------------------|-------|-----------|
| Senadores | `senadores_vigentes.php` | `<senadores><senador>` | `PARLID`, `REGION`, `CIRCUNSCRIPCION`, `PARTIDO` (texto). **31** ítems (< 50 esperado). |
| Proyectos | `tramitacion.php?boletin=<n>` | `<proyectos><proyecto>` | `n` = número antes del guion. Expone `estado` (hueco de la Cámara). Autores por **nombre**. |
| Votaciones | `//votaciones` anidado en `tramitacion.php` | `votacion/DETALLE_VOTACION/VOTO` | Join voto→proyecto **inherente**. `SELECCION` explícito (Si/No/Abstencion/Pareo). Votante por **nombre, sin id**. |
| Asistencia | — (404 en todas las variantes) | — | **HUECO**: sin endpoint; `sesiones.php` no anida asistencia nominal. |
| (soporte) Sesiones | `sesiones.php?legislatura=<id>` | `<sesiones><sesion>` | Legislatura vigente autodetectada = 374 (45 sesiones). Sin asistencia. |

## 3. Muestras guardadas (auto-auditadas, XML parseable real)

Ruta: `50_documentacion/andamios/exploracion_api_senado/`

| Archivo | bytes | ítems | raíz | verificación |
|---------|-------|-------|------|-------------|
| `senadores_muestra.xml` | 12897 | 31 senadores | `<senadores>` | OK |
| `proyectos_muestra.xml` | 2294 | 1 proyecto (bol. 16972) | `<proyectos>` | OK |
| `votaciones_muestra.xml` | 16287 | 1 votación / 29 votos (bol. 15776) | `<proyectos>` | OK (21 Si / 2 No / 6 Abst / 0 Pareo, consistente) |
| `sesiones_muestra.xml` | 14473 | 45 sesiones (leg. 374) | `<sesiones>` | OK |

Asistencia: sin muestra (hueco declarado, no fabricado).

## 4. Huecos / # REVISAR

- **Asistencia nominal:** sin fuente en `wspublico` (caso de detención #3; ver §7).
- **Roster de 31 senadores:** por debajo de la dotación esperada (~50). Sin
  endpoint de roster completo alternativo. A confirmar con el titular.
- **Identidad por nombre:** votaciones y autorías traen `PARLAMENTARIO` como
  nombre (tres formatos distintos entre roster/autores/votos), sin `PARLID`.
- **Sin catálogo global** de boletines ni de votaciones del Senado: iteración
  boletín-por-boletín, sembrando la lista desde la Cámara (`CamaraOrigen=2`).
- **Partido como texto** (`"P.P.D."`) sin código → normalización pendiente para
  poder derivar `tendencia`.

## 5. Qué costó (esfuerzo real)

- El protocolo NO es SOAP-con-sobre: son endpoints `.php` con XML plano sin
  namespace. El cliente `httr2` con `req_url_query` + retry/backoff bastó.
- El obstáculo mayor fue el **formato del parámetro `boletin`**: `tramitacion.php`
  espera el número ANTES del guion (`16972`), no el boletín completo (`16972-06`);
  con el sufijo devuelve "No existe el número de boletín". Se descubrió probando
  variantes de formato, no boletines.
- `votaciones.php` responde vacío con todo parámetro probado (año, legislatura,
  fecha, sesión, boletín) → se concluyó que las votaciones sólo viven anidadas en
  `tramitacion.php`, y se validó encontrando un boletín con votación nominal real
  (escaneo de boletines Senado 2022-2023 hasta el primer `<votaciones>` poblado).
- La legislatura no tiene endpoint de listado → se sondea el rango descendente.

## 6. Decisiones tomadas

- **Reusar los helpers genéricos de `10_utils.R`** (`instalar_si_falta`,
  `log_msg`, `obtener_raiz_proyecto`, `%||%`) pero **NO** el cliente HTTP de la
  Cámara (`descargar_xml_camara`): se implementó `descargar_senado()` con `httr2`
  (invariante del encargo).
- **Muestras como bytes crudos** (`writeBin(resp_body_raw)`), no re-serializadas,
  para preservar exactamente lo que envía el servidor.
- **Boletines de muestra fijos** (16972 proyecto limpio, 15776 con votación) por
  reproducibilidad; documentados como representativos.
- **No detener el encargo** en el hueco de asistencia: se completó el diagnóstico
  de las otras tres entidades y se elevó la asistencia como el riesgo #1 (§7), que
  es más útil que abortar con entregables incompletos. No se fabricó fuente.

## 7. Caso de detención #3 — asistencia nominal (elevado, no improvisado)

El ejemplo textual del caso de detención #3 del encargo ("el Senado no expone
asistencia nominal en absoluto") **se materializó**. La asistencia es un hueco
total en `wspublico`. Implicación: la métrica de asistencia del contrato del
dashboard **no es poblable para el Senado** con esta fuente. Requiere decisión
del titular: (a) omitir asistencia para senadores, o (b) incorporar una segunda
fuente. No se avanzó en ninguna de las dos (fuera de alcance de un diagnóstico).

## 8. Invariantes verificados

| Invariante | Estado |
|-----------|--------|
| R único lenguaje (toda inspección en R; cero Python/curl+jq) | PASA |
| `httr2` para el Senado; no se reusó el cliente de la Cámara | PASA |
| Llaves como character (documentado; `PARLID` num-como-string) | PASA |
| Naming sin tildes/ñ/espacios en archivos nuevos | PASA |
| No modificar 31-39, `00_run_all.R`, `10_utils/*`, `10_configuracion.R` | PASA |
| No tocar `20_insumos/`, `40_salidas/`, `docs/` | PASA |
| Script nuevo NO agregado a `run_all`/`PASOS` | PASA |
| No inventar cobertura (asistencia reportada como hueco) | PASA |
| Rama `explore/api-senado`; sin push/PR/merge | PASA |

## 9. Archivos nuevos (entregables)

- `30_procesamiento/31b_explorar_api_senado.R` — script reproducible.
- `50_documentacion/activa/exploracion_api_senado.md` — análisis + comparación.
- `50_documentacion/andamios/exploracion_api_senado/{senadores,proyectos,votaciones,sesiones}_muestra.xml`
- `50_documentacion/andamios/logs/20260710_exploracion_api_senado_log.md` — este log.

Nota: el working tree traía cambios previos ajenos a este encargo (refresh
automatizado de `50_documentacion/estructura/*` y `backlog_acumulativo.md`); no
se tocaron ni se incluyen en los commits de esta rama.
