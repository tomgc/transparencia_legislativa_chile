# Log de ejecución — P-63: captura XML cruda del 36 y rescate del nodo `Votaciones`

- **Encargo:** `50_documentacion/andamios/50_encargo_p63_captura_xml_y_nodo_votaciones.md`
- **Sesión:** 17. **Fecha:** 2026-08-08.
- **Rama:** `feat/captura-xml-y-nodo-votaciones`. **PR abierto, no mergeado.**
- **Resultado:** el paso 36 persiste el XML de respuesta tal cual bajo clave propia, el
  parser deja de descartar `Votaciones` (14 campos reales), y el portal publicado no cambió:
  **156 de 156** artefactos idénticos excluido `metadatos.generado`. **12 de 12** criterios
  CUMPLEN; panel adversarial **4 de 4** sin hallazgos.

---

## 1. Compuertas de precondición (§3)

### G1 — El 35

**No es consumidor de `parsear_contenido_proyecto()`: 0 ocurrencias** en
`30_procesamiento/35_extraer_proyectos.R`. Barrido recursivo de los **24** archivos `.R` del
repositorio: **1 definición** (`10_utils.R`) y **1 sola invocación real**
([36:82](../../../30_procesamiento/36_extraer_detalle_proyectos.R:82)).

El 35 parsea `./Autores/ParlamentarioAutor` por su cuenta
([35:58-61](../../../30_procesamiento/35_extraer_proyectos.R:58)) y cachea aparte bajo la
clave `proyectos_long_<anio>` ([35:26-27](../../../30_procesamiento/35_extraer_proyectos.R:26)),
persistiendo el tibble de autorías y sellando con `ruta_cache(proyectos_long…)`
([35:107-111](../../../30_procesamiento/35_extraer_proyectos.R:107)).

**Efecto de extender el retorno del parser sobre el 35: ninguno.** No se tocó el 35.

> **HALLAZGO 1 — comentario obsoleto, corregido.** El comentario que respaldaba la hipótesis
> (`10_utils.R`, "Compartido por 35 (proyectos autorados) y 36 (proyectos votados) -> DRY")
> era falso. Se reescribió declarando el consumidor único y dejando registro de la medición.
> No dispara el §9: esa cláusula se activa si el 35 **no puede** quedar indemne, y aquí queda
> indemne por no ser consumidor.

### G2 — El 39

Consume **4 de las 5** columnas de `proyectos_detalle.rds`:

| Columna | Línea en el 39 | ¿La consume? |
|---|---|---|
| `boletin` | [:74](../../../30_procesamiento/39_consolidar_json.R:74), [:83](../../../30_procesamiento/39_consolidar_json.R:83), [:88](../../../30_procesamiento/39_consolidar_json.R:88) | Sí |
| `nombre` | [:84](../../../30_procesamiento/39_consolidar_json.R:84) | Sí |
| `tipo_iniciativa` | [:85](../../../30_procesamiento/39_consolidar_json.R:85) | Sí |
| `materias` | [:86](../../../30_procesamiento/39_consolidar_json.R:86) | Sí |
| `n_materias` | — | **No: 0 ocurrencias** |

`det_map` se arma con **lista explícita de campos**
([39:82-87](../../../30_procesamiento/39_consolidar_json.R:82)), así que columnas nuevas en el
intermedio son inertes para el JSON público. Fuera del pipeline lo leen 4 andamios de
diagnóstico vía `readRDS`; una extensión aditiva no los rompe.

### G3 — Configuración

`CORTE_FECHA <- "2026-08-03"` ([10_configuracion.R:41](../../../10_utils/10_configuracion.R:41));
`ANIO_PROCESO <- 2026L` ([:27](../../../10_utils/10_configuracion.R:27)). Ninguno heredado de
un documento.

### G4 — Peso real

10 boletines descargados (única descarga previa a la autorización), muestreo estratificado
determinista sobre la partición del universo: 5 votados + 5 solo autorados.

| Estrato | n | XML sin comprimir (medio) | `.rds` de los 5 |
|---|---|---|---|
| A — votado | 5 | 11 481 B | 6 253 B |
| B — solo autorado | 5 | 2 114 B | 1 818 B |

Extrapolado a 381: **1,80 MB sin comprimir**, **0,229 MB comprimido**. La extrapolación del
`.rds` es lineal por estrato, o sea **cota superior**. Bajo el umbral de 2 MB del §4.

