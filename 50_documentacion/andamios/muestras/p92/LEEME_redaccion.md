# Muestras crudas del sondeo P-92 — nota de redacción

Las respuestas de este directorio son **crudas y sin tocar, con una excepción
declarada**: en los tres XML de comisiones se redactaron los campos de contacto.

## Qué se redactó y por qué

`retornarComisionesXPeriodo` y `retornarComisionesVigentes` devuelven `<Correo>`,
`<Telefono>` y `<Fax>` por comisión. Este repositorio es **público**, y el propio
proyecto ya tomó esta decisión antes: `50_documentacion/activa/50_catalogo_fuentes_camara.md`
§6 dejó fuera del versionado el caché de exploración del 2026-08-07 porque contenía
`EMAIL` y `FONO`, con el argumento de que *agregar eso a un repositorio público no es
lo mismo que consultarlo en la fuente*. Se aplica el mismo criterio.

| Archivo | Campos redactados | md5 de la respuesta original | md5 del archivo redactado |
|---|---|---|---|
| `comisiones_periodo_10.xml` | 382 | `583474a2…` | `24fda4ad…` |
| `comisiones_periodo_11.xml` | 6 | `5015dfc5…` | `39686cb7…` |
| `comisiones_vigentes.xml` | 6 | `5015dfc5…` | `39686cb7…` |

El valor original se reemplazó por la cadena `[REDACTADO-P92]`. **El md5 de la
respuesta original está en el libro mayor** (`../p92_llamadas_http.csv`, columnas
`n`, `url`, `md5`), así que la integridad de la descarga sigue siendo auditable
aunque el archivo en disco ya no la reproduzca byte a byte.

⚠️ **No compares el md5 de estos tres archivos contra el libro mayor: no van a
coincidir, y esa discrepancia es intencional.** Los demás archivos del directorio sí
coinciden.

## Qué NO se redactó

- **`diputados_historico.xml`**: `RUT` no vacío en **0 de 633** diputados (la API no
  lo expone). `FechaNacimiento` en **507 de 633**: es dato público de autoridades
  electas, servido por la API de datos abiertos, y el pipeline ya lo consume para el
  padrón vigente. Queda dentro del invariante 6 (datos 100 % públicos, Rama A).
- Todo lo demás: catálogos, materias, páginas de error de Cloudflare y las respuestas
  de los controles negativos, ninguna con dato de contacto.

## Reproducibilidad

Nada de esto afecta la reproducibilidad de las mediciones: ninguna cifra del veredicto
usa `Correo`, `Telefono` ni `Fax`. El cruce de F2b usa solo `Id`, `Nombre`, `Alias`,
`Tipo` y `Numero`. Volver a correr
`Rscript 50_documentacion/andamios/50_sondeo_p92_f2.R` baja las respuestas originales.