**Contraste con la captura real, ya descargada:** **132 494 bytes = 0,126 MB**, un **45 %
por debajo** de la cota extrapolada y el **6,3 %** del umbral de 2 MB. La dirección del error
es la anunciada: gzip comparte diccionario entre 381 documentos casi idénticos, así que
extrapolar linealmente desde bloques de 5 sobreestima. La estimación sirvió para decidir y no
subestimó el costo, que es lo que se le pedía.

### G5 — Universo, contado

| Autorados | Votados | Unión | Intersección | Solo autorados |
|---|---|---|---|---|
| **272** | **115** | **381** | 6 | 266 |

Identidad `272 + 115 − 6 = 381` verificada. La cifra heredada de 381 quedó **confirmada por
recuento propio**, no citada.

### G6 — Forma real del nodo

Contenedor `./Votaciones` presente en **10 de 10**, con hijos en **5 de 10** — exactamente los
votados (**5 de 5** del estrato A, **0 de 5** del B). Hijo: `VotacionProyectoLey`, **44**
elementos en la muestra.

**14 campos reales, no los 4 que hipotetizaba el traspaso v16.** Los 4 existen (4 de 4), pero
el traspaso omitía **10**: `Descripcion`, `Fecha`, `Id`, `Quorum`, `Resultado`, `Tipo`,
`TotalAbstencion`, `TotalDispensado`, `TotalNo`, `TotalSi`.

**6 de 14 traen el código de dominio en un atributo** (`Valor` en `Quorum`, `Resultado`,
`Tipo` y `TipoVotacionProyectoLey`; `Id` en `TramiteConstitucional` y `TramiteReglamentario`),
en 44 de 44 nodos.

---

## 2. Punto de autorización (§4)

Reportado al titular con los tres números de G5, el peso extrapolado, la estructura real y el
efecto sobre 35 y 39. La condición de continuación automática (peso < 2 MB) **se cumplía**;
aun así se pausó porque el titular declaró ese punto como pausa explícita, conforme al §9
("si crees que detenerte es innecesario, detente y dilo").

El titular autorizó y fijó **seis ajustes que priman sobre el encargo**: contrato de 14 campos
(no 4); una fila por boletín con las votaciones como list-col más `n_votaciones` escalar;
código y glosa en los 6 campos con atributo; corrección del comentario obsoleto; C6 con dos
denominadores contados; y el cruce `votacion_id` medido pero **no implementado**.

---

## 3. Implementación

| Pieza | Ubicación |
|---|---|
| `parsear_contenido_proyecto()`, retorno extendido con `votaciones` | [10_utils.R:429](../../../10_utils/10_utils.R:429) |
| `VOTACIONES_COLUMNAS` (esquema de 20 columnas, un solo sitio) | [10_utils.R:449](../../../10_utils/10_utils.R:449) |
| `parsear_votaciones_proyecto()` | [10_utils.R:457](../../../10_utils/10_utils.R:457) |
| `capturas_crudas_de_paso("36")` → captura XML | [10_utils.R:280](../../../10_utils/10_utils.R:280) |
| Estados de la captura (3, antes 2 colapsados) | [36:97](../../../30_procesamiento/36_extraer_detalle_proyectos.R:97) |
| `capturar_xml_detalle()` (clave `detalle_proyectos_xml_<anio>`) | [36:101](../../../30_procesamiento/36_extraer_detalle_proyectos.R:101) |
| `derivar_detalle()` (parsea DESDE la captura, no del vuelo) | [36:163](../../../30_procesamiento/36_extraer_detalle_proyectos.R:163) |
| `hash_origen_de()` apuntando a la captura nueva | [36:245](../../../30_procesamiento/36_extraer_detalle_proyectos.R:245) |

**Esquema del list-col `votaciones` (20 columnas, todas `character`):** 8 campos llanos
(`votacion_id`, `descripcion`, `fecha`, `total_si`, `total_no`, `total_abstencion`,
`total_dispensado`, `articulo`) y 6 pares código/glosa
(`quorum_*`, `resultado_*`, `tipo_*`, `tipo_votacion_*`, `tramite_constitucional_*`,
`tramite_reglamentario_*`), con el patrón `attr_nodo()` + `texto_nodo()` del 33 y el 34.

**Decisiones de extracción, declaradas:** los valores se conservan **sin transformar**
(character tal cual la fuente, `""` → `NA`); la única excepción es `votacion_id`, que pasa por
`como_llave()` por ser llave. No se coerciona a entero ni se trunca `fecha` (la fuente da fecha
y hora): cualquier coerción es decisión del consumidor, no del extractor. El caso vacío
devuelve un `data.frame` de 0 filas **con las 20 columnas**, nunca `NULL`.

**Corrida con red: una sola,** `camara.refrescar = TRUE` fijado a propósito y restaurado con
`on.exit`. Se corrió **solo el paso 36**: poner el flag y correr `run_all()` habría
re-descargado también 32–35, que ya tenían su captura del corte. **90,3 s**, 381 de 381
resueltos, 0 errores de red, 0 boletines no reconocidos.

---

## 4. Criterios de éxito (§6)

| # | Criterio | Medición | Estado |
|---|---|---|---|
| C1 | Captura completa | **381 de 381** entradas con XML no vacío; **0** vacías; unión de G5 = 381; boletines de la captura ≡ unión | **CUMPLE** |
| C2 | Captura anterior intacta | md5 de `20260803_detalle_proyectos_2026_tope-inf.rds` idéntico (`23cba02c…`); **43 de 43** preexistentes iguales; 0 perdidos o renombrados | **CUMPLE** |
| C3 | XML reparseable | Columna `character`; **10 de 10** entradas releídas del `.rds` reparsean con `Nombre` no vacío | **CUMPLE** |
| C4 | El tibble no cambió en lo viejo | **0 diferencias** en las 5 columnas previas sobre **381 boletines comunes** (referencia: la captura anterior, que guardaba justamente el tibble del parser previo) | **CUMPLE** |
| C5 | Claves nuevas presentes | `n_votaciones` `integer`; `votaciones` list-col de `data.frame`; esquema de 20 columnas y todas `character` en **381 de 381** | **CUMPLE** |
| C6 | Cobertura del nodo | **115 de 115** boletines votados con ≥1 elemento (contraste: **0 de 266** solo autorados); **723** nodos `VotacionProyectoLey`; 13 de 20 campos al 100 %; `articulo` **619 de 723** (85,6 %) | **CUMPLE** |
| C7 | Regeneración sin red | 6 intermedios borrados; **0 intentos HTTP**; `run_all()` completo en **13,6 s**; `validar_corte()` **6 de 6** | **CUMPLE** |
| C8 | La guarda apunta bien | `capturas_crudas_de_paso("36")` → `20260803_detalle_proyectos_xml_2026_tope-inf.rds`, presente; escenario "intermedio ausente" resuelto sin red | **CUMPLE** |
| C9 | Neutralidad del artefacto | **156 de 156** idénticos excluido `metadatos.generado` (volátil por construcción, [39:365](../../../30_procesamiento/39_consolidar_json.R:365)); **0** diferencias fuera de él; `corte_fecha` **155 de 155**; **0** rutas de clave nuevas (85 = 85 en 3 perfiles) | **CUMPLE** |
| C10 | `docs/` intacto | `git status` acotado: **0 líneas** (y 0 en `40_salidas/json/`) | **CUMPLE** |
| C11 | Dato personal | **0 de 12** campos sensibles con valor no vacío sobre 381 documentos; **0** coincidencias de patrón RUT (con control positivo del regex). Único dato de persona: 2 089 elementos `Diputado` con `Id`, `Nombre`, `ApellidoPaterno`, `ApellidoMaterno` — parlamentarios en su rol público, ya publicados en el portal. **Decisión: se versiona** | **CUMPLE** |
| C12 | El PR declara sus conteos | Cuerpo del PR con C1, C4, C6 y C9, cada una con denominador | **CUMPLE** |

**12 CUMPLE, 0 NO CUMPLE.**

---

## 5. Panel adversarial (§7)

| # | Verificador | Técnica propia | Veredicto |
|---|---|---|---|
| **V1** | El puntero externo | Recorrido en profundidad de los **50** `.rds` buscando `externalptr` y clases de xml2, más prueba de **uso** (reparsear 25 entradas) y **contraprueba** que serializa un `xml_document` a propósito para demostrar que el detector dispara | **SIN HALLAZGOS**: 0 de 50 con puntero; 25 de 25 reparsean; la contraprueba confirma que un `xml_document` serializado se lee sin error, el detector lo marca y usarlo falla |
| **V2** | El denominador | Recuento propio sin `10_utils.R`, con xpath **distinto** (`//Votaciones/*` en vez de `./Votaciones/VotacionProyectoLey`) para no heredar un error de xpath del ejecutor | **CIFRAS VERIFICADAS**: unión 381; **723** elementos; **115 de 115** votados; **0 de 266** solo autorados; `articulo` **619 de 723**; **0 de 381** boletines donde su recuento difiera del declarado |
| **V3** | La inmutabilidad | **Baseline propio**: no usa el md5 del ejecutor sino el objeto de git en `HEAD` (`git ls-tree` vs `git hash-object`), un tercero independiente | **SIN HALLAZGOS**: **44 de 44** blobs versionados idénticos (43 `.rds` + `.gitkeep`), 0 faltantes, +1 archivo nuevo; 7 claves de caché resuelven a 7 rutas distintas; la nueva y la vieja coexisten |
| **V4** | La promesa de la guarda | Corte de red en **otra capa** que el ejecutor: `curl::curl_fetch_memory` (transporte) en vez de `httr::GET`, con contraprueba aislada de que el corte funciona | **LA GUARDA CUMPLE**: contraprueba corta una llamada real y la cuenta (1); con los 6 intermedios borrados, `run_all()` completa en **13,2 s** con **0 intentos de transporte**, 6 de 6 reconstruidos, insumo intacto, 723 elementos regenerados sin red |

---

## 6. Hallazgos y decisiones tomadas en autonomía

1. **HALLAZGO 1 — el comentario de `10_utils.R` declaraba un consumidor inexistente.** Corregido en la implementación, por instrucción explícita del titular; registrado aquí como hallazgo, no como cambio incidental.
2. **HALLAZGO 2 — mi primer chequeo del invariante 14 dio un falso positivo.** Buscaba colisión de **nombre** y marcó `n_votaciones`, que ya existía en el bloque `votaciones` del perfil desde la sesión 1 ([39:323](../../../30_procesamiento/39_consolidar_json.R:323)) y no tiene relación con la columna nueva del intermedio. El test correcto compara el **conjunto de rutas de clave** contra `HEAD`: 0 nuevas. El artefacto nunca estuvo mal; el instrumento sí.
3. **C11 se adelantó a la descarga completa**, midiéndolo sobre la muestra de 10 ya en disco: si hubiera aparecido dato personal, el §9 obligaba a detenerse y la descarga de 381 habría sido gasto perdido.
4. **La corrida con red se acotó al paso 36**, no a `run_all()`, para que `camara.refrescar = TRUE` no arrastrara a 32–35 a re-descargar lo que ya tenían.
5. **C4 se contrastó contra la captura anterior**, que es justamente el tibble derivado por el parser previo y es inmutable, porque el intermedio está gitignored y no existe versión en `HEAD` contra la cual comparar.
6. **La red se probó cortando de verdad, no confiando en `camara.refrescar = FALSE`**, y en dos capas distintas (ejecutor y V4), cada una con su contraprueba: un contador que nunca se arma no prueba nada.
7. **Los valores del nodo se extraen sin transformar.** Ni coerción a entero ni truncado de fecha: el XML crudo está en disco y cualquier coerción es reversible desde ahí, pero una decisión silenciosa del extractor no lo sería.

---

## 7. Insumo para P-66 (medido, NO implementado)

El `Id` de `VotacionProyectoLey` es una llave directa hacia `votos.rds`, lo que abre la
trazabilidad voto ↔ proyecto sin heurística de boletín. Medido sobre el universo completo:

| Medida | Cifra |
|---|---|
| `votacion_id` distintos en el nodo `Votaciones` | **723** |
| `votacion_id` distintos en `votos.rds` | **791** |
| Intersección | **546 de 723** del nodo (75,5 %) |
| En el nodo pero no en `votos.rds` | **177** |
| En `votos.rds` pero no en el nodo | **245** |

Conforme al ajuste 6 del titular y al invariante 14, **no se implementó nada** de este cruce
en esta sesión: queda como insumo de P-66. Las dos asimetrías (177 y 245) son la pregunta
abierta que ese pendiente debería medir antes de decidir contrato.

---

## 8. Lo que este encargo NO hizo (§10)

No mergeó el PR. No tocó `docs/` ni ningún artefacto publicado. No agregó bloque `materias`
ni vista temática. No tocó `sellar()`, `leer_sellado()` ni `validar_corte()`. No abordó P-59
ni P-60. No movió archivos entre carpetas. La captura anterior del 36 sigue en
`20_insumos/camara/`, intacta: dejó de leerse, no se borró.
